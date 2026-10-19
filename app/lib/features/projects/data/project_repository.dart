import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/date_only.dart';
import '../../plan/domain/enums.dart';
import '../../plan/domain/models.dart';
import '../../plan/domain/task_scheduler.dart';
import '../../plants/domain/plant.dart';
import '../domain/project.dart';
import '../domain/project_progress.dart';

abstract class ProjectRepository {
  /// Creates the project (PRJ-02/03) owned by the current user, shared with
  /// their household when they have one.
  Future<Project> createProject(NewProject input);

  /// My projects and my household's, newest first, with current stage,
  /// today's task count and latest photo (PRJ-01, PRJ-04).
  Future<List<ProjectSummary>> listProjects(DateTime today);

  Future<ProjectDetail> getProject(String id);

  /// Done / skip / snooze log of the project's tasks, newest first (TSK-06).
  Future<List<TaskHistoryEntry>> taskHistory(String projectId, {int limit = 50});

  /// Uploads an optional cover photo, returns its storage path.
  Future<String> uploadCover(Uint8List bytes, {String ext = 'jpg'});
}

/// Raw rows needed to build the project list; separated from Supabase so the
/// assembly rule is unit-testable.
List<ProjectSummary> buildProjectSummaries({
  required List<Map<String, dynamic>> projectRows,
  required List<Map<String, dynamic>> planRows,
  required List<Map<String, dynamic>> taskRows,
  required List<Map<String, dynamic>> checkinRows,
  required DateTime today,
}) {
  final plansByProject = <String, List<Plan>>{};
  for (final r in planRows) {
    final p = Plan.fromJson(Map<String, dynamic>.from(r));
    if (p.status == PlanStatus.superseded) continue;
    plansByProject.putIfAbsent(p.projectId, () => []).add(p);
  }
  final tasksByProject = <String, List<Task>>{};
  for (final r in taskRows) {
    final t = Task.fromJson(Map<String, dynamic>.from(r));
    tasksByProject.putIfAbsent(t.projectId, () => []).add(t);
  }
  final photoByProject = <String, ({String path, DateTime at})>{};
  for (final r in checkinRows) {
    final pid = r['project_id']?.toString();
    final path = firstShotPath(r['shots']);
    if (pid == null || path == null) continue;
    final at = DateTime.tryParse('${r['created_at']}') ?? DateTime(1970);
    final prev = photoByProject[pid];
    if (prev == null || at.isAfter(prev.at)) {
      photoByProject[pid] = (path: path, at: at);
    }
  }

  final out = <ProjectSummary>[];
  for (final row in projectRows) {
    final project = Project.fromJson(row);
    final plant = row['plants'] is Map
        ? Map<String, dynamic>.from(row['plants'] as Map)
        : null;
    final plans = plansByProject[project.id] ?? const [];
    Plan? plan;
    for (final p in plans) {
      if (p.status == PlanStatus.approved &&
          (plan == null || p.version > plan.version)) {
        plan = p;
      }
    }
    if (plan == null) {
      for (final p in plans) {
        if (plan == null || p.version > plan.version) plan = p;
      }
    }
    final progress = plan == null
        ? null
        : ProjectProgress.compute(
            stages: plan.stages,
            projectStart: project.startDate,
            today: today,
          );
    var todayCount = 0;
    if (plan != null && plan.status == PlanStatus.approved) {
      final stageIds = {for (final s in plan.stages) s.id};
      final tasks = (tasksByProject[project.id] ?? const [])
          .where((t) => t.stageId == null || stageIds.contains(t.stageId))
          .toList();
      todayCount = TaskScheduler.expandAll(
        tasks: tasks,
        stages: plan.stages,
        projectStart: project.startDate,
        from: today,
        to: today,
      ).length;
    }
    final photo = photoByProject[project.id];
    out.add(
      ProjectSummary(
        project: project,
        plantNameVi: plant?['name_vi'] as String?,
        plantNameEn: plant?['name_en'] as String?,
        group: PlantGroup.fromCode(plant?['group'] as String?),
        progress: progress,
        planStatus: plan?.status.db,
        todayTaskCount: todayCount,
        latestPhotoPath: photo?.path,
        latestPhotoAt: photo?.at,
      ),
    );
  }
  return out;
}

/// `checkins.shots` is a list of `{type, path}` (spec §4.2).
String? firstShotPath(Object? shots) {
  if (shots is List) {
    for (final s in shots) {
      if (s is Map && s['path'] is String) return s['path'] as String;
      if (s is String) return s;
    }
  }
  return null;
}

