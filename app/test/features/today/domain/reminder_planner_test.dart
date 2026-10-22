import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/plan/domain/enums.dart';
import 'package:vuon_nha/features/plan/domain/models.dart';
import 'package:vuon_nha/features/today/domain/outbox_entry.dart';
import 'package:vuon_nha/features/today/domain/today_builder.dart';
import 'package:vuon_nha/features/settings/domain/notification_settings.dart';
import 'package:vuon_nha/features/today/data/reminder_scheduler.dart';
import 'package:vuon_nha/features/today/domain/checkin_due.dart';
import 'package:vuon_nha/features/today/domain/reminder_planner.dart';

import '../helpers/today_fixtures.dart';

List<PlannedNotification> plan({
  DateTime? now,
  NotificationSettings settings = const NotificationSettings(),
  QuietHours? quiet,
  List<OutboxEntry> outbox = const [],
  Map<String, DateTime> lastCheckins = const {},
  List<TodayProject>? projects,
}) => ReminderPlanner.plan(
  now: now ?? kNow,
  projects: projects ?? [project()],
  outbox: outbox,
  settings: settings,
  userId: 'u1',
  taskName: (t) => t.taskCode,
  texts: testTexts(),
  lastCheckins: lastCheckins,
  quiet: quiet,
);

void main() {
  final noCheckin = const NotificationSettings().withType(
    NotifType.checkinReminder,
    false,
  );

  test('groups per window and uses the earliest reminder time', () {
    final n = plan(settings: noCheckin);
    final today = n.where((x) => x.when.day == 19).toList();
    // 06:30 is already past at 07:00 -> only the afternoon group remains.
    expect(today, hasLength(1));
    expect(today.single.when, DateTime(2026, 10, 19, 16, 30));
    expect(today.single.title, 'W:afternoon');
    expect(today.single.body, 'T_FERT_ORGANIC');
    expect(today.single.payload, '/today');
  });

  test('covers 7 days with one notification per day and window', () {
    final n = plan(settings: noCheckin);
    final morning = n.where((x) => x.title == 'W:morning').toList();
    // Oct 20..25 (Oct 19 06:30 passed).
    expect(morning.map((x) => x.when.day), [20, 21, 22, 23, 24, 25]);
    expect(morning.every((x) => x.when.hour == 6 && x.when.minute == 30), true);
    final fert = n.where((x) => x.title == 'W:afternoon').toList();
    // Every 3 days from day 1 (Oct 10): 19, 22, 25.
    expect(fert.map((x) => x.when.day), [19, 22, 25]);
    expect(n.last.when.isBefore(DateTime(2026, 10, 26)), true);
    // Sorted, unique ids.
    expect(n.map((x) => x.when).toList(), [...n.map((x) => x.when)]..sort());
    expect(n.map((x) => x.id).toSet().length, n.length);
  });

  test('same-window tasks are merged into one notification', () {
    final n = plan(
      settings: noCheckin,
      projects: [
        project(),
        project(id: 'p2', name: 'Rau muống', tasks: [kPrune]),
      ],
    );
    final tomorrow = n.where((x) => x.when.day == 20 && x.title == 'W:morning');
    expect(tomorrow, hasLength(1));
    // kPrune has no reminder time -> window default 06:00 is the earliest.
    expect(tomorrow.single.when.hour, 6);
    expect(tomorrow.single.when.minute, 0);
    expect(tomorrow.single.body, 'T_PRUNE+T_WATER');
  });

  test('task reminder toggle off removes task notifications', () {
    final n = plan(
      settings: const NotificationSettings().withType(
        NotifType.taskReminder,
        false,
      ),
    );
    expect(n.every((x) => x.kind == ReminderKind.checkin), true);
    final none = plan(
      settings: noCheckin.withType(NotifType.taskReminder, false),
    );
    expect(none, isEmpty);
  });

  test('a task already done today is not reminded', () {
    final n = plan(
      settings: noCheckin,
      projects: [
        project(tasks: [kFert], start: DateTime.utc(2026, 10, 19)),
      ],
      outbox: [entry('c1', 't-fert', TaskAction.done)],
    );
    expect(n.where((x) => x.when.day == 19), isEmpty);
  });

  test('a snoozed task moves to the snooze date', () {
    final n = plan(
      settings: noCheckin,
      projects: [
        project(tasks: [kFert], start: DateTime.utc(2026, 10, 19)),
      ],
      outbox: [
        entry(
          'c1',
          't-fert',
          TaskAction.snooze,
          snoozeUntil: DateTime.utc(2026, 10, 21),
        ),
      ],
    );
    expect(n.where((x) => x.when.day == 19), isEmpty);
    final d21 = n.where((x) => x.when.day == 21 && x.title == 'W:afternoon');
    expect(d21, hasLength(1));
  });

  test(
    'bundle daily creates one notification per day at the earliest time',
    () {
      final n = plan(settings: noCheckin.withBundle(true));
      final byDay = <int, int>{};
      for (final x in n) {
        byDay[x.when.day] = (byDay[x.when.day] ?? 0) + 1;
      }
      expect(byDay.values.every((c) => c == 1), true);
      final d22 = n.firstWhere((x) => x.when.day == 22);
      expect(d22.title, 'Daily:2');
      expect(d22.when, DateTime(2026, 10, 22, 6, 30));
    },
  );

  test('quiet hours push a reminder to the end of the quiet period', () {
    const quiet = QuietHours(22 * 60, 7 * 60); // 22:00-07:00
    final n = plan(settings: noCheckin, quiet: quiet);
    final d20 = n.firstWhere((x) => x.when.day == 20 && x.title == 'W:morning');
    expect(d20.when, DateTime(2026, 10, 20, 7, 0));
    // Afternoon is outside quiet hours and unchanged.
    expect(
      n.firstWhere((x) => x.title == 'W:afternoon').when,
      DateTime(2026, 10, 19, 16, 30),
    );
  });

  test('QuietHours.shift handles late-evening times on the previous day', () {
    const q = QuietHours(22 * 60, 6 * 60);
    expect(
      q.shift(DateTime(2026, 10, 19, 23, 0)),
      DateTime(2026, 10, 20, 6, 0),
    );
    expect(q.shift(DateTime(2026, 10, 19, 5, 0)), DateTime(2026, 10, 19, 6, 0));
    expect(q.shift(DateTime(2026, 10, 19, 6, 0)), DateTime(2026, 10, 19, 6, 0));
    expect(QuietHours.parse('22:00:00', '06:00:00')!.contains(23 * 60), true);
    expect(QuietHours.parse(null, '06:00'), isNull);
  });

  test('tasks assigned to someone else are not reminded', () {
    final other = kWater.toJson()..['assignee_id'] = 'u2';
    final n = plan(
      settings: noCheckin,
      projects: [
        project(tasks: [kFert]),
        project(id: 'p3', name: 'X', tasks: [Task.fromJson(other)]),
      ],
    );
    expect(n.where((x) => x.title == 'W:morning'), isEmpty);
  });

  group('check-in reminders', () {
    test('never checked in: due today, 09:00 still ahead', () {
      final n = plan();
      final c = n.firstWhere((x) => x.kind == ReminderKind.checkin);
      expect(c.when, DateTime(2026, 10, 19, 9, 0));
      expect(c.payload, '/projects/p1/checkin');
      expect(c.title, 'Checkin');
      expect(c.body, 'Chup Cà chua bi');
    });

    test('after 09:00 a due check-in is nudged tomorrow', () {
      final n = plan(now: DateTime(2026, 10, 19, 10, 0));
      final c = n.firstWhere((x) => x.kind == ReminderKind.checkin);
      expect(c.when, DateTime(2026, 10, 20, 9, 0));
    });

    test('upcoming check-in uses the stage cadence', () {
      // Stage code S2_growth -> every 5 days; last on 17/10 -> due 22/10.
      final n = plan(lastCheckins: {'p1': DateTime.utc(2026, 10, 17)});
      final c = n.firstWhere((x) => x.kind == ReminderKind.checkin);
      expect(c.when, DateTime(2026, 10, 22, 9, 0));
    });

    test('toggle off removes check-in reminders', () {
      expect(
        plan(settings: noCheckin).any((x) => x.kind == ReminderKind.checkin),
        false,
      );
    });

    test('checkinsDue lists only due projects', () {
      final due = checkinsDue(
        today: kToday,
        projects: [
          project(),
          project(id: 'p9', name: 'B'),
        ],
        lastCheckins: {'p9': DateTime.utc(2026, 10, 18)},
      );
      expect(due.map((d) => d.projectId), ['p1']);
    });
  });

  group('ReminderScheduler', () {
    Future<List<PlannedNotification>> run(FakeNotificationGateway g) =>
        ReminderScheduler(g, clock: () => kNow).reschedule(
          projects: [project()],
          logs: const [],
          outbox: const [],
          settings: const NotificationSettings(),
          userId: 'u1',
          taskName: (t) => t.taskCode,
          texts: testTexts(),
        );

    test('replaces all scheduled notifications', () async {
      final g = FakeNotificationGateway();
      final plan1 = await run(g);
      expect(g.scheduled, plan1);
      expect(plan1, isNotEmpty);
      await run(g);
      expect(g.replaceCalls, 2);
    });

    test('schedules nothing without OS permission', () async {
      final g = FakeNotificationGateway(granted: false);
      expect(await run(g), isEmpty);
      expect(g.scheduled, isEmpty);
    });
  });
}
