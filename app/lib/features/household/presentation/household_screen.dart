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

/// Screen 17 (tab 3): members, shared projects, realtime activity.
class HouseholdScreen extends ConsumerWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(householdProvider);
    final pad = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
      120,
    );
    return Material(
      type: MaterialType.transparency,
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => EmptyState(
          title: l10n.householdLoadError,
          actionLabel: l10n.commonRetry,
          onAction: () => ref.read(householdProvider.notifier).reload(),
        ),
        data: (h) {
          if (h == null) {
            return ListView(
              padding: pad,
              children: [
                Text(
                  l10n.tabFamily,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.householdNoneTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.householdNoneSub,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
                CreateHouseholdCard(
                  onCreated: () => context.push('/household/invite'),
                ),
                const SizedBox(height: AppSpacing.md),
                JoinCodeCard(
                  initialCode: ref.watch(pendingJoinCodeProvider),
                  onJoined: () {},
                ),
              ],
            );
          }
          return _HouseholdBody(household: h, padding: pad);
        },
      ),
    );
  }
}

class _HouseholdBody extends ConsumerWidget {
  const _HouseholdBody({required this.household, required this.padding});
  final Household household;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final h = household;
    final projects =
        ref.watch(householdProjectsProvider(h.id)).value ?? const [];
    final shared = projects.where((p) => p.sharedWithHousehold).toList();
    final activity = ref.watch(householdActivityProvider(h.id));
    final names = {for (final m in h.members) m.userId: m.name};
    final projectNames = {for (final p in projects) p.id: p.name};

    return ListView(
      padding: padding,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.householdEyebrow(h.members.length),
                    style: t.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    h.name,
                    style: t.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Members cannot invite (spec §6.6, backend gap 57).
            if (h.isOwner)
              GlowButton(
                key: const Key('invite-button'),
                label: l10n.householdInvite,
                expanded: false,
                onPressed: () => context.push('/household/invite'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final m in h.members) ...[
          _MemberTile(household: h, member: m),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.householdSharedProjects,
          style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (shared.isEmpty)
          Text(
            l10n.householdNoShared,
            style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final p in shared) TagChip(label: p.name)],
          ),
        if (h.isOwner) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            key: const Key('share-more'),
            onPressed: () => _openShareSheet(context, h),
            child: Text(l10n.householdShareMore),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.householdActivity,
          style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        activity.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Text(l10n.householdLoadError),
          data: (items) {
            if (items.isEmpty) {
              return Text(
                l10n.householdActivityEmpty,
                style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
              );
            }
            return GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _ActivityRow(
                      item: items[i],
                      names: names,
                      projectNames: projectNames,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _openShareSheet(BuildContext context, Household h) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (_) => _ShareProjectsSheet(household: h),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({required this.household, required this.member});
  final Household household;
  final HouseholdMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final isMe = member.userId == household.myUserId;
    final away = member.isAway(DateTime.now());
    final meta = [
      l10n.householdTasksWeek(member.tasksThisWeek),
      if (away) l10n.householdAway,
    ].join(' · ');
    return GlassCard(
      key: Key('member-${member.userId}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          MemberAvatar(name: member.name),
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
                  meta,
                  style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          RoleChip(role: member.role),
          if (household.isOwner && !isMe)
            PopupMenuButton<String>(
              key: Key('member-menu-${member.userId}'),
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (_) => _remove(context, ref),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'remove',
                  child: Text(l10n.householdRemoveMember),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.householdRemoveTitle(member.name)),
        content: Text(l10n.householdRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            key: const Key('remove-confirm'),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.householdRemoveMember),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(householdRepositoryProvider).removeMember(member.userId);
      await ref.read(householdProvider.notifier).reload();
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.householdErrorGeneric)),
      );
    }
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.item,
    required this.names,
    required this.projectNames,
  });
  final ActivityItem item;
  final Map<String, String> names;
  final Map<String, String> projectNames;

  String _text(AppLocalizations l10n) {
    final who = names[item.actorId] ?? l10n.householdSomeone;
    final project =
        projectNames[item.projectId] ?? item.payload['name'] as String?;
    final base = switch (item.kind) {
      'task_done' => l10n.householdActTaskDone(who),
      'checkin' => l10n.householdActCheckin(who),
      'milestone' => l10n.householdActMilestone(who),
      'member_joined' => l10n.householdActJoined(who),
      'member_left' => l10n.householdActLeft(who),
      'project_shared' => l10n.householdActShared(who, project ?? ''),
      _ => who,
    };
    if (project != null && item.kind != 'project_shared') {
      return l10n.householdActProject(base, project);
    }
    return base;
  }

  String _time() {
    final now = DateTime.now();
    final c = item.createdAt;
    final sameDay =
        c.year == now.year && c.month == now.month && c.day == now.day;
    return DateFormat(sameDay ? 'HH:mm' : 'dd/MM HH:mm').format(c);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Text(_text(l10n), style: t.bodyMedium)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _time(),
            style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// HSH-03: Owner shares/unshares their own projects.
class _ShareProjectsSheet extends ConsumerWidget {
  const _ShareProjectsSheet({required this.household});
  final Household household;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(householdProjectsProvider(household.id));
    final mine = (async.value ?? const <ShareableProject>[])
        .where((p) => p.ownerId == household.myUserId)
        .toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.householdShareTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            if (async.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (mine.isEmpty)
              Text(l10n.householdShareNoProjects)
            else
              for (final p in mine)
                SwitchListTile(
                  key: Key('share-${p.id}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.name),
                  subtitle: Text(
                    p.sharedWithHousehold
                        ? l10n.householdUnshare
                        : l10n.householdShare,
                  ),
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.green,
                  value: p.sharedWithHousehold,
                  onChanged: (v) async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ref
                          .read(householdRepositoryProvider)
                          .setProjectHousehold(p.id, v ? household.id : null);
                      ref.invalidate(householdProjectsProvider(household.id));
                    } catch (_) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.householdErrorGeneric)),
                      );
                    }
                  },
                ),
          ],
        ),
      ),
    );
  }
}
