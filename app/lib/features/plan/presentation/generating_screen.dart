import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../projects/presentation/projects_providers.dart';
import '../domain/plan_bundle.dart';
import 'plan_providers.dart';

/// Screen 09 (PLN-01): AI is building the plan. Target <= 20 s; on timeout or
/// error the plant-type template plan is offered instead.
class GeneratingScreen extends ConsumerWidget {
  const GeneratingScreen({super.key, required this.projectId, this.plantGroup});

  final String projectId;
  final String? plantGroup;

  void _openPlan(BuildContext context) =>
      context.go('/projects/$projectId/plan');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final provider = generationControllerProvider(GenerationArgs(projectId, plantGroup));
    final state = ref.watch(provider);
    final name = ref.watch(projectDetailProvider(projectId)).value;

    ref.listen<GenerationState>(provider, (prev, next) {
      if (next.phase == GenerationPhase.done &&
          !next.usedFallback &&
          prev?.phase != GenerationPhase.done) {
        _openPlan(context);
      }
    });

    final steps = [
      (l10n.planGenStep1, l10n.planGenStep1Sub),
      (l10n.planGenStep2, l10n.planGenStep2Sub),
      (l10n.planGenStep3, l10n.planGenStep3Sub),
      (l10n.planGenStep4, l10n.planGenStep4Sub),
    ];
    final failed = state.phase == GenerationPhase.failed;
    final done = state.phase == GenerationPhase.done;

    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            l10n.planGeneratingEyebrow,
            style: t.labelLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: done
                  ? const Icon(
                      Icons.check_circle_rounded,
                      size: 96,
                      color: AppColors.green,
                    )
                  : failed
                  ? const Icon(
                      Icons.cloud_off_rounded,
                      size: 80,
                      color: AppColors.textSecondary,
                    )
                  : const CircularProgressIndicator(
                      key: Key('generating-spinner'),
                      strokeWidth: 6,
                      color: AppColors.green,
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.planGeneratingTitle,
            textAlign: TextAlign.center,
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (name != null)
            Text(
              name.project.name,
              textAlign: TextAlign.center,
              style: t.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.green,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.planGeneratingHint,
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          GlassCard(
            child: Column(
              children: [
                for (var i = 0; i < steps.length; i++)
                  _StepRow(
                    title: steps[i].$1,
                    subtitle: steps[i].$2,
                    done: i < state.completedSteps,
                    active: i == state.completedSteps && !failed && !done,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (failed)
            GlassCard(
              key: const Key('generating-failed'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.planGenFailedTitle,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    state.fallbackReason == FallbackReason.quotaExceeded
                        ? l10n.planFallbackQuota
                        : l10n.planGenFailedMessage,
                    style: t.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GlowButton(
                    key: const Key('generating-retry'),
                    label: l10n.commonRetry,
                    onPressed: () => ref.read(provider.notifier).retry(),
                  ),
                ],
              ),
            )
          else ...[
            if (done && state.usedFallback)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: GlassCard(
                  key: const Key('fallback-message'),
                  child: Text(
                    state.fallbackReason == FallbackReason.quotaExceeded
                        ? l10n.planFallbackQuota
                        : l10n.planFallbackAiFailure,
                    style: t.bodyMedium,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  l10n.planGeneratingFallbackNote,
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            GlowButton(
              key: const Key('view-plan'),
              label: l10n.planViewPlan,
              onPressed: done ? () => _openPlan(context) : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.active,
  });

  final String title;
  final String subtitle;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done
                ? Icons.check_circle_rounded
                : active
                ? Icons.autorenew_rounded
                : Icons.radio_button_unchecked_rounded,
            color: done ? AppColors.green : AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
