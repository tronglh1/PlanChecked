import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/profile/domain/user_profile.dart';
import 'package:vuon_nha/features/settings/domain/notification_settings.dart';
import 'package:vuon_nha/features/settings/presentation/settings_screen.dart';

import '../../helpers/fakes.dart';

void main() {
  const profile = UserProfile(
    id: 'u1',
    displayName: 'Minh',
    provinceCode: 'tp-hcm',
  );

  testWidgets('language switch changes locale live', (t) async {
    final repo = FakeProfileRepository(profile);
    await pumpApp(
      t,
      const SettingsScreen(),
      auth: FakeAuthRepository(userId: 'u1'),
      profile: repo,
    );
    expect(find.text('THÔNG BÁO'), findsOneWidget);
    expect(find.text('TP. Hồ Chí Minh · Tiếng Việt'), findsOneWidget);

    await t.tap(find.byKey(const Key('settings-lang-en')));
    await t.pumpAndSettle();
    expect(find.text('NOTIFICATIONS'), findsOneWidget);
    expect(find.text('THÔNG BÁO'), findsNothing);
    expect(repo.langUpdates, ['en']);
  });

  testWidgets('notification toggle is saved remotely', (t) async {
    final prefs = FakeNotificationPrefsRepository();
    await pumpApp(
      t,
      const SettingsScreen(),
      auth: FakeAuthRepository(userId: 'u1'),
      profile: FakeProfileRepository(profile),
      notifPrefs: prefs,
    );
    await t.tap(find.text('Nhắc việc chăm cây'));
    await t.pumpAndSettle();
    expect(prefs.saved!.isEnabled(NotifType.taskReminder), isFalse);
    expect(prefs.saved!.isEnabled(NotifType.checkinReminder), isTrue);
  });

  testWidgets('delete account needs two confirmations', (t) async {
    final auth = FakeAuthRepository(userId: 'u1');
    await pumpApp(
      t,
      const SettingsScreen(),
      auth: auth,
      profile: FakeProfileRepository(profile),
    );
    final del = find.byKey(const Key('delete-account'));
    await t.scrollUntilVisible(
      del,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(del);
    await t.pumpAndSettle();
    expect(find.text('Xóa tài khoản?'), findsOneWidget);

    // Cancel at the first dialog: nothing happens.
    await t.tap(find.text('Huỷ'));
    await t.pumpAndSettle();
    expect(auth.calls, isEmpty);

    await t.tap(del);
    await t.pumpAndSettle();
    await t.tap(find.text('Tiếp tục'));
    await t.pumpAndSettle();
    expect(find.text('Bạn chắc chắn chứ?'), findsOneWidget);
    expect(auth.calls, isEmpty);

    await t.tap(find.text('Xóa vĩnh viễn'));
    await t.pumpAndSettle();
    expect(auth.calls, ['delete']);
  });

  test('notification settings encode/decode', () {
    final s = const NotificationSettings()
        .withType(NotifType.assignment, false)
        .withBundle(true);
    final back = NotificationSettings.decode(s.encode());
    expect(back.isEnabled(NotifType.assignment), isFalse);
    expect(back.isEnabled(NotifType.taskReminder), isTrue);
    expect(back.bundleDaily, isTrue);
    expect(NotificationSettings.decode(null).bundleDaily, isFalse);
  });
}
