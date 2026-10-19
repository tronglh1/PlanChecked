import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/plan/domain/enums.dart';
import 'package:vuon_nha/features/plan/domain/plan_bundle.dart';
import 'package:vuon_nha/features/projects/data/project_repository.dart';
import 'package:vuon_nha/features/projects/domain/project.dart';
import 'package:vuon_nha/features/projects/domain/project_progress.dart';

import '../../helpers/projects_fakes.dart';

ProjectSummary summaryOf(
  String id,
  String name, {
  int tasks = 0,
  ProjectStatus status = ProjectStatus.active,
  DateTime? photoAt,
}) {
  final bundle = fakeBundle(status: PlanStatus.approved, projectId: id);
  return ProjectSummary(
    project: fakeProject(id: id, name: name, status: status),
    plantNameVi: 'Cà chua bi',
    progress: ProjectProgress.compute(
      stages: bundle.stages,
      projectStart: testStart,
      today: DateTime.utc(2026, 10, 15),
    ),
    planStatus: 'approved',
    todayTaskCount: tasks,
    latestPhotoAt: photoAt,
  );
}

void main() {
  group('project list', () {
    testWidgets('empty state with a way to start', (t) async {
      await pumpRouterApp(t, initial: '/garden');
      expect(find.byKey(const Key('projects-empty')), findsOneWidget);
      expect(find.text('Chưa có cây nào'), findsOneWidget);
      await t.tap(find.text('Trồng cây mới').last);
      await t.pumpAndSettle();
      expect(find.text('SEARCH'), findsOneWidget);
    });

    testWidgets('non-empty list shows stage, today count and photo age', (
      t,
    ) async {
      final repo = FakeProjectRepository(
        summaries: [
          summaryOf(
            'a',
            'Cà chua ban công',
            tasks: 3,
            photoAt: DateTime.utc(2026, 10, 13),
          ),
          summaryOf('b', 'Rau muống', tasks: 1, status: ProjectStatus.done),
        ],
      );
      await pumpRouterApp(
        t,
        initial: '/garden',
        projects: repo,
        today: DateTime.utc(2026, 10, 15),
      );
      expect(find.byKey(const Key('projects-empty')), findsNothing);
      expect(find.text('Vườn của tôi'), findsOneWidget);
      expect(find.text('Đang trồng · 1'), findsOneWidget);
      expect(find.text('Đã xong · 1'), findsOneWidget);
      expect(find.text('Cà chua ban công'), findsOneWidget);
      expect(find.text('Rau muống'), findsNothing);
      expect(find.text('3 việc hôm nay'), findsOneWidget);
      expect(find.text('Ươm hạt'), findsOneWidget); // day 3 is stage 1
      expect(find.text('Ảnh: 2 ngày trước'), findsOneWidget);
      expect(find.textContaining('ngày 3'), findsOneWidget);

      await t.tap(find.byKey(const Key('filter-done')));
      await t.pumpAndSettle();
      expect(find.text('Rau muống'), findsOneWidget);
      expect(find.text('Cà chua ban công'), findsNothing);
      expect(find.text('Chưa có ảnh'), findsOneWidget);
    });

    testWidgets('tapping a card opens project detail', (t) async {
      final repo = FakeProjectRepository(
        summaries: [summaryOf('new1', 'Cà chua ban công')],
      );
      await pumpRouterApp(
        t,
        initial: '/garden',
        projects: repo,
        plans: FakePlanRepository(
          bundle: fakeBundle(status: PlanStatus.approved),
        ),
      );
      await t.tap(find.byKey(const Key('project-new1')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('detail-name')), findsOneWidget);
    });
  });

  group('project detail', () {
    testWidgets('overview, history, photos placeholder and members', (t) async {
      final repo = FakeProjectRepository(
        members: const {'u2': 'Lan'},
        history: [
          TaskHistoryEntry(
            taskId: 't1',
            taskCode: 'T_WATER',
            action: 'done',
            occurrenceDate: DateTime.utc(2026, 10, 14),
            createdAt: DateTime.utc(2026, 10, 14, 1),
          ),
          TaskHistoryEntry(
            taskId: 't2',
            taskCode: 'T_SOAK',
            action: 'skip',
            occurrenceDate: DateTime.utc(2026, 10, 13),
            createdAt: DateTime.utc(2026, 10, 13, 1),
          ),
        ],
      );
      await pumpRouterApp(
        t,
        initial: '/projects/new1',
        projects: repo,
        plans: FakePlanRepository(
          bundle: fakeBundle(status: PlanStatus.approved, assignee: 'u2'),
        ),
        today: DateTime.utc(2026, 10, 15),
      );
      expect(find.text('Giai đoạn 1/2 · Ươm hạt'), findsOneWidget);
      expect(find.text('Ngày 3/25'), findsOneWidget);
      expect(find.textContaining('Mốc tiếp theo: Nảy mầm'), findsOneWidget);
      expect(find.textContaining('Chia sẻ với gia đình'), findsOneWidget);
      // History (TSK-06).
      expect(find.text('Tưới gốc · Xong'), findsOneWidget);
      expect(find.text('Ngâm hạt nước ấm · Bỏ qua'), findsOneWidget);
      // Photo timeline placeholder.
      expect(find.text('Ảnh tăng trưởng'), findsOneWidget);
      // Members tab shows who is assigned.
      await t.tap(find.byKey(const Key('tab-members')));
      await t.pumpAndSettle();
      expect(find.text('Lan'), findsOneWidget);
      expect(find.text('1 việc'), findsOneWidget);
    });

    testWidgets('draft plan offers to review it', (t) async {
      await pumpRouterApp(
        t,
        initial: '/projects/new1',
        plans: FakePlanRepository(bundle: fakeBundle()),
      );
      expect(find.byKey(const Key('detail-no-plan')), findsOneWidget);
      expect(find.text('Duyệt kế hoạch'), findsOneWidget);
    });
  });

  group('domain', () {
    test('ProjectProgress: stage, day, next milestone', () {
      final b = fakeBundle(status: PlanStatus.approved);
      final p = ProjectProgress.compute(
        stages: b.stages,
        projectStart: testStart,
        today: DateTime.utc(2026, 10, 22), // day 10
      )!;
      expect(p.day, 10);
      expect(p.totalDays, 25);
      expect(p.stageNumber, 2);
      expect(p.currentStage!.code, 'S2');
      expect(p.milestonesReached, 1);
      expect(p.milestonesTotal, 2);
      expect(p.nextMilestone, 'TRUE_LEAVES');
      expect(p.nextMilestoneDate, DateTime.utc(2026, 11, 6));
      expect(p.daysLeftInStage, 15);
      // Before start and after the end.
      final before = ProjectProgress.compute(
        stages: b.stages,
        projectStart: testStart,
        today: DateTime.utc(2026, 10, 1),
      )!;
      expect(before.currentStage!.code, 'S1');
      final after = ProjectProgress.compute(
        stages: b.stages,
        projectStart: testStart,
        today: DateTime.utc(2027, 1, 1),
      )!;
      expect(after.currentStage!.code, 'S2');
      expect(after.fraction, 1);
      expect(
        ProjectProgress.compute(
          stages: const [],
          projectStart: testStart,
          today: testStart,
        ),
        isNull,
      );
    });

    test('buildProjectSummaries counts today tasks only for approved plans', () {
      final approved = fakeBundle(status: PlanStatus.approved, projectId: 'a');
      final draft = fakeBundle(planId: 'plan2', projectId: 'b');
      Map<String, dynamic> planRow(PlanBundleLike b) => {
        ...b.bundle.plan.toJson(),
        'stages': [for (final s in b.bundle.stages) s.toJson()],
      };
      final rows = buildProjectSummaries(
        projectRows: [
          {
            'id': 'a',
            'owner_id': 'u1',
            'name': 'A',
            'start_date': '2026-10-13',
            'plants': {'name_vi': 'Cà chua bi', 'group': 'rau_qua'},
          },
          {
            'id': 'b',
            'owner_id': 'u1',
            'name': 'B',
            'start_date': '2026-10-13',
          },
          {
            'id': 'c',
            'owner_id': 'u1',
            'name': 'C',
            'start_date': '2026-10-13',
          },
        ],
        planRows: [
          planRow(PlanBundleLike(approved)),
          planRow(PlanBundleLike(draft)),
        ],
        taskRows: [
          for (final b in [approved, draft])
            for (final task in b.tasks) task.toJson(),
        ],
        checkinRows: [
          {
            'project_id': 'a',
            'created_at': '2026-10-10T01:00:00Z',
            'shots': [
              {'type': 'whole_plant', 'path': 'old.jpg'},
            ],
          },
          {
            'project_id': 'a',
            'created_at': '2026-10-12T01:00:00Z',
            'shots': [
              {'type': 'whole_plant', 'path': 'new.jpg'},
            ],
          },
        ],
        today: DateTime.utc(2026, 10, 13),
      );
      expect(rows[0].todayTaskCount, 2);
      expect(rows[0].currentStage!.code, 'S1');
      expect(rows[0].latestPhotoPath, 'new.jpg');
      expect(rows[0].plantNameVi, 'Cà chua bi');
      expect(rows[1].todayTaskCount, 0); // draft: nothing scheduled yet
      expect(rows[1].planStatus, 'draft');
      expect(rows[2].progress, isNull);
    });

    test('AiPlanResult.fromJson maps quota and failure', () {
      final q = AiPlanResult.fromJson({'error': 'quota_exceeded'}, status: 429);
      expect(q.fallbackReason, FallbackReason.quotaExceeded);
      expect(q.planId, isNull);
      expect(q.isFallback, isTrue);
      final f = AiPlanResult.fromJson({
        'plan_id': 'p',
        'source': 'fallback',
        'fallback_reason': 'ai_failure',
      });
      expect(f.planId, 'p');
      expect(f.source, PlanSource.fallback);
      expect(f.fallbackReason, FallbackReason.aiFailure);
      final ok = AiPlanResult.fromJson({'plan_id': 'p', 'source': 'ai'});
      expect(ok.isFallback, isFalse);
    });
  });
}

class PlanBundleLike {
  PlanBundleLike(this.bundle);
  final PlanBundle bundle;
}
