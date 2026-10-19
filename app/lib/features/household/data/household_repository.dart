import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/household_models.dart';

abstract class HouseholdRepository {
  /// The caller's household with members, or null when not in one.
  Future<Household?> fetchHousehold();

  /// RPC `create_household(p_name)`. Throws [HouseholdFailure].
  Future<void> createHousehold(String name);

  /// RPC `accept_invite(p_code)`.
  Future<JoinResult> acceptInvite(String code);

  /// RPC `leave_household()`. Ownership passes server-side to the
  /// longest-standing member; the last member leaving deletes the household.
  Future<void> leaveHousehold();

  /// RPC `remove_member(p_user)` (Owner only).
  Future<void> removeMember(String userId);

  /// Edge Function `invite`. [channel] is link | code | email | phone.
  Future<InviteResult> createInvite({
    required String channel,
    String? target,
    required HouseholdRole role,
  });

  /// Projects the user can see (own + shared), for the sharing list.
  Future<List<ShareableProject>> fetchProjects(String householdId);

  /// Sets `projects.household_id` ([householdId] null = unshare).
  Future<void> setProjectHousehold(String projectId, String? householdId);

  /// Realtime feed of `household_activity` (newest first).
  Stream<List<ActivityItem>> watchActivity(String householdId);

  Future<AssignableTask?> fetchTask(String taskId, {String lang = 'vi'});

  /// Updates `tasks.assignee_id / assignment_mode / rotation_order`.
  Future<void> assignTask({
    required String taskId,
    required AssignMode mode,
    String? assigneeId,
    List<String> rotationOrder = const [],
  });
}

