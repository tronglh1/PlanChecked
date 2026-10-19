import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/plan/domain/enums.dart';
import 'package:vuon_nha/features/plan/domain/models.dart';
import 'package:vuon_nha/features/today/domain/outbox_entry.dart';
import 'package:vuon_nha/features/today/domain/today_builder.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

Task daily(
  String id, {
  TaskWindow window = TaskWindow.morning,
  String? reminder,
  String project = 'p1',
  String? assignee,
  Frequency freq = Frequency.daily,
  int? interval,
}) => Task(
  id: id,
  projectId: project,
  taskCode: 'T_$id',
  window: window,
  frequency: freq,
  intervalDays: interval,
  reminderTime: reminder,
  assigneeId: assignee,
);

TodayProject project(
  String id,
  String name,
  List<Task> tasks, {
  DateTime? start,
}) => TodayProject(
  id: id,
  name: name,
  startDate: start ?? d(2026, 10, 1),
  stages: const [],
  tasks: tasks,
);

OutboxEntry out(
  String cid,
  String task,
  DateTime occ,
  TaskAction a, {
  DateTime? at,
  DateTime? snoozeUntil,
  DateTime? actedOn,
}) => OutboxEntry(
  clientId: cid,
  taskId: task,
  occurrenceDate: occ,
  action: a,
  userId: 'u1',
  createdAt: at ?? DateTime.utc(2026, 11, 1, 8),
  actedOn: actedOn,
  snoozeUntil: snoozeUntil,
);

TaskLog log(
  String id,
  String task,
  DateTime occ,
  TaskAction a, {
  DateTime? at,
  DateTime? snoozeUntil,
  String? clientId,
  DateTime? actedOn,
}) => TaskLog(
  id: id,
  taskId: task,
  occurrenceDate: occ,
  userId: 'u1',
  action: a,
  createdAt: at ?? DateTime.utc(2026, 11, 1, 7),
  actedOn: actedOn,
  snoozeUntil: snoozeUntil,
  clientId: clientId,
);

final today = d(2026, 11, 1);

TodayItem? find(TodayView v, String task, DateTime date) {
  for (final i in [...v.items, ...v.snoozed]) {
    if (i.task.id == task && i.occurrence.date == date) return i;
  }
  return null;
}

