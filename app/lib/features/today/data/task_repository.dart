import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/date_only.dart';
import '../../plan/domain/enums.dart';
import '../../plan/domain/models.dart';
import '../domain/outbox_entry.dart';
import '../domain/today_builder.dart';
import '../domain/today_snapshot.dart';

/// Server access for Today / task detail. Screens never call Supabase.
abstract class TaskRepository {
  /// Active projects (own + household, enforced by RLS) with the approved
  /// plan's stages and active tasks, recent task logs and check-in dates.
  Future<TaskSnapshot> fetchSnapshot({required DateTime today});

  /// Inserts one `task_logs` row for a queued action. Idempotent: a row with
  /// the same `client_id` already on the server counts as success.
  Future<void> insertLog(OutboxEntry entry);

  /// Emits whenever `tasks` or `task_logs` change on the server.
  Stream<void> changes();
}

/// How far back logs are fetched (covers overdue lookback and snoozes).
const int kLogLookbackDays = 14;

class SupabaseTaskRepository implements TaskRepository {
  SupabaseTaskRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<TaskSnapshot> fetchSnapshot({required DateTime today}) async {
    final projectRows = await _client
        .from('projects')
        .select(
          'id, name, start_date, status, '
          'tasks(*), '
          'plans(id, project_id, version, status, source, stages(*))',
        )
        .eq('status', 'active');

    final projects = <TodayProject>[];
    for (final r in projectRows) {
      final p = _parseProject(Map<String, dynamic>.from(r));
      if (p != null) projects.add(p);
    }

    // Roll the server-side occurrence window forward (best effort).
    for (final p in projects) {
      try {
        await _client.rpc(
          'materialize_occurrences',
          params: {'p_project': p.id},
        );
      } catch (_) {}
    }

    final since = formatIsoDate(addDays(today, -kLogLookbackDays));
    final logRows = await _client
        .from('task_logs')
        .select(
          'id, task_id, project_id, occurrence_date, user_id, action, '
          'skip_reason, snooze_until, client_id, acted_at, created_at',
        )
        .gte('occurrence_date', since)
        .order('created_at', ascending: true)
        .limit(2000);
    final logs = <TaskLog>[];
    for (final r in logRows) {
      try {
        logs.add(parseTaskLog(Map<String, dynamic>.from(r)));
      } on FormatException {
        continue;
      }
    }

    return TaskSnapshot(
      projects: projects,
      logs: logs,
      lastCheckins: await _lastCheckins(),
      memberNames: await _memberNames(projects),
    );
  }

  /// Null on failure so the cached value is kept (table may not exist yet).
  Future<Map<String, DateTime>?> _lastCheckins() async {
    try {
      final rows = await _client
          .from('checkins')
          .select('project_id, created_at, status')
          .order('created_at', ascending: false)
          .limit(300);
      final out = <String, DateTime>{};
      for (final r in rows) {
        if (r['status'] == 'rejected' || r['status'] == 'retake') continue;
        final id = r['project_id'] as String;
        out.putIfAbsent(
          id,
          () => dateOnly(DateTime.parse(r['created_at'] as String).toLocal()),
        );
      }
      return out;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>?> _memberNames(List<TodayProject> projects) async {
    final ids = {
      for (final p in projects)
        for (final t in p.tasks)
          if (t.assigneeId != null) t.assigneeId!,
    };
    if (ids.isEmpty) return const {};
    try {
      final rows = await _client
          .from('member_profiles')
          .select('id, display_name')
          .inFilter('id', ids.toList());
      return {
        for (final r in rows)
          r['id'] as String: (r['display_name'] as String?) ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> insertLog(OutboxEntry e) async {
    try {
      await _client.from('task_logs').insert({
        'task_id': e.taskId,
        'occurrence_date': formatIsoDate(e.occurrenceDate),
        'action': e.action.db,
        'skip_reason': e.skipReason,
        'snooze_until': e.snoozeUntil == null
            ? null
            : formatIsoDate(e.snoozeUntil!),
        'client_id': e.clientId,
        // Client action time; the server clamps it to [now-7d, now].
        'acted_at': e.createdAt.toUtc().toIso8601String(),
      });
    } on PostgrestException catch (err) {
      // 23505 = unique_violation on client_id: already stored.
      if (err.code == '23505') return;
      rethrow;
    }
  }

  @override
  Stream<void> changes() {
    late final StreamController<void> ctrl;
    RealtimeChannel? channel;
    ctrl = StreamController<void>.broadcast(
      onListen: () {
        channel = _client.channel('today-changes');
        for (final table in const ['tasks', 'task_logs']) {
          channel!.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (_) => ctrl.add(null),
          );
        }
        channel!.subscribe();
      },
      onCancel: () async {
        final c = channel;
        if (c != null) await _client.removeChannel(c);
      },
    );
    return ctrl.stream;
  }
}

/// `task_logs` row -> [TaskLog]. `acted_on` is not a column, so it is derived
/// from `acted_at` (else `created_at`) in the device's local calendar, and
/// `acted_at` is used as the log's timestamp for ordering.
TaskLog parseTaskLog(Map<String, dynamic> row) {
  final j = Map<String, dynamic>.from(row);
  final at = (j['acted_at'] ?? j['created_at']) as String?;
  if (at != null) {
    j['created_at'] = at;
    j['acted_on'] ??= formatIsoDate(DateTime.parse(at).toLocal());
  }
  return TaskLog.fromJson(j);
}

/// Embedded `projects` row -> [TodayProject] (null when it has no approved
/// plan or cannot be parsed).
TodayProject? _parseProject(Map<String, dynamic> j) {
  try {
    final plans = <Plan>[];
    for (final p in (j['plans'] as List?) ?? const []) {
      plans.add(Plan.fromJson(Map<String, dynamic>.from(p as Map)));
    }
    final approved = plans
        .where((p) => p.status == PlanStatus.approved)
        .toList();
    if (approved.isEmpty) return null;
    final plan = approved.reduce((a, b) => a.version >= b.version ? a : b);

    final tasks = <Task>[];
    for (final t in (j['tasks'] as List?) ?? const []) {
      try {
        final task = Task.fromJson(Map<String, dynamic>.from(t as Map));
        if (task.isActive) tasks.add(task);
      } on FormatException {
        continue;
      }
    }
    return TodayProject(
      id: j['id'] as String,
      name: (j['name'] as String?) ?? '',
      startDate: parseIsoDate(j['start_date'] as String),
      stages: plan.stages,
      tasks: tasks,
    );
  } on FormatException {
    return null;
  }
}
