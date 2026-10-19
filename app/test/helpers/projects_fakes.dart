import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vuon_nha/core/db/local_prefs.dart';
import 'package:vuon_nha/features/plan/data/plan_repository.dart';
import 'package:vuon_nha/features/plan/domain/enums.dart';
import 'package:vuon_nha/features/plan/domain/models.dart';
import 'package:vuon_nha/features/plan/domain/plan_bundle.dart';
import 'package:vuon_nha/features/plan/plan_routes.dart';
import 'package:vuon_nha/features/plan/presentation/plan_providers.dart';
import 'package:vuon_nha/features/plants/data/plant_repository.dart';
import 'package:vuon_nha/features/plants/presentation/plant_providers.dart';
import 'package:vuon_nha/features/projects/data/project_repository.dart';
import 'package:vuon_nha/features/projects/domain/project.dart';
import 'package:vuon_nha/features/projects/presentation/project_context_screen.dart';
import 'package:vuon_nha/features/projects/presentation/project_list_screen.dart';
import 'package:vuon_nha/features/projects/presentation/projects_providers.dart';
import 'package:vuon_nha/features/projects/projects_routes.dart';
import 'package:vuon_nha/features/settings/presentation/locale_provider.dart';
import 'package:vuon_nha/l10n/app_localizations.dart';

import 'fakes.dart';

final testStart = DateTime.utc(2026, 10, 13);

Project fakeProject({
  String id = 'new1',
  String name = 'Cà chua bi – 10/2026',
  ProjectStatus status = ProjectStatus.active,
  String? householdId,
}) => Project(
  id: id,
  ownerId: 'u1',
  householdId: householdId,
  plantId: 'p2',
  name: name,
  startDate: testStart,
  potCount: 4,
  status: status,
);

/// Two stages (days 1-7 and 8-25) and four tasks.
PlanBundle fakeBundle({
  String planId = 'plan1',
  String projectId = 'new1',
  PlanSource source = PlanSource.ai,
  double? confidence = 0.86,
  PlanStatus status = PlanStatus.draft,
  List<String> sources = const [],
  String? assignee,
}) {
  final stages = [
    Stage(
      id: 's1',
      planId: planId,
      idx: 1,
      code: 'S1',
      name: 'Ươm hạt',
      dayFrom: 1,
      dayTo: 7,
      milestoneCode: 'SPROUT',
    ),
    Stage(
      id: 's2',
      planId: planId,
      idx: 2,
      code: 'S2',
      name: 'Cây con',
      dayFrom: 8,
      dayTo: 25,
      milestoneCode: 'TRUE_LEAVES',
    ),
  ];
  Task task(
    String id,
    String stage,
    String code,
    Frequency f, {
    int? n,
    String? assigneeId,
  }) => Task(
    id: id,
    projectId: projectId,
    stageId: stage,
    taskCode: code,
    window: TaskWindow.morning,
    frequency: f,
    intervalDays: n,
    assigneeId: assigneeId,
  );
  return PlanBundle(
    plan: Plan(
      id: planId,
      projectId: projectId,
      version: 1,
      source: source,
      confidence: confidence,
      status: status,
      stages: stages,
    ),
    tasks: [
      task('t1', 's1', 'T_WATER', Frequency.daily, assigneeId: assignee),
      task('t2', 's1', 'T_SOAK', Frequency.once),
      task('t3', 's2', 'T_FERT_ORGANIC', Frequency.everyNDays, n: 14),
      task('t4', 's2', 'T_PRUNE', Frequency.everyNDays, n: 7),
    ],
    sources: sources,
  );
}

class FakeProjectRepository implements ProjectRepository {
  FakeProjectRepository({
    this.summaries = const [],
    this.failCreate = false,
    this.history = const [],
    this.members = const {},
  });

  List<ProjectSummary> summaries;
  bool failCreate;
  List<TaskHistoryEntry> history;
  Map<String, String> members;
  final List<NewProject> created = [];

  @override
  Future<Project> createProject(NewProject input) async {
    if (failCreate) throw Exception('boom');
    created.add(input);
    return fakeProject(name: input.name);
  }

  @override
  Future<List<ProjectSummary>> listProjects(DateTime today) async => summaries;

  @override
  Future<ProjectDetail> getProject(String id) async => ProjectDetail(
    project: fakeProject(id: id, householdId: 'h1'),
    plantNameVi: 'Cà chua bi',
    plantNameEn: 'Cherry tomato',
    group: null,
    memberNames: members,
    checkinCount: 2,
  );

  @override
  Future<List<TaskHistoryEntry>> taskHistory(
    String projectId, {
    int limit = 50,
  }) async => history;
}

class FakePlanRepository implements PlanRepository {
  FakePlanRepository({
    this.result = const AiPlanResult(planId: 'plan1'),
    PlanBundle? bundle,
  }) : bundle = bundle ?? fakeBundle();

  AiPlanResult result;