void main() {
  group('basics', () {
    test('today pending, previous days within lookback are overdue', () {
      final v = TodayBuilder.build(
        today: today,
        projects: [
          project('p1', 'Cà chua', [daily('w')]),
        ],
      );
      expect(find(v, 'w', today)!.state, TodayState.pending);
      // lookback 3 => Oct 29, 30, 31 overdue (month boundary)
      for (final dd in [d(2026, 10, 29), d(2026, 10, 30), d(2026, 10, 31)]) {
        expect(find(v, 'w', dd)!.state, TodayState.overdue, reason: '$dd');
      }
      expect(find(v, 'w', d(2026, 10, 28)), isNull);
      expect(v.overdue.length, 3);
      expect(v.totalCount, 4);
      expect(v.doneCount, 0);
    });

    test('overdue lookback is configurable; 0 disables overdue', () {
      final v = TodayBuilder.build(
        today: today,
        overdueLookbackDays: 0,
        projects: [
          project('p1', 'A', [daily('w')]),
        ],
      );
      expect(v.items.length, 1);
      expect(v.overdue, isEmpty);
    });

    test('project not started yet shows nothing', () {
      final v = TodayBuilder.build(
        today: today,
        projects: [
          project('p1', 'A', [daily('w')], start: d(2026, 11, 2)),
        ],
      );
      expect(v.items, isEmpty);
      expect(v.progress, 0);
    });

    test('time part of today is ignored', () {
      final v = TodayBuilder.build(
        today: DateTime(2026, 11, 1, 23, 59),
        overdueLookbackDays: 0,
        projects: [
          project('p1', 'A', [daily('w')]),
        ],
      );
      expect(v.items.single.occurrence.date, today);
    });
  });

  group('grouping and ordering', () {
    final p1 = project('p1', 'Cà chua', [
      daily('a', window: TaskWindow.afternoon, reminder: '16:30'),
      daily('m2', reminder: '07:00'),
      daily('m1', reminder: '06:30'),
      daily('all', window: TaskWindow.allDay),
    ]);
    final p2 = project('p2', 'Húng quế', [
      daily('h', project: 'p2', reminder: '06:45'),
    ]);

    test('by window: morning, afternoon, all day; sorted by reminder', () {
      final v = TodayBuilder.build(
        today: today,
        overdueLookbackDays: 0,
        projects: [p1, p2],
      );
      final g = v.byWindow();
      expect(g.map((e) => e.window), [
        TaskWindow.morning,
        TaskWindow.afternoon,
        TaskWindow.allDay,
      ]);
      expect(g.first.items.map((i) => i.task.id), ['m1', 'h', 'm2']);
    });

    test('by project keeps first-appearance order', () {
      final v = TodayBuilder.build(
        today: today,
        overdueLookbackDays: 0,
        projects: [p1, p2],
      );
      final g = v.byProject();
      // morning sorted first: m1 (Cà chua), h (Húng quế) -> Cà chua first.
      expect(g.map((e) => e.projectName), ['Cà chua', 'Húng quế']);
      expect(g.last.items.single.task.id, 'h');
    });

    test('overdue goes in a leading group; can be merged back', () {
      final v = TodayBuilder.build(
        today: today,
        overdueLookbackDays: 1,
        projects: [
          project('p1', 'A', [daily('w')]),
        ],
      );
      final sep = v.byWindow();
      expect(sep.first.overdue, isTrue);
      expect(sep.first.items.single.occurrence.date, d(2026, 10, 31));
      expect(sep.last.window, TaskWindow.morning);
      final merged = v.byWindow(separateOverdue: false);
      expect(merged.single.items.length, 2);
      expect(v.byProject().first.overdue, isTrue);
    });

    test('assignee filter keeps own and unassigned tasks', () {
      final v = TodayBuilder.build(
        today: today,
        overdueLookbackDays: 0,
        assigneeId: 'u1',
        projects: [
          project('p1', 'A', [
            daily('mine', assignee: 'u1'),
            daily('theirs', assignee: 'u2'),
            daily('nobody'),
          ]),
        ],
      );
      expect(v.items.map((i) => i.task.id).toSet(), {'mine', 'nobody'});
    });
  });

  group('logs and outbox', () {
    final proj = project('p1', 'A', [daily('w')]);

    test('server done shows done and counts for progress', () {
      final v = TodayBuilder.build(
        today: today,
        overdueLookbackDays: 0,
        projects: [proj],
        logs: [log('l1', 'w', today, TaskAction.done, actedOn: today)],
      );
      final i = find(v, 'w', today)!;
      expect(i.state, TodayState.done);
      expect(i.pendingSync, isFalse);
      expect(i.doneOnTime, isTrue);
      expect(v.doneCount, 1);
      expect(v.progress, 1);
    });

    test('pending outbox done shows immediately with pendingSync', () {
      final v = TodayBuilder.build(
        today: today,
        overdueLookbackDays: 0,
        projects: [proj],
        outbox: [out('c1', 'w', today, TaskAction.done)],
      );
      final i = find(v, 'w', today)!;
      expect(i.isDone, isTrue);
      expect(i.pendingSync, isTrue);
    });

    test('outbox entry already synced (same client_id) is ignored', () {
      final v = TodayBuilder.build(
        today: today,
        overdueLookbackDays: 0,
        projects: [proj],
        logs: [
          log(
            'l1',
            'w',
            today,
            TaskAction.done,
            clientId: 'c1',
            at: DateTime.utc(2026, 11, 1, 8),
          ),
        ],
        outbox: [out('c1', 'w', today, TaskAction.skip)],
      );
      expect(find(v, 'w', today)!.state, TodayState.done);
    });

    test('latest action wins: outbox skip after server done', () {
      final v = TodayBuilder.build(
        today: today,
        overdueLookbackDays: 0,
        projects: [proj],
        logs: [
          log(
            'l1',
            'w',
            today,
            TaskAction.done,
            at: DateTime.utc(2026, 11, 1, 6),
          ),
        ],
        outbox: [
          out(
            'c1',
            'w',
            today,
            TaskAction.skip,
            at: DateTime.utc(2026, 11, 1, 9),
          ),
        ],
      );
      final i = find(v, 'w', today)!;
      expect(i.state, TodayState.skipped);
      expect(i.pendingSync, isTrue);
      expect(v.totalCount, 0); // skipped excluded from the denominator
    });

    test('server row newer than outbox wins', () {
      final v = TodayBuilder.build(
        today: today,
        overdueLookbackDays: 0,
        projects: [proj],
        logs: [
          log(
            'l1',
            'w',
            today,
            TaskAction.done,
            at: DateTime.utc(2026, 11, 1, 10),
          ),
        ],
        outbox: [
          out(
            'c1',
            'w',
            today,
            TaskAction.skip,
            at: DateTime.utc(2026, 11, 1, 9),
          ),
        ],
      );
      expect(find(v, 'w', today)!.state, TodayState.done);
    });

    test('duplicate outbox client_ids collapse', () {
      final e = out('c1', 'w', today, TaskAction.done);
      expect(
        OutboxEntry.dedupe([e, e, out('c2', 'w', today, TaskAction.skip)])
            .length,
        2,
      );
    });

    test('done overdue item disappears; done late today stays visible', () {
      final v = TodayBuilder.build(
        today: today,
        overdueLookbackDays: 2,
        projects: [proj],
        logs: [
          // Oct 31 done yesterday: hidden.
          log(
            'l1',
            'w',
            d(2026, 10, 31),
            TaskAction.done,
            actedOn: d(2026, 10, 31),
          ),
          // Oct 30 done late, today: visible as done.
          log('l2', 'w', d(2026, 10, 30), TaskAction.done, actedOn: today),
        ],
      );
      expect(find(v, 'w', d(2026, 10, 31)), isNull);
      final late = find(v, 'w', d(2026, 10, 30))!;
      expect(late.isDone, isTrue);
      expect(late.doneOnTime, isFalse);
    });

    test('skip on an overdue day removes it from overdue', () {
      final v = TodayBuilder.build(
        today: today,
        overdueLookbackDays: 1,
        projects: [proj],
        outbox: [
          out(
            'c1',
            'w',
            d(2026, 10, 31),
            TaskAction.skip,
            actedOn: d(2026, 10, 31),
          ),
        ],
      );
      expect(v.overdue, isEmpty);
    });
  });

  group('snooze', () {
    final proj = project('p1', 'A', [daily('w')]);

    test('snooze into next day hides the item today', () {
      final v = TodayBuilder.build(
        today: today,
        overdueLookbackDays: 0,
        projects: [proj],
        outbox: [
          out('c1', 'w', today, TaskAction.snooze, snoozeUntil: d(2026, 11, 2)),
        ],
      );
      expect(v.items, isEmpty);
      final s = v.snoozed.single;
      expect(s.state, TodayState.snoozed);
      expect(s.dueDate, d(2026, 11, 2));
    });

    test('snooze without a date defaults to the next day', () {
      final v = TodayBuilder.build(
        today: today,
        overdueLookbackDays: 0,
        projects: [proj],
        logs: [log('l1', 'w', today, TaskAction.snooze)],
      );
      expect(v.items, isEmpty);
      expect(v.snoozed.single.dueDate, d(2026, 11, 2));
    });

    test('snoozed yesterday to today is pending today, not overdue', () {
      final v = TodayBuilder.build(
        today: today,
        overdueLookbackDays: 2,
        projects: [proj],
        logs: [
          log(
            'l1',
            'w',
            d(2026, 10, 31),
            TaskAction.snooze,
            snoozeUntil: today,
            actedOn: d(2026, 10, 31),
          ),
        ],
      );
      final i = find(v, 'w', d(2026, 10, 31))!;
      expect(i.state, TodayState.pending);
      expect(i.dueDate, today);
    });

    test('snoozed to a past date is overdue relative to the new date', () {
      final v = TodayBuilder.build(
        today: today,
        overdueLookbackDays: 3,
        projects: [proj],
        logs: [
          log(
            'l1',
            'w',
            d(2026, 10, 29),
            TaskAction.snooze,
            snoozeUntil: d(2026, 10, 30),
          ),
        ],
      );
      expect(find(v, 'w', d(2026, 10, 29))!.state, TodayState.overdue);
    });

    test('done after snooze: on time when done by the snooze date', () {
      final v = TodayBuilder.build(
        today: d(2026, 11, 2),
        overdueLookbackDays: 2,
        projects: [proj],
        logs: [
          log(
            'l1',
            'w',
            today,
            TaskAction.snooze,
            snoozeUntil: d(2026, 11, 2),
            at: DateTime.utc(2026, 11, 1, 8),
          ),
        ],
        outbox: [
          out(
            'c1',
            'w',
            today,
            TaskAction.done,
            at: DateTime.utc(2026, 11, 2, 7),
            actedOn: d(2026, 11, 2),
          ),
        ],
      );
      final i = find(v, 'w', today)!;
      expect(i.isDone, isTrue);
      expect(i.dueDate, d(2026, 11, 2));
      expect(i.doneOnTime, isTrue);
      expect(i.pendingSync, isTrue);
    });

    test('re-snoozing moves the target again', () {
      final v = TodayBuilder.build(
        today: today,
        overdueLookbackDays: 0,
        projects: [proj],
        logs: [
          log(
            'l1',
            'w',
            today,
            TaskAction.snooze,
            snoozeUntil: today,
            at: DateTime.utc(2026, 11, 1, 6),
          ),
        ],
        outbox: [
          out('c1', 'w', today, TaskAction.snooze, snoozeUntil: d(2026, 11, 3)),
        ],
      );
      expect(v.items, isEmpty);
      expect(v.snoozed.single.dueDate, d(2026, 11, 3));
    });
  });

  group('stage boundaries', () {
    test('stage-bound tasks appear only within their stage days', () {
      const s1 = Stage(
        id: 's1',
        planId: 'pl',
        idx: 0,
        code: 'seedling',
        name: 'Cây con',
        dayFrom: 1,
        dayTo: 7,
      );
      const s2 = Stage(
        id: 's2',
        planId: 'pl',
        idx: 1,
        code: 'veg',
        name: 'Sinh trưởng',
        dayFrom: 8,
        dayTo: 30,
      );
      final a = Task(
        id: 'a',
        projectId: 'p1',
        stageId: 's1',
        taskCode: 'T_A',
        window: TaskWindow.morning,
        frequency: Frequency.daily,
      );
      final b = Task(
        id: 'b',
        projectId: 'p1',
        stageId: 's2',
        taskCode: 'T_B',
        window: TaskWindow.morning,
        frequency: Frequency.daily,
      );
      final proj = TodayProject(
        id: 'p1',
        name: 'A',
        startDate: d(2026, 10, 25),
        stages: const [s1, s2],
        tasks: [a, b],
      );
      // Oct 31 = day 7 (last of s1); Nov 1 = day 8 (first of s2).
      final v31 = TodayBuilder.build(
        today: d(2026, 10, 31),
        overdueLookbackDays: 0,
        projects: [proj],
      );
      expect(v31.items.map((i) => i.task.id), ['a']);
      final v01 = TodayBuilder.build(
        today: d(2026, 11, 1),
        overdueLookbackDays: 0,
        projects: [proj],
      );
      expect(v01.items.map((i) => i.task.id), ['b']);
    });
  });
}
