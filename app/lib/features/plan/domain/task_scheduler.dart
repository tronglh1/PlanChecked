/// Expands plan tasks into dated occurrences and computes check-in cadence.
/// Pure Dart, timezone-free (all dates are date-only UTC).
///
/// Day numbering: project day 1 = `start_date`; stage `day_from`/`day_to` are
/// inclusive in the same numbering.
library;

import '../../../core/utils/date_only.dart';
import 'enums.dart';
import 'models.dart';

class TaskScheduler {
  const TaskScheduler._();

  /// 1-based project day number of [date] (day 1 = [projectStart]). Can be
  /// <= 0 before the start.
  static int dayNumber(DateTime projectStart, DateTime date) =>
      daysBetween(projectStart, date) + 1;

  /// Calendar date of 1-based project [day].
  static DateTime dateOfDay(DateTime projectStart, int day) =>
      addDays(dateOnly(projectStart), day - 1);

  /// The stage containing [date], or null before the start / after the last
  /// stage. If stages overlap, the lowest `idx` wins.
  static Stage? stageOn(
    List<Stage> stages,
    DateTime projectStart,
    DateTime date,
  ) {
    final day = dayNumber(projectStart, date);
    final sorted = [...stages]..sort((a, b) => a.idx.compareTo(b.idx));
    for (final s in sorted) {
      if (s.containsDay(day)) return s;
    }
    return null;
  }

  /// Occurrences of [task] with `from <= date <= to` (inclusive).
  ///
  /// Mirrors SQL `task_due_on` exactly. With `first = stage.dayFrom +
  /// task.dayOffset` (project day 1 + offset without stage):
  /// - Active days are `first..stage.dayTo` (no upper bound without stage).
  /// - `daily`: every active day.
  /// - `every_n_days`: on `first`, then every `interval_days` (null/<1 is
  ///   treated as 1).
  /// - `once`: on `first`.
  /// - `fixed_date`: active days whose calendar day-of-month equals
  ///   `intervalDays` (null -> 1).
  static List<TaskOccurrence> expand({
    required Task task,
    Stage? stage,
    required DateTime projectStart,
    required DateTime from,
    required DateTime to,
  }) {
    if (!task.isActive) return const [];
    final start = dateOnly(projectStart);
    final f = dateOnly(from);
    final t = dateOnly(to);
    if (t.isBefore(f)) return const [];

    final stageLo = (stage?.dayFrom ?? 1) + task.dayOffset;
    final stageHi = stage?.dayTo; // null = unbounded
    final lo = [
      dayNumber(start, f),
      stageLo,
      1,
    ].reduce((a, b) => a > b ? a : b);
    var hi = dayNumber(start, t);
    if (stageHi != null && stageHi < hi) hi = stageHi;
    if (hi < lo) return const [];

    final days = <int>[];
    switch (task.frequency) {
      case Frequency.daily:
        for (var d = lo; d <= hi; d++) {
          days.add(d);
        }
      case Frequency.everyNDays:
        final n = (task.intervalDays ?? 1) < 1 ? 1 : task.intervalDays!;
        final steps = ((lo - stageLo) + n - 1) ~/ n; // ceil
        for (var d = stageLo + steps * n; d <= hi; d += n) {
          days.add(d);
        }
      case Frequency.once:
        if (stageLo >= lo && stageLo <= hi) days.add(stageLo);
      case Frequency.fixedDate:
        final dom = task.intervalDays ?? 1;
        for (var d = lo; d <= hi; d++) {
          if (dateOfDay(start, d).day == dom) days.add(d);
        }
    }
    return [
      for (final d in days)
        TaskOccurrence(
          taskId: task.id,
          projectId: task.projectId,
          date: dateOfDay(start, d),
          window: task.window,
        ),
    ];
  }

