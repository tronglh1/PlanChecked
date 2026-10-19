import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/achievements_models.dart';

abstract class GamificationRepository {
  /// Reads `users` (xp_total), `levels`, `badges_catalog`, `user_badges`,
  /// `xp_events`, `milestones_reached` and RPC `my_streak`.
  Future<AchievementsData> fetchAchievements();

  /// The milestone row for the celebration screen (null if not found).
  Future<MilestoneInfo?> fetchMilestone(
    String projectId,
    String code, {
    String lang = 'vi',
  });

  /// Codes of the milestones already reached in [projectId].
  Future<Set<String>> reachedMilestones(String projectId);
}

class SupabaseGamificationRepository implements GamificationRepository {
  SupabaseGamificationRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Not signed in');
    return id;
  }

  Future<List<BadgeInfo>> _badges(String uid) async {
    final catalog = await _client
        .from('badges_catalog')
        .select('code, name_vi, name_en, sort_order')
        .order('sort_order');
    final mine = await _client
        .from('user_badges')
        .select('badge_code, earned_at')
        .eq('user_id', uid);
    final earned = {
      for (final r in mine)
        r['badge_code'] as String: DateTime.parse(r['earned_at'] as String),
    };
    return [
      for (final r in catalog)
        BadgeInfo(
          code: r['code'] as String,
          nameVi: r['name_vi'] as String,
          nameEn: r['name_en'] as String,
          sortOrder: (r['sort_order'] as num?)?.toInt() ?? 0,
          earned: earned.containsKey(r['code']),
          earnedAt: earned[r['code']],
        ),
    ];
  }

  @override
  Future<AchievementsData> fetchAchievements() async {
    final uid = _uid;
    final user = await _client
        .from('users')
        .select('xp_total, level')
        .eq('id', uid)
        .maybeSingle();
    var levels = <LevelRow>[];
    try {
      final rows = await _client
          .from('levels')
          .select('level, xp_min, name_vi, name_en')
          .order('xp_min');
      levels = [
        for (final r in rows)
          LevelRow(
            (r['level'] as num).toInt(),
            (r['xp_min'] as num).toInt(),
            r['name_vi'] as String,
            r['name_en'] as String,
          ),
      ];
    } catch (_) {
      // Falls back to the domain defaults.
    }
    final badges = await _badges(uid);
    var streak = 0;
    try {
      streak = ((await _client.rpc('my_streak')) as num?)?.toInt() ?? 0;
    } catch (_) {}
    final events = await _client
        .from('xp_events')
        .select('source, amount, day')
        .eq('user_id', uid);
    final xp = XpBreakdown.fromEvents([
      for (final e in events)
        (
          source: e['source'] as String,
          amount: (e['amount'] as num).toInt(),
          day: DateTime.parse(e['day'] as String),
        ),
    ], DateTime.now());
    var pending = 0;
    try {
      final manual = await _client
          .from('milestones_reached')
          .select('id, projects!inner(owner_id)')
          .eq('confirmed_by', 'user')
          .filter('checkin_id', 'is', null)
          .eq('projects.owner_id', uid);
      pending = manual.length;
    } catch (_) {}
    return AchievementsData(
      xpTotal: (user?['xp_total'] as num?)?.toInt() ?? 0,
      levels: levels,
      badges: badges,
      streak: streak,
      xp: xp,
      pendingPhotoMilestones: pending,
    );
  }

  @override
  Future<Set<String>> reachedMilestones(String projectId) async {
    final rows = await _client
        .from('milestones_reached')
        .select('milestone_code')
        .eq('project_id', projectId);
    return {for (final r in rows) r['milestone_code'] as String};
  }

  @override
  Future<MilestoneInfo?> fetchMilestone(
    String projectId,
    String code, {
    String lang = 'vi',
  }) async {
    final uid = _uid;
    final m = await _client
        .from('milestones_reached')
        .select('id, checkin_id, reached_on, projects(name)')
        .eq('project_id', projectId)
        .eq('milestone_code', code)
        .maybeSingle();
    if (m == null) return null;
    final id = m['id'] as String;
    final xpRows = await _client
        .from('xp_events')
        .select('amount')
        .eq('user_id', uid)
        .eq('source', 'milestone')
        .eq('ref_id', id);
    final xp = xpRows.fold<int>(0, (a, r) => a + (r['amount'] as num).toInt());
    String? title;
    try {
      final t = await _client
          .from('text_templates')
          .select('body')
          .eq('kind', 'milestone')
          .eq('code', code)
          .eq('field', 'name')
          .eq('lang', lang)
          .maybeSingle();
      title = t?['body'] as String?;
    } catch (_) {}
    BadgeInfo? badge;
    try {
      final cat = await _client
          .from('badges_catalog')
          .select('code, name_vi, name_en, criteria')
          .eq('criteria->>type', 'milestone')
          .eq('criteria->>code', code)
          .maybeSingle();
      if (cat != null) {
        final got = await _client
            .from('user_badges')
            .select('earned_at')
            .eq('user_id', uid)
            .eq('badge_code', cat['code'] as String)
            .maybeSingle();
        badge = BadgeInfo(
          code: cat['code'] as String,
          nameVi: cat['name_vi'] as String,
          nameEn: cat['name_en'] as String,
          earned: got != null,
        );
      }
    } catch (_) {}
    final project = m['projects'] as Map?;
    return MilestoneInfo(
      projectId: projectId,
      projectName: (project?['name'] as String?) ?? '',
      code: code,
      title: title,
      photoConfirmed: m['checkin_id'] != null,
      xpAwarded: xp,
      badge: badge,
      reachedOn: DateTime.tryParse('${m['reached_on']}'),
    );
  }
}
