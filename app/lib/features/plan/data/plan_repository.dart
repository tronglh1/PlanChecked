import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/plan_bundle.dart';

abstract class PlanRepository {
  /// Calls Edge Function `ai-plan` for [projectId] (docs/backend.md). Quota
  /// exceeded and AI failure come back as an [AiPlanResult] whose
  /// `source = fallback` plan is already stored as a draft. [plantGroup]
  /// (`rau_qua` | `cay_canh`) is only for plants not in the catalogue.
  /// Throws [PlanGenerationException] when no plan could be produced at all.
  Future<AiPlanResult> generatePlan(
    String projectId, {
    String? plantGroup,
    bool regenerate = false,
  });

  /// The approved plan, else the newest draft; null when none. Tasks are the
  /// project's active tasks that belong to this plan (or to no stage).
  Future<PlanBundle?> loadPlan(String projectId);

  /// Approves a draft ("Bắt đầu trồng") and supersedes older approved plans.
  Future<void> approvePlan(String planId);

  Future<List<TaskCodeInfo>> fetchTaskCodes();

  Future<Task> addTask(NewTask input);

  /// Persists frequency / interval / window / reminder changes (PLN-05).
  Future<Task> updateTask(Task task);

  /// Soft delete (`status = 'archived'`) so task_logs keep their reference.
  Future<void> deleteTask(String taskId);
}

class SupabasePlanRepository implements PlanRepository {
  SupabasePlanRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<AiPlanResult> generatePlan(
    String projectId, {
    String? plantGroup,
    bool regenerate = false,
  }) async {
    try {
      final res = await _client.functions.invoke(
        'ai-plan',
        body: {
          'project_id': projectId,
          if (regenerate) 'regenerate': true,
          'plant_group': ?plantGroup,
        },
      );
      final data = res.data;
      if (data is Map) {
        return AiPlanResult.fromJson(
          Map<String, dynamic>.from(data),
          status: res.status,
        );
      }
      throw const PlanGenerationException('Unexpected ai-plan response');
    } on FunctionException catch (e) {
      final d = e.details;
      if (d is Map) {
        final r = AiPlanResult.fromJson(
          Map<String, dynamic>.from(d),
          status: e.status,
        );
        if (r.planId != null || r.fallbackReason != FallbackReason.none) {
          return r;
        }
      }
      if (e.status == 429) {
        return const AiPlanResult(
          source: PlanSource.fallback,
          fallbackReason: FallbackReason.quotaExceeded,
        );
      }
      throw PlanGenerationException('ai-plan failed (${e.status})');
    }
  }

  @override
  Future<PlanBundle?> loadPlan(String projectId) async {
    final rows = await _client
        .from('plans')
        .select('*, stages(*)')
        .eq('project_id', projectId)
        .neq('status', PlanStatus.superseded.db)
        .order('version', ascending: false)
        .limit(5);
    if (rows.isEmpty) return null;
    Map<String, dynamic> pick = rows.first;
    for (final r in rows) {
      if (r['status'] == PlanStatus.approved.db) {
        pick = r;
        break;
      }
    }
    final plan = Plan.fromJson(Map<String, dynamic>.from(pick));
    final taskRows = await _client
        .from('tasks')
        .select()
        .eq('project_id', projectId)
        .eq('status', 'active');
    final stageIds = {for (final s in plan.stages) s.id};
    final tasks = [
      for (final r in taskRows)
        if (r['stage_id'] == null || stageIds.contains(r['stage_id']))
          Task.fromJson(Map<String, dynamic>.from(r)),
    ];
    // `plans` has no `sources` column yet; sources stay empty.
    return PlanBundle(plan: plan, tasks: tasks, sources: const []);
  }

  @override
  Future<void> approvePlan(String planId) async {
    // Marks approved, supersedes the old plan, materializes 14 days.
    await _client.rpc('approve_plan', params: {'p_plan': planId});
  }

  @override
  Future<List<TaskCodeInfo>> fetchTaskCodes() async {
    final rows = await _client
        .from('task_codes')
        .select('code, default_window, default_frequency')
        .order('code');
    TaskWindow w(Object? v) {
      try {
        return TaskWindow.fromDb(v);
      } on FormatException {
        return TaskWindow.morning;
      }
    }

    Frequency f(Object? v) {
      try {
        return Frequency.fromDb(v);
      } on FormatException {
        return Frequency.everyNDays;
      }
    }

    return [
      for (final r in rows)
        TaskCodeInfo(
          code: r['code'] as String,
          defaultWindow: w(r['default_window']),
          defaultFrequency: f(r['default_frequency']),
        ),
    ];
  }

  @override
  Future<Task> addTask(NewTask input) async {
    final row = await _client
        .from('tasks')
        .insert({
          'project_id': input.projectId,
          'stage_id': input.stageId,
          'task_code': input.taskCode,
          'window': input.window.db,
          'frequency': input.frequency.db,
          'interval_days': input.intervalDays,
          'reminder_time': input.reminderTime,
          'assignment_mode': AssignmentMode.once.db,
          'source': TaskSource.manual.db,
          'status': 'active',
        })
        .select()
        .single();
    return Task.fromJson(row);
  }

  @override
  Future<Task> updateTask(Task task) async {
    final row = await _client
        .from('tasks')
        .update({
          'window': task.window.db,
          'frequency': task.frequency.db,
          'interval_days': task.intervalDays,
          'reminder_time': task.reminderTime,
        })
        .eq('id', task.id)
        .select()
        .single();
    return Task.fromJson(row);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').update({'status': 'archived'}).eq('id', taskId);
  }
}
