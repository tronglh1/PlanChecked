import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/date_only.dart';
import '../../plan/domain/enums.dart';
import '../../plan/domain/models.dart';
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

}

/// Raw rows needed to build the project list; separated from Supabase so the
/// assembly rule is unit-testable. [todayCounts] = rows of `task_occurrences`
/// due [today], counted per project (materialized by `approve_plan`).
List<ProjectSummary> buildProjectSummaries({
  required List<Map<String, dynamic>> projectRows,
  required List<Map<String, dynamic>> planRows,
  required Map<String, int> todayCounts,
  required List<Map<String, dynamic>> checkinRows,
  required DateTime today,
}) {
  final plansByProject = <String, List<Plan>>{};
  for (final r in planRows) {
    final p = Plan.fromJson(Map<String, dynamic>.from(r));
    if (p.status == PlanStatus.superseded) continue;
    plansByProject.putIfAbsent(p.projectId, () => []).add(p);
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
    final photo = photoByProject[project.id];
    out.add(
      ProjectSummary(
        project: project,
        plantNameVi: plant?['name_vi'] as String?,
        plantNameEn: plant?['name_en'] as String?,
        group: PlantGroup.fromCode(plant?['group'] as String?),
        progress: progress,
        planStatus: plan?.status.db,
        todayTaskCount: todayCounts[project.id] ?? 0,
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
          if (input.plantId == null) 'plant_name_custom': input.plantName,
          'name': input.name,
          'start_date': formatIsoDate(input.startDate),
          'start_stage': input.startStage.db,
          'pot_count': input.potCount,
          'space': input.space.db,
          'sun_level': input.sunLevel.db,
          'pot_type': input.potType,
          'watering': input.watering.db,
          'status': ProjectStatus.active.db,
        })
        .select()
        .single();
    var project = Project.fromJson(row);
    final cover = input.coverBytes;
    if (cover != null) {
      // Covers share the private `checkins` bucket: {user}/{project}/cover.jpg.
      try {
        final path = '$_uid/${project.id}/cover.jpg';
        await _client.storage
            .from('checkins')
            .uploadBinary(
              path,
              cover,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
        final updated = await _client
            .from('projects')
            .update({'cover_path': path})
            .eq('id', project.id)
            .select()
            .single();
        project = Project.fromJson(updated);
      } catch (_) {
        // Cover is optional; the project exists without it.
      }
    }
    return project;
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
    final occ = await _client
        .from('task_occurrences')
        .select('project_id')
        .inFilter('project_id', ids)
        .eq('due_date', formatIsoDate(today));
    final todayCounts = <String, int>{};
    for (final o in occ) {
      final pid = o['project_id'].toString();
      todayCounts[pid] = (todayCounts[pid] ?? 0) + 1;
    }
    final checkins = await _client
        .from('checkins')
        .select('project_id, shots, created_at')
        .inFilter('project_id', ids)
        .order('created_at', ascending: false);
    return buildProjectSummaries(
      projectRows: List<Map<String, dynamic>>.from(projects),
      planRows: List<Map<String, dynamic>>.from(plans),
      todayCounts: todayCounts,
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
      final users = await _client
          .from('member_profiles')
          .select('id, display_name');
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
}
