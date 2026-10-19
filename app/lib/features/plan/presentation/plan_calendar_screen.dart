import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/date_only.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../projects/domain/project.dart';
import '../../projects/presentation/projects_providers.dart';
import '../domain/models.dart';
import '../domain/plan_bundle.dart';
import '../domain/task_scheduler.dart';
import '../domain/template_renderer.dart';
import 'plan_labels.dart';
import 'plan_providers.dart';
import 'task_edit_sheet.dart';

/// Monday of the week containing [d].
DateTime weekStartOf(DateTime d) {
  final x = dateOnly(d);
  return addDays(x, 1 - x.weekday);
}

/// Screen 11 (PLN-04/05): week strip + day list + stage timeline, all from
/// [TaskScheduler].
class PlanCalendarScreen extends ConsumerStatefulWidget {
  const PlanCalendarScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<PlanCalendarScreen> createState() => _PlanCalendarScreenState();
}

class _PlanCalendarScreenState extends ConsumerState<PlanCalendarScreen> {
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final detail = ref.watch(projectDetailProvider(widget.projectId));
    final bundleAsync = ref.watch(planBundleProvider(widget.projectId));
    final today = ref.watch(projectsTodayProvider);

    return GlassScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              key: const Key('calendar-back'),
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
                final d = detail.value;
                if (bundle == null || d == null) {
                  return EmptyState(
                    icon: Icons.event_note_rounded,
                    title: d == null && bundle != null
                        ? l10n.commonLoading
                        : l10n.planEmpty,
                  );
                }
                return _content(context, d, bundle, today, t);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    ProjectDetail detail,
    PlanBundle bundle,
    DateTime today,
    TextTheme t,
  ) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final renderer = watchRenderer(ref);
    final start = detail.project.startDate;
    final selected = _selected ?? dateOnly(today);
    final weekStart = weekStartOf(selected);
    final weekEnd = addDays(weekStart, 6);

    final occurrences = TaskScheduler.expandAll(
      tasks: bundle.tasks,
      stages: bundle.stages,
      projectStart: start,
      from: weekStart,
      to: weekEnd,
    );
    final byDate = <DateTime, List<TaskOccurrence>>{};
    for (final o in occurrences) {
      byDate.putIfAbsent(o.date, () => []).add(o);
    }
    final taskById = {for (final x in bundle.tasks) x.id: x};
    final stage = TaskScheduler.stageOn(bundle.stages, start, selected);
    final dayItems = byDate[dateOnly(selected)] ?? const <TaskOccurrence>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Text(
          detail.project.name,
          style: t.labelLarge?.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          l10n.planCalendarTitle,
          style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            TagChip(
              key: const Key('seg-stages'),
              label: l10n.planSegStages,
              onTap: () => context.go('/projects/${widget.projectId}/plan'),
            ),
            const SizedBox(width: AppSpacing.sm),
            TagChip(
              key: const Key('seg-calendar'),
              label: l10n.planSegCalendar,
              selected: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _StageTimeline(stages: bundle.stages, current: stage),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            IconButton(
              key: const Key('week-prev'),
              tooltip: l10n.planPrevWeek,
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () =>
                  setState(() => _selected = addDays(selected, -7)),
            ),
            Expanded(
              child: Text(
                l10n.planWeekLabel(shortDate(weekStart), shortDate(weekEnd)),
                key: const Key('week-label'),
                textAlign: TextAlign.center,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              key: const Key('week-next'),
              tooltip: l10n.planNextWeek,
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => setState(() => _selected = addDays(selected, 7)),
            ),
          ],
        ),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: _DayCell(
                  key: Key('day-${formatIsoDate(addDays(weekStart, i))}'),
                  date: addDays(weekStart, i),
                  count: (byDate[addDays(weekStart, i)] ?? const []).length,
                  selected: isSameDate(addDays(weekStart, i), selected),
                  onTap: () =>
                      setState(() => _selected = addDays(weekStart, i)),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _StageBanner(stage: stage, stages: bundle.stages, day: TaskScheduler.dayNumber(start, selected)),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.planDayLabel(dowLabel(l10n, selected), shortDate(selected)),
          style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (dayItems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              l10n.planNoTasksDay,
              key: const Key('day-empty'),
              style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        for (final o in dayItems)
          if (taskById[o.taskId] case final task?)
            _TaskRow(
              task: task,
              renderer: renderer,
              lang: lang,
              assignee: task.assigneeId == null
                  ? null
                  : detail.memberNames[task.assigneeId],
              onTap: () => showTaskEditor(
                context,
                projectId: widget.projectId,
                stages: bundle.stages,
                task: task,
              ),
            ),
        const SizedBox(height: AppSpacing.md),
        GlowButton(
          key: const Key('add-manual-task'),
          label: l10n.planAddManual,
          variant: GlowButtonVariant.secondary,
          onPressed: () => showTaskEditor(
            context,
            projectId: widget.projectId,
            stages: bundle.stages,
            stageId: stage?.id,
          ),
        ),
      ],
    );
  }
}

class _StageTimeline extends StatelessWidget {
  const _StageTimeline({required this.stages, required this.current});

  final List<Stage> stages;
  final Stage? current;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    if (stages.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.planTimeline,
          style: t.labelLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          key: const Key('stage-timeline'),
          children: [
            for (final s in stages)
              Expanded(
                flex: s.lengthDays < 1 ? 1 : s.lengthDays,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: s.id == current?.id
                          ? AppColors.green
                          : AppColors.greenSoft,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.date,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final fg = selected ? Colors.white : AppColors.text;
    final sub = selected ? Colors.white : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            gradient: selected ? AppGradients.primary : null,
            color: selected ? null : AppColors.glassFillSolid,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.button),
            onTap: onTap,
            child: SizedBox(
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dowLabel(l10n, date),
                    style: t.labelSmall?.copyWith(color: sub),
                  ),
                  Text(
                    '${date.day}',
                    style: t.titleMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$count',
                    key: Key('count-${formatIsoDate(date)}'),
                    style: t.labelSmall?.copyWith(color: sub),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StageBanner extends StatelessWidget {
  const _StageBanner({
    required this.stage,
    required this.stages,
    required this.day,
  });

  final Stage? stage;
  final List<Stage> stages;
  final int day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = stage;
    final text = s == null
        ? l10n.planOutsideStages
        : l10n.planStageBanner(
            stages.indexWhere((x) => x.id == s.id) + 1,
            s.name.isEmpty ? s.code : s.name,
            s.dayFrom,
            s.dayTo,
            (s.dayTo - day) < 0 ? 0 : s.dayTo - day,
          );
    return Container(
      key: const Key('stage-banner'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.greenTint,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.greenDeep,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.renderer,
    required this.lang,
    required this.assignee,
    required this.onTap,
  });

  final Task task;
  final TemplateRenderer renderer;
  final String lang;
  final String? assignee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final meta = [
      frequencyLabel(l10n, task),
      if (assignee != null && assignee!.isNotEmpty) assignee!,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        key: Key('cal-task-${task.id}'),
        radius: 16,
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                task.reminderTime ?? windowShortLabel(l10n, task.window),
                style: t.labelMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            Container(
              width: 3,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.orangeMid,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    renderer.taskName(task.taskCode, lang: lang),
                    style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    meta,
                    style: t.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
