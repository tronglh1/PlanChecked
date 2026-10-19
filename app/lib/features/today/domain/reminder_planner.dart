/// Computes which local notifications to schedule for the user's own
/// upcoming occurrences. Pure Dart: times are wall-clock [DateTime]s (the
/// fields are read as the user's local time; the plugin adapter attaches the
/// timezone).
library;

import '../../../core/utils/date_only.dart';
import '../../plan/domain/enums.dart';
import '../../plan/domain/models.dart';
import '../../plan/domain/task_scheduler.dart';
import '../../settings/domain/notification_settings.dart';
import 'checkin_due.dart';
import 'outbox_entry.dart';
import 'today_builder.dart';

/// Quiet hours, e.g. 22:00-06:00 (may wrap midnight). A reminder that falls
/// inside is moved to the end of the quiet period.
class QuietHours {
  const QuietHours(this.startMinute, this.endMinute);

  final int startMinute;
  final int endMinute;

  static QuietHours? parse(String? start, String? end) {
    final s = parseHm(start);
    final e = parseHm(end);
    if (s == null || e == null || s == e) return null;
    return QuietHours(s, e);
  }

  bool contains(int minute) => startMinute < endMinute
      ? minute >= startMinute && minute < endMinute
      : minute >= startMinute || minute < endMinute;

  /// [when] moved to the end of the quiet period if inside it.
  DateTime shift(DateTime when) {
    final m = when.hour * 60 + when.minute;
    if (!contains(m)) return when;
    final wraps = startMinute > endMinute;
    final nextDay = wraps && m >= startMinute;
    final day = DateTime(when.year, when.month, when.day + (nextDay ? 1 : 0));
    return DateTime(day.year, day.month, day.day, 0, endMinute);
  }
}

/// Minutes since midnight for "HH:mm" or "HH:mm:ss"; null when malformed.
int? parseHm(String? s) {
  if (s == null) return null;
  final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(s.trim());
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2)!);
  if (h > 23 || min > 59) return null;
  return h * 60 + min;
}

/// Localized strings used in notifications (kept out of the planner so it
/// stays pure and testable).
/// Localized Android notification channel names/descriptions (shown in the
/// system notification settings).
class ReminderChannels {
  const ReminderChannels({
    required this.taskName,
    required this.taskDescription,
    required this.checkinName,
    required this.checkinDescription,
  });

  final String taskName;
  final String taskDescription;
  final String checkinName;
  final String checkinDescription;
}

class ReminderTexts {
  const ReminderTexts({
    required this.windowTitle,
    required this.taskBody,
    required this.dailyTitle,
    required this.checkinTitle,
    required this.checkinBody,
    required this.channels,
  });

  final ReminderChannels channels;

  final String Function(TaskWindow window) windowTitle;

  /// [names] are the task names of the group, in time order.
  final String Function(List<String> names) taskBody;
  final String Function(int count) dailyTitle;
  final String Function() checkinTitle;
  final String Function(String projectName) checkinBody;
}

enum ReminderKind { task, checkin }

class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.kind,
    required this.when,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final ReminderKind kind;

  /// Wall-clock fire time in the user's timezone.
  final DateTime when;
  final String title;
  final String body;

  /// Route to open when tapped.
  final String payload;

  @override
  String toString() => 'Planned($id, $kind, $when, $title)';
}

class ReminderPlanner {
  const ReminderPlanner._();

  static const int defaultHorizonDays = 7;
  static const int defaultMaxCount = 60;

  /// Default start per window when no task has its own reminder time.
  static int defaultMinute(TaskWindow w) => switch (w) {
    TaskWindow.morning => 6 * 60,
    TaskWindow.afternoon => 16 * 60,
    TaskWindow.allDay => 8 * 60,
  };

  static const int checkinMinute = 9 * 60;

  static int stableId(String key) {
    var h = 0x811c9dc5;
    for (final c in key.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0xffffffff;
    }
    return h & 0x7fffffff;
  }

  static List<PlannedNotification> plan({
    required DateTime now,
    required List<TodayProject> projects,
    List<TaskLog> logs = const [],
    List<OutboxEntry> outbox = const [],
    required NotificationSettings settings,
    String? userId,
    required String Function(Task) taskName,
    required ReminderTexts texts,
    Map<String, DateTime> lastCheckins = const {},
    QuietHours? quiet,
    int horizonDays = defaultHorizonDays,
    int maxCount = defaultMaxCount,
  }) {
    final today = dateOnly(now);
    final out = <PlannedNotification>[];

    if (settings.isEnabled(NotifType.taskReminder)) {
      out.addAll(
        _tasks(
          now: now,
          today: today,
          projects: projects,
          logs: logs,
          outbox: outbox,
          userId: userId,
          bundle: settings.bundleDaily,
          taskName: taskName,
          texts: texts,
          horizonDays: horizonDays,
        ),
      );
    }
    if (settings.isEnabled(NotifType.checkinReminder)) {
      out.addAll(
        _checkins(
          now: now,
          today: today,
          projects: projects,
          lastCheckins: lastCheckins,
          texts: texts,
          horizonDays: horizonDays,
        ),
      );
    }

    final shifted = <PlannedNotification>[];
    for (final n in out) {
      final when = quiet == null ? n.when : quiet.shift(n.when);
      if (!when.isAfter(now)) continue;
      shifted.add(
        PlannedNotification(
          id: n.id,
          kind: n.kind,
          when: when,
          title: n.title,
          body: n.body,
          payload: n.payload,
        ),
      );
    }
    shifted.sort((a, b) => a.when.compareTo(b.when));
    return shifted.length > maxCount ? shifted.sublist(0, maxCount) : shifted;
  }

