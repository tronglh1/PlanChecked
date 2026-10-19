import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/core/db/local_prefs.dart';
import 'package:vuon_nha/core/router/app_router.dart';
import 'package:vuon_nha/features/auth/presentation/auth_state.dart';
import 'package:vuon_nha/features/household/domain/household_models.dart';
import 'package:vuon_nha/features/household/presentation/household_providers.dart';

import '../../helpers/fakes.dart';
import '../../helpers/household_fakes.dart';

void main() {
  group('deep link + code parsing', () {
    test('join links', () {
      expect(
        joinCodeFromUri(Uri.parse('vuonnha://join?code=VUON-K7M2QX')),
        'VUON-K7M2QX',
      );
      expect(
        joinCodeFromUri(Uri.parse('https://vuonnha.app/join?code=vuon-k7m2qx')),
        'VUON-K7M2QX',
      );
      expect(
        joinCodeFromUri(Uri.parse('https://vuonnha.app/i/VUON-AB2CD3')),
        'VUON-AB2CD3',
      );
      expect(
        joinCodeFromUri(Uri.parse('io.supabase.vuonnha://login-callback/')),
        isNull,
      );
      expect(joinCodeFromUri(Uri.parse('vuonnha://join?code=abc')), isNull);
      // Legacy 4-digit codes still parse for their 7 days; ambiguous chars do not.
      expect(
        joinCodeFromUri(Uri.parse('vuonnha://join?code=VUON-4821')),
        'VUON-4821',
      );
      expect(
        joinCodeFromUri(Uri.parse('vuonnha://join?code=VUON-K7M2Q0')),
        isNull,
      );
    });

    test('normalize and validate', () {
      expect(normalizeInviteCode(' vuon-k7m2qx '), 'VUON-K7M2QX');
      expect(normalizeInviteCode('k7m2qx'), 'VUON-K7M2QX');
      expect(normalizeInviteCode('4821'), 'VUON-4821');
      expect(isValidInviteCode('vuon-12'), isFalse);
      expect(isValidInviteCode('VUON-K7M2QX'), isTrue);
      expect(isValidInviteCode('VUON-K7M2Q'), isFalse, reason: 'too short');
      expect(isValidInviteCode('VUON-K7M2QXX'), isFalse, reason: 'too long');
      for (final bad in ['I', 'L', 'O', '0', '1']) {
        expect(isValidInviteCode('VUON-K7M2Q$bad'), isFalse, reason: bad);
      }
      expect(isValidInviteCode('VUON-1234'), isTrue, reason: 'legacy');
    });
  });

  group('onboarding redirect', () {
    test('no household and not skipped goes to step 2', () {
      expect(
        authRedirect(
          AuthStatus.signedIn,
          '/today',
          household: HouseholdGate.needsSetup,
        ),
        '/onboarding/household',
      );
      expect(
        authRedirect(
          AuthStatus.signedIn,
          '/login',
          household: HouseholdGate.needsSetup,
        ),
        '/onboarding/household',
      );
    });

    test('exempt locations and other gate states do not redirect', () {
      for (final loc in [
        '/onboarding/household',
        '/onboarding/profile',
        '/household/invite',
        '/join',
      ]) {
        expect(
          authRedirect(
            AuthStatus.signedIn,
            loc,
            household: HouseholdGate.needsSetup,
          ),
          isNull,
          reason: loc,
        );
      }
      expect(
        authRedirect(
          AuthStatus.signedIn,
          '/today',
          household: HouseholdGate.unknown,
        ),
        isNull,
      );
      expect(
        authRedirect(
          AuthStatus.signedIn,
          '/today',
          household: HouseholdGate.done,
        ),
        isNull,
      );
    });
  });

  group('household setup (03)', () {
    testWidgets('create household then lands on invite screen', (t) async {
      final repo = FakeHouseholdRepository();
      await pumpRouted(t, location: '/onboarding/household', household: repo);
      expect(find.text('Chăm cây cùng người nhà?'), findsOneWidget);

      await t.tap(find.byKey(const Key('create-household')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('household-create-confirm')));
      await t.pumpAndSettle();

      expect(repo.created, ['Nhà mình']);
      expect(find.text('Mời người nhà'), findsOneWidget);
      // Owner sees a code card.
      expect(find.byKey(const Key('invite-code')), findsOneWidget);
    });

    testWidgets('join by code normalizes input and goes to Today', (t) async {
      final repo = FakeHouseholdRepository();
      await pumpRouted(t, location: '/onboarding/household', household: repo);
      await t.enterText(
        find.byKey(const Key('join-code-field')),
        'vuon-k7m2qx',
      );
      await t.tap(find.byKey(const Key('join-submit')));
      await t.pumpAndSettle();
      expect(repo.accepted, ['VUON-K7M2QX']);
      expect(find.text('STUB-TODAY'), findsOneWidget);
    });

    testWidgets('bad format is rejected locally; server errors are shown', (
      t,
    ) async {
      final repo = FakeHouseholdRepository()
        ..joinResult = const JoinResult.failed(JoinError.expired);
      await pumpRouted(t, location: '/onboarding/household', household: repo);
      await t.enterText(find.byKey(const Key('join-code-field')), 'xyz');
      await t.tap(find.byKey(const Key('join-submit')));
      await t.pumpAndSettle();
      expect(find.text('Mã có dạng VUON-K7M2QX'), findsOneWidget);
      expect(repo.accepted, isEmpty);

      await t.enterText(
        find.byKey(const Key('join-code-field')),
        'VUON-K7M2QX',
      );
      await t.tap(find.byKey(const Key('join-submit')));
      await t.pumpAndSettle();
      expect(repo.accepted, ['VUON-K7M2QX']);
      expect(find.text('Mã mời đã hết hạn'), findsOneWidget);
    });

    testWidgets('skip stores the flag locally and goes to Today', (t) async {
      final prefs = MemoryLocalPrefs();
      await pumpRouted(
        t,
        location: '/onboarding/household',
        household: FakeHouseholdRepository(),
        prefs: prefs,
      );
      await t.tap(find.byKey(const Key('household-skip')));
      await t.pumpAndSettle();
      expect(await prefs.get(kHouseholdSkipKey), '1');
      expect(find.text('STUB-TODAY'), findsOneWidget);
    });

    testWidgets('deep link screen pre-fills the code', (t) async {
      final repo = FakeHouseholdRepository();
      await pumpRouted(t, location: '/join?code=VUON-K7M2QX', household: repo);
      expect(find.text('Bạn được mời bằng mã VUON-K7M2QX'), findsOneWidget);
      await t.tap(find.byKey(const Key('join-submit')));
      await t.pumpAndSettle();
      expect(repo.accepted, ['VUON-K7M2QX']);
    });
  });

  group('join screen (B3)', () {
    testWidgets('already in a household: explanation instead of the form', (
      t,
    ) async {
      final repo = FakeHouseholdRepository(household: sampleHousehold());
      await pumpRouted(t, location: '/join?code=VUON-K7M2QX', household: repo);
      expect(find.byKey(const Key('join-already-member')), findsOneWidget);
      expect(find.text('Bạn đã ở trong một gia đình'), findsOneWidget);
      expect(find.textContaining('VUON-K7M2QX'), findsOneWidget);
      expect(find.byKey(const Key('join-submit')), findsNothing);
      expect(repo.accepted, isEmpty);
    });

    testWidgets('showing the code consumes the saved pending code', (t) async {
      final prefs = MemoryLocalPrefs();
      await prefs.set(kPendingJoinCodeKey, 'VUON-K7M2QX');
      await pumpRouted(t, location: '/join?code=VUON-K7M2QX', prefs: prefs);
      // shown, then forgotten so the post-sign-in redirect fires only once
      expect(find.text('Bạn được mời bằng mã VUON-K7M2QX'), findsOneWidget);
      expect(await prefs.get(kPendingJoinCodeKey), '');
    });
  });

  group('pending join code storage', () {
    test('is persisted and restored in a new session', () async {
      final prefs = MemoryLocalPrefs();
      final a = ProviderContainer(
        overrides: [localPrefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(a.dispose);
      a.read(pendingJoinCodeProvider);
      a.read(pendingJoinCodeProvider.notifier).set('VUON-K7M2QX');
      await Future<void>.delayed(Duration.zero);
      expect(await prefs.get(kPendingJoinCodeKey), 'VUON-K7M2QX');

      // app restarted: a fresh container reads the same store
      final b = ProviderContainer(
        overrides: [localPrefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(b.dispose);
      expect(b.read(pendingJoinCodeProvider), isNull);
      await Future<void>.delayed(Duration.zero);
      expect(b.read(pendingJoinCodeProvider), 'VUON-K7M2QX');

      b.read(pendingJoinCodeProvider.notifier).set(null);
      await Future<void>.delayed(Duration.zero);
      expect(b.read(pendingJoinCodeProvider), isNull);
      expect(await prefs.get(kPendingJoinCodeKey), '');
    });

    test('garbage in the store is ignored', () async {
      final prefs = MemoryLocalPrefs();
      await prefs.set(kPendingJoinCodeKey, 'hello');
      final c = ProviderContainer(
        overrides: [localPrefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      c.read(pendingJoinCodeProvider);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(pendingJoinCodeProvider), isNull);
    });
  });

  group('gate provider', () {
    test('needsSetup until skipped or in a household', () async {
      final repo = FakeHouseholdRepository();
      final c = ProviderContainer(
        overrides: [
          localPrefsProvider.overrideWithValue(MemoryLocalPrefs()),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(userId: 'u1'),
          ),
          householdRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(c.dispose);
      await c.read(householdProvider.future);
      await c.read(householdSkipProvider.future);
      expect(c.read(householdGateProvider), HouseholdGate.needsSetup);

      await c.read(householdSkipProvider.notifier).skip();
      expect(c.read(householdGateProvider), HouseholdGate.done);
    });

    test('member of a household is done without skipping', () async {
      final c = ProviderContainer(
        overrides: [
          localPrefsProvider.overrideWithValue(MemoryLocalPrefs()),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(userId: 'u1'),
          ),
          householdRepositoryProvider.overrideWithValue(
            FakeHouseholdRepository(household: sampleHousehold()),
          ),
        ],
      );
      addTearDown(c.dispose);
      await c.read(householdProvider.future);
      await c.read(householdSkipProvider.future);
      expect(c.read(householdGateProvider), HouseholdGate.done);
    });

    test('signed out is unknown', () async {
      final c = ProviderContainer(
        overrides: [
          localPrefsProvider.overrideWithValue(MemoryLocalPrefs()),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          householdRepositoryProvider.overrideWithValue(
            FakeHouseholdRepository(),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(householdGateProvider), HouseholdGate.unknown);
    });
  });
}
