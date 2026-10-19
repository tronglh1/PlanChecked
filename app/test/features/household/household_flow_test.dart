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
        joinCodeFromUri(Uri.parse('vuonnha://join?code=VUON-4821')),
        'VUON-4821',
      );
      expect(
        joinCodeFromUri(Uri.parse('https://vuonnha.app/join?code=vuon-4821')),
        'VUON-4821',
      );
      expect(
        joinCodeFromUri(Uri.parse('https://vuonnha.app/i/VUON-0007')),
        'VUON-0007',
      );
      expect(
        joinCodeFromUri(Uri.parse('io.supabase.vuonnha://login-callback/')),
        isNull,
      );
      expect(joinCodeFromUri(Uri.parse('vuonnha://join?code=abc')), isNull);
    });

    test('normalize and validate', () {
      expect(normalizeInviteCode(' vuon-4821 '), 'VUON-4821');
      expect(normalizeInviteCode('4821'), 'VUON-4821');
      expect(isValidInviteCode('vuon-12'), isFalse);
      expect(isValidInviteCode('VUON-1234'), isTrue);
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
      await t.enterText(find.byKey(const Key('join-code-field')), 'vuon-4821');
      await t.tap(find.byKey(const Key('join-submit')));
      await t.pumpAndSettle();
      expect(repo.accepted, ['VUON-4821']);
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
      expect(find.text('Mã có dạng VUON-1234'), findsOneWidget);
      expect(repo.accepted, isEmpty);

      await t.enterText(find.byKey(const Key('join-code-field')), 'VUON-1111');
      await t.tap(find.byKey(const Key('join-submit')));
      await t.pumpAndSettle();
      expect(repo.accepted, ['VUON-1111']);
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
      await pumpRouted(t, location: '/join?code=VUON-4821', household: repo);
      expect(find.text('Bạn được mời bằng mã VUON-4821'), findsOneWidget);
      await t.tap(find.byKey(const Key('join-submit')));
      await t.pumpAndSettle();
      expect(repo.accepted, ['VUON-4821']);
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
