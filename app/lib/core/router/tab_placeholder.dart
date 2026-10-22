import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/widgets.dart';

/// Temporary body for the 5 tabs until their features land.
class TabPlaceholder extends StatelessWidget {
  const TabPlaceholder({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        Expanded(
          child: EmptyState(icon: icon, title: l10n.placeholderComingSoon),
        ),
      ],
    );
  }
}
