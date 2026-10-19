import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env.dart';
import '../../auth/presentation/auth_state.dart';
import '../../settings/presentation/locale_provider.dart';
import '../data/gamification_repository.dart';
import '../domain/achievements_models.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  if (!Env.isConfigured) throw StateError('Supabase is not configured');
  return SupabaseGamificationRepository();
});

final achievementsProvider = FutureProvider<AchievementsData>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(gamificationRepositoryProvider).fetchAchievements();
});

typedef MilestoneKey = ({String projectId, String code});

final milestoneProvider = FutureProvider.family<MilestoneInfo?, MilestoneKey>((
  ref,
  key,
) {
  final lang = ref.watch(localeProvider).languageCode;
  return ref
      .watch(gamificationRepositoryProvider)
      .fetchMilestone(key.projectId, key.code, lang: lang);
});

/// Milestone codes already reached in a project (tappable in project detail).
final reachedMilestonesProvider = FutureProvider.family<Set<String>, String>((
  ref,
  projectId,
) {
  ref.watch(authStateProvider);
  return ref.watch(gamificationRepositoryProvider).reachedMilestones(projectId);
});
