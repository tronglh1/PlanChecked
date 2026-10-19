import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vuon_nha/core/db/local_prefs.dart';
import 'package:vuon_nha/core/utils/share_service.dart';
import 'package:vuon_nha/features/auth/presentation/auth_state.dart';
import 'package:vuon_nha/features/gamification/data/gamification_repository.dart';
import 'package:vuon_nha/features/gamification/domain/achievements_models.dart';
import 'package:vuon_nha/features/gamification/gamification_routes.dart';
import 'package:vuon_nha/features/gamification/presentation/gamification_providers.dart';
import 'package:vuon_nha/features/household/data/household_repository.dart';
import 'package:vuon_nha/features/household/domain/household_models.dart';
import 'package:vuon_nha/features/household/household_routes.dart';
import 'package:vuon_nha/features/household/presentation/household_providers.dart';
import 'package:vuon_nha/features/settings/presentation/locale_provider.dart';
import 'package:vuon_nha/l10n/app_localizations.dart';

import 'fakes.dart';

final _t0 = DateTime(2026, 1, 1);

HouseholdMember member(
  String id,
  String name, {
  HouseholdRole role = HouseholdRole.member,
  int joinedDays = 0,
  int tasks = 0,
  DateTime? away,
}) => HouseholdMember(
  userId: id,
  name: name,
  role: role,
  joinedAt: _t0.add(Duration(days: joinedDays)),
  tasksThisWeek: tasks,
  awayUntil: away,
);

/// Minh (u1, Owner, oldest), Lan (u2), Hung (u3).
Household sampleHousehold({String me = 'u1'}) => Household(
  id: 'h1',
  name: 'Nhà mình',
  ownerId: 'u1',
  myUserId: me,
  members: [
    member('u1', 'Minh', role: HouseholdRole.owner, tasks: 5),
    member('u2', 'Lan', joinedDays: 1, tasks: 8),
    member('u3', 'Hùng', joinedDays: 2, tasks: 3),
  ],
);

class FakeShareService implements ShareService {
  final List<String> texts = [];
  final List<Uint8List> images = [];
  final List<String?> imageTexts = [];

  @override
  Future<void> shareText(String text, {String? subject}) async =>
      texts.add(text);

  @override
  Future<void> shareImage(
    Uint8List png, {
    required String fileName,
    String? text,
  }) async {
    images.add(png);
    imageTexts.add(text);
  }
}

class FakeHouseholdRepository implements HouseholdRepository {
  FakeHouseholdRepository({this.household, this.task});

  Household? household;
  AssignableTask? task;
  JoinResult joinResult = const JoinResult.ok(householdId: 'h1');
  final List<String> created = [];
  final List<String> accepted = [];
  final List<({String channel, String? target, HouseholdRole role})> invites =
      [];
  int leaves = 0;
  final List<String> removed = [];
  final List<({String project, String? household})> shares = [];
  final List<
    ({String taskId, AssignMode mode, String? assignee, List<String> order})
  >
  assigned = [];
  bool emailSent = false;
  List<ShareableProject> projects = const [];
  final activity = StreamController<List<ActivityItem>>.broadcast();

  @override
  Future<Household?> fetchHousehold() async => household;

  @override
  Future<void> createHousehold(String name) async {
    created.add(name);
    household = Household(
      id: 'h1',
      name: name,
      ownerId: 'u1',
      myUserId: 'u1',
      members: [member('u1', 'Minh', role: HouseholdRole.owner)],
    );
  }

  @override
  Future<JoinResult> acceptInvite(String code) async {
    accepted.add(code);
    if (joinResult.ok) household = sampleHousehold(me: 'u2');
    return joinResult;
  }

  @override
  Future<void> leaveHousehold() async {
    leaves++;
    household = null;
  }

  @override
  Future<void> removeMember(String userId) async {
    removed.add(userId);
    final h = household!;
    household = Household(
      id: h.id,
      name: h.name,
      ownerId: h.ownerId,
      myUserId: h.myUserId,
      members: [
        for (final m in h.members)
          if (m.userId != userId) m,
      ],
    );
  }

  @override
  Future<InviteResult> createInvite({
    required String channel,
    String? target,
    required HouseholdRole role,
  }) async {
    invites.add((channel: channel, target: target, role: role));
    return InviteResult(
      code: 'VUON-4821',
      link: 'https://vuonnha.app/i/VUON-4821',
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      role: role,
      emailSent: channel == 'email' && emailSent,
    );
  }

  @override
  Future<List<ShareableProject>> fetchProjects(String householdId) async =>
      projects;

  @override
  Future<void> setProjectHousehold(
    String projectId,
    String? householdId,
  ) async {
    shares.add((project: projectId, household: householdId));
    projects = [
      for (final p in projects)
        p.id == projectId
            ? ShareableProject(
                id: p.id,
                name: p.name,
                ownerId: p.ownerId,
                sharedWithHousehold: householdId != null,
              )
            : p,
    ];
  }

  @override
  Stream<List<ActivityItem>> watchActivity(String householdId) async* {
    yield const [];
    yield* activity.stream;
  }

  @override
  Future<AssignableTask?> fetchTask(
    String taskId, {
    String lang = 'vi',
  }) async => task;

  @override
  Future<void> assignTask({
    required String taskId,
    required AssignMode mode,
    String? assigneeId,
    List<String> rotationOrder = const [],
  }) async {
    assigned.add((
      taskId: taskId,
      mode: mode,
      assignee: assigneeId,
      order: rotationOrder,
    ));
  }
}

class FakeGamificationRepository implements GamificationRepository {
  FakeGamificationRepository({this.data, this.milestone});
  AchievementsData? data;
  MilestoneInfo? milestone;

  @override
  Future<AchievementsData> fetchAchievements() async => data!;

  @override
  Future<MilestoneInfo?> fetchMilestone(
    String projectId,
    String code, {
    String lang = 'vi',
  }) async => milestone;
}

const sampleTask = AssignableTask(
  taskId: 't1',
  taskCode: 'T_WATER',
  title: 'Tưới gốc',
  projectId: 'p1',
  projectName: 'Cà chua bi ban công',
  window: 'morning',
  intervalDays: 2,
  mode: AssignMode.series,
  canManage: true,
);

/// Pumps [routes] inside a MaterialApp.router with fakes. `/today` and
/// `/projects/:id` are stub pages so navigation can be asserted.
Future<GoRouter> pumpRouted(
  WidgetTester tester, {
  required String location,
  FakeHouseholdRepository? household,
  FakeGamificationRepository? gamification,
  FakeShareService? share,
  MemoryLocalPrefs? prefs,
  String? userId = 'u1',
  FakeProfileRepository? profile,
  List<Override> extra = const [],
}) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: '/today', builder: (_, _) => const Text('STUB-TODAY')),
      GoRoute(
        path: '/projects/:id',
        builder: (_, s) => Text('STUB-PROJECT-${s.pathParameters['id']}'),
      ),
      ...householdRoutes(),
      ...gamificationRoutes(),
      ...householdTabRoutes(),
      ...gamificationTabRoutes(),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(prefs ?? MemoryLocalPrefs()),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(userId: userId),
        ),
        householdRepositoryProvider.overrideWithValue(
          household ?? FakeHouseholdRepository(),
        ),
        gamificationRepositoryProvider.overrideWithValue(
          gamification ?? FakeGamificationRepository(),
        ),
        shareServiceProvider.overrideWithValue(share ?? FakeShareService()),
        ...extra,
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          locale: ref.watch(localeProvider),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
