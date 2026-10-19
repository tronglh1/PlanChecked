import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vuon_nha/core/db/local_prefs.dart';
import 'package:vuon_nha/features/auth/presentation/auth_state.dart';
import 'package:vuon_nha/features/plan/domain/enums.dart';
import 'package:vuon_nha/features/plants/data/plant_repository.dart';
import 'package:vuon_nha/features/plants/presentation/plant_providers.dart';
import 'package:vuon_nha/features/profile/domain/user_profile.dart';
import 'package:vuon_nha/features/profile/presentation/profile_providers.dart';
import 'package:vuon_nha/features/settings/domain/notification_settings.dart';
import 'package:vuon_nha/features/settings/presentation/settings_providers.dart';
import 'package:vuon_nha/features/today/data/today_local_store.dart';
import 'package:vuon_nha/features/today/presentation/today_providers.dart';
import 'package:vuon_nha/features/today/presentation/today_screen.dart';
import 'package:vuon_nha/features/today/today_routes.dart';
import 'package:vuon_nha/l10n/app_localizations.dart';

import '../../../helpers/fakes.dart';
import '../helpers/today_fixtures.dart';

class _Plants extends FakePlantRepository {
  _Plants() : super(const []);
  @override
  Future<List<TextTemplate>> fetchTextTemplates(
    String lang, {
    String? kind,
  }) async => [
    for (final t in kTemplates)
      TextTemplate(kind: t.kind, code: t.code, field: t.field, body: t.body),
  ];
}

class Env {
  Env({FakeTaskRepository? repo, bool granted = true})
    : repo = repo ?? FakeTaskRepository(projects: [project()]),
      gateway = FakeNotificationGateway(granted: granted),
      store = MemoryTodayLocalStore(),
      prefs = MemoryLocalPrefs();

  final FakeTaskRepository repo;
  final FakeNotificationGateway gateway;
  final MemoryTodayLocalStore store;
  final MemoryLocalPrefs prefs;
  late ProviderContainer container;
}

/// Simulates a previous online session: the cache is filled, then the
/// network goes away.
Future<void> seedCacheThenGoOffline(Env env) async {
  final snap = await env.repo.fetchSnapshot(today: kToday);
  await env.store.writeCache(
    userId: 'u1',
    snapshot: snap,
    templates: kTemplates,
  );
  env.repo.offline = true;
}

