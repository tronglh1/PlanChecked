/// Plan + its tasks, and the result of the `ai-plan` Edge Function. Pure Dart.
library;

import 'enums.dart';
import 'models.dart';

/// A plan with embedded stages and the active tasks of its project.
class PlanBundle {
  const PlanBundle({
    required this.plan,
    this.tasks = const [],
    this.sources = const [],
  });

  final Plan plan;
  final List<Task> tasks;

  /// Source labels (e.g. plant DB, documents). Empty when not provided.
  final List<String> sources;

  List<Stage> get stages => plan.stages;

  bool get isApproved => plan.status == PlanStatus.approved;

  int get totalDays => stages.isEmpty
      ? 0
      : stages.map((s) => s.dayTo).reduce((a, b) => a > b ? a : b);

  List<Task> tasksOf(Stage s) =>
      tasks.where((t) => t.stageId == s.id).toList();

  PlanBundle copyWith({Plan? plan, List<Task>? tasks}) => PlanBundle(
    plan: plan ?? this.plan,
    tasks: tasks ?? this.tasks,
    sources: sources,
  );
}

enum FallbackReason {
  none,
  quotaExceeded,
  aiFailure;

  static FallbackReason fromWire(Object? v) => switch (v) {
    'quota_exceeded' || 'quota' || 'limit_reached' => quotaExceeded,
    'ai_failure' || 'ai_error' || 'error' || 'timeout' => aiFailure,
    _ => none,
  };
}

/// Response of `ai-plan`. [planId] is null only when the server could not
/// even produce a fallback plan.
class AiPlanResult {
  const AiPlanResult({
    this.planId,
    this.source = PlanSource.ai,
    this.fallbackReason = FallbackReason.none,
  });

  final String? planId;
  final PlanSource source;
  final FallbackReason fallbackReason;

  bool get isFallback =>
      source == PlanSource.fallback || fallbackReason != FallbackReason.none;

  factory AiPlanResult.fromJson(Map<String, dynamic> j, {int? status}) {
    var reason = FallbackReason.fromWire(j['fallback_reason'] ?? j['error']);
    if (status == 429 && reason == FallbackReason.none) {
      reason = FallbackReason.quotaExceeded;
    }
    PlanSource src;
    try {
      src = j['source'] == null
          ? (reason == FallbackReason.none
                ? PlanSource.ai
                : PlanSource.fallback)
          : PlanSource.fromDb(j['source']);
    } on FormatException {
      src = PlanSource.fallback;
    }
    return AiPlanResult(
      planId: (j['plan_id'] ?? j['planId'])?.toString(),
      source: src,
      fallbackReason: reason,
    );
  }
}

/// Thrown by repositories when the AI call failed and gave no plan.
class PlanGenerationException implements Exception {
  const PlanGenerationException(this.message);
  final String message;
  @override
  String toString() => 'PlanGenerationException: $message';
}

/// Input for adding a manual task (PLN-05).
class NewTask {
  const NewTask({
    required this.projectId,
    this.stageId,
    required this.taskCode,
    this.window = TaskWindow.morning,
    this.frequency = Frequency.everyNDays,
    this.intervalDays,
    this.reminderTime,
  });

  final String projectId;
  final String? stageId;
  final String taskCode;
  final TaskWindow window;
  final Frequency frequency;
  final int? intervalDays;
  final String? reminderTime;
}

/// A row of `task_codes` usable when adding a manual task.
class TaskCodeInfo {
  const TaskCodeInfo({
    required this.code,
    this.defaultWindow = TaskWindow.morning,
    this.defaultFrequency = Frequency.everyNDays,
  });

  final String code;
  final TaskWindow defaultWindow;
  final Frequency defaultFrequency;
}
