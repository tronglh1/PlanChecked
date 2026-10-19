import '../../../core/utils/date_only.dart';
import '../../gamification/domain/xp.dart';
import '../../plan/domain/enums.dart';
import '../../plan/domain/models.dart';
import '../../plan/domain/template_renderer.dart';
import '../domain/checkin_due.dart';
import '../domain/outbox_entry.dart';
import '../domain/today_builder.dart';
import '../domain/today_snapshot.dart';

/// One line of a task's history (server log or pending offline action).
class TaskHistoryRow {
  const TaskHistoryRow({
    required this.action,
    required this.occurrenceDate,
    required this.at,
    this.reason,
    this.pending = false,
  });

  final TaskAction action;
  final DateTime occurrenceDate;
  final DateTime at;
  final String? reason;
  final bool pending;
}

/// Immutable view-model for Today and task detail: cache + outbox merged by
/// [TodayBuilder], so it renders the same online and offline.
class TodayModel {
  TodayModel({
    required this.today,
    required this.lang,
    this.userId,
    this.loaded = false,
    this.syncing = false,
    this.offline = false,
    this.snapshot = TaskSnapshot.empty,
    this.outbox = const [],
    TemplateRenderer? renderer,
  }) : renderer = renderer ?? TemplateRenderer(const []),
       view = TodayBuilder.build(
         today: today,
         projects: snapshot.projects,
         logs: snapshot.logs,
         outbox: outbox,
         assigneeId: userId,
       ) {
    checkins = checkinsDue(
      today: today,
      projects: snapshot.projects,
      lastCheckins: snapshot.lastCheckins ?? const {},
    );
  }

  final DateTime today;
  final String lang;
  final String? userId;

  /// The cache has been read at least once.
  final bool loaded;
  final bool syncing;

  /// Last server contact failed (or Supabase is not configured).
  final bool offline;
  final TaskSnapshot snapshot;
  final List<OutboxEntry> outbox;
  final TemplateRenderer renderer;
  final TodayView view;
  late final List<CheckinDue> checkins;

  bool get hasData => snapshot.projects.isNotEmpty;
  int get pendingCount => outbox.length;

  TodayModel copyWith({
    DateTime? today,
    bool? loaded,
    bool? syncing,
    bool? offline,
    TaskSnapshot? snapshot,
    List<OutboxEntry>? outbox,
    TemplateRenderer? renderer,
  }) => TodayModel(
    today: today ?? this.today,
    lang: lang,
    userId: userId,
    loaded: loaded ?? this.loaded,
    syncing: syncing ?? this.syncing,
    offline: offline ?? this.offline,
    snapshot: snapshot ?? this.snapshot,
    outbox: outbox ?? this.outbox,
    renderer: renderer ?? this.renderer,
  );

  String taskName(Task t) => renderer.taskName(t.taskCode, lang: lang);

  /// Ordinary XP already earned today (done on time, acted today), capped.
  int get earnedXpToday {
    final n = view.items.where((i) => i.doneOnTime && i.actedOn == today);
    return XpPreview.cappedToday(n.length * XpRules.taskDone);
  }

  Task? findTask(String id) {
    for (final p in snapshot.projects) {
      for (final t in p.tasks) {
        if (t.id == id) return t;
      }
    }
    return null;
  }

  TodayProject? projectOfTask(String taskId) {
    for (final p in snapshot.projects) {
      if (p.tasks.any((t) => t.id == taskId)) return p;
    }
    return null;
  }

  /// The stage the project is in today (for the detail eyebrow).
  Stage? stageOfProject(TodayProject p) {
    for (final s in p.stages) {
      final day = daysBetween(p.startDate, today) + 1;
      if (s.containsDay(day)) return s;
    }
    return null;
  }

  /// Today's row for [taskId] (any state), earliest occurrence first.
  TodayItem? itemFor(String taskId) {
    for (final i in view.items) {
      if (i.task.id == taskId) return i;
    }
    return null;
  }

  List<TaskHistoryRow> historyOf(String taskId) {
    final syncedIds = {
      for (final l in snapshot.logs)
        if (l.clientId != null) l.clientId!,
    };
    final rows = <TaskHistoryRow>[
      for (final l in snapshot.logs)
        if (l.taskId == taskId)
          TaskHistoryRow(
            action: l.action,
            occurrenceDate: l.occurrenceDate,
            at: l.createdAt,
            reason: l.skipReason,
          ),
      for (final o in OutboxEntry.dedupe(outbox))
        if (o.taskId == taskId && !syncedIds.contains(o.clientId))
          TaskHistoryRow(
            action: o.action,
            occurrenceDate: o.occurrenceDate,
            at: o.createdAt,
            reason: o.skipReason,
            pending: true,
          ),
    ]..sort((a, b) => b.at.compareTo(a.at));
    return rows;
  }
}