  static List<PlannedNotification> _tasks({
    required DateTime now,
    required DateTime today,
    required List<TodayProject> projects,
    required List<TaskLog> logs,
    required List<OutboxEntry> outbox,
    required String? userId,
    required bool bundle,
    required String Function(Task) taskName,
    required ReminderTexts texts,
    required int horizonDays,
  }) {
    // (date, window) -> entries
    final entries = <DateTime, List<_Entry>>{};
    void add(DateTime date, Task t, TaskWindow w) {
      final list = entries[date] ??= [];
      // An overdue and a due-today occurrence of one task remind once.
      if (list.any((e) => e.task.id == t.id && e.window == w)) return;
      list.add(_Entry(t, w, parseHm(t.reminderTime)));
    }

    // Today (and carried-over overdue / snoozed-due) via the Today rules.
    final view = TodayBuilder.build(
      today: today,
      projects: projects,
      logs: logs,
      outbox: outbox,
      assigneeId: userId,
    );
    for (final i in view.items) {
      if (i.state == TodayState.pending || i.state == TodayState.overdue) {
        add(today, i.task, i.window);
      }
    }
    final end = addDays(today, horizonDays - 1);
    for (final i in view.snoozed) {
      if (!i.dueDate.isAfter(end)) add(i.dueDate, i.task, i.window);
    }

    // Future days.
    if (horizonDays > 1) {
      final latest = _latestByKey(logs, outbox);
      for (final p in projects) {
        final occs = TaskScheduler.expandAll(
          tasks: p.tasks,
          stages: p.stages,
          projectStart: p.startDate,
          from: addDays(today, 1),
          to: end,
        );
        final byId = {for (final t in p.tasks) t.id: t};
        for (final o in occs) {
          final t = byId[o.taskId]!;
          if (userId != null &&
              t.assigneeId != null &&
              t.assigneeId != userId) {
            continue;
          }
          if (latest.containsKey(o.key)) continue; // already acted on / moved
          add(o.date, t, o.window);
        }
      }
    }

    final result = <PlannedNotification>[];
    final dates = entries.keys.toList()..sort();
    for (final date in dates) {
      final list = entries[date]!;
      if (bundle) {
        final min = _earliest(list, null);
        result.add(
          _make(
            id: 'task|${formatIsoDate(date)}',
            date: date,
            minute: min,
            title: texts.dailyTitle(list.length),
            names: _names(list, taskName),
            texts: texts,
          ),
        );
        continue;
      }
      for (final w in TaskWindow.values) {
        final group = list.where((e) => e.window == w).toList();
        if (group.isEmpty) continue;
        result.add(
          _make(
            id: 'task|${formatIsoDate(date)}|${w.db}',
            date: date,
            minute: _earliest(group, w),
            title: texts.windowTitle(w),
            names: _names(group, taskName),
            texts: texts,
          ),
        );
      }
    }
    return result;
  }

  static PlannedNotification _make({
    required String id,
    required DateTime date,
    required int minute,
    required String title,
    required List<String> names,
    required ReminderTexts texts,
  }) => PlannedNotification(
    id: stableId(id),
    kind: ReminderKind.task,
    when: DateTime(date.year, date.month, date.day, 0, minute),
    title: title,
    body: texts.taskBody(names),
    payload: '/today',
  );

  static int _earliest(List<_Entry> list, TaskWindow? w) {
    int? best;
    for (final e in list) {
      final m = e.minute ?? defaultMinute(e.window);
      if (best == null || m < best) best = m;
    }
    return best ?? defaultMinute(w ?? TaskWindow.morning);
  }

  static List<String> _names(
    List<_Entry> list,
    String Function(Task) taskName,
  ) {
    final sorted = [...list]
      ..sort(
        (a, b) => (a.minute ?? defaultMinute(a.window)).compareTo(
          b.minute ?? defaultMinute(b.window),
        ),
      );
    return [for (final e in sorted) taskName(e.task)];
  }

  static Map<String, bool> _latestByKey(
    List<TaskLog> logs,
    List<OutboxEntry> outbox,
  ) => {
    for (final l in logs) l.occurrenceKey: true,
    for (final o in outbox) o.occurrenceKey: true,
  };

  static List<PlannedNotification> _checkins({
    required DateTime now,
    required DateTime today,
    required List<TodayProject> projects,
    required Map<String, DateTime> lastCheckins,
    required ReminderTexts texts,
    required int horizonDays,
  }) {
    final end = addDays(today, horizonDays - 1);
    final next = nextCheckinDates(
      projects: projects,
      lastCheckins: lastCheckins,
    );
    final out = <PlannedNotification>[];
    for (final p in projects) {
      var date = next[p.id]!;
      if (date.isBefore(today)) date = today;
      if (date.isBefore(dateOnly(p.startDate))) date = dateOnly(p.startDate);
      var when = DateTime(date.year, date.month, date.day, 0, checkinMinute);
      if (!when.isAfter(now)) {
        // Due today but 09:00 has passed: nudge again tomorrow.
        date = addDays(date, 1);
        when = DateTime(date.year, date.month, date.day, 0, checkinMinute);
      }
      if (date.isAfter(end)) continue;
      out.add(
        PlannedNotification(
          id: stableId('checkin|${p.id}'),
          kind: ReminderKind.checkin,
          when: when,
          title: texts.checkinTitle(),
          body: texts.checkinBody(p.name),
          payload: '/projects/${p.id}/checkin',
        ),
      );
    }
    return out;
  }
}

class _Entry {
  _Entry(this.task, this.window, this.minute);
  final Task task;
  final TaskWindow window;
  final int? minute;
}