Future<void> pumpToday(
  WidgetTester t,
  Env env, {
  String location = '/today',
  DateTime? now,
}) async {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/today',
        builder: (_, _) => const Scaffold(body: TodayScreen()),
      ),
      ...todayRoutes,
      GoRoute(
        path: '/task/:id/assign',
        builder: (_, _) => const Scaffold(body: Text('assign-stub')),
      ),
      GoRoute(
        path: '/projects/:id/checkin',
        builder: (_, _) => const Scaffold(body: Text('checkin-stub')),
      ),
    ],
  );
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => now ?? kNow),
        taskRepositoryProvider.overrideWithValue(env.repo),
        todayLocalStoreProvider.overrideWithValue(env.store),
        notificationGatewayProvider.overrideWithValue(env.gateway),
        localPrefsProvider.overrideWithValue(env.prefs),
        plantRepositoryProvider.overrideWithValue(_Plants()),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(userId: 'u1'),
        ),
        profileRepositoryProvider.overrideWithValue(
          FakeProfileRepository(
            const UserProfile(
              id: 'u1',
              displayName: 'Minh',
              provinceCode: 'tp-hcm',
            ),
          ),
        ),
        notificationPrefsRepositoryProvider.overrideWithValue(
          FakeNotificationPrefsRepository(),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          env.container = ProviderScope.containerOf(context);
          return MaterialApp.router(
            routerConfig: router,
            locale: const Locale('vi'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('renders greeting, date, progress and rows by window', (t) async {
    final env = Env();
    await pumpToday(t, env);
    expect(find.text('Thứ Hai, 19/10'), findsOneWidget);
    expect(find.text('Chào Minh'), findsOneWidget);
    expect(find.text('Đã xong 0/2 việc'), findsOneWidget);
    expect(find.text('Tưới nước'), findsOneWidget);
    expect(find.text('Bón phân hữu cơ'), findsOneWidget);
    expect(find.text('SÁNG SỚM · 6–8H'), findsOneWidget);
    expect(find.text('CHIỀU MÁT · 16–18H'), findsOneWidget);
    // Check-in is due (never checked in) -> banner shown.
    expect(find.text('Đến hạn chụp ảnh check-in'), findsOneWidget);
  });

  testWidgets('toggle groups by project', (t) async {
    final env = Env(
      repo: FakeTaskRepository(
        projects: [
          project(),
          project(id: 'p2', name: 'Rau muống', tasks: [kPrune]),
        ],
        lastCheckins: {
          'p1': DateTime.utc(2026, 10, 18),
          'p2': DateTime.utc(2026, 10, 18),
        },
      ),
    );
    await pumpToday(t, env);
    expect(find.text('SÁNG SỚM · 6–8H'), findsOneWidget);
    await t.tap(find.byKey(const Key('group-project')));
    await t.pumpAndSettle();
    expect(find.text('SÁNG SỚM · 6–8H'), findsNothing);
    expect(find.text('CÀ CHUA BI'), findsOneWidget);
    expect(find.text('RAU MUỐNG'), findsOneWidget);
    expect(find.text('Đến hạn chụp ảnh check-in'), findsNothing);
  });

  testWidgets('Done works offline: instant, queued in outbox, XP toast', (
    t,
  ) async {
    final env = Env();
    await seedCacheThenGoOffline(env);
    await pumpToday(t, env);
    await t.tap(find.byKey(const Key('done-t-water')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('Đã xong 1/2 việc'), findsOneWidget);
    expect(find.text('+10 XP'), findsOneWidget);
    expect(find.byKey(const Key('pending-t-water')), findsOneWidget);
    final queued = await env.store.readOutbox();
    expect(queued, hasLength(1));
    expect(queued.single.entry.action, TaskAction.done);
    expect(queued.single.entry.taskId, 't-water');
    expect(queued.single.entry.clientId, isNotEmpty);
    expect(env.repo.inserted, isEmpty);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('offline-banner')), findsOneWidget);
    expect(find.text('10 XP hôm nay'), findsOneWidget);
  });

  testWidgets('queued Done is flushed once the network is back', (t) async {
    final env = Env();
    await seedCacheThenGoOffline(env);
    await pumpToday(t, env);
    await t.tap(find.byKey(const Key('done-t-water')));
    await t.pumpAndSettle();
    expect(await env.store.readOutbox(), hasLength(1));

    env.repo.offline = false;
    await env.container.read(todayModelProvider.notifier).syncNow(force: true);
    await t.pumpAndSettle();
    expect(env.repo.inserted.single.taskId, 't-water');
    expect(await env.store.readOutbox(), isEmpty);
    expect(find.byKey(const Key('pending-t-water')), findsNothing);
    expect(find.text('Đã xong 1/2 việc'), findsOneWidget);
    expect(find.byKey(const Key('offline-banner')), findsNothing);
  });

  testWidgets('Skip from the menu with a reason', (t) async {
    final env = Env();
    await pumpToday(t, env);
    await t.tap(find.byKey(const Key('menu-t-fert')));
    await t.pumpAndSettle();
    await t.tap(find.text('Bỏ qua').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Trời mưa'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('skip-confirm')));
    await t.pumpAndSettle();

    final log = env.repo.inserted.single;
    expect(log.action, TaskAction.skip);
    expect(log.skipReason, 'Trời mưa');
    // Skipped rows leave the denominator.
    expect(find.text('Đã xong 0/1 việc'), findsOneWidget);
    expect(find.textContaining('Đã bỏ qua'), findsOneWidget);
  });

  testWidgets('Snooze hides the row and records snooze_until', (t) async {
    final env = Env();
    await pumpToday(t, env);
    await t.tap(find.byKey(const Key('menu-t-water')));
    await t.pumpAndSettle();
    await t.tap(find.text('Dời lại').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('snooze-2')));
    await t.pumpAndSettle();

    final log = env.repo.inserted.single;
    expect(log.action, TaskAction.snooze);
    expect(log.snoozeUntil, DateTime.utc(2026, 10, 21));
    expect(find.text('Tưới nước'), findsNothing);
    expect(find.text('Đã xong 0/1 việc'), findsOneWidget);
  });

  testWidgets('overdue items get their own section first', (t) async {
    // Water was due yesterday (start 10/10, daily): no log -> overdue.
    final env = Env(
      repo: FakeTaskRepository(
        projects: [
          project(tasks: [kFert], start: DateTime.utc(2026, 10, 10)),
        ],
        lastCheckins: {'p1': DateTime.utc(2026, 10, 18)},
      ),
    );
    // Fert due 16/10 (day 7) is overdue, and again today.
    await pumpToday(t, env);
    expect(find.text('QUÁ HẠN'), findsOneWidget);
    final overdueY = t.getTopLeft(find.text('QUÁ HẠN')).dy;
    final windowY = t.getTopLeft(find.text('CHIỀU MÁT · 16–18H')).dy;
    expect(overdueY, lessThan(windowY));
  });

  testWidgets('check-in banner opens the check-in route', (t) async {
    final env = Env();
    await pumpToday(t, env);
    await t.tap(find.byKey(const Key('checkin-p1')));
    await t.pumpAndSettle();
    expect(find.text('checkin-stub'), findsOneWidget);
  });

  testWidgets('empty state when nothing is planned', (t) async {
    final env = Env(repo: FakeTaskRepository());
    await pumpToday(t, env);
    expect(find.text('Hôm nay chưa có việc'), findsOneWidget);
  });

  testWidgets('asks for notification permission once, in context', (t) async {
    final env = Env(granted: false);
    await pumpToday(t, env);
    expect(env.gateway.permissionRequests, 0);
    expect(find.text('Bật nhắc việc?'), findsOneWidget);
    await t.tap(find.byKey(const Key('perm-allow')));
    await t.pumpAndSettle();
    expect(env.gateway.permissionRequests, 1);
    // Reminders are planned right after the grant.
    expect(env.gateway.scheduled, isNotEmpty);
    expect(await env.prefs.get(kNotifPermAskedKey), '1');
  });

  testWidgets('does not ask again after the user declined', (t) async {
    final env = Env(granted: false);
    await env.prefs.set(kNotifPermAskedKey, '1');
    await pumpToday(t, env);
    expect(find.text('Bật nhắc việc?'), findsNothing);
  });

  testWidgets('reminders follow the notification toggles', (t) async {
    final env = Env();
    await pumpToday(t, env);
    expect(env.gateway.scheduled, isNotEmpty);
    await env.container
        .read(notificationSettingsProvider.notifier)
        .setType(NotifType.taskReminder, false);
    await env.container
        .read(notificationSettingsProvider.notifier)
        .setType(NotifType.checkinReminder, false);
    await t.pumpAndSettle();
    expect(env.gateway.scheduled, isEmpty);
  });
}
