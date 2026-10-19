/// Builds the "Hôm nay" view from plans, server task logs and pending offline
/// actions. Pure Dart, timezone-free.
library;

import '../../../core/utils/date_only.dart';
import '../../plan/domain/enums.dart';
import '../../plan/domain/models.dart';
import '../../plan/domain/task_scheduler.dart';
import 'outbox_entry.dart';

/// One project with the approved plan's stages and tasks.
class TodayProject {
  const TodayProject({
    required this.id,
    required this.name,
    required this.startDate,
    required this.stages,
    required this.tasks,
  });

  final String id;
  final String name;
  final DateTime startDate;
  final List<Stage> stages;
  final List<Task> tasks;
}

enum TodayState { pending, overdue, done, skipped, snoozed }

class TodayItem {
  const TodayItem({
    required this.occurrence,
    required this.task,
    required this.projectName,
    required this.state,
    required this.dueDate,
    this.pendingSync = false,
    this.actedOn,
    this.skipReason,
  });

  final TaskOccurrence occurrence;
  final Task task;
  final String projectName;
  final TodayState state;

  /// Effective due date: the occurrence date, or the snooze target if the user
  /// postponed it. Drives overdue detection and on-time XP.
  final DateTime dueDate;

  /// The latest action is still in the offline outbox.
  final bool pendingSync;

  /// Date the done/skip/snooze action happened.
  final DateTime? actedOn;
  final String? skipReason;

  String get projectId => occurrence.projectId;
  TaskWindow get window => occurrence.window;
  bool get isDone => state == TodayState.done;
  bool get isOverdue => state == TodayState.overdue;

  /// Done on or before [dueDate].
  bool get doneOnTime =>
      isDone && actedOn != null && !actedOn!.isAfter(dueDate);
}

/// A group of rows: either the overdue block, a window, or a project.
class TodayGroup {
  const TodayGroup({
    this.window,
    this.projectId,
    this.projectName,
    this.overdue = false,
    required this.items,
  });

  final TaskWindow? window;
  final String? projectId;
  final String? projectName;
  final bool overdue;
  final List<TodayItem> items;
}

class TodayView {
  const TodayView({
    required this.today,
    required this.items,
    required this.snoozed,
  });

  final DateTime today;

  /// Visible rows: pending, overdue, done and skipped (snoozed-away rows are
  /// in [snoozed]). Sorted overdue first, then window, reminder time, project.
  final List<TodayItem> items;

  /// Rows postponed to a later date; hidden from today.
  final List<TodayItem> snoozed;

  List<TodayItem> get overdue => [
    for (final i in items)
      if (i.isOverdue) i,
  ];

  int get doneCount => items.where((i) => i.isDone).length;

  /// Skipped rows are excluded from the denominator.
  int get totalCount =>
      items.where((i) => i.state != TodayState.skipped).length;

  double get progress => totalCount == 0 ? 0 : doneCount / totalCount;

  /// Groups by window (morning, afternoon, all day). Overdue rows are pulled
  /// into a leading overdue group when [separateOverdue] is true.
  List<TodayGroup> byWindow({bool separateOverdue = true}) {
    final groups = <TodayGroup>[];
    final base = separateOverdue
        ? items.where((i) => !i.isOverdue).toList()
        : items;
    if (separateOverdue && overdue.isNotEmpty) {
      groups.add(TodayGroup(overdue: true, items: overdue));
    }
    for (final w in TaskWindow.values) {
      final rows = base.where((i) => i.window == w).toList();
      if (rows.isNotEmpty) groups.add(TodayGroup(window: w, items: rows));
    }
    return groups;
  }

  /// Groups by project, in order of first appearance in [items].
  List<TodayGroup> byProject({bool separateOverdue = true}) {
    final groups = <TodayGroup>[];
    final base = separateOverdue
        ? items.where((i) => !i.isOverdue).toList()
        : items;
    if (separateOverdue && overdue.isNotEmpty) {
      groups.add(TodayGroup(overdue: true, items: overdue));
    }
    final order = <String>[];
    final byId = <String, List<TodayItem>>{};
    for (final i in base) {
      (byId[i.projectId] ??= []).add(i);
      if (!order.contains(i.projectId)) order.add(i.projectId);
    }
    for (final id in order) {
      groups.add(
        TodayGroup(
          projectId: id,
          projectName: byId[id]!.first.projectName,
          items: byId[id]!,
        ),
      );
    }
    return groups;
  }
}

class _Event {
  _Event({
    required this.action,
    required this.createdAt,
    required this.actedOn,
    required this.pending,
    required this.seq,
    this.snoozeUntil,
    this.skipReason,
  });
  final TaskAction action;
  final DateTime createdAt;
  final DateTime actedOn;
  final bool pending;
  final int seq;
  final DateTime? snoozeUntil;
  final String? skipReason;
}

class TodayBuilder {
  const TodayBuilder._();

  /// Occurrences older than this many days are no longer shown as overdue.
  static const int defaultOverdueLookbackDays = 3;

