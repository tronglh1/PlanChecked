import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';

/// Placeholder for screen 08 (built in the projects milestone). Receives the
/// chosen catalogue plant id (`plant`) or a free-text plant name (`name`).
class ProjectContextScreen extends StatelessWidget {
  const ProjectContextScreen({super.key, this.plantId, this.freeText});

  final String? plantId;
  final String? freeText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          SectionHeader(title: l10n.contextTitle),
          Expanded(
            child: EmptyState(
              icon: Icons.eco_outlined,
              title: freeText ?? plantId ?? '',
              message: l10n.placeholderComingSoon,
            ),
          ),
        ],
      ),
    );
  }
}
