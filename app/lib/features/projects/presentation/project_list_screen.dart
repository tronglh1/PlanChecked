import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/date_only.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../plan/presentation/plan_providers.dart';
import '../../plants/domain/plant.dart';
import '../domain/project.dart';
import 'projects_providers.dart';

String plantGroupLabel(AppLocalizations l10n, PlantGroup? g) => switch (g) {
  PlantGroup.rauQua => l10n.filterVeg,
  PlantGroup.cayCanh => l10n.filterOrnamental,
  null => '',
};

/// Screen 06 (PRJ-01, PRJ-04): "Vườn của tôi", the Vườn tab body.
class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  ProjectStatus _filter = ProjectStatus.active;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(projectListProvider);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: l10n.projectsTitle),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: l10n.projectsLoadError,
                  actionLabel: l10n.commonRetry,
                  onAction: () => ref.invalidate(projectListProvider),
                ),
                data: (all) {
                  if (all.isEmpty) {
                    return EmptyState(
                      key: const Key('projects-empty'),
                      icon: Icons.yard_outlined,
                      title: l10n.projectsEmptyTitle,
                      message: l10n.projectsEmptyMessage,
                      actionLabel: l10n.projectsAddNew,
                      onAction: () => context.push('/projects/new/search'),
                    );
                  }
                  int count(ProjectStatus s) => all
                      .where((p) => _statusGroup(p.project.status) == s)
                      .length;
                  final shown = all
                      .where((p) => _statusGroup(p.project.status) == _filter)
                      .toList();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      160,
                    ),
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            TagChip(
                              key: const Key('filter-active'),
                              label: l10n.projectsFilterActive(
                                count(ProjectStatus.active),
                              ),
                              selected: _filter == ProjectStatus.active,
                              onTap: () => setState(
                                () => _filter = ProjectStatus.active,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            TagChip(
                              key: const Key('filter-done'),
                              label: l10n.projectsFilterDone(
                                count(ProjectStatus.done),
                              ),
                              selected: _filter == ProjectStatus.done,
                              onTap: () =>
                                  setState(() => _filter = ProjectStatus.done),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            TagChip(
                              key: const Key('filter-archived'),
                              label: l10n.projectsFilterArchived,
                              selected: _filter == ProjectStatus.archived,
                              onTap: () => setState(
                                () => _filter = ProjectStatus.archived,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (final s in shown)
                        _ProjectCard(
                          summary: s,
                          onTap: () =>
                              context.push('/projects/${s.project.id}'),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: AppSpacing.lg,
          bottom: 96,
          child: GlowButton(
            key: const Key('add-project'),
            label: l10n.projectsAddNew,
            icon: Icons.add_rounded,
            expanded: false,
            onPressed: () => context.push('/projects/new/search'),
          ),
        ),
      ],
    );
  }

  /// Failed projects live under "Đã xong" until the Phase 2 end-of-project
  /// flow (PRJ-07) gives them their own place.
  ProjectStatus _statusGroup(ProjectStatus s) =>
      s == ProjectStatus.failed ? ProjectStatus.done : s;
}

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({required this.summary, required this.onTap});

  final ProjectSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;
    final today = ref.watch(projectsTodayProvider);
    final p = summary.project;
    final progress = summary.progress;
    final day = progress?.day ?? daysBetween(p.startDate, today) + 1;
    final group = plantGroupLabel(l10n, summary.group);
    final kind = l10n.projectsKindLine(
      group.isEmpty ? summary.plantName(lang) : group,
      p.potCount,
      day < 1 ? 1 : day,
    );
    final stage = summary.currentStage;
    final stageLine = progress == null
        ? l10n.projectsNoPlan
        : summary.planStatus == 'draft'
        ? l10n.projectsPlanPending
        : day < 1
        ? l10n.projectsStageBeforeStart
        : (stage?.name.isNotEmpty ?? false)
        ? stage!.name
        : (stage?.code ?? '');
    final photoAt = summary.latestPhotoAt;
    final photoLine = photoAt == null
        ? l10n.projectsNoPhoto
        : () {
            final d = daysBetween(dateOnly(photoAt), today);
            return d <= 0 ? l10n.projectsPhotoToday : l10n.projectsPhotoAgo(d);
          }();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        key: Key('project-${p.id}'),
        radius: 18,
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 88,
              height: 104,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.orangeTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.orangeTintInk,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.projectsLatestPhoto,
                    textAlign: TextAlign.center,
                    style: t.labelSmall?.copyWith(
                      color: AppColors.orangeTintInk,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    kind,
                    style: t.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: AppColors.green),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          stageLine,
                          key: Key('stage-line-${p.id}'),
                          style: t.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppProgressBar(value: progress?.fraction ?? 0, height: 8),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.projectsTasksToday(summary.todayTaskCount),
                          key: Key('today-count-${p.id}'),
                          style: t.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        photoLine,
                        style: t.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