  /// Expands every task in [tasks] against [stages] and returns occurrences
  /// sorted by date, window (morning, afternoon, all day), reminder time, then
  /// task code. A task pointing at an unknown `stage_id` yields nothing.
  static List<TaskOccurrence> expandAll({
    required List<Task> tasks,
    required List<Stage> stages,
    required DateTime projectStart,
    required DateTime from,
    required DateTime to,
  }) {
    final byId = {for (final s in stages) s.id: s};
    final taskById = {for (final t in tasks) t.id: t};
    final out = <TaskOccurrence>[];
    for (final task in tasks) {
      Stage? stage;
      if (task.stageId != null) {
        stage = byId[task.stageId];
        if (stage == null) continue;
      }
      out.addAll(
        expand(
          task: task,
          stage: stage,
          projectStart: projectStart,
          from: from,
          to: to,
        ),
      );
    }
    out.sort((a, b) {
      var c = a.date.compareTo(b.date);
      if (c != 0) return c;
      c = a.window.index.compareTo(b.window.index);
      if (c != 0) return c;
      final ta = taskById[a.taskId]!;
      final tb = taskById[b.taskId]!;
      c = (ta.reminderTime ?? '99:99').compareTo(tb.reminderTime ?? '99:99');
      if (c != 0) return c;
      return ta.taskCode.compareTo(tb.taskCode);
    });
    return out;
  }
}

/// Photo check-in cadence: every 3-7 days depending on the stage (CHK-01).
///
/// Spec §6.1 gives only the range and "5 days for Cây con". Rule used:
/// by stage code keyword (seed/germinat -> 3, seedling -> 5, vegetative or
/// growth -> 5, flower/fruit/harvest/mature -> 7); unknown codes fall back to
/// about a quarter of the stage length, clamped to 3..7.
class CheckinCadence {
  const CheckinCadence._();

  static const int minDays = 3;
  static const int maxDays = 7;

  static int intervalDays(Stage stage) {
    final c = stage.code.toLowerCase();
    // "seedling" must be tested before "seed".
    if (c.contains('seedling') || c.contains('cay_con')) return 5;
    if (c.contains('germ') || c.contains('seed') || c.contains('sprout')) {
      return 3;
    }
    if (c.contains('veget') || c.contains('growth') || c.contains('grow')) {
      return 5;
    }
    if (c.contains('flower') ||
        c.contains('fruit') ||
        c.contains('harvest') ||
        c.contains('mature')) {
      return 7;
    }
    final q = (stage.lengthDays / 4).round();
    return q < minDays ? minDays : (q > maxDays ? maxDays : q);
  }

  /// Stage to use for cadence on [date]: the stage containing it, else the
  /// last stage when past the plan, else the first when before. Null if no
  /// stages.
  static Stage? stageFor(
    List<Stage> stages,
    DateTime projectStart,
    DateTime date,
  ) {
    if (stages.isEmpty) return null;
    final hit = TaskScheduler.stageOn(stages, projectStart, date);
    if (hit != null) return hit;
    final sorted = [...stages]..sort((a, b) => a.idx.compareTo(b.idx));
    return TaskScheduler.dayNumber(projectStart, date) < sorted.first.dayFrom
        ? sorted.first
        : sorted.last;
  }

  /// Next check-in date. Never checked in => due on [projectStart] (so it is
  /// already due today for a running project). Otherwise last + the interval
  /// of the stage that applies on the last check-in day.
  static DateTime nextDue({
    required List<Stage> stages,
    required DateTime projectStart,
    DateTime? lastCheckin,
  }) {
    if (lastCheckin == null) return dateOnly(projectStart);
    final last = dateOnly(lastCheckin);
    final stage = stageFor(stages, projectStart, last);
    return addDays(last, stage == null ? maxDays : intervalDays(stage));
  }

  static bool isDue({
    required DateTime today,
    required List<Stage> stages,
    required DateTime projectStart,
    DateTime? lastCheckin,
  }) {
    final due = nextDue(
      stages: stages,
      projectStart: projectStart,
      lastCheckin: lastCheckin,
    );
    return !dateOnly(today).isBefore(due);
  }

  /// Projected check-in dates in `[from, to]`, assuming each one happens on
  /// time (used for calendar markers).
  static List<DateTime> projected({
    required List<Stage> stages,
    required DateTime projectStart,
    DateTime? lastCheckin,
    required DateTime from,
    required DateTime to,
  }) {
    final out = <DateTime>[];
    final end = dateOnly(to);
    final f = dateOnly(from);
    var cursor = nextDue(
      stages: stages,
      projectStart: projectStart,
      lastCheckin: lastCheckin,
    );
    var guard = 0;
    while (!cursor.isAfter(end) && guard++ < 1000) {
      if (!cursor.isBefore(f)) out.add(cursor);
      final stage = stageFor(stages, projectStart, cursor);
      cursor = addDays(cursor, stage == null ? maxDays : intervalDays(stage));
    }
    return out;
  }
}
