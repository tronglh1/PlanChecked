import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/household_models.dart';
import 'household_providers.dart';
import 'household_widgets.dart';

/// Screen 19 (HSH-04): `/task/:taskId/assign`. Owner only.
class AssignTaskScreen extends ConsumerStatefulWidget {
  const AssignTaskScreen({super.key, required this.taskId});
  final String taskId;

  @override
  ConsumerState<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends ConsumerState<AssignTaskScreen> {
  AssignMode? _mode;
  String? _single;
  List<String>? _order;
  bool _busy = false;
  String? _error;

  void _init(AssignableTask task, Household h) {
    if (_mode != null) return;
    final fresh = task.assigneeId == null && task.rotationOrder.isEmpty;
    _mode = fresh ? AssignMode.rotation : task.mode;
    _single = task.assigneeId ?? h.myUserId;
    final ids = {for (final m in h.members) m.userId};
    final existing = [
      for (final id in task.rotationOrder)
        if (ids.contains(id)) id,
    ];
    _order = existing.length >= 2
        ? existing
        : [for (final m in h.members) m.userId];
  }

  String _window(AppLocalizations l10n, String w) => switch (w) {
    'afternoon' => l10n.householdWindowAfternoon,
    'all_day' => l10n.householdWindowAllDay,
    _ => l10n.householdWindowMorning,
  };

  Future<void> _submit(AssignableTask task) async {
    final l10n = AppLocalizations.of(context);
    final mode = _mode!;
    if (mode == AssignMode.rotation && (_order?.length ?? 0) < 2) {
      setState(() => _error = l10n.householdAssignRotationMin);
      return;
    }
    if (mode != AssignMode.rotation && _single == null) {
      setState(() => _error = l10n.householdAssignPickOne);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(householdRepositoryProvider)
          .assignTask(
            taskId: task.taskId,
            mode: mode,
            assigneeId: mode == AssignMode.rotation ? null : _single,
            rotationOrder: mode == AssignMode.rotation ? _order! : const [],
          );
      ref.invalidate(assignableTaskProvider(widget.taskId));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.householdAssignDone)));
      context.go('/household');
    } catch (_) {
      if (mounted) setState(() => _error = l10n.householdErrorGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _tapMember(String id) {
    setState(() {
      _error = null;
      if (_mode == AssignMode.rotation) {
        final order = [..._order!];
        order.contains(id) ? order.remove(id) : order.add(id);
        _order = order;
      } else {
        _single = id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final taskAsync = ref.watch(assignableTaskProvider(widget.taskId));
    final household = ref.watch(householdProvider).value;

    Widget body;
    if (taskAsync.isLoading || ref.watch(householdProvider).isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (taskAsync.hasError) {
      body = EmptyState(
        title: l10n.householdLoadError,
        actionLabel: l10n.commonRetry,
        onAction: () => ref.invalidate(assignableTaskProvider(widget.taskId)),
      );
    } else if (taskAsync.value == null) {
      body = EmptyState(title: l10n.householdAssignNoTask);
    } else if (household == null) {
      body = EmptyState(
        key: const Key('assign-need-household'),
        icon: Icons.family_restroom_rounded,
        title: l10n.householdAssignNeedHousehold,
      );
    } else {
      final task = taskAsync.value!;
      if (!task.canManage || !household.isOwner) {
        body = EmptyState(
          key: const Key('assign-owner-only'),
          icon: Icons.lock_outline_rounded,
          title: l10n.householdAssignOwnerOnly,
        );
      } else {
        _init(task, household);
        body = _form(context, l10n, t, task, household);
      }
    }

    return GlassScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/today'),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        title: Text(
          l10n.householdAssignTitle,
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: body,
    );
  }

  Widget _form(
    BuildContext context,
    AppLocalizations l10n,
    TextTheme t,
    AssignableTask task,
    Household h,
  ) {
    final mode = _mode!;
    final rotation = mode == AssignMode.rotation;
    final title = task.title ?? task.taskCode;
    final nameOf = {for (final m in h.members) m.userId: m.name};
    final meta = [
      task.projectName,
      _window(l10n, task.window),
      if (task.intervalDays != null)
        l10n.householdEveryDays(task.intervalDays!),
    ].join(' · ');
    final hint = switch (mode) {
      AssignMode.rotation => l10n.householdAssignHintRotation(
        [for (final id in _order!) nameOf[id] ?? ''].join(' → '),
      ),
      AssignMode.series => l10n.householdAssignHintSeries(
        title,
        nameOf[_single] ?? '',
      ),
      AssignMode.once => l10n.householdAssignHintOnce(
        title,
        nameOf[_single] ?? '',
      ),
    };
    final today = DateTime.now();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                key: const Key('assign-task-title'),
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                meta,
                style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.householdAssignHow,
          style: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            TagChip(
              key: const Key('mode-once'),
              label: l10n.householdModeOnce,
              selected: mode == AssignMode.once,
              onTap: () => setState(() => _mode = AssignMode.once),
            ),
            TagChip(
              key: const Key('mode-series'),
              label: l10n.householdModeSeries,
              selected: mode == AssignMode.series,
              onTap: () => setState(() => _mode = AssignMode.series),
            ),
            TagChip(
              key: const Key('mode-rotation'),
              label: l10n.householdModeRotation,
              selected: mode == AssignMode.rotation,
              onTap: () => setState(() => _mode = AssignMode.rotation),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          rotation ? l10n.householdAssignOrder : l10n.householdAssignTo,
          style: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final m in h.members) ...[
          _PersonRow(
            key: Key('person-${m.userId}'),
            member: m,
            isMe: m.userId == h.myUserId,
            marker: rotation
                ? (_order!.contains(m.userId)
                      ? '${_order!.indexOf(m.userId) + 1}'
                      : null)
                : (_single == m.userId ? '✓' : null),
            awayText: m.isAway(today)
                ? l10n.householdAssignAwayUntil(
                    DateFormat('dd/MM').format(m.awayUntil!),
                  )
                : null,
            onTap: () => _tapMember(m.userId),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFE6EEFA),
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              hint,
              key: const Key('assign-hint'),
              style: t.bodySmall?.copyWith(color: const Color(0xFF1D4785)),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            key: const Key('assign-error'),
            style: t.bodySmall?.copyWith(color: AppColors.danger),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        GlowButton(
          key: const Key('assign-submit'),
          label: l10n.householdAssignTitle,
          onPressed: _busy ? null : () => _submit(task),
        ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    super.key,
    required this.member,
    required this.isMe,
    required this.marker,
    required this.onTap,
    this.awayText,
  });
  final HouseholdMember member;
  final bool isMe;
  final String? marker;
  final String? awayText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          MemberAvatar(name: member.name, radius: 18),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? l10n.householdYou(member.name) : member.name,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  awayText ?? l10n.householdTasksWeek(member.tasksThisWeek),
                  style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (marker != null)
            CircleAvatar(
              key: const Key('marker'),
              radius: 14,
              backgroundColor: AppColors.orangeMid,
              child: Text(
                marker!,
                style: t.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