  /// Builds today's view.
  ///
  /// - Server [logs] and pending [outbox] entries are merged per occurrence;
  ///   the latest wins (by `createdAt`; on a tie the outbox wins, then the
  ///   later one in the list). An outbox entry whose `clientId` already
  ///   appears in [logs] is ignored (already synced); duplicate outbox
  ///   `clientId`s are collapsed.
  /// - Unresolved occurrences before [today] (within [overdueLookbackDays])
  ///   are `overdue`.
  /// - A snoozed occurrence is hidden while `snoozeUntil > today`; from
  ///   `snoozeUntil` on it is due again (overdue only if `snoozeUntil <
  ///   today`). A snooze without a date means "tomorrow" (occurrence + 1).
  /// - Done/skipped rows stay visible only if the occurrence is today or the
  ///   action happened today.
  /// - [assigneeId] (optional) keeps tasks assigned to that user or to nobody.
  static TodayView build({
    required DateTime today,
    required List<TodayProject> projects,
    List<TaskLog> logs = const [],
    List<OutboxEntry> outbox = const [],
    int overdueLookbackDays = defaultOverdueLookbackDays,
    String? assigneeId,
  }) {
    final day = dateOnly(today);
    final from = addDays(day, -overdueLookbackDays);

    // Merge actions per occurrence key.
    final syncedClientIds = {
      for (final l in logs)
        if (l.clientId != null) l.clientId!,
    };
    final events = <String, List<_Event>>{};
    var seq = 0;
    for (final l in logs) {
      (events[l.occurrenceKey] ??= []).add(
        _Event(
          action: l.action,
          createdAt: l.createdAt,
          actedOn: l.actedOn,
          pending: false,
          seq: seq++,
          snoozeUntil: l.snoozeUntil,
          skipReason: l.skipReason,
        ),
      );
    }
    for (final o in OutboxEntry.dedupe(outbox)) {
      if (syncedClientIds.contains(o.clientId)) continue;
      (events[o.occurrenceKey] ??= []).add(
        _Event(
          action: o.action,
          createdAt: o.createdAt,
          actedOn: o.actedOn,
          pending: true,
          seq: seq++,
          snoozeUntil: o.snoozeUntil,
          skipReason: o.skipReason,
        ),
      );
    }
    _Event? latest(String key) {
      final list = events[key];
      if (list == null || list.isEmpty) return null;
      return list.reduce((a, b) {
        final c = a.createdAt.compareTo(b.createdAt);
        if (c != 0) return c > 0 ? a : b;
        if (a.pending != b.pending) return a.pending ? a : b;
        return a.seq >= b.seq ? a : b;
      });
    }

    final visible = <TodayItem>[];
    final snoozed = <TodayItem>[];

    for (final p in projects) {
      final occs = TaskScheduler.expandAll(
        tasks: p.tasks,
        stages: p.stages,
        projectStart: p.startDate,
        from: from,
        to: day,
      );
      final taskById = {for (final t in p.tasks) t.id: t};
      for (final occ in occs) {
        final task = taskById[occ.taskId]!;
        if (assigneeId != null &&
            task.assigneeId != null &&
            task.assigneeId != assigneeId) {
          continue;
        }
        final ev = latest(occ.key);
        final item = _classify(occ, task, p.name, ev, events[occ.key], day);
        if (item == null) continue;
        (item.state == TodayState.snoozed ? snoozed : visible).add(item);
      }
    }

    visible.sort((a, b) {
      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
      var c = a.window.index.compareTo(b.window.index);
      if (c != 0) return c;
      c = (a.task.reminderTime ?? '99:99').compareTo(
        b.task.reminderTime ?? '99:99',
      );
      if (c != 0) return c;
      c = a.projectName.compareTo(b.projectName);
      if (c != 0) return c;
      return a.task.taskCode.compareTo(b.task.taskCode);
    });
    return TodayView(today: day, items: visible, snoozed: snoozed);
  }

  static TodayItem? _classify(
    TaskOccurrence occ,
    Task task,
    String projectName,
    _Event? ev,
    List<_Event>? all,
    DateTime today,
  ) {
    TodayItem make(TodayState s, DateTime due) => TodayItem(
      occurrence: occ,
      task: task,
      projectName: projectName,
      state: s,
      dueDate: due,
      pendingSync: ev?.pending ?? false,
      actedOn: ev?.actedOn,
      skipReason: ev?.skipReason,
    );

    if (ev == null) {
      return make(
        occ.date.isBefore(today) ? TodayState.overdue : TodayState.pending,
        occ.date,
      );
    }
    switch (ev.action) {
      case TaskAction.done:
      case TaskAction.skip:
        final shown = occ.date == today || ev.actedOn == today;
        if (!shown) return null;
        return make(
          ev.action == TaskAction.done ? TodayState.done : TodayState.skipped,
          _dueBefore(all, ev, occ.date),
        );
      case TaskAction.snooze:
        final until = ev.snoozeUntil ?? addDays(occ.date, 1);
        if (until.isAfter(today)) return make(TodayState.snoozed, until);
        return make(
          until.isBefore(today) ? TodayState.overdue : TodayState.pending,
          until,
        );
    }
  }
}

/// Due date in force when [ev] happened: the target of the latest snooze
/// recorded before it, else the occurrence date.
DateTime _dueBefore(List<_Event>? all, _Event ev, DateTime occDate) {
  _Event? snooze;
  for (final e in all ?? const <_Event>[]) {
    if (identical(e, ev) || e.action != TaskAction.snooze) continue;
    if (e.createdAt.isAfter(ev.createdAt)) continue;
    if (snooze == null || e.createdAt.isAfter(snooze.createdAt)) snooze = e;
  }
  if (snooze == null) return occDate;
  return snooze.snoozeUntil ?? addDays(occDate, 1);
}
