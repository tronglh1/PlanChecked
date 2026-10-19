import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/local_prefs.dart';
import '../../../core/env.dart';
import '../../auth/presentation/auth_state.dart';
import '../../settings/presentation/locale_provider.dart';
import '../data/household_repository.dart';
import '../domain/household_models.dart';

/// LocalSettings key: the user tapped "Bỏ qua" on screen 03.
const String kHouseholdSkipKey = 'household_setup_skipped';

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  if (!Env.isConfigured) throw StateError('Supabase is not configured');
  return SupabaseHouseholdRepository();
});

/// The signed-in user's household (null = none or signed out).
class HouseholdNotifier extends AsyncNotifier<Household?> {
  @override
  Future<Household?> build() async {
    final auth = ref.watch(authStateProvider);
    if (auth != AuthStatus.signedIn) return null;
    return ref.read(householdRepositoryProvider).fetchHousehold();
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(
      () => ref.read(householdRepositoryProvider).fetchHousehold(),
    );
  }
}

final householdProvider = AsyncNotifierProvider<HouseholdNotifier, Household?>(
  HouseholdNotifier.new,
);

/// Whether onboarding step 2 was skipped (stored in LocalSettings).
class HouseholdSkipNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final v = await ref.read(localPrefsProvider).get(kHouseholdSkipKey);
    return v == '1';
  }

  Future<void> skip() async {
    await ref.read(localPrefsProvider).set(kHouseholdSkipKey, '1');
    state = const AsyncData(true);
  }
}

final householdSkipProvider =
    AsyncNotifierProvider<HouseholdSkipNotifier, bool>(
      HouseholdSkipNotifier.new,
    );

/// Router input: should the user be sent to `/onboarding/household`?
enum HouseholdGate { unknown, needsSetup, done }

final householdGateProvider = Provider<HouseholdGate>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth != AuthStatus.signedIn) return HouseholdGate.unknown;
  final h = ref.watch(householdProvider);
  final skipped = ref.watch(householdSkipProvider);
  // Loading or errors never trap the user.
  if (h.isLoading || h.hasError || skipped.isLoading || skipped.hasError) {
    return HouseholdGate.unknown;
  }
  if (h.value != null) return HouseholdGate.done;
  return (skipped.value ?? false)
      ? HouseholdGate.done
      : HouseholdGate.needsSetup;
});

/// Invite code received through a deep link, waiting for the user to sign in
/// or open the join screen.
class PendingJoinCodeNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? code) => state = code;
}

final pendingJoinCodeProvider =
    NotifierProvider<PendingJoinCodeNotifier, String?>(
      PendingJoinCodeNotifier.new,
    );

final householdActivityProvider =
    StreamProvider.family<List<ActivityItem>, String>(
      (ref, householdId) =>
          ref.watch(householdRepositoryProvider).watchActivity(householdId),
    );

final householdProjectsProvider =
    FutureProvider.family<List<ShareableProject>, String>(
      (ref, householdId) =>
          ref.watch(householdRepositoryProvider).fetchProjects(householdId),
    );

final assignableTaskProvider = FutureProvider.family<AssignableTask?, String>((
  ref,
  taskId,
) {
  final lang = ref.watch(localeProvider).languageCode;
  return ref.watch(householdRepositoryProvider).fetchTask(taskId, lang: lang);
});
