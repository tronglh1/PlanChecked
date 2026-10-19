import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/plan/domain/enums.dart';
import 'package:vuon_nha/features/plan/domain/task_scheduler.dart';

import '../../helpers/projects_fakes.dart';

void main() {
  testWidgets('calendar shows the occurrences TaskScheduler computes', (
    t,
  ) async {
    final bundle = fakeBundle(status: PlanStatus.approved);
    // Source of truth for the expectations.
    final week = TaskScheduler.expandAll(
      tasks: bundle.tasks,
      stages: bundle.stages,
      projectStart: testStart,
      from: DateTime.utc(2026, 10, 12),
      to: DateTime.utc(2026, 10, 18),
    );
    int expected(int day) => week.where((o) => o.date.day == day).length;
    expect(expected(12), 0); // before day 1
    expect(expected(13), 2); // daily water + once soak

    await pumpRouterApp(
      t,
      initial: '/projects/new1/calendar',
      plans: FakePlanRepository(bundle: bundle),
      today: DateTime.utc(2026, 10, 13),
    );

    expect(find.text('Lịch chăm sóc'), findsOneWidget);
    expect(find.byKey(const Key('week-label')), findsOneWidget);
    expect(find.text('Tuần 12/10–18/10'), findsOneWidget);
    for (var d = 12; d <= 18; d++) {
      expect(
        tester(t, 'count-2026-10-$d').data,
        '${expected(d)}',
        reason: 'day $d',
      );
    }

    // Selected day = today (Tue 13/10): its tasks are listed.
    expect(find.text('T4, 13/10'), findsNothing);
    expect(find.text('T3, 13/10'), findsOneWidget);
    expect(find.text('Tưới gốc'), findsOneWidget);
    expect(find.text('Ngâm hạt nước ấm'), findsOneWidget);
    expect(find.byKey(const Key('cal-task-t1')), findsOneWidget);

    // Stage banner and timeline.
    expect(find.byKey(const Key('stage-timeline')), findsOneWidget);
    expect(
      find.text('Giai đoạn 1 · Ươm hạt (ngày 1–7) · còn 6 ngày'),
      findsOneWidget,
    );

    // A day before the plan has no tasks.
    await t.tap(find.byKey(const Key('day-2026-10-12')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('day-empty')), findsOneWidget);

    // Next week: stage 2 starts on day 8 (20/10).
    await t.tap(find.byKey(const Key('week-next')));
    await t.pumpAndSettle();
    expect(find.text('Tuần 19/10–25/10'), findsOneWidget);
    final next = TaskScheduler.expandAll(
      tasks: bundle.tasks,
      stages: bundle.stages,
      projectStart: testStart,
      from: DateTime.utc(2026, 10, 19),
      to: DateTime.utc(2026, 10, 25),
    );
    int n(int day) => next.where((o) => o.date.day == day).length;
    expect(n(19), 1); // water on day 7
    expect(n(20), 2); // fert + prune start stage 2
    expect(tester(t, 'count-2026-10-19').data, '1');
    expect(tester(t, 'count-2026-10-20').data, '2');
    await t.tap(find.byKey(const Key('day-2026-10-20')));
    await t.pumpAndSettle();
    expect(find.text('Bón phân hữu cơ'), findsOneWidget);
    expect(find.text('Tỉa chồi nách'), findsOneWidget);
    expect(find.text('7 ngày/lần'), findsOneWidget);
    expect(find.textContaining('Giai đoạn 2 · Cây con'), findsOneWidget);
  });

  testWidgets('add a manual task from the calendar', (t) async {
    final plans = FakePlanRepository(
      bundle: fakeBundle(status: PlanStatus.approved),
    );
    await pumpRouterApp(
      t,
      initial: '/projects/new1/calendar',
      plans: plans,
      today: DateTime.utc(2026, 10, 13),
    );
    await t.ensureVisible(find.byKey(const Key('add-manual-task')));
    await t.tap(find.byKey(const Key('add-manual-task')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('task-code-field')));
    await t.pumpAndSettle();
    await t.tap(find.text('Tưới gốc').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('task-save')));
    await t.pumpAndSettle();
    expect(plans.added.single.taskCode, 'T_WATER');
    expect(plans.added.single.frequency, Frequency.daily);
    expect(plans.added.single.stageId, 's1');
  });
}

Text tester(WidgetTester t, String key) =>
    t.widget<Text>(find.byKey(Key(key)));
