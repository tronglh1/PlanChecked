import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/household_models.dart';
import 'household_providers.dart';
import 'household_widgets.dart';

/// `/join?code=VUON-K7M2QX` (deep link target, HSH-02). Pre-fills the code and
/// lets the user confirm before `accept_invite` runs. Users who already belong
/// to a household see an explanation instead of the code form.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key, this.code});
  final String? code;

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  late final String _code;

  @override
  void initState() {
    super.initState();
    _code = normalizeInviteCode(
      widget.code ?? ref.read(pendingJoinCodeProvider) ?? '',
    );
    // The code is on screen now: forget the saved copy so the post-sign-in
    // redirect to /join fires only once.
    Future.microtask(() {
      if (mounted) ref.read(pendingJoinCodeProvider.notifier).set(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final inHousehold = ref.watch(householdProvider).value != null;
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
                if (inHousehold) ...[
                  const SizedBox(height: AppSpacing.xl),
                  GlassCard(
                    key: const Key('join-already-member'),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.householdJoinAlreadyTitle,
                          style: t.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.householdJoinAlreadyBody(_code),
                          style: t.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        GlowButton(
                          key: const Key('join-already-go'),
                          label: l10n.householdJoinAlreadyAction,
                          onPressed: () => context.go('/household'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  if (isValidInviteCode(_code)) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.householdJoinLinkBody(_code),
                      key: const Key('join-link-body'),
                      style: t.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  JoinCodeCard(
                    initialCode: _code,
                    onJoined: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.householdJoined)),
                      );
                      context.go('/household');
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
