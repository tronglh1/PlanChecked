import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env.dart';
import '../../auth/presentation/auth_state.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

/// Whether the signed-in user already completed the profile.
enum ProfileStatus { unknown, missing, complete }

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (!Env.isConfigured) throw StateError('Supabase is not configured');
  return SupabaseProfileRepository();
});

/// The current user's `users` row (null = no profile yet or signed out).
class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final auth = ref.watch(authStateProvider);
    if (auth != AuthStatus.signedIn) return null;
    return ref.read(profileRepositoryProvider).fetch();
  }

  Future<void> save(UserProfile profile) async {
    await ref.read(profileRepositoryProvider).save(profile);
    state = AsyncData(profile);
  }

  Future<void> updateLang(String lang) async {
    final current = state.value;
    await ref.read(profileRepositoryProvider).updateLang(lang);
    if (current != null) state = AsyncData(current.copyWith(lang: lang));
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile?>(
  ProfileNotifier.new,
);

/// Derived status used by the router. Errors map to [ProfileStatus.unknown]
/// so a network failure never traps the user in onboarding.
final profileStatusProvider = Provider<ProfileStatus>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth != AuthStatus.signedIn) return ProfileStatus.unknown;
  final p = ref.watch(profileProvider);
  return p.when(
    data: (profile) => (profile != null && profile.isComplete)
        ? ProfileStatus.complete
        : ProfileStatus.missing,
    loading: () => ProfileStatus.unknown,
    error: (_, _) => ProfileStatus.unknown,
  );
});
