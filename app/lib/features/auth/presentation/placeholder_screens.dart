import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassScaffold(
      body: EmptyState(
        icon: Icons.login_rounded,
        title: l10n.loginTitle,
        message: l10n.loginPlaceholder,
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassScaffold(
      body: EmptyState(
        icon: Icons.spa_outlined,
        title: l10n.onboardingTitle,
        message: l10n.onboardingPlaceholder,
      ),
    );
  }
}

class ConfigErrorScreen extends StatelessWidget {
  const ConfigErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassScaffold(
      body: EmptyState(
        icon: Icons.settings_suggest_outlined,
        title: l10n.configErrorTitle,
        message: l10n.configErrorMessage,
      ),
    );
  }
}
