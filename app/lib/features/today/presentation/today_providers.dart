import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/local_prefs.dart';
import '../../../core/env.dart';
import '../../../core/utils/date_only.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_state.dart';
import '../../gamification/domain/xp.dart';
import '../../plan/domain/enums.dart';
import '../../plan/domain/template_renderer.dart' as domain;
import '../../plants/presentation/plant_providers.dart';
import '../../settings/presentation/settings_providers.dart';
import '../data/notification_gateway.dart';
import '../data/outbox_syncer.dart';
import '../data/push_service.dart';
import '../data/reminder_scheduler.dart';
import '../data/task_repository.dart';
import '../data/today_local_store.dart';
import '../domain/outbox_entry.dart';
import '../domain/reminder_planner.dart';
import '../domain/today_builder.dart';
import '../domain/today_snapshot.dart';
import 'today_model.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers (overridden with fakes in tests)
// ---------------------------------------------------------------------------

/// Device clock; tests override it.
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  if (!Env.isConfigured) throw StateError('Supabase is not configured');
  return SupabaseTaskRepository();
});

final todayLocalStoreProvider = Provider<TodayLocalStore>(
  (ref) => DriftTodayLocalStore(ref.watch(appDatabaseProvider)),
);

final outboxSyncerProvider = Provider<OutboxSyncer>(
  (ref) => OutboxSyncer(
    store: ref.watch(todayLocalStoreProvider),
    repository: ref.watch(taskRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

final notificationGatewayProvider = Provider<NotificationGateway>(
  (ref) => LocalNotificationsGateway(),
);

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => ReminderScheduler(
    ref.watch(notificationGatewayProvider),
    clock: ref.watch(clockProvider),
  ),
);

final pushMessagingProvider = Provider<PushMessaging>(
  (ref) => FirebasePushMessaging(),
);

final pushTokenRepositoryProvider = Provider<PushTokenRepository>((ref) {
  if (!Env.isConfigured) throw StateError('Supabase is not configured');
  return SupabasePushTokenRepository();
});

/// Quiet hours (`users.quiet_start` / `quiet_end`). The profile model does
/// not carry them yet, so reminders ignore quiet hours until it does.
final quietHoursProvider = Provider<QuietHours?>((_) => null);

/// Signed-in user id, or null.
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  try {
    return ref.read(authRepositoryProvider).currentUserId;
  } catch (_) {
    return null;
  }
});

// ---------------------------------------------------------------------------
// UI state
// ---------------------------------------------------------------------------

enum TodayGrouping { window, project }

class TodayGroupingNotifier extends Notifier<TodayGrouping> {
  @override
  TodayGrouping build() => TodayGrouping.window;
  void set(TodayGrouping g) => state = g;
}

final todayGroupingProvider =
    NotifierProvider<TodayGroupingNotifier, TodayGrouping>(
      TodayGroupingNotifier.new,
    );

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

const _uuid = Uuid();

class TodayNotifier extends Notifier<TodayModel> {
  bool _syncing = false;
  bool _disposed = false;
  Timer? _debounce;
  StreamSubscription<void>? _realtime;

