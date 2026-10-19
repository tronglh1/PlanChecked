import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../plan/domain/enums.dart';
import '../../plan/domain/models.dart';
import '../domain/today_builder.dart';
import '../today_routes.dart';
import 'task_actions.dart';
import 'today_model.dart';
import 'today_providers.dart';

/// Screen 05: `/task/:id`.
class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final model = ref.watch(todayModelProvider);
    final task = model.findTask(taskId);
    final project = model.projectOfTask(taskId);
    return GlassScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/today'),
        ),
      ),
      body: task == null || project == null
          ? EmptyState(
              icon: Icons.search_off_rounded,
              title: model.loaded ? l.taskNotFound : l.commonLoading,
            )
          : _Body(model: model, task: task, project: project),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.model, required this.task, required this.project});

  final TodayModel model;
  final Task task;
  final TodayProject project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final r = model.renderer;
    final lang = model.lang;
    final name = model.taskName(task);
    final stage = model.stageOfProject(project);
    final steps = r.taskSteps(task.taskCode, lang: lang);
    final why = r.taskWhy(task.taskCode, lang: lang);
    final safety =
        r.taskSafety(task.taskCode, lang: lang) ??
        (_isChemical(task.taskCode) ? l.taskSafetyGeneric : null);
    final item = model.itemFor(task.id);
    final actionable =
        item != null &&
        (item.state == TodayState.pending || item.state == TodayState.overdue);
    final assigneeName = task.assigneeId == null
        ? null
        : model.snapshot.memberNames?[task.assigneeId];
    final history = model.historyOf(task.id);
    final reminder = task.reminderTime;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              Text(
                stage == null
                    ? project.name
                    : '${project.name} · ${stage.name}',
                style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                key: const Key('task-title'),
                style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  _Tile(
                    label: l.taskTileWindow,
                    value: _windowShort(l, task.window),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _Tile(label: l.taskTileFrequency, value: _frequency(l, task)),
                  const SizedBox(width: AppSpacing.sm),
                  _Tile(
                    label: l.taskTileReminder,
                    value: reminder != null && reminder.length >= 5
                        ? reminder.substring(0, 5)
                        : l.taskReminderByWindow,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        assigneeName != null && assigneeName.isNotEmpty
                            ? l.taskAssignedTo(assigneeName)
                            : l.taskUnassigned,
                        key: const Key('task-assignee'),
                        style: t.bodyMedium,
                      ),
                    ),
                    TextButton(
                      key: const Key('task-assign'),
                      onPressed: () =>
                          context.push(TodayRoutes.assign(task.id)),
                      child: Text(
                        assigneeName != null && assigneeName.isNotEmpty
                            ? l.taskChange
                            : l.taskAssign,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.taskHowTo,
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (steps.isEmpty)
                      Text(
                        l.taskNoSteps,
                        style: t.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      for (var i = 0; i < steps.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 22,
                                child: Text(
                                  '${i + 1}.',
                                  style: t.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(steps[i], style: t.bodyMedium),
                              ),
                            ],
                          ),
                        ),
                    if (why != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${l.taskWhy} ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: why),
                          ],
                        ),
                        key: const Key('task-why'),
                        style: t.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              if (safety != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  key: const Key('task-safety'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.orangeTint,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.orangeTintInk,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          safety,
                          style: t.bodySmall?.copyWith(
                            color: AppColors.orangeTintInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                l.taskHistory,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (history.isEmpty)
                Text(
                  l.taskHistoryEmpty,
                  key: const Key('task-history-empty'),
                  style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
                )
              else
                for (final h in history) _HistoryRow(row: h),
            ],
          ),
        ),
        _ActionBar(item: item, actionable: actionable, task: task),
      ],
    );
  }
}

bool _isChemical(String code) =>
    RegExp(r'FERT|PEST|SPRAY|FUNG|INSECT|CHEM|HERB').hasMatch(code);

String _windowShort(AppLocalizations l, TaskWindow w) => switch (w) {
  TaskWindow.morning => l.todayWindowMorning.split(' · ').first,
  TaskWindow.afternoon => l.todayWindowAfternoon.split(' · ').first,
  TaskWindow.allDay => l.todayWindowAllDay,
};

String _frequency(AppLocalizations l, Task t) => switch (t.frequency) {
  Frequency.once => l.taskFreqOnce,
  Frequency.daily => l.taskFreqDaily,
  Frequency.everyNDays => l.taskFreqEveryN(t.intervalDays ?? 1),
  Frequency.fixedDate =>
    t.fixedDate != null
        ? shortDate(t.fixedDate!)
        : l.taskFreqFixed(t.intervalDays ?? 1),
};

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        radius: AppRadius.button,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: t.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.row});

  final TaskHistoryRow row;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final label = switch (row.action) {
      TaskAction.done => l.taskHistoryDone,
      TaskAction.skip => l.taskHistorySkip,
      TaskAction.snooze => l.taskHistorySnooze,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            shortDate(row.occurrenceDate),
            style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              row.reason == null ? label : '$label · ${row.reason}',
              style: t.bodyMedium,
            ),
          ),
          if (row.pending)
            const Icon(
              Icons.cloud_upload_outlined,
              size: 16,
              color: AppColors.orangeTintInk,
            ),
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({
    required this.item,
    required this.actionable,
    required this.task,
  });

  final TodayItem? item;
  final bool actionable;
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final it = item;
    final doneLabel = it != null && it.isDone
        ? l.taskHistoryDone
        : l.taskDoneButton(
            actionable
                ? ref.read(todayModelProvider.notifier).previewDone(it!).amount
                : task.xp,
          );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!actionable && it == null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  l.taskNotDueToday,
                  key: const Key('task-not-due'),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            Row(
              children: [
                _SecondaryAction(
                  key: const Key('task-skip'),
                  label: l.commonSkip,
                  onTap: actionable
                      ? () => skipWithSheet(context, ref, it!)
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                _SecondaryAction(
                  key: const Key('task-snooze'),
                  label: l.taskSnooze,
                  onTap: actionable
                      ? () => snoozeWithSheet(context, ref, it!)
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: GlowButton(
                    key: const Key('task-done'),
                    label: doneLabel,
                    onPressed: actionable
                        ? () async {
                            await markDone(context, ref, it!);
                            if (context.mounted && context.canPop()) {
                              context.pop();
                            }
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: SizedBox(
        width: 76,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 15),
          radius: AppRadius.button,
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