class SupabaseProjectRepository implements ProjectRepository {
  SupabaseProjectRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Not signed in');
    return id;
  }

  Future<String?> _householdId() async {
    final rows = await _client
        .from('household_members')
        .select('household_id')
        .eq('user_id', _uid)
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first['household_id'] as String?;
  }

  @override
  Future<Project> createProject(NewProject input) async {
    final row = await _client
        .from('projects')
        .insert({
          'household_id': await _householdId(),
          'owner_id': _uid,
          'plant_id': input.plantId,
          'name': input.name,
          'start_date': formatIsoDate(input.startDate),
          'start_stage': input.startStage.db,
          'pot_count': input.potCount,
          'space': input.space.db,
          'sun_level': input.sunLevel.db,
          'pot_type': input.potType,
          'watering': input.watering.db,
          'cover_path': input.coverPath,
          'status': ProjectStatus.active.db,
        })
        .select()
        .single();
    return Project.fromJson(row);
  }

  @override
  Future<List<ProjectSummary>> listProjects(DateTime today) async {
    final projects = await _client
        .from('projects')
        .select('*, plants(name_vi, name_en, group)')
        .order('created_at', ascending: false);
    if (projects.isEmpty) return const [];
    final ids = [for (final p in projects) p['id'].toString()];
    final plans = await _client
        .from('plans')
        .select('*, stages(*)')
        .inFilter('project_id', ids);
    final tasks = await _client
        .from('tasks')
        .select()
        .inFilter('project_id', ids)
        .eq('status', 'active');
    final checkins = await _client
        .from('checkins')
        .select('project_id, shots, created_at')
        .inFilter('project_id', ids)
        .order('created_at', ascending: false);
    return buildProjectSummaries(
      projectRows: List<Map<String, dynamic>>.from(projects),
      planRows: List<Map<String, dynamic>>.from(plans),
      taskRows: List<Map<String, dynamic>>.from(tasks),
      checkinRows: List<Map<String, dynamic>>.from(checkins),
      today: today,
    );
  }

  @override
  Future<ProjectDetail> getProject(String id) async {
    final row = await _client
        .from('projects')
        .select('*, plants(name_vi, name_en, group)')
        .eq('id', id)
        .single();
    final project = Project.fromJson(row);
    final plant = row['plants'] is Map
        ? Map<String, dynamic>.from(row['plants'] as Map)
        : null;
    final checkins = await _client
        .from('checkins')
        .select('shots, created_at')
        .eq('project_id', id)
        .order('created_at', ascending: false);
    final photos = <String>[
      for (final c in checkins)
        ?firstShotPath(c['shots']),
    ];
    final members = <String, String>{};
    try {
      final users = await _client.from('users').select('id, display_name');
      for (final u in users) {
        members[u['id'].toString()] = (u['display_name'] as String?) ?? '';
      }
    } catch (_) {
      // Names are decoration; the screen works without them.
    }
    return ProjectDetail(
      project: project,
      plantNameVi: plant?['name_vi'] as String?,
      plantNameEn: plant?['name_en'] as String?,
      group: PlantGroup.fromCode(plant?['group'] as String?),
      memberNames: members,
      checkinCount: checkins.length,
      photoPaths: photos,
    );
  }

  @override
  Future<List<TaskHistoryEntry>> taskHistory(
    String projectId, {
    int limit = 50,
  }) async {
    final tasks = await _client
        .from('tasks')
        .select('id, task_code')
        .eq('project_id', projectId);
    if (tasks.isEmpty) return const [];
    final codeById = {
      for (final t in tasks) t['id'].toString(): t['task_code'] as String,
    };
    final logs = await _client
        .from('task_logs')
        .select('task_id, occurrence_date, user_id, action, created_at')
        .inFilter('task_id', codeById.keys.toList())
        .order('created_at', ascending: false)
        .limit(limit);
    return [
      for (final l in logs)
        TaskHistoryEntry(
          taskId: l['task_id'].toString(),
          taskCode: codeById[l['task_id'].toString()] ?? '',
          action: l['action'] as String,
          occurrenceDate: parseIsoDate(l['occurrence_date'] as String),
          userId: l['user_id'] as String?,
          createdAt: DateTime.parse(l['created_at'] as String),
        ),
    ];
  }

  @override
  Future<String> uploadCover(Uint8List bytes, {String ext = 'jpg'}) async {
    final path = '$_uid/${const Uuid().v4()}.$ext';
    await _client.storage
        .from('covers')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$ext'),
        );
    return path;
  }
}
