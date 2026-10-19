import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/app.dart';
import 'package:vuon_nha/core/db/local_prefs.dart';
import 'package:vuon_nha/features/auth/presentation/auth_state.dart';
import 'package:vuon_nha/features/profile/domain/user_profile.dart';
import 'package:vuon_nha/features/profile/presentation/profile_providers.dart';
import 'package:vuon_nha/features/settings/presentation/settings_providers.dart';

import 'helpers/fakes.dart';

class _Fake extends AuthStateNotifier {
  _Fake(this.status);
  final AuthStatus status;
  @override
  AuthStatus build() => status;
}

Future<void> _pump(WidgetTester t, AuthStatus s, {UserProfile? profile}) async {
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _Fake(s)),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(userId: s == AuthStatus.signedIn ? 'u1' : null),
        ),
        profileRepositoryProvider.overrideWithValue(
          FakeProfileRepository(profile),
        ),
        notificationPrefsRepositoryProvider.overrideWithValue(
          FakeNotificationPrefsRepository(),
        ),
        localPrefsProvider.overrideWithValue(MemoryLocalPrefs()),
      ],
      child: const VuonNhaApp(),
    ),
  );
  await t.pumpAndSettle();
}

const _done = UserProfile(
  id: 'u1',
  displayName: 'Minh',
  provinceCode: 'tp-hcm',
);

void main() {
  testWidgets('signed in shows 5 tab labels', (t) async {
    await _pump(t, AuthStatus.signedIn, profile: _done);
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
    expect(find.text('THÔNG BÁO'), findsOneWidget);
  });

  testWidgets('signed in without profile lands on onboarding', (t) async {
    await _pump(t, AuthStatus.signedIn);
    expect(find.text('Giới thiệu một chút về bạn'), findsOneWidget);
  });

  testWidgets('signed out redirects to login', (t) async {
    await _pump(t, AuthStatus.signedOut);
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
  });

  testWidgets('missing config shows config error, no crash', (t) async {
    await _pump(t, AuthStatus.configMissing);
    expect(find.text('Thiếu cấu hình'), findsOneWidget);
  });
}
