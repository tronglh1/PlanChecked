import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/plan/domain/enums.dart';
import 'package:vuon_nha/features/plan/domain/plan_bundle.dart';

import '../../helpers/projects_fakes.dart';

void main() {
  group('create project -> generating -> review -> approve', () {
    testWidgets('happy path with an AI plan', (t) async {
      final projects = FakeProjectRepository();
      final plans = FakePlanRepository(bundle: fakeBundle());
      await pumpRouterApp(
        t,
        initial: '/projects/new/context?plant=p2',
        projects: projects,
        plans: plans,
      );

      // Screen 08: defaults from the plant and the start date.
      expect(find.text('Cà chua bi trồng ở đâu?'), findsOneWidget);
      expect(find.text('Cà chua bi – 10/2026'), findsOneWidget);
      expect(find.text('Hạt giống'), findsOneWidget);
      expect(find.text('Sân thượng'), findsOneWidget);
      expect(find.text('Dưới 3 giờ'), findsOneWidget);
      expect(find.text('Chậu nhựa 20L, đất trộn'), findsOneWidget);

      await t.tap(find.byKey(const Key('pots-plus')));
      await t.tap(find.byKey(const Key('pots-plus')));
      await t.tap(find.byKey(const Key('pots-plus')));
      await t.tap(find.byKey(const Key('space-yard')));
      await t.tap(find.byKey(const Key('stage-seedling')));
      await t.pump();
      await t.tap(find.byKey(const Key('create-plan')));
      await t.pumpAndSettle();

      expect(projects.created, hasLength(1));
      final c = projects.created.single;
      expect(c.plantId, 'p2');
      expect(c.potCount, 4);
      expect(c.name, 'Cà chua bi – 10/2026');
      expect(c.space.db, 'yard');
      expect(c.startStage.db, 'seedling');
      expect(c.sunLevel.db, 2);

      // Generating finished with AI result -> review screen.
      expect(plans.generateCalls, hasLength(1));
      expect(plans.generateCalls.single.projectId, 'new1');
      expect(plans.generateCalls.single.plantGroup, isNull);
      expect(find.text('Kế hoạch 25 ngày'), findsOneWidget);

      await t.tap(find.byKey(const Key('approve-plan')));
      await t.pumpAndSettle();
      expect(plans.approved, ['plan1']);
      // Lands on project detail.
      expect(find.byKey(const Key('detail-name')), findsOneWidget);
      expect(find.byKey(const Key('stage-card')), findsOneWidget);
    });

    testWidgets('empty name is rejected', (t) async {
      final projects = FakeProjectRepository();
      await pumpRouterApp(
        t,
        initial: '/projects/new/context?name=Xoai',
        projects: projects,
      );
      // Free text plant: default name uses the typed text.
      expect(find.text('Xoai – 10/2026'), findsOneWidget);
      await t.enterText(find.byKey(const Key('project-name')), '  ');
      await t.tap(find.byKey(const Key('create-plan')));
      await t.pumpAndSettle();
      expect(find.text('Hãy đặt tên cho project'), findsOneWidget);
      expect(projects.created, isEmpty);
    });

    testWidgets('create failure shows an error and stays', (t) async {
      final projects = FakeProjectRepository(failCreate: true);
      await pumpRouterApp(
        t,
        initial: '/projects/new/context?plant=p2',
        projects: projects,
      );
      await t.tap(find.byKey(const Key('create-plan')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('create-error')), findsOneWidget);
    });
  });

  group('fallback path', () {
    testWidgets('server fallback (quota) shows a message and Xem kế hoạch', (
      t,
    ) async {
      final plans = FakePlanRepository(
        result: const AiPlanResult(
          planId: 'plan1',
          source: PlanSource.fallback,
          fallbackReason: FallbackReason.quotaExceeded,
        ),
        bundle: fakeBundle(source: PlanSource.fallback, confidence: null),
      );
      await pumpRouterApp(t, initial: '/projects/new1/generating', plans: plans);

      expect(find.byKey(const Key('fallback-message')), findsOneWidget);
      expect(find.textContaining('hết lượt AI'), findsOneWidget);
      // Did not auto-navigate.
      expect(find.text('Kế hoạch 25 ngày'), findsNothing);

      await t.tap(find.byKey(const Key('view-plan')));
      await t.pumpAndSettle();
      expect(find.text('Kế hoạch 25 ngày'), findsOneWidget);
      expect(find.text('Plan mẫu'), findsOneWidget);
      expect(find.text('Gợi ý từ AI'), findsNothing);
      expect(find.byKey(const Key('plan-confidence-chip')), findsNothing);
    });

    testWidgets('quota without any plan -> failed card with quota text', (
      t,
    ) async {
      final plans = FakePlanRepository(
        result: const AiPlanResult(
          source: PlanSource.fallback,
          fallbackReason: FallbackReason.quotaExceeded,
        ),
      )..bundle = null;
      await pumpRouterApp(t, initial: '/projects/new1/generating', plans: plans);
      expect(find.byKey(const Key('generating-failed')), findsOneWidget);
      expect(find.textContaining('hết lượt AI'), findsOneWidget);
    });

    testWidgets('AI error but a stored plan exists -> fallback message', (
      t,
    ) async {
      final plans = FakePlanRepository(
        bundle: fakeBundle(source: PlanSource.fallback, confidence: null),
      )..throwOnGenerate = true;
      await pumpRouterApp(t, initial: '/projects/new1/generating', plans: plans);
      expect(find.byKey(const Key('fallback-message')), findsOneWidget);
      expect(find.textContaining('AI gặp sự cố'), findsWidgets);
    });

    testWidgets('timeout with no plan -> failed card -> retry', (t) async {
      final plans = FakePlanRepository()
        ..bundle = null
        ..hangOnGenerate = true;
      await pumpRouterApp(
        t,
        initial: '/projects/new1/generating',
        plans: plans,
        aiTimeout: const Duration(milliseconds: 100),
      );
      expect(find.byKey(const Key('generating-failed')), findsOneWidget);
      expect(find.text('AI đang gặp sự cố'), findsOneWidget);

      // Server recovered and returns its fallback template plan.
      plans
        ..hangOnGenerate = false
        ..bundle = fakeBundle(source: PlanSource.fallback, confidence: null)
        ..result = const AiPlanResult(
          planId: 'plan1',
          source: PlanSource.fallback,
          fallbackReason: FallbackReason.aiFailure,
        );
      await t.tap(find.byKey(const Key('generating-retry')));
      await t.pumpAndSettle();
      expect(plans.generateCalls, hasLength(2));
      expect(find.byKey(const Key('fallback-message')), findsOneWidget);
    });

    testWidgets('free-text plant passes plant_group to ai-plan', (t) async {
      final plans = FakePlanRepository();
      await pumpRouterApp(
        t,
        initial: '/projects/new/context?name=Xoai',
        plans: plans,
      );
      await t.tap(find.byKey(const Key('group-cay_canh')));
      await t.pump();
      await t.tap(find.byKey(const Key('create-plan')));
      await t.pumpAndSettle();
      expect(plans.generateCalls.single.plantGroup, 'cay_canh');
    });
  });

  group('plan review', () {
    testWidgets('shows AI label, confidence, sources, safety and stages', (
      t,
    ) async {
      final plans = FakePlanRepository(
        bundle: fakeBundle(sources: const ['CSDL cây', '2 tài liệu']),
      );
      await pumpRouterApp(t, initial: '/projects/new1/plan', plans: plans);

      expect(find.text('Kế hoạch 25 ngày'), findsOneWidget);
      expect(find.text('Gợi ý từ AI'), findsOneWidget);
      expect(find.text('Tin cậy cao · 86%'), findsOneWidget);
      expect(find.text('Nguồn: CSDL cây, 2 tài liệu'), findsOneWidget);
      // Safety: organic note + template safety text of T_FERT_ORGANIC.
      expect(find.text('Lưu ý an toàn'), findsOneWidget);
      expect(find.textContaining('hãy đọc nhãn sản phẩm'), findsOneWidget);
      expect(
        find.textContaining('Đọc nhãn sản phẩm, không tự pha liều.'),
        findsOneWidget,
      );
      // First stage expanded, with milestone and rendered task names.
      expect(find.text('Ươm hạt'), findsOneWidget);
      expect(find.text('Ngày 1–7 · Mốc: Nảy mầm'), findsOneWidget);
      expect(find.text('Tưới gốc'), findsOneWidget);
      expect(find.text('Hằng ngày'), findsOneWidget);
      expect(find.text('Một lần'), findsOneWidget);
      // Second stage collapsed until toggled.
      expect(find.text('Bón phân hữu cơ'), findsNothing);
      await t.tap(find.byKey(const Key('stage-toggle-s2')));
      await t.pumpAndSettle();
      expect(find.text('Bón phân hữu cơ'), findsOneWidget);
      expect(find.text('14 ngày/lần'), findsOneWidget);
    });

    testWidgets('medium confidence band', (t) async {
      final plans = FakePlanRepository(bundle: fakeBundle(confidence: 0.58));
      await pumpRouterApp(t, initial: '/projects/new1/plan', plans: plans);
      expect(find.text('Tin cậy trung bình · 58%'), findsOneWidget);
    });

    testWidgets('editing a task changes its frequency (PLN-05)', (t) async {
      final plans = FakePlanRepository(bundle: fakeBundle());
      await pumpRouterApp(t, initial: '/projects/new1/plan', plans: plans);
      await t.tap(find.byKey(const Key('task-t1')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('freq-once')));
      await t.pump();
      await t.tap(find.byKey(const Key('window-afternoon')));
      await t.pump();
      await t.tap(find.byKey(const Key('task-save')));
      await t.pumpAndSettle();
      expect(plans.updated, hasLength(1));
      expect(plans.updated.single.id, 't1');
      expect(plans.updated.single.frequency, Frequency.once);
      expect(plans.updated.single.window, TaskWindow.afternoon);
    });

    testWidgets('deleting and adding tasks go through the repository', (
      t,
    ) async {
      final plans = FakePlanRepository(bundle: fakeBundle());
      await pumpRouterApp(t, initial: '/projects/new1/plan', plans: plans);
      await t.tap(find.byKey(const Key('task-t2')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('task-delete')));
      await t.pumpAndSettle();
      expect(plans.deleted, ['t2']);

      await t.tap(find.byKey(const Key('add-task-s1')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('task-code-field')));
      await t.pumpAndSettle();
      await t.tap(find.text('Tỉa chồi nách').last);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('task-save')));
      await t.pumpAndSettle();
      expect(plans.added, hasLength(1));
      expect(plans.added.single.taskCode, 'T_PRUNE');
      expect(plans.added.single.stageId, 's1');
    });
  });
}