  PlanBundle? bundle;
  bool throwOnGenerate = false;
  bool hangOnGenerate = false;
  final List<({String projectId, String? plantGroup})> generateCalls = [];
  final List<String> approved = [];
  final List<Task> updated = [];
  final List<NewTask> added = [];
  final List<String> deleted = [];
  List<TaskCodeInfo> codes = const [
    TaskCodeInfo(code: 'T_WATER', defaultFrequency: Frequency.daily),
    TaskCodeInfo(code: 'T_PRUNE'),
  ];

  @override
  Future<AiPlanResult> generatePlan(
    String projectId, {
    String? plantGroup,
    bool regenerate = false,
  }) async {
    generateCalls.add((projectId: projectId, plantGroup: plantGroup));
    if (hangOnGenerate) return Completer<AiPlanResult>().future;
    if (throwOnGenerate) throw const PlanGenerationException('down');
    return result;
  }

  @override
  Future<PlanBundle?> loadPlan(String projectId) async => bundle;

  @override
  Future<void> approvePlan(String planId) async {
    approved.add(planId);
    final b = bundle;
    if (b != null) {
      bundle = b.copyWith(
        plan: Plan(
          id: b.plan.id,
          projectId: b.plan.projectId,
          version: b.plan.version,
          source: b.plan.source,
          confidence: b.plan.confidence,
          status: PlanStatus.approved,
          stages: b.plan.stages,
        ),
      );
    }
  }

  @override
  Future<List<TaskCodeInfo>> fetchTaskCodes() async => codes;

  @override
  Future<Task> addTask(NewTask input) async {
    added.add(input);
    return Task(
      id: 'tn${added.length}',
      projectId: input.projectId,
      stageId: input.stageId,
      taskCode: input.taskCode,
      window: input.window,
      frequency: input.frequency,
      intervalDays: input.intervalDays,
      source: TaskSource.manual,
    );
  }

  @override
  Future<Task> updateTask(Task task) async {
    updated.add(task);
    return task;
  }

  @override
  Future<void> deleteTask(String taskId) async => deleted.add(taskId);
}

/// Plant repository that also serves text templates for any language.
class TemplatePlantRepository extends FakePlantRepository {
  TemplatePlantRepository() : super(testPlants);

  static const rows = [
    TextTemplate(
      kind: 'task',
      code: 'T_WATER',
      field: 'name',
      body: 'Tưới gốc',
    ),
    TextTemplate(
      kind: 'task',
      code: 'T_SOAK',
      field: 'name',
      body: 'Ngâm hạt nước ấm',
    ),
    TextTemplate(
      kind: 'task',
      code: 'T_FERT_ORGANIC',
      field: 'name',
      body: 'Bón phân hữu cơ',
    ),
    TextTemplate(
      kind: 'task',
      code: 'T_FERT_ORGANIC',
      field: 'safety',
      body: 'Đọc nhãn sản phẩm, không tự pha liều.',
    ),
    TextTemplate(
      kind: 'task',
      code: 'T_PRUNE',
      field: 'name',
      body: 'Tỉa chồi nách',
    ),
    TextTemplate(
      kind: 'milestone',
      code: 'SPROUT',
      field: 'name',
      body: 'Nảy mầm',
    ),
    TextTemplate(
      kind: 'milestone',
      code: 'TRUE_LEAVES',
      field: 'name',
      body: 'Ra lá thật',
    ),
  ];

  @override
  Future<List<TextTemplate>> fetchTextTemplates(
    String lang, {
    String? kind,
  }) async => rows;
}

/// Pumps the garden tab, the context form and the project/plan routes in a
/// real [GoRouter], with fakes for every repository.
Future<GoRouter> pumpRouterApp(
  WidgetTester tester, {
  required String initial,
  FakeProjectRepository? projects,
  FakePlanRepository? plans,
  DateTime? today,
  Duration aiTimeout = const Duration(seconds: 25),
  List<Override> extra = const [],
}) async {
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/garden',
        builder: (_, _) => const Scaffold(body: ProjectListScreen()),
      ),
      GoRoute(
        path: '/projects/new/search',
        builder: (_, _) => const Scaffold(body: Text('SEARCH')),
      ),
      GoRoute(
        path: '/projects/new/context',
        builder: (_, state) => ProjectContextScreen(
          plantId: state.uri.queryParameters['plant'],
          freeText: state.uri.queryParameters['name'],
        ),
      ),
      ...projectsRoutes,
      ...planRoutes,
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(MemoryLocalPrefs()),
        plantRepositoryProvider.overrideWithValue(TemplatePlantRepository()),
        projectRepositoryProvider.overrideWithValue(
          projects ?? FakeProjectRepository(),
        ),
        planRepositoryProvider.overrideWithValue(plans ?? FakePlanRepository()),
        projectsTodayProvider.overrideWithValue(today ?? testStart),
        aiPlanTimeoutProvider.overrideWithValue(aiTimeout),
        aiPlanStepIntervalProvider.overrideWithValue(
          const Duration(milliseconds: 20),
        ),
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
