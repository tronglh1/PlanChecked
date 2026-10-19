import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/plan/domain/enums.dart';
import 'package:vuon_nha/features/plan/domain/models.dart';
import 'package:vuon_nha/features/plan/domain/task_scheduler.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

const seedling = Stage(
  id: 's1',
  planId: 'pl',
  idx: 0,
  code: 'seedling',
  name: 'Cây con',
  dayFrom: 1,
  dayTo: 14,
);
const veg = Stage(
  id: 's2',
  planId: 'pl',
  idx: 1,
  code: 'vegetative',
  name: 'Sinh trưởng',
  dayFrom: 15,
  dayTo: 40,
);
final start = d(2026, 10, 25); // day 1 = Oct 25, day 8 = Nov 1

Task task(
  Frequency f, {
  String id = 't',
  String? stageId,
  int? interval,
  TaskWindow window = TaskWindow.morning,
  DateTime? fixedDate,
  String status = 'active',
  String? reminder,
  String code = 'T_WATER',
}) => Task(
  id: id,
  projectId: 'p',
  stageId: stageId,
  taskCode: code,
  window: window,
  frequency: f,
  intervalDays: interval,
  fixedDate: fixedDate,
  status: status,
  reminderTime: reminder,
);

List<DateTime> dates(List<TaskOccurrence> o) => o.map((e) => e.date).toList();

