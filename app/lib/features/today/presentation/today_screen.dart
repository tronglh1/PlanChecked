import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../plan/domain/enums.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/checkin_due.dart';
import '../domain/today_builder.dart';
import 'task_actions.dart';
import 'today_model.dart';
import 'today_providers.dart';
import '../today_routes.dart';

/// Screen 04 (tab 1).
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _promptChecked = false;

  Future<void> _maybePromptForReminders() async {
    if (_promptChecked) return;
    _promptChecked = true;
    final perm = ref.read(reminderPermissionProvider);
    if (!await perm.shouldPrompt() || !mounted) return;
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.todayPermTitle),
        content: Text(l.todayPermBody),
        actions: [
          TextButton(
            key: const Key('perm-later'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.todayPermLater),
          ),
          TextButton(
            key: const Key('perm-allow'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.todayPermAllow),
          ),
        ],
      ),
    );
    if (ok == true) {
      await perm.request();
    } else {
      await perm.markAsked();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final model = ref.watch(todayModelProvider);
    final grouping = ref.watch(todayGroupingProvider);

    // Ask for notification permission the first time Today has tasks.
    if (model.loaded && model.hasData && !_promptChecked) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybePromptForReminders(),
      );
    }

    final name = ref.watch(profileProvider).value?.displayName.trim();
    final groups = grouping == TodayGrouping.window
        ? model.view.byWindow()
        : model.view.byProject();

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(todayModelProvider.notifier).syncNow(force: true),
      child: ListView(
        key: const Key('today-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          120,
        ),
        children: [
          _Header(model: model, name: name),
          const SizedBox(height: AppSpacing.md),
          _ProgressCard(model: model),
          if (model.pendingCount > 0 && model.offline) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.todayOfflineBanner(model.pendingCount),
              key: const Key('offline-banner'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.orangeTintInk),
            ),
          ],
          for (final c in model.checkins) ...[
            const SizedBox(height: AppSpacing.md),
            _CheckinBanner(due: c),
          ],
          const SizedBox(height: AppSpacing.lg),
          _GroupToggle(grouping: grouping),
          const SizedBox(height: AppSpacing.md),
          if (!model.loaded)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (model.view.items.isEmpty)
            SizedBox(
              height: 260,
              child: EmptyState(
                icon: Icons.wb_sunny_outlined,
                title: l.todayEmptyTitle,
                message: l.todayEmptyBody,
              ),
            )
          else
            for (final g in groups) ...[
              _GroupLabel(group: g),
              for (final item in g.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _TaskRow(item: item, model: model),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.model, this.name});

  final TodayModel model;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final weekday = _weekday(l, model.today.weekday);
    final eyebrow = '$weekday, ${shortDate(model.today)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          key: const Key('today-eyebrow'),
          style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                l.todayTitle,
                style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            _XpChip(xp: model.earnedXpToday),
          ],
        ),
        if (name != null && name!.isNotEmpty)
          Text(
            l.todayGreeting(name!),
            key: const Key('today-greeting'),
            style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
      ],
    );
  }
}

String _weekday(AppLocalizations l, int w) => switch (w) {
  1 => l.todayWd1,
  2 => l.todayWd2,
  3 => l.todayWd3,
  4 => l.todayWd4,
  5 => l.todayWd5,
  6 => l.todayWd6,
  _ => l.todayWd7,
};

class _XpChip extends StatelessWidget {
  const _XpChip({required this.xp});

  final int xp;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.greenTint,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        l.todayXpChip(xp),
        key: const Key('xp-chip'),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.greenDeep,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.model});

  final TodayModel model;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final v = model.view;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.todayProgress(v.doneCount, v.totalCount),
            key: const Key('today-progress'),
            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            l.todayXpHint,
            style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppProgressBar(value: v.progress, height: 8),
        ],
      ),
    );
  }
}

class _CheckinBanner extends StatelessWidget {
  const _CheckinBanner({required this.due});

