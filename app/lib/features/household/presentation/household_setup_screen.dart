import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import 'household_providers.dart';
import 'household_widgets.dart';

/// Screen 03 (HSH-01/02): onboarding step 2/2. Create, join by code, or skip.
class HouseholdSetupScreen extends ConsumerWidget {
  const HouseholdSetupScreen({super.key});

  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    await ref.read(householdSkipProvider.notifier).skip();
    if (context.mounted) context.go('/today');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final pending = ref.watch(pendingJoinCodeProvider);
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
                    if (context.canPop())
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                    Expanded(
                      child: Text(
                        l10n.householdSetupStep,
                        style: t.labelLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('household-skip'),
                      onPressed: () => _skip(context, ref),
                      child: Text(l10n.householdSetupSkip),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Row(
                  children: [
                    Expanded(child: AppProgressBar(value: 1, height: 4)),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(child: AppProgressBar(value: 1, height: 4)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.householdSetupTitle,
                  style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.householdSetupSub,
                  style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _Illustration(),
                const SizedBox(height: AppSpacing.xl),
                CreateHouseholdCard(
                  onCreated: () => context.go('/household/invite'),
                ),
                const SizedBox(height: AppSpacing.md),
                JoinCodeCard(
                  initialCode: pending,
                  onJoined: () => context.go('/today'),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.householdSetupFooter,
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    Widget dot(String s, Color c) => CircleAvatar(
      radius: 30,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 27,
        backgroundColor: c,
        child: Text(
          s,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.greenTint,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 150,
        height: 60,
        child: Stack(
          children: [
            Positioned(left: 0, child: dot('M', AppColors.green)),
            Positioned(left: 45, child: dot('L', AppColors.orangeDark)),
            Positioned(left: 90, child: dot('H', const Color(0xFF2457A6))),
          ],
        ),
      ),
    );
  }
}
