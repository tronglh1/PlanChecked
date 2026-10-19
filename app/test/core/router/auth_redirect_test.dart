import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/core/router/app_router.dart';
import 'package:vuon_nha/features/auth/presentation/auth_state.dart';
import 'package:vuon_nha/features/profile/presentation/profile_providers.dart';

void main() {
  test('redirect rules', () {
    expect(authRedirect(AuthStatus.signedOut, '/today'), '/login');
    expect(authRedirect(AuthStatus.signedOut, '/login'), isNull);
    expect(authRedirect(AuthStatus.signedIn, '/login'), '/today');
    expect(authRedirect(AuthStatus.signedIn, '/garden'), isNull);
    expect(authRedirect(AuthStatus.configMissing, '/today'), '/config-error');
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
