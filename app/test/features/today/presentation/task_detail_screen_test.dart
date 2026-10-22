import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/plan/domain/enums.dart';

import 'today_screen_test.dart';

void main() {
  testWidgets('shows name, steps, why, tiles, assign link and actions', (
    t,
  ) async {
    final env = Env();
    await pumpToday(t, env, location: '/task/t-water');
    expect(find.byKey(const Key('task-title')), findsOneWidget);
    expect(find.text('Tưới nước'), findsOneWidget);
    expect(find.text('Tưới đẫm gốc'), findsOneWidget);
    expect(find.text('Tránh ướt lá'), findsOneWidget);
    expect(find.byKey(const Key('task-why')), findsOneWidget);
    expect(find.text('Hằng ngày'), findsOneWidget);
    expect(find.text('06:30'), findsOneWidget);
    expect(find.text('Chưa giao ai'), findsOneWidget);
    expect(find.text('Xong · +10 XP'), findsOneWidget);
    expect(find.byKey(const Key('task-safety')), findsNothing);
    expect(find.byKey(const Key('task-history-empty')), findsOneWidget);

    await t.tap(find.byKey(const Key('task-assign')));
    await t.pumpAndSettle();
    expect(find.text('assign-stub'), findsOneWidget);
  });

  testWidgets('fertilizer tasks show the safety warning (PLN-09)', (t) async {
    final env = Env();
    await pumpToday(t, env, location: '/task/t-fert');
    expect(find.byKey(const Key('task-safety')), findsOneWidget);
    expect(find.textContaining('nhãn sản phẩm'), findsOneWidget);
    expect(find.text('3 ngày/lần'), findsOneWidget);
  });

  testWidgets('Done from detail logs it and shows history', (t) async {
    final env = Env();
    await pumpToday(t, env, location: '/task/t-water');
    await t.tap(find.byKey(const Key('task-done')));
    await t.pumpAndSettle();
    expect(env.repo.inserted.single.action, TaskAction.done);
    // No page below to pop to: stays here with the history updated.
    expect(find.text('Xong'), findsNWidgets(2)); // button + history row
    expect(find.byKey(const Key('task-history-empty')), findsNothing);
  });

  testWidgets('unknown task id shows not found', (t) async {
    final env = Env();
    await pumpToday(t, env, location: '/task/nope');
    expect(find.text('Không tìm thấy việc này'), findsOneWidget);
  });
}