class SupabaseHouseholdRepository implements HouseholdRepository {
  SupabaseHouseholdRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Not signed in');
    return id;
  }

  HouseholdFailure _failure(PostgrestException e) {
    final m = e.message;
    for (final c in const [
      HouseholdFailure.alreadyInHousehold,
      HouseholdFailure.notOwner,
      HouseholdFailure.tooManyInvites,
      'not_a_member',
      'use_leave_household',
    ]) {
      if (m.contains(c)) return HouseholdFailure(c);
    }
    return HouseholdFailure(m);
  }

  @override
  Future<Household?> fetchHousehold() async {
    final uid = _uid;
    final mine = await _client
        .from('household_members')
        .select('household_id')
        .eq('user_id', uid)
        .maybeSingle();
    if (mine == null) return null;
    final hid = mine['household_id'] as String;
    final h = await _client
        .from('households')
        .select('id, name, owner_id')
        .eq('id', hid)
        .single();
    final rows = await _client
        .from('household_members')
        .select('user_id, role, joined_at, away_until')
        .eq('household_id', hid);
    final ids = [for (final r in rows) r['user_id'] as String];
    final profiles = await _client
        .from('member_profiles')
        .select('id, display_name, avatar_path, level, xp_total')
        .inFilter('id', ids);
    final byId = {for (final p in profiles) p['id'] as String: p};

    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final counts = <String, int>{};
    try {
      final logs = await _client
          .from('task_logs')
          .select('user_id')
          .eq('action', 'done')
          .gte('acted_at', monday.toUtc().toIso8601String())
          .inFilter('user_id', ids);
      for (final l in logs) {
        final u = l['user_id'] as String;
        counts[u] = (counts[u] ?? 0) + 1;
      }
    } catch (_) {
      // Counts are decorative; never block the screen on them.
    }

    final members = [
      for (final r in rows)
        HouseholdMember(
          userId: r['user_id'] as String,
          name: (byId[r['user_id']]?['display_name'] as String?) ?? '',
          avatarPath: byId[r['user_id']]?['avatar_path'] as String?,
          role: HouseholdRole.fromDb(r['role']),
          joinedAt: DateTime.parse(r['joined_at'] as String),
          awayUntil: r['away_until'] == null
              ? null
              : DateTime.parse(r['away_until'] as String),
          level: (byId[r['user_id']]?['level'] as num?)?.toInt() ?? 1,
          xpTotal: (byId[r['user_id']]?['xp_total'] as num?)?.toInt() ?? 0,
          tasksThisWeek: counts[r['user_id']] ?? 0,
        ),
    ]..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
    return Household(
      id: h['id'] as String,
      name: h['name'] as String,
      ownerId: h['owner_id'] as String,
      members: members,
      myUserId: uid,
    );
  }

  @override
  Future<void> createHousehold(String name) async {
    try {
      await _client.rpc('create_household', params: {'p_name': name});
    } on PostgrestException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<JoinResult> acceptInvite(String code) async {
    try {
      final res = await _client.rpc('accept_invite', params: {'p_code': code});
      final m = Map<String, dynamic>.from(res as Map);
      if (m['ok'] == true) {
        return JoinResult.ok(
          householdId: m['household_id'] as String?,
          role: HouseholdRole.fromDb(m['role']),
        );
      }
      return JoinResult.failed(JoinResult.errorFromCode(m['error'] as String?));
    } on PostgrestException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<void> leaveHousehold() async {
    try {
      await _client.rpc('leave_household');
    } on PostgrestException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<void> removeMember(String userId) async {
    try {
      await _client.rpc('remove_member', params: {'p_user': userId});
    } on PostgrestException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<InviteResult> createInvite({
    required String channel,
    String? target,
    required HouseholdRole role,
  }) async {
    try {
      final res = await _client.functions.invoke(
        'invite',
        body: {'channel': channel, 'target': ?target, 'role': role.db},
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      final inv = Map<String, dynamic>.from(data['invite'] as Map);
      return InviteResult(
        code: inv['code'] as String,
        link: data['link'] as String,
        expiresAt: DateTime.parse(inv['expires_at'] as String),
        role: HouseholdRole.fromDb(inv['role']),
        emailSent: data['email_sent'] == true,
        emailError: data['email_error'] as String?,
      );
    } on FunctionException catch (e) {
      final d = e.details;
      final code = d is Map ? (d['error'] as String?) : null;
      throw HouseholdFailure(code ?? 'invite_failed');
    }
  }

  @override
  Future<List<ShareableProject>> fetchProjects(String householdId) async {
    final rows = await _client
        .from('projects')
        .select('id, name, owner_id, household_id')
        .eq('status', 'active')
        .order('created_at');
    return [
      for (final r in rows)
        ShareableProject(
          id: r['id'] as String,
          name: r['name'] as String,
          ownerId: r['owner_id'] as String,
          sharedWithHousehold: r['household_id'] == householdId,
        ),
    ];
  }

  @override
  Future<void> setProjectHousehold(
    String projectId,
    String? householdId,
  ) async {
    await _client
        .from('projects')
        .update({'household_id': householdId})
        .eq('id', projectId);
  }

  @override
  Stream<List<ActivityItem>> watchActivity(String householdId) {
    return _client
        .from('household_activity')
        .stream(primaryKey: ['id'])
        .eq('household_id', householdId)
        .order('created_at', ascending: false)
        .limit(30)
        .map(
          (rows) => [
            for (final r in rows)
              ActivityItem(
                id: r['id'] as String,
                kind: r['kind'] as String,
                actorId: r['actor_id'] as String?,
                projectId: r['project_id'] as String?,
                createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
                payload: Map<String, dynamic>.from(
                  (r['payload'] as Map?) ?? const {},
                ),
              ),
          ],
        );
  }

  @override
  Future<AssignableTask?> fetchTask(String taskId, {String lang = 'vi'}) async {
    final r = await _client
        .from('tasks')
        .select(
          'id, task_code, project_id, window, interval_days, assignment_mode, '
          'assignee_id, rotation_order, projects(name, owner_id, household_id)',
        )
        .eq('id', taskId)
        .maybeSingle();
    if (r == null) return null;
    final p = Map<String, dynamic>.from(r['projects'] as Map);
    final uid = _uid;
    var canManage = p['owner_id'] == uid;
    if (!canManage && p['household_id'] != null) {
      final m = await _client
          .from('household_members')
          .select('role')
          .eq('household_id', p['household_id'] as String)
          .eq('user_id', uid)
          .maybeSingle();
      canManage = m?['role'] == 'owner';
    }
    String? title;
    try {
      final t = await _client
          .from('text_templates')
          .select('body')
          .eq('kind', 'task')
          .eq('code', r['task_code'] as String)
          .eq('field', 'name')
          .eq('lang', lang)
          .maybeSingle();
      title = t?['body'] as String?;
    } catch (_) {}
    return AssignableTask(
      taskId: r['id'] as String,
      taskCode: r['task_code'] as String,
      title: title,
      projectId: r['project_id'] as String,
      projectName: p['name'] as String,
      window: r['window'] as String,
      intervalDays: (r['interval_days'] as num?)?.toInt(),
      mode: AssignMode.fromDb(r['assignment_mode']),
      assigneeId: r['assignee_id'] as String?,
      rotationOrder: [
        for (final x in (r['rotation_order'] as List? ?? const [])) '$x',
      ],
      canManage: canManage,
    );
  }

  @override
  Future<void> assignTask({
    required String taskId,
    required AssignMode mode,
    String? assigneeId,
    List<String> rotationOrder = const [],
  }) async {
    await _client
        .from('tasks')
        .update({
          'assignee_id': mode == AssignMode.rotation
              ? (rotationOrder.isEmpty ? null : rotationOrder.first)
              : assigneeId,
          'assignment_mode': mode.db,
          'rotation_order': mode == AssignMode.rotation
              ? rotationOrder
              : <String>[],
        })
        .eq('id', taskId);
  }
}
