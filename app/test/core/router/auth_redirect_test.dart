import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vuon_nha/core/router/app_router.dart';
import 'package:vuon_nha/features/auth/presentation/auth_state.dart';
import 'package:vuon_nha/features/household/presentation/household_providers.dart';
import 'package:vuon_nha/features/profile/presentation/profile_providers.dart';

void main() {
  testWidgets('spec route /projects redirects to the Vườn tab /garden', (
    t,
  ) async {
    final router = GoRouter(
      initialLocation: '/projects',
      routes: [
        projectsAliasRoute(),
        GoRoute(path: '/garden', builder: (_, _) => const Text('GARDEN')),
      ],
    );
    addTearDown(router.dispose);
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    await t.pumpAndSettle();
    expect(find.text('GARDEN'), findsOneWidget);
  });

  test('redirect rules', () {
    expect(authRedirect(AuthStatus.signedOut, '/today'), '/login');
    expect(authRedirect(AuthStatus.signedOut, '/login'), isNull);
    expect(authRedirect(AuthStatus.signedIn, '/login'), '/today');
    expect(authRedirect(AuthStatus.signedIn, '/garden'), isNull);
    expect(authRedirect(AuthStatus.configMissing, '/today'), '/config-error');
  });

  group('pending invite code (B3)', () {
    const code = 'VUON-K7M2QX';

    test('signed in with a pending code goes to /join?code=', () {
      for (final gate in [HouseholdGate.needsSetup, HouseholdGate.done]) {
        for (final loc in ['/login', '/today', '/onboarding/household']) {
          expect(
            authRedirect(
              AuthStatus.signedIn,
              loc,
              household: gate,
              pendingJoinCode: code,
            ),
            '/join?code=$code',
            reason: '$gate $loc',
          );
        }
      }
    });

    test('not while the join screen is open, or state is still loading', () {
      expect(
        authRedirect(AuthStatus.signedIn, '/join', pendingJoinCode: code),
        isNull,
      );
      expect(
        authRedirect(
          AuthStatus.signedIn,
          '/today',
          household: HouseholdGate.unknown,
          pendingJoinCode: code,
        ),
        isNull,
      );
      expect(
        authRedirect(
          AuthStatus.signedIn,
          '/today',
          profile: ProfileStatus.unknown,
          pendingJoinCode: code,
        ),
        isNull,
      );
    });

    test('profile onboarding comes first; signed out still logs in first', () {
      expect(
        authRedirect(
          AuthStatus.signedIn,
          '/today',
          profile: ProfileStatus.missing,
          pendingJoinCode: code,
        ),
        '/onboarding/profile',
      );
      expect(
        authRedirect(AuthStatus.signedOut, '/join', pendingJoinCode: code),
        '/login',
      );
    });

    test('no pending code: unchanged', () {
      expect(authRedirect(AuthStatus.signedIn, '/today'), isNull);
    });
  });

  group('profile gate', () {
    test('signed in without profile is sent to /onboarding/profile', () {
      for (final loc in [
        '/today',
        '/login',
        '/settings',
        '/projects/new/search',
      ]) {
        expect(
          authRedirect(
            AuthStatus.signedIn,
            loc,
            profile: ProfileStatus.missing,
          ),
          '/onboarding/profile',
          reason: loc,
        );
      }
      expect(
        authRedirect(
          AuthStatus.signedIn,
          '/onboarding/profile',
          profile: ProfileStatus.missing,
        ),
        isNull,
      );
    });

    test('profile still loading or unknown does not trap the user', () {
      expect(
        authRedirect(
          AuthStatus.signedIn,
          '/garden',
          profile: ProfileStatus.unknown,
        ),
        isNull,
      );
      expect(
        authRedirect(
          AuthStatus.signedIn,
          '/login',
          profile: ProfileStatus.unknown,
        ),
        '/today',
      );
    });

    test('complete profile may open the edit screen; login goes to today', () {
      expect(
        authRedirect(
          AuthStatus.signedIn,
          '/onboarding/profile',
          profile: ProfileStatus.complete,
        ),
        isNull,
      );
      expect(
        authRedirect(
          AuthStatus.signedIn,
          '/login',
          profile: ProfileStatus.complete,
        ),
        '/today',
      );
    });

    test('signed out ignores profile status', () {
      expect(
        authRedirect(
          AuthStatus.signedOut,
          '/onboarding/profile',
          profile: ProfileStatus.missing,
        ),
        '/login',
      );
    });
  });
}
