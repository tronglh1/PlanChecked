import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/core/router/app_router.dart';
import 'package:vuon_nha/features/auth/presentation/auth_state.dart';

void main() {
  test('redirect rules', () {
    expect(authRedirect(AuthStatus.signedOut, '/today'), '/login');
    expect(authRedirect(AuthStatus.signedOut, '/login'), isNull);
    expect(authRedirect(AuthStatus.signedIn, '/login'), '/today');
    expect(authRedirect(AuthStatus.signedIn, '/garden'), isNull);
    expect(authRedirect(AuthStatus.configMissing, '/today'), '/config-error');
  });
}