  @override
  TodayModel build() {
    final lang = ref.watch(localeProvider).languageCode;
    final userId = ref.watch(currentUserIdProvider);
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _debounce?.cancel();
      _realtime?.cancel();
    });
    // Toggling a notification type re-plans reminders.
    ref.listen(notificationSettingsProvider, (_, _) => rescheduleReminders());
    final model = TodayModel(
      today: dateOnly(ref.read(clockProvider)()),
      lang: lang,
      userId: userId,
    );
    if (userId != null) scheduleMicrotask(_bootstrap);
    return model;
  }

  Future<void> _bootstrap() async {
    final store = ref.read(todayLocalStoreProvider);
    var cache = await store.readCache();
    if (cache.userId != null && cache.userId != state.userId) {
      await store.clear();
      cache = const CachedToday();
    }
    final outbox = [for (final q in await store.readOutbox()) q.entry];
    if (_disposed) return;
    state = state.copyWith(
      loaded: true,
      snapshot: cache.snapshot,
      outbox: outbox,
      renderer: _renderer(cache),
    );
    _listenRealtime();
    await syncNow();
  }

  domain.TemplateRenderer _renderer(CachedToday cache) =>
      domain.TemplateRenderer(cache.templates);

  void _listenRealtime() {
    try {
      _realtime ??= ref.read(taskRepositoryProvider).changes().listen((_) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(seconds: 1), () => syncNow());
      });
    } catch (_) {
      // Not configured / offline: no live updates.
    }
  }

  /// Flushes the outbox, then refreshes the cache from the server, then
  /// re-plans local reminders. Never throws; failures just mark [offline].
  Future<void> syncNow({bool force = false}) async {
    if (_syncing || _disposed) return;
    final userId = state.userId;
    if (userId == null) return;
    _syncing = true;
    state = state.copyWith(syncing: true);
    var offline = false;
    try {
      TaskRepository? repo;
      try {
        repo = ref.read(taskRepositoryProvider);
      } catch (_) {
        offline = true;
      }
      if (repo != null) {
        final flush = await ref.read(outboxSyncerProvider).flush(force: force);
        offline = flush.offline;
        if (!flush.offline) {
          try {
            final snap = await repo.fetchSnapshot(today: state.today);
            final templates = await _fetchTemplates();
            final store = ref.read(todayLocalStoreProvider);
            await store.writeCache(
              userId: userId,
              snapshot: snap,
              templates: templates,
            );
            final cache = await store.readCache();
            if (!_disposed) {
              state = state.copyWith(
                snapshot: cache.snapshot,
                renderer: _renderer(cache),
              );
            }
          } catch (e) {
            debugPrint('Today refresh failed: $e');
            offline = true;
          }
        }
      }
      final queued = await ref.read(todayLocalStoreProvider).readOutbox();
      if (_disposed) return;
      state = state.copyWith(
        outbox: [for (final q in queued) q.entry],
        offline: offline,
      );
    } finally {
      _syncing = false;
      if (!_disposed) state = state.copyWith(syncing: false);
    }
    await rescheduleReminders();
  }

  Future<List<domain.TextTemplate>?> _fetchTemplates() async {
    try {
      final rows = await ref
          .read(plantRepositoryProvider)
          .fetchTextTemplates(state.lang);
      return [
        for (final r in rows)
          domain.TextTemplate(
            kind: r.kind,
            code: r.code,
            lang: state.lang,
            field: r.field,
            body: r.body,
          ),
      ];
    } catch (_) {
      return null; // keep cached templates
    }
  }

  /// Done / Skip / Snooze: written to the outbox first, so the UI updates
  /// at once (also offline); the sync runs in the background.
  Future<void> act(
    TodayItem item,
    TaskAction action, {
    String? skipReason,
    DateTime? snoozeUntil,
  }) async {
    final userId = state.userId;
    if (userId == null) return;
    final now = ref.read(clockProvider)();
    final entry = OutboxEntry(
      clientId: _uuid.v4(),
      taskId: item.task.id,
      occurrenceDate: item.occurrence.date,
      action: action,
      userId: userId,
      createdAt: now,
      actedOn: now,
      snoozeUntil: snoozeUntil,
      skipReason: skipReason,
    );
    final added = await ref.read(todayLocalStoreProvider).enqueue(entry);
    if (!added) return;
    state = state.copyWith(outbox: [...state.outbox, entry]);
    unawaited(syncNow(force: true));
  }

  /// XP shown in the toast for completing [item] right now.
  XpAward previewDone(TodayItem item) => XpPreview.award(
    XpSource.taskDone,
    earnedOrdinaryToday: state.earnedXpToday,
    onTime: XpPreview.isOnTime(dueDate: item.dueDate, actedOn: state.today),
  );

  /// Re-plans local notifications from the current model.
  Future<void> rescheduleReminders() async {
    final m = state;
    if (!m.loaded || m.userId == null || _disposed) return;
    try {
      final l = lookupAppLocalizations(Locale(m.lang));
      await ref
          .read(reminderSchedulerProvider)
          .reschedule(
            projects: m.snapshot.projects,
            logs: m.snapshot.logs,
            outbox: m.outbox,
            settings: ref.read(notificationSettingsProvider),
            userId: m.userId,
            taskName: m.taskName,
            texts: reminderTextsFor(l),
            lastCheckins: m.snapshot.lastCheckins ?? const {},
            quiet: ref.read(quietHoursProvider),
          );
    } catch (e) {
      debugPrint('Reminder scheduling failed: $e');
    }
  }
}

final todayModelProvider = NotifierProvider<TodayNotifier, TodayModel>(
  TodayNotifier.new,
);

String windowLabel(AppLocalizations l, TaskWindow w) => switch (w) {
  TaskWindow.morning => l.todayWindowMorning,
  TaskWindow.afternoon => l.todayWindowAfternoon,
  TaskWindow.allDay => l.todayWindowAllDay,
};

/// Localized notification strings for the planner.
ReminderTexts reminderTextsFor(AppLocalizations l) => ReminderTexts(
  windowTitle: (w) => l.todayNotifTitle(windowLabel(l, w)),
  taskBody: (names) {
    const shown = 3;
    final head = names.take(shown).join(', ');
    final more = names.length - shown;
    return more > 0 ? '$head ${l.todayNotifMore(more)}' : head;
  },
  dailyTitle: l.todayNotifDailyTitle,
  checkinTitle: () => l.todayNotifCheckinTitle,
  checkinBody: l.todayNotifCheckinBody,
);

// ---------------------------------------------------------------------------
// Notification permission (asked in context, never on launch)
// ---------------------------------------------------------------------------

const String kNotifPermAskedKey = 'notif_permission_asked';

class ReminderPermission {
  ReminderPermission(this._ref);
  final Ref _ref;

  /// True when Today has tasks and we have not asked yet.
  Future<bool> shouldPrompt() async {
    try {
      final asked = await _ref.read(localPrefsProvider).get(kNotifPermAskedKey);
      if (asked != null) return false;
      return !await _ref.read(notificationGatewayProvider).isPermissionGranted();
    } catch (_) {
      return false;
    }
  }

  Future<void> markAsked() async {
    try {
      await _ref.read(localPrefsProvider).set(kNotifPermAskedKey, '1');
    } catch (_) {}
  }

  /// Shows the OS prompt, then schedules reminders.
  Future<bool> request() async {
    await markAsked();
    final ok = await _ref.read(notificationGatewayProvider).requestPermission();
    await _ref.read(todayModelProvider.notifier).rescheduleReminders();
    return ok;
  }
}

final reminderPermissionProvider = Provider<ReminderPermission>(
  ReminderPermission.new,
);
