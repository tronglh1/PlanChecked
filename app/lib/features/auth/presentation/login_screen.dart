import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/auth_validation.dart';
import 'auth_state.dart';

enum _LoginStep { email, otp }

/// Screen 01 (ACC-01): Google + email OTP. No Apple sign-in.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _otp = TextEditingController();
  _LoginStep _step = _LoginStep.email;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String failure) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      // Keep the server's reason visible (rate limit, mailer not allowed, provider off)
      // so a failed sign-in can be diagnosed from a screenshot.
      final raw = e is AuthException ? e.message : '${e.runtimeType}: $e';
      final detail = raw.length > 200 ? '${raw.substring(0, 200)}…' : raw;
      if (mounted) setState(() => _error = '$failure\n($detail)');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() {
    final l10n = AppLocalizations.of(context);
    return _run(
      () => ref.read(authRepositoryProvider).signInWithGoogle(),
      l10n.loginError,
    );
  }

  Future<void> _sendCode() async {
    final l10n = AppLocalizations.of(context);
    if (!AuthValidation.isValidEmail(_email.text)) {
      setState(() => _error = l10n.loginEmailInvalid);
      return;
    }
    await _run(() async {
      await ref.read(authRepositoryProvider).sendEmailOtp(_email.text);
      if (mounted) {
        setState(() {
          _step = _LoginStep.otp;
          _otp.clear();
        });
      }
    }, l10n.loginError);
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context);
    if (!AuthValidation.isValidOtp(_otp.text)) {
      setState(() => _error = l10n.loginOtpInvalid);
      return;
    }
    // On success the auth stream flips to signedIn and the router redirects.
    await _run(
      () => ref
          .read(authRepositoryProvider)
          .verifyEmailOtp(_email.text, _otp.text),
      l10n.loginOtpWrong,
    );
  }

  Future<void> _resend() {
    final l10n = AppLocalizations.of(context);
    return _run(
      () => ref.read(authRepositoryProvider).sendEmailOtp(_email.text),
      l10n.loginError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return GlassScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: AppColors.textOnPrimary,
                    size: 48,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.appName,
                  style: t.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 290),
                  child: Text(
                    l10n.loginTagline,
                    textAlign: TextAlign.center,
                    style: t.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_step == _LoginStep.email)
                  ..._emailStep(l10n, t)
                else
                  ..._otpStep(l10n, t),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _error!,
                    key: const Key('login-error'),
                    textAlign: TextAlign.center,
                    style: t.bodyMedium?.copyWith(color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                _Footer(l10n: l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _emailStep(AppLocalizations l10n, TextTheme t) => [
    _GoogleButton(
      key: const Key('google-button'),
      label: l10n.loginGoogle,
      onTap: _busy ? null : _google,
    ),
    const SizedBox(height: AppSpacing.lg),
    Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            l10n.loginOr,
            style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    ),
    const SizedBox(height: AppSpacing.lg),
    GlassTextField(
      key: const Key('email-field'),
      controller: _email,
      label: l10n.loginEmailLabel,
      hint: l10n.loginEmailHint,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _sendCode(),
    ),
    const SizedBox(height: AppSpacing.lg),
    GlowButton(
      key: const Key('send-code-button'),
      label: l10n.loginSendCode,
      onPressed: _busy ? null : _sendCode,
    ),
  ];

  List<Widget> _otpStep(AppLocalizations l10n, TextTheme t) => [
    Text(
      l10n.loginOtpTitle,
      style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: AppSpacing.sm),
    Text(
      l10n.loginOtpSent(_email.text.trim()),
      textAlign: TextAlign.center,
      style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
    ),
    const SizedBox(height: AppSpacing.lg),
    GlassTextField(
      key: const Key('otp-field'),
      controller: _otp,
      label: l10n.loginOtpLabel,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      autofocus: true,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onSubmitted: (_) => _verify(),
    ),
    const SizedBox(height: AppSpacing.lg),
    GlowButton(
      key: const Key('verify-button'),
      label: l10n.loginOtpVerify,
      onPressed: _busy ? null : _verify,
    ),
    const SizedBox(height: AppSpacing.sm),
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: _busy ? null : _resend,
          child: Text(l10n.loginResend),
        ),
        TextButton(
          key: const Key('change-email-button'),
          onPressed: _busy
              ? null
              : () => setState(() {
                  _step = _LoginStep.email;
                  _error = null;
                }),
          child: Text(l10n.loginChangeEmail),
        ),
      ],
    ),
  ];
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  // Google brand blue for the "G" glyph; not part of the app palette.
  static const Color _googleBlue = Color(0xFF4285F4);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: GlassCard(
        onTap: onTap,
        radius: AppRadius.button,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'G',
                style: t.titleLarge?.copyWith(
                  color: _googleBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.textSecondary);
    final link = base?.copyWith(
      color: AppColors.text,
      decoration: TextDecoration.underline,
    );
    // Terms / policy pages are not published yet; links are styled but inert.
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: l10n.loginTermsPrefix),
          TextSpan(text: l10n.loginTerms, style: link),
          TextSpan(text: l10n.loginTermsAnd),
          TextSpan(text: l10n.loginPrivacy, style: link),
          TextSpan(text: l10n.loginTermsSuffix),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
