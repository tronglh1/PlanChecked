import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';

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
