import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/app.dart';
import 'package:vuon_nha/features/auth/presentation/auth_state.dart';

class _Fake extends AuthStateNotifier {
  _Fake(this.status);
  final AuthStatus status;
  @override
  AuthStatus build() => status;
}

Future<void> _pump(WidgetTester t, AuthStatus s) async {
  await t.pumpWidget(
    ProviderScope(
      overrides: [authStateProvider.overrideWith(() => _Fake(s))],
      child: const VuonNhaApp(),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() {
    // Avoid network font fetches in tests.
  });

  testWidgets('signed in shows 5 tab labels', (t) async {
    await _pump(t, AuthStatus.signedIn);
    for (final label in [
      'Hôm nay',
      'Vườn',
      'Gia đình',
      'Thành tích',
      'Cài đặt',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    await t.tap(find.text('Cài đặt'));
    await t.pumpAndSettle();
    expect(find.text('Sắp ra mắt'), findsOneWidget);
  });

  testWidgets('signed out redirects to login', (t) async {
    await _pump(t, AuthStatus.signedOut);
    expect(find.text('Đăng nhập'), findsOneWidget);
  });

  testWidgets('missing config shows config error, no crash', (t) async {
    await _pump(t, AuthStatus.configMissing);
    expect(find.text('Thiếu cấu hình'), findsOneWidget);
  });
}