  final CheckinDue due;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Material(
      color: AppColors.orangeTint,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        key: Key('checkin-${due.projectId}'),
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: () => context.push(TodayRoutes.checkin(due.projectId)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.orangeTintInk,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.todayCheckinDueTitle,
                      style: t.titleSmall?.copyWith(
                        color: AppColors.orangeTintInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l.todayCheckinDueBody(due.projectName),
                      style: t.bodySmall?.copyWith(
                        color: AppColors.orangeTintInk,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.orangeTintInk,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupToggle extends ConsumerWidget {
  const _GroupToggle({required this.grouping});

  final TodayGrouping grouping;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    void set(TodayGrouping g) =>
        ref.read(todayGroupingProvider.notifier).set(g);
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        TagChip(
          key: const Key('group-window'),
          label: l.todayGroupByWindow,
          selected: grouping == TodayGrouping.window,
          onTap: () => set(TodayGrouping.window),
        ),
        TagChip(
          key: const Key('group-project'),
          label: l.todayGroupByProject,
          selected: grouping == TodayGrouping.project,
          onTap: () => set(TodayGrouping.project),
        ),
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.group});

  final TodayGroup group;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final label = group.overdue
        ? l.todayOverdue
        : group.window != null
        ? windowLabel(l, group.window!)
        : (group.projectName ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label.toUpperCase(),
        key: Key('group-${group.overdue ? 'overdue' : group.window?.db ?? group.projectId}'),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: group.overdue ? AppColors.danger : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _TaskRow extends ConsumerWidget {
  const _TaskRow({required this.item, required this.model});

  final TodayItem item;
  final TodayModel model;

  bool get _actionable =>
      item.state == TodayState.pending || item.state == TodayState.overdue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final title = model.taskName(item.task);
    final reminder = item.task.reminderTime;
    final metaParts = [
      item.projectName,
      if (reminder != null && reminder.length >= 5) reminder.substring(0, 5),
    ];
    final skipped = item.state == TodayState.skipped;
    final assignee = item.task.assigneeId == null
        ? null
        : model.snapshot.memberNames?[item.task.assigneeId];

    final card = GlassCard(
      key: Key('row-${item.task.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      radius: AppRadius.button,
      child: Row(
        children: [
          Semantics(
            label: l.todayMarkDone,
            child: GlowCheckbox(
              key: Key('done-${item.task.id}'),
              size: 32,
              value: item.isDone,
              onChanged: _actionable ? (_) => markDone(context, ref, item) : null,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: InkWell(
              onTap: () => context.push(TodayRoutes.task(item.task.id)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: skipped || item.isDone
                          ? TextDecoration.lineThrough
                          : null,
                      color: skipped || item.isDone
                          ? AppColors.textSecondary
                          : AppColors.text,
                    ),
                  ),
                  Text(
                    skipped
                        ? '${item.projectName} · ${l.todaySkippedLabel}'
                        : metaParts.join(' · '),
                    style: t.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (item.pendingSync)
            Tooltip(
              message: l.todayPendingSync,
              child: Icon(
                Icons.cloud_upload_outlined,
                key: Key('pending-${item.task.id}'),
                size: 18,
                color: AppColors.orangeTintInk,
              ),
            ),
          if (assignee != null && assignee.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.greenTint,
                child: Text(
                  assignee.characters.first.toUpperCase(),
                  style: t.labelMedium?.copyWith(color: AppColors.greenDeep),
                ),
              ),
            ),
          if (_actionable)
            PopupMenuButton<TaskAction>(
              key: Key('menu-${item.task.id}'),
              tooltip: l.todayMenu,
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textSecondary,
              ),
              onSelected: (a) {
                if (a == TaskAction.skip) skipWithSheet(context, ref, item);
                if (a == TaskAction.snooze) snoozeWithSheet(context, ref, item);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: TaskAction.skip,
                  child: Text(l.commonSkip),
                ),
                PopupMenuItem(
                  value: TaskAction.snooze,
                  child: Text(l.taskSnooze),
                ),
              ],
            ),
        ],
      ),
    );

    if (!_actionable) return card;
    return Dismissible(
      key: ValueKey('dismiss-${item.occurrence.key}'),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await skipWithSheet(context, ref, item);
        } else {
          await snoozeWithSheet(context, ref, item);
        }
        return false;
      },
      background: _SwipeBg(
        icon: Icons.skip_next_rounded,
        label: l.commonSkip,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _SwipeBg(
        icon: Icons.schedule_rounded,
        label: l.taskSnooze,
        alignment: Alignment.centerRight,
      ),
      child: card,
    );
  }
}

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.orangeTint,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.orangeTintInk),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: const TextStyle(color: AppColors.orangeTintInk)),
        ],
      ),
    );
  }
}