void main() {
  group('day numbering', () {
    test('day 1 is the start date; crosses month boundary', () {
      expect(TaskScheduler.dayNumber(start, start), 1);
      expect(TaskScheduler.dayNumber(start, d(2026, 11, 1)), 8);
      expect(TaskScheduler.dateOfDay(start, 8), d(2026, 11, 1));
      expect(TaskScheduler.dayNumber(start, d(2026, 10, 24)), 0);
    });

    test('stageOn respects inclusive boundaries and gaps', () {
      final stages = [veg, seedling]; // unsorted on purpose
      expect(TaskScheduler.stageOn(stages, start, d(2026, 10, 24)), isNull);
      expect(TaskScheduler.stageOn(stages, start, start)?.id, 's1');
      expect(
        TaskScheduler.stageOn(stages, start, d(2026, 11, 7))?.id,
        's1',
      ); // day 14
      expect(
        TaskScheduler.stageOn(stages, start, d(2026, 11, 8))?.id,
        's2',
      ); // day 15
      expect(
        TaskScheduler.stageOn(stages, start, d(2026, 12, 3))?.id,
        's2',
      ); // day 40
      expect(TaskScheduler.stageOn(stages, start, d(2026, 12, 4)), isNull);
    });
  });

  group('expand', () {
    test('daily within a stage is clipped to the stage range', () {
      final o = TaskScheduler.expand(
        task: task(Frequency.daily, stageId: 's1'),
        stage: seedling,
        projectStart: start,
        from: d(2026, 10, 20),
        to: d(2026, 12, 31),
      );
      expect(o.length, 14);
      expect(o.first.date, d(2026, 10, 25));
      expect(o.last.date, d(2026, 11, 7));
    });

    test('daily over a month boundary', () {
      final o = TaskScheduler.expand(
        task: task(Frequency.daily),
        projectStart: start,
        from: d(2026, 10, 30),
        to: d(2026, 11, 2),
      );
      expect(dates(o), [
        d(2026, 10, 30),
        d(2026, 10, 31),
        d(2026, 11, 1),
        d(2026, 11, 2),
      ]);
    });

    test(
      'every_n_days anchors on the stage first day, not on the range start',
      () {
        // veg starts day 15 = Nov 8. every 3 days: Nov 8, 11, 14, ...
        final o = TaskScheduler.expand(
          task: task(Frequency.everyNDays, stageId: 's2', interval: 3),
          stage: veg,
          projectStart: start,
          from: d(2026, 11, 9), // query starts mid-cycle
          to: d(2026, 11, 20),
        );
        expect(dates(o), [
          d(2026, 11, 11),
          d(2026, 11, 14),
          d(2026, 11, 17),
          d(2026, 11, 20),
        ]);
      },
    );

    test('every_n_days: stage boundary day is included, day after is not', () {
      // seedling days 1..14, every 7 -> days 1, 8 (14 is not on the cycle).
      final o = TaskScheduler.expand(
        task: task(Frequency.everyNDays, stageId: 's1', interval: 7),
        stage: seedling,
        projectStart: start,
        from: start,
        to: d(2026, 12, 31),
      );
      expect(dates(o), [d(2026, 10, 25), d(2026, 11, 1)]);
      // every 13 -> day 1 and day 14 (last stage day, inclusive).
      final o2 = TaskScheduler.expand(
        task: task(Frequency.everyNDays, stageId: 's1', interval: 13),
        stage: seedling,
        projectStart: start,
        from: start,
        to: d(2026, 12, 31),
      );
      expect(dates(o2), [d(2026, 10, 25), d(2026, 11, 7)]);
    });

    test('every_n_days with missing/invalid interval behaves as daily', () {
      final o = TaskScheduler.expand(
        task: task(Frequency.everyNDays, interval: 0),
        projectStart: start,
        from: start,
        to: d(2026, 10, 27),
      );
      expect(o.length, 3);
    });

    test('once lands on the stage first day only if in range', () {
      final t = task(Frequency.once, stageId: 's2');
      expect(
        dates(
          TaskScheduler.expand(
            task: t,
            stage: veg,
            projectStart: start,
            from: d(2026, 11, 1),
            to: d(2026, 11, 30),
          ),
        ),
        [d(2026, 11, 8)],
      );
      expect(
        TaskScheduler.expand(
          task: t,
          stage: veg,
          projectStart: start,
          from: d(2026, 11, 9),
          to: d(2026, 11, 30),
        ),
        isEmpty,
      );
    });

    test('once without a stage is project day 1', () {
      expect(
        dates(
          TaskScheduler.expand(
            task: task(Frequency.once),
            projectStart: start,
            from: d(2026, 10, 1),
            to: d(2026, 12, 1),
          ),
        ),
        [start],
      );
    });

    test('fixed_date uses explicit date, else project day number', () {
      final explicit = task(Frequency.fixedDate, fixedDate: d(2026, 11, 20));
      expect(
        dates(
          TaskScheduler.expand(
            task: explicit,
            projectStart: start,
            from: d(2026, 11, 1),
            to: d(2026, 11, 30),
          ),
        ),
        [d(2026, 11, 20)],
      );
      final byDay = task(Frequency.fixedDate, interval: 20); // day 20 = Nov 13
      expect(
        dates(
          TaskScheduler.expand(
            task: byDay,
            projectStart: start,
            from: d(2026, 11, 1),
            to: d(2026, 11, 30),
          ),
        ),
        [d(2026, 11, 13)],
      );
      // No date and no day -> nothing.
      expect(
        TaskScheduler.expand(
          task: task(Frequency.fixedDate),
          projectStart: start,
          from: d(2026, 10, 1),
          to: d(2026, 12, 31),
        ),
        isEmpty,
      );
    });

    test('fixed_date day outside its stage yields nothing', () {
      expect(
        TaskScheduler.expand(
          task: task(Frequency.fixedDate, stageId: 's1', interval: 20),
          stage: seedling,
          projectStart: start,
          from: d(2026, 10, 1),
          to: d(2026, 12, 31),
        ),
        isEmpty,
      );
    });

    test('inactive task and reversed range yield nothing', () {
      expect(
        TaskScheduler.expand(
          task: task(Frequency.daily, status: 'archived'),
          projectStart: start,
          from: start,
          to: d(2026, 11, 1),
        ),
        isEmpty,
      );
      expect(
        TaskScheduler.expand(
          task: task(Frequency.daily),
          projectStart: start,
          from: d(2026, 11, 1),
          to: start,
        ),
        isEmpty,
      );
    });

    test('range before project start yields nothing; leap day handled', () {
      expect(
        TaskScheduler.expand(
          task: task(Frequency.daily),
          projectStart: start,
          from: d(2026, 10, 1),
          to: d(2026, 10, 24),
        ),
        isEmpty,
      );
      final leapStart = d(2028, 2, 27);
      final o = TaskScheduler.expand(
        task: task(Frequency.daily),
        projectStart: leapStart,
        from: leapStart,
        to: d(2028, 3, 1),
      );
      expect(dates(o), [
        d(2028, 2, 27),
        d(2028, 2, 28),
        d(2028, 2, 29),
        d(2028, 3, 1),
      ]);
    });

    test('local-time inputs are read by their y/m/d, time ignored', () {
      final o = TaskScheduler.expand(
        task: task(Frequency.daily),
        projectStart: DateTime(2026, 10, 25, 23, 30),
        from: DateTime(2026, 10, 25, 0, 5),
        to: DateTime(2026, 10, 25, 23, 59),
      );
      expect(dates(o), [d(2026, 10, 25)]);
    });
  });

  group('expandAll', () {
    test('sorts by date, window, reminder time, code; skips unknown stage', () {
      final tasks = [
        task(
          Frequency.daily,
          id: 'a',
          window: TaskWindow.afternoon,
          reminder: '16:30',
          code: 'T_B',
        ),
        task(
          Frequency.daily,
          id: 'b',
          window: TaskWindow.morning,
          reminder: '07:00',
          code: 'T_C',
        ),
        task(
          Frequency.daily,
          id: 'c',
          window: TaskWindow.morning,
          reminder: '06:30',
          code: 'T_D',
        ),
        task(Frequency.daily, id: 'z', stageId: 'missing'),
      ];
      final o = TaskScheduler.expandAll(
        tasks: tasks,
        stages: [seedling, veg],
        projectStart: start,
        from: start,
        to: d(2026, 10, 26),
      );
      expect(o.map((e) => e.taskId).toList(), ['c', 'b', 'a', 'c', 'b', 'a']);
      expect(o.any((e) => e.taskId == 'z'), isFalse);
    });

    test(
      'stage change: task of stage 1 stops, stage 2 starts the next day',
      () {
        final tasks = [
          task(Frequency.daily, id: 'a', stageId: 's1'),
          task(Frequency.daily, id: 'b', stageId: 's2'),
        ];
        final o = TaskScheduler.expandAll(
          tasks: tasks,
          stages: [seedling, veg],
          projectStart: start,
          from: d(2026, 11, 7),
          to: d(2026, 11, 8),
        );
        expect(o.map((e) => '${e.taskId}@${e.date.day}').toList(), [
          'a@7',
          'b@8',
        ]);
      },
    );
  });

  group('CheckinCadence', () {
    test('interval by stage code, always within 3..7', () {
      Stage s(String code, int from, int to) => Stage(
        id: code,
        planId: 'p',
        idx: 0,
        code: code,
        name: code,
        dayFrom: from,
        dayTo: to,
      );
      expect(CheckinCadence.intervalDays(s('seed', 1, 7)), 3);
      expect(CheckinCadence.intervalDays(s('germination', 1, 7)), 3);
      expect(CheckinCadence.intervalDays(seedling), 5); // mockup: Cây con = 5
      expect(CheckinCadence.intervalDays(veg), 5);
      expect(CheckinCadence.intervalDays(s('flowering', 40, 60)), 7);
      expect(CheckinCadence.intervalDays(s('harvest', 60, 90)), 7);
      // unknown code: ~quarter of length, clamped
      expect(CheckinCadence.intervalDays(s('x', 1, 4)), 3);
      expect(CheckinCadence.intervalDays(s('x', 1, 20)), 5);
      expect(CheckinCadence.intervalDays(s('x', 1, 200)), 7);
    });

    test('never checked in => due on project start (so due today)', () {
      expect(
        CheckinCadence.nextDue(stages: [seedling, veg], projectStart: start),
        start,
      );
      expect(
        CheckinCadence.isDue(
          today: d(2026, 10, 25),
          stages: [seedling, veg],
          projectStart: start,
        ),
        isTrue,
      );
    });

    test('next due uses the stage of the last check-in; month boundary', () {
      final last = d(2026, 10, 30); // day 6, seedling -> 5 days
      final due = CheckinCadence.nextDue(
        stages: [seedling, veg],
        projectStart: start,
        lastCheckin: last,
      );
      expect(due, d(2026, 11, 4));
      expect(
        CheckinCadence.isDue(
          today: d(2026, 11, 3),
          stages: [seedling, veg],
          projectStart: start,
          lastCheckin: last,
        ),
        isFalse,
      );
      expect(
        CheckinCadence.isDue(
          today: d(2026, 11, 4),
          stages: [seedling, veg],
          projectStart: start,
          lastCheckin: last,
        ),
        isTrue,
      );
    });

    test(
      'past the last stage falls back to the last stage; no stages => 7',
      () {
        final late = d(2027, 1, 1);
        expect(
          CheckinCadence.nextDue(
            stages: [seedling, veg],
            projectStart: start,
            lastCheckin: late,
          ),
          d(2027, 1, 6),
        );
        expect(
          CheckinCadence.nextDue(
            stages: const [],
            projectStart: start,
            lastCheckin: late,
          ),
          d(2027, 1, 8),
        );
      },
    );

    test('projected dates step through stages', () {
      final p = CheckinCadence.projected(
        stages: [seedling, veg],
        projectStart: start,
        from: start,
        to: d(2026, 11, 15),
      );
      // day1 (Oct 25) +5 -> Oct 30 +5 -> Nov 4 +5 -> Nov 9 (veg, 5) -> Nov 14
      expect(p, [
        d(2026, 10, 25),
        d(2026, 10, 30),
        d(2026, 11, 4),
        d(2026, 11, 9),
        d(2026, 11, 14),
      ]);
    });
  });
}
