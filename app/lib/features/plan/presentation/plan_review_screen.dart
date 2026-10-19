import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../projects/presentation/projects_providers.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/plan_bundle.dart';
import '../domain/template_renderer.dart';
import 'plan_labels.dart';
import 'plan_providers.dart';
import 'task_edit_sheet.dart';

/// Screen 10 (PLN-02/03/05/07/09): review the plan, edit tasks, approve.
class PlanReviewScreen extends ConsumerStatefulWidget {
  const PlanReviewScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<PlanReviewScreen> createState() => _PlanReviewScreenState();
}

class _PlanReviewScreenState extends ConsumerState<PlanReviewScreen> {
  final Set<String> _expanded = {};
  bool _initialized = false;
  bool _busy = false;
  bool _error = false;

  Future<void> _approve(PlanBundle bundle) async {
    setState(() {
      _busy = true;
      _error = false;
    });
    try {
      await ref
          .read(planActionsProvider)
          .approve(widget.projectId, bundle.plan.id);
      ref.invalidate(projectListProvider);
      ref.invalidate(projectDetailProvider(widget.projectId));
      if (mounted) context.go('/projects/${widget.projectId}');
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bundleAsync = ref.watch(planBundleProvider(widget.projectId));

    return GlassScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              key: const Key('plan-back'),
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go('/projects/${widget.projectId}'),
            ),
          ),
          Expanded(
            child: bundleAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => EmptyState(
                icon: Icons.cloud_off_rounded,
                title: l10n.planLoadError,
                actionLabel: l10n.commonRetry,
                onAction: () =>
                    ref.invalidate(planBundleProvider(widget.projectId)),
              ),
              data: (bundle) {
                if (bundle == null) {
                  return EmptyState(
                    icon: Icons.event_note_rounded,
                    title: l10n.planEmpty,
                  );
                }
                if (!_initialized && bundle.stages.isNotEmpty) {
                  _initialized = true;
                  _expanded.add(bundle.stages.first.id);
                }
                return _body(context, bundle);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, PlanBundle bundle) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;
    final renderer = watchRenderer(ref);
    final plan = bundle.plan;
    final isAi = plan.source == PlanSource.ai;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              Text(
                l10n.planReviewTitle(bundle.totalDays),
                style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _InfoChip(
                    key: const Key('plan-source-chip'),
                    label: isAi ? l10n.planAiLabel : l10n.planTemplateLabel,
                    icon: isAi
                        ? Icons.auto_awesome_rounded
                        : Icons.description_outlined,
                    tint: isAi ? AppColors.orangeTint : AppColors.greenTint,
                    ink: isAi ? AppColors.orangeTintInk : AppColors.greenDeep,
                  ),
                  if (plan.confidence != null)
                    _InfoChip(
                      key: const Key('plan-confidence-chip'),
                      label: confidenceLabel(l10n, plan.confidence!),
                      tint: AppColors.greenTint,
                      ink: AppColors.greenDeep,
                    ),
                  _InfoChip(
                    key: const Key('plan-sources-chip'),
                    label: l10n.planSources(
                      bundle.sources.isEmpty
                          ? l10n.planSourcesDefault
                          : bundle.sources.join(', '),
                    ),
                    tint: AppColors.cream,
                    ink: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  TagChip(
                    key: const Key('seg-stages'),
                    label: l10n.planSegStages,
                    selected: true,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TagChip(
                    key: const Key('seg-calendar'),
                    label: l10n.planSegCalendar,
                    onTap: () =>
                        context.push('/projects/${widget.projectId}/calendar'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SafetyCard(bundle: bundle, renderer: renderer, lang: lang),
              const SizedBox(height: AppSpacing.lg),
              for (final s in bundle.stages)
                _StageTile(
                  stage: s,
                  tasks: bundle.tasksOf(s),
                  expanded: _expanded.contains(s.id),
                  renderer: renderer,
                  lang: lang,
                  onToggle: () => setState(() {
                    if (!_expanded.add(s.id)) _expanded.remove(s.id);
                  }),
                  onEdit: (task) => showTaskEditor(
                    context,
                    projectId: widget.projectId,
                    stages: bundle.stages,
                    task: task,
                  ),
                  onAdd: () => showTaskEditor(
                    context,
                    projectId: widget.projectId,
                    stages: bundle.stages,
                    stageId: s.id,
                  ),
                ),
            ],
          ),
        ),
        if (!bundle.isApproved)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      l10n.planApproveError,
                      style: t.bodyMedium?.copyWith(color: AppColors.danger),
                    ),
                  ),
                GlowButton(
                  key: const Key('approve-plan'),
                  label: l10n.planStart,
                  icon: Icons.eco_rounded,
                  onPressed: _busy ? null : () => _approve(bundle),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    super.key,
    required this.label,
    required this.tint,
    required this.ink,
    this.icon,
  });

  final String label;
  final Color tint;
  final Color ink;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: ink),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// PLN-09: organic-first note + per-task safety text from templates.
class _SafetyCard extends StatelessWidget {
  const _SafetyCard({
    required this.bundle,
    required this.renderer,
    required this.lang,
  });

  final PlanBundle bundle;
  final TemplateRenderer renderer;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final codes = {for (final x in bundle.tasks) x.taskCode}.toList()..sort();
    final warnings = <(String, String)>[];
    for (final c in codes) {
      final s = renderer.taskSafety(c, lang: lang);
      if (s != null && s.trim().isNotEmpty) {
        warnings.add((renderer.taskName(c, lang: lang), s));
      }
    }
    return GlassCard(
      key: const Key('safety-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.health_and_safety_rounded,
                color: AppColors.orangeMid,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.planSafetyTitle,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.planSafetyOrganic, style: t.bodyMedium),
          for (final w in warnings) ...[
            const SizedBox(height: AppSpacing.sm),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${w.$1}: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: w.$2),
                ],
              ),
              style: t.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({
    required this.stage,
    required this.tasks,
    required this.expanded,
    required this.renderer,
    required this.lang,
    required this.onToggle,
    required this.onEdit,
    required this.onAdd,
  });

  final Stage stage;
  final List<Task> tasks;
  final bool expanded;
  final TemplateRenderer renderer;
  final String lang;
  final VoidCallback onToggle;
  final void Function(Task) onEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final milestone = stage.milestoneCode == null
        ? null
        : renderer.render('milestone', stage.milestoneCode!, 'name', lang: lang);
    final sub = [
      l10n.planStageDays(stage.dayFrom, stage.dayTo),
      ?(milestone == null ? null : l10n.planStageMilestone(milestone)),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        key: Key('stage-${stage.id}'),
        radius: 18,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              key: Key('stage-toggle-${stage.id}'),
              onTap: onToggle,
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: expanded ? AppColors.green : AppColors.greenSoft,
                    ),
                    child: Text(
                      '${stage.idx}',
                      style: t.labelLarge?.copyWith(
                        color: expanded ? Colors.white : AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage.name.isEmpty ? stage.code : stage.name,
                          style: t.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          sub,
                          style: t.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    l10n.planStageTaskCount(tasks.length),
                    style: t.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (expanded) ...[
              const SizedBox(height: AppSpacing.sm),
              for (final task in tasks)
                InkWell(
                  key: Key('task-${task.id}'),
                  onTap: () => onEdit(task),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            renderer.taskName(task.taskCode, lang: lang),
                            style: t.bodyMedium,
                          ),
                        ),
                        Text(
                          frequencyLabel(l10n, task),
                          style: t.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              TextButton(
                key: Key('add-task-${stage.id}'),
                onPressed: onAdd,
                child: Text(l10n.planAddTask),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
