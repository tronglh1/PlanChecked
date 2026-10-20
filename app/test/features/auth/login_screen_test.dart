import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/auth/presentation/login_screen.dart';

import '../../helpers/fakes.dart';

void main() {
  testWidgets('shows Google and email buttons, no Apple', (t) async {
    await pumpApp(t, const LoginScreen());
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
    expect(find.text('Nhận mã đăng nhập'), findsOneWidget);
    expect(find.text('ban@email.com'), findsOneWidget);
    expect(find.textContaining('Apple'), findsNothing);
  });

  testWidgets('Google button starts the OAuth flow', (t) async {
    final auth = FakeAuthRepository();
    await pumpApp(t, const LoginScreen(), auth: auth);
    await t.tap(find.byKey(const Key('google-button')));
    await t.pumpAndSettle();
    expect(auth.calls, ['google']);
  });

  testWidgets('invalid email shows an error and sends nothing', (t) async {
    final auth = FakeAuthRepository();
    await pumpApp(t, const LoginScreen(), auth: auth);
    await t.enterText(find.byKey(const Key('email-field')), 'nope');
    await t.tap(find.byKey(const Key('send-code-button')));
    await t.pumpAndSettle();
    expect(find.text('Email chưa hợp lệ'), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets('email then 6-digit OTP step', (t) async {
    final auth = FakeAuthRepository();
    await pumpApp(t, const LoginScreen(), auth: auth);
    await t.enterText(find.byKey(const Key('email-field')), 'minh@x.vn');
    await t.tap(find.byKey(const Key('send-code-button')));
    await t.pumpAndSettle();
    expect(auth.calls, ['otp:minh@x.vn']);
    expect(find.text('Nhập mã xác nhận'), findsOneWidget);
    expect(find.byKey(const Key('otp-field')), findsOneWidget);
    expect(find.byKey(const Key('google-button')), findsNothing);

    // Too short.
    await t.enterText(find.byKey(const Key('otp-field')), '123');
    await t.tap(find.byKey(const Key('verify-button')));
    await t.pumpAndSettle();
    expect(find.text('Mã gồm 6 chữ số'), findsOneWidget);

    await t.enterText(find.byKey(const Key('otp-field')), '123456');
    await t.tap(find.byKey(const Key('verify-button')));
    await t.pumpAndSettle();
    expect(auth.calls.last, 'verify:minh@x.vn:123456');
  });

  testWidgets('wrong OTP shows an error; change email goes back', (t) async {
    final auth = FakeAuthRepository()..failVerify = true;
    await pumpApp(t, const LoginScreen(), auth: auth);
    await t.enterText(find.byKey(const Key('email-field')), 'minh@x.vn');
    await t.tap(find.byKey(const Key('send-code-button')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('otp-field')), '000000');
    await t.tap(find.byKey(const Key('verify-button')));
    await t.pumpAndSettle();
    expect(find.textContaining('Mã không đúng hoặc đã hết hạn'), findsOneWidget);

    await t.ensureVisible(find.byKey(const Key('change-email-button')));
    await t.tap(find.byKey(const Key('change-email-button')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('email-field')), findsOneWidget);
  });
}
