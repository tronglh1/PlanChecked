/// Plan / Stage / Task models (docs/spec-mvp.md §4.2). Pure Dart.
///
/// JSON keys are the DB column names (snake_case) so rows from Supabase and
/// drift can be passed straight in.
library;

import '../../../core/utils/date_only.dart';
import 'enums.dart';

class Plan {
  const Plan({
    required this.id,
    required this.projectId,
    required this.version,
    required this.source,
    this.confidence,
    this.status = PlanStatus.draft,
    this.approvedAt,
    this.stages = const [],
  });

  final String id;
  final String projectId;
  final int version;
  final PlanSource source;

  /// 0..1 (mockup shows "86%"). Null when not provided (template plans).
  final double? confidence;
  final PlanStatus status;
  final DateTime? approvedAt;

  /// Optional embedded stages, ordered by [Stage.idx].
  final List<Stage> stages;

  factory Plan.fromJson(Map<String, dynamic> j) {
    final rawStages = j['stages'] as List?;
    final stages = [
      for (final s in rawStages ?? const [])
        Stage.fromJson(Map<String, dynamic>.from(s as Map)),
    ]..sort((a, b) => a.idx.compareTo(b.idx));
    return Plan(
      id: j['id'] as String,
      projectId: j['project_id'] as String,
      version: (j['version'] as num).toInt(),
      source: PlanSource.fromDb(j['source']),
      confidence: (j['confidence'] as num?)?.toDouble(),
      status: j['status'] == null
          ? PlanStatus.draft
          : PlanStatus.fromDb(j['status']),
      approvedAt: j['approved_at'] == null
          ? null
          : DateTime.parse(j['approved_at'] as String),
      stages: stages,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'version': version,
    'source': source.db,
    'confidence': confidence,
    'status': status.db,
    'approved_at': approvedAt?.toUtc().toIso8601String(),
    if (stages.isNotEmpty) 'stages': [for (final s in stages) s.toJson()],
  };
}

/// A growth stage. [dayFrom]..[dayTo] are 1-based project day numbers,
/// inclusive on both ends (day 1 = project `start_date`).
class Stage {
  const Stage({
    required this.id,
    required this.planId,
    required this.idx,
    required this.code,
    required this.name,
    this.nameEn,
    required this.dayFrom,
    required this.dayTo,
    this.milestoneCode,
  });

  final String id;
  final String planId;
  final int idx;
  final String code;
  final String name;

  /// `stages.name_en`; null when the plan has none.
  final String? nameEn;
  final int dayFrom;
  final int dayTo;
  final String? milestoneCode;

  /// Name for [lang] (`vi` | `en`), falling back to the other language, then
  /// to the readable [code].
  String label(String lang) {
    final en = (nameEn ?? '').trim();
    final vi = name.trim();
    final first = lang == 'en' ? en : vi;
    final second = lang == 'en' ? vi : en;
    if (first.isNotEmpty) return first;
    if (second.isNotEmpty) return second;
    return code;
  }

  int get lengthDays => dayTo - dayFrom + 1;

  bool containsDay(int day) => day >= dayFrom && day <= dayTo;

  factory Stage.fromJson(Map<String, dynamic> j) => Stage(
    id: j['id'] as String,
    planId: j['plan_id'] as String,
    idx: (j['idx'] as num).toInt(),
    code: j['code'] as String,
    name: (j['name'] as String?) ?? '',
    nameEn: j['name_en'] as String?,
    dayFrom: (j['day_from'] as num).toInt(),
    dayTo: (j['day_to'] as num).toInt(),
    milestoneCode: j['milestone_code'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'plan_id': planId,
    'idx': idx,
    'code': code,
    'name': name,
    'name_en': nameEn,
    'day_from': dayFrom,
    'day_to': dayTo,
    'milestone_code': milestoneCode,
  };
}

class Task {
  const Task({
    required this.id,
    required this.projectId,
    this.stageId,
    required this.taskCode,
    required this.window,
    required this.frequency,
    this.intervalDays,
    this.dayOffset = 0,
    this.reminderTime,
    this.assigneeId,
    this.assignmentMode = AssignmentMode.once,
    this.rotationOrder,
    this.source = TaskSource.template,
    this.status = 'active',
    this.xp = 10,
  });

  final String id;
  final String projectId;

  /// Null = not tied to a stage (applies from project day 1, unbounded).
  final String? stageId;
  final String taskCode;
  final TaskWindow window;
  final Frequency frequency;

  /// every_n_days: N. fixed_date: the day of the month (1-31), same as SQL
  /// `task_due_on`. Unused otherwise.
  final int? intervalDays;

  /// Days after the stage's first day that the task starts (`tasks.day_offset`,
  /// written by `create_draft_plan`). Mirrors SQL `task_due_on`.
  final int dayOffset;

  /// "HH:mm" (24h), e.g. "16:30".
  final String? reminderTime;
  final String? assigneeId;
  final AssignmentMode assignmentMode;
  final int? rotationOrder;
  final TaskSource source;

  /// Free string; only `active` is scheduled. Spec §4.2 does not list values.
  final String status;
  final int xp;

  bool get isActive => status == 'active';

  factory Task.fromJson(Map<String, dynamic> j) => Task(
    id: j['id'] as String,
    projectId: j['project_id'] as String,
    stageId: j['stage_id'] as String?,
    taskCode: j['task_code'] as String,
    window: TaskWindow.fromDb(j['window']),
    frequency: Frequency.fromDb(j['frequency']),
    intervalDays: (j['interval_days'] as num?)?.toInt(),
    dayOffset: (j['day_offset'] as num?)?.toInt() ?? 0,
    reminderTime: (j['reminder_time'] as String?)?.substring(
      0,
      (j['reminder_time'] as String).length < 5
          ? (j['reminder_time'] as String).length
          : 5,
    ), // Postgres time -> HH:mm
    assigneeId: j['assignee_id'] as String?,
    assignmentMode: j['assignment_mode'] == null
        ? AssignmentMode.once
        : AssignmentMode.fromDb(j['assignment_mode']),
    rotationOrder: j['rotation_order'] is num
        ? (j['rotation_order'] as num).toInt()
        : null, // DB column is uuid[]
    source: j['source'] == null
        ? TaskSource.template
        : TaskSource.fromDb(j['source']),
    status: (j['status'] as String?) ?? 'active',
    xp: (j['xp'] as num?)?.toInt() ?? 10,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'stage_id': stageId,
    'task_code': taskCode,
    'window': window.db,
    'frequency': frequency.db,
    'interval_days': intervalDays,
    'day_offset': dayOffset,
    'reminder_time': reminderTime,
    'assignee_id': assigneeId,
    'assignment_mode': assignmentMode.db,
    'rotation_order': rotationOrder,
    'source': source.db,
    'status': status,
    'xp': xp,
  };
}

/// One dated instance of a [Task]. [date] is date-only (UTC midnight).
class TaskOccurrence {
  const TaskOccurrence({
    required this.taskId,
    required this.projectId,
    required this.date,
    required this.window,
  });

  final String taskId;
  final String projectId;
  final DateTime date;
  final TaskWindow window;

  /// Stable key shared with task_logs / outbox: `<taskId>|yyyy-MM-dd`.
  String get key => occurrenceKey(taskId, date);

  @override
  bool operator ==(Object other) =>
      other is TaskOccurrence && other.key == key && other.window == window;

  @override
  int get hashCode => Object.hash(key, window);

  @override
  String toString() => 'TaskOccurrence($key, ${window.db})';
}

String occurrenceKey(String taskId, DateTime date) =>
    '$taskId|${formatIsoDate(date)}';
