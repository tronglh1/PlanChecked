import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/household_models.dart';
import 'household_providers.dart';
import 'household_widgets.dart';

/// `/join?code=VUON-1234` (deep link target, HSH-02). Pre-fills the code and
/// lets the user confirm before `accept_invite` runs.
class JoinScreen extends ConsumerWidget {
  const JoinScreen({super.key, this.code});
  final String? code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final raw = code ?? ref.watch(pendingJoinCodeProvider) ?? '';
    final normalized = normalizeInviteCode(raw);
    return GlassScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/today'),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                  ],
                ),
                Text(
                  l10n.householdJoinScreenTitle,
                  style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (isValidInviteCode(normalized)) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.householdJoinLinkBody(normalized),
                    key: const Key('join-link-body'),
                    style: t.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                JoinCodeCard(
                  initialCode: normalized,
                  onJoined: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.householdJoined)),
                    );
                    context.go('/household');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
