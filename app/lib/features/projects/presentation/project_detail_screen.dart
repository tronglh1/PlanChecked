import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../plan/domain/template_renderer.dart';
import '../../plan/presentation/plan_labels.dart';
import '../../plan/presentation/plan_providers.dart';
import '../../checkin/domain/checkin_models.dart';
import '../../checkin/presentation/checkin_providers.dart';
import '../../gamification/gamification_routes.dart' show GamificationPaths;
import '../../gamification/presentation/gamification_providers.dart';
import '../domain/project.dart';
import '../domain/project_progress.dart';
import 'project_list_screen.dart' show plantGroupLabel;
import 'projects_providers.dart';

enum _Tab { overview, plan, calendar, photos, members }

/// Screen 12 (PRJ-06, TSK-06, HSH-03): overview, plan, history, photos
/// placeholder and assigned members.
class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  _Tab _tab = _Tab.overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(projectDetailProvider(widget.projectId));
    return GlassScaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/garden'),
              ),
            ),
            Expanded(
              child: EmptyState(
                icon: Icons.cloud_off_rounded,
                title: l10n.projectDetailLoadError,
                actionLabel: l10n.commonRetry,
                onAction: () =>
                    ref.invalidate(projectDetailProvider(widget.projectId)),
              ),
            ),
          ],
        ),
        data: _content,
      ),
    );
  }

  Widget _content(ProjectDetail detail) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;
    final p = detail.project;
    final spaceLabel = switch (p.space) {
      Space.indoor => l10n.projectsSpaceIndoor,
      Space.balcony => l10n.projectsSpaceBalcony,
      Space.yard => l10n.projectsSpaceYard,
      Space.rooftop => l10n.projectsSpaceRooftop,
    };
    final sunLabel = switch (p.sunLevel) {
      SunLevel.low => l10n.projectsSunLow,
      SunLevel.medium => l10n.projectsSunMedium,
      SunLevel.high => l10n.projectsSunHigh,
    };
    final meta = [
      l10n.projectDetailMeta(
        plantGroupLabel(l10n, detail.group).isEmpty
            ? detail.plantName(lang)
            : plantGroupLabel(l10n, detail.group),
        p.potCount,
        spaceLabel,
        sunLabel,
      ),
      if (p.isShared) l10n.projectDetailShared,
    ].join(' · ');

    final tabs = <_Tab, String>{
      _Tab.overview: l10n.projectDetailTabOverview,
      _Tab.plan: l10n.projectDetailTabPlan,
      _Tab.calendar: l10n.projectDetailTabCalendar,
      _Tab.photos: l10n.projectDetailTabPhotos,
      _Tab.members: l10n.projectDetailTabMembers,
    };

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        Stack(
          children: [
            Container(
              height: 180,
              margin: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              decoration: BoxDecoration(
                color: AppColors.orangeTint,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: const Center(
                child: Icon(
                  Icons.yard_rounded,
                  size: 56,
                  color: AppColors.orangeTintInk,
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.lg + 8,
              top: AppSpacing.sm + 8,
              child: CircleAvatar(
                backgroundColor: AppColors.glassFillSolid,
                child: IconButton(
                  key: const Key('detail-back'),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/garden'),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                key: const Key('detail-name'),
                style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                meta,
                style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              for (final e in tabs.entries) ...[
                TagChip(
                  key: Key('tab-${e.key.name}'),
                  label: e.value,
                  selected: _tab == e.key,
                  onTap: () {
                    if (e.key == _Tab.calendar) {
                      context.push('/projects/${widget.projectId}/calendar');
                    } else {
                      setState(() => _tab = e.key);
                    }
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: switch (_tab) {
            _Tab.overview => _Overview(detail: detail),
            _Tab.plan => _PlanTab(projectId: widget.projectId),
            _Tab.photos => _Photos(detail: detail),
            _Tab.members => _Members(detail: detail),
            _Tab.calendar => const SizedBox.shrink(),
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: GlowButton(
            key: const Key('checkin-entry'),
            label: l10n.checkinEntryButton,
            icon: Icons.photo_camera_rounded,
            onPressed: () =>
                context.push('/projects/${widget.projectId}/checkin'),
          ),
        ),
      ],
    );
  }
}

class _NoPlan extends StatelessWidget {
  const _NoPlan({required this.projectId, required this.hasDraft});

  final String projectId;
  final bool hasDraft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      key: const Key('detail-no-plan'),
      child: Column(
        children: [
          Text(
            l10n.projectDetailNoPlan,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          GlowButton(
            label: l10n.projectDetailReviewPlan,
            onPressed: () => context.push(
              hasDraft
                  ? '/projects/$projectId/plan'
                  : '/projects/$projectId/generating',
            ),
          ),
        ],
      ),
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview({required this.detail});

  final ProjectDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;
    final id = detail.project.id;
    final today = ref.watch(projectsTodayProvider);
    final bundle = ref.watch(planBundleProvider(id)).value;
    final history = ref.watch(taskHistoryProvider(id)).value ?? const [];
    final renderer = watchRenderer(ref);

    final progress = (bundle == null || !bundle.isApproved)
        ? null
        : ProjectProgress.compute(
            stages: bundle.stages,
            projectStart: detail.project.startDate,
            today: today,
          );
    final doneCount = history.where((h) => h.action == 'done').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (progress == null)
          _NoPlan(projectId: id, hasDraft: bundle != null)
        else ...[
          _StageCard(progress: progress, renderer: renderer, lang: lang),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _Stat(
                key: const Key('stat-done'),
                value: '$doneCount',
                label: l10n.projectDetailStatDone,
              ),
              _Stat(
                key: const Key('stat-checkins'),
                value: '${detail.checkinCount}',
                label: l10n.projectDetailStatCheckins,
              ),
              _Stat(
                key: const Key('stat-milestones'),
                value:
                    '${progress.milestonesReached}/${progress.milestonesTotal}',
                label: l10n.projectDetailStatMilestones,
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _Photos(detail: detail, compact: true),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.projectDetailHistory,
          style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (history.isEmpty)
          Text(
            l10n.projectDetailHistoryEmpty,
            key: const Key('history-empty'),
            style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        for (final h in history.take(10))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.projectDetailHistoryLine(
                      renderer.taskName(h.taskCode, lang: lang),
                      switch (h.action) {
                        'done' => l10n.commonDone,
                        'skip' => l10n.commonSkip,
                        'snooze' => l10n.commonSnooze,
                        final a => a,
                      },
                    ),
                    style: t.bodyMedium,
                  ),
                ),
                Text(
                  shortDate(h.occurrenceDate),
                  style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.progress,
    required this.renderer,
    required this.lang,
  });

  final ProjectProgress progress;
  final TemplateRenderer renderer;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final stage = progress.currentStage;
    final name =
        stage?.label(Localizations.localeOf(context).languageCode) ?? '';
    final milestone = progress.nextMilestone == null
        ? null
        : renderer.render(
            'milestone',
            progress.nextMilestone!,
            'name',
            lang: lang,
          );
    return GlassCard(
      key: const Key('stage-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.projectDetailStageCard(
                    progress.stageNumber,
                    progress.stageCount,
                    name,
                  ),
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                l10n.projectDetailDay(
                  progress.day < 1 ? 0 : progress.day,
                  progress.totalDays,
                ),
                key: const Key('detail-day'),
                style: t.labelMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final s in progress.stages)
                Expanded(
                  flex: s.lengthDays < 1 ? 1 : s.lengthDays,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: s.dayTo < progress.day
                            ? AppColors.green
                            : s.id == stage?.id
                            ? AppColors.green.withValues(alpha: 0.55)
                            : AppColors.greenSoft,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (milestone != null && progress.nextMilestoneDate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.projectDetailNextMilestone(
                milestone,
                shortDate(progress.nextMilestoneDate!),
              ),
              style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: t.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Stage milestone label; once reached it reopens the celebration screen.
class _MilestoneLine extends StatelessWidget {
  const _MilestoneLine({
    required this.projectId,
    required this.code,
    required this.name,
    required this.reached,
  });

  final String projectId;
  final String code;
  final String name;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (!reached) {
      return Text(
        name,
        style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
      );
    }
    return InkWell(
      key: Key('milestone-$code'),
      onTap: () => context.push(GamificationPaths.milestone(projectId, code)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                name,
                style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanTab extends ConsumerWidget {
  const _PlanTab({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;
    final bundle = ref.watch(planBundleProvider(projectId)).value;
    final renderer = watchRenderer(ref);
    final reached = ref.watch(reachedMilestonesProvider(projectId)).value ?? {};
    if (bundle == null) {
      return _NoPlan(projectId: projectId, hasDraft: false);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in bundle.stages)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GlassCard(
              radius: 16,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name.isEmpty ? s.code : s.name,
                          style: t.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.planStageDays(s.dayFrom, s.dayTo),
                          style: t.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (s.milestoneCode != null)
                          _MilestoneLine(
                            projectId: projectId,
                            code: s.milestoneCode!,
                            name: l10n.planStageMilestone(
                              renderer.render(
                                'milestone',
                                s.milestoneCode!,
                                'name',
                                lang: lang,
                              ),
                            ),
                            reached: reached.contains(s.milestoneCode),
                          ),
                      ],
                    ),
                  ),
                  Text(l10n.planStageTaskCount(bundle.tasksOf(s).length)),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        GlowButton(
          key: const Key('open-plan'),
          label: bundle.isApproved
              ? l10n.projectDetailOpenPlan
              : l10n.projectDetailReviewPlan,
          onPressed: () => context.push('/projects/$projectId/plan'),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlowButton(
          key: const Key('open-calendar'),
          label: l10n.projectDetailOpenCalendar,
          variant: GlowButtonVariant.secondary,
          onPressed: () => context.push('/projects/$projectId/calendar'),
        ),
      ],
    );
  }
}

/// Photo timeline: real thumbnails (signed URLs) from the project's check-ins;
/// placeholders while loading or when the URLs cannot be fetched.
class _Photos extends ConsumerWidget {
  const _Photos({required this.detail, this.compact = false});

  final ProjectDetail detail;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final projectId = detail.project.id;
    final timeline = _timelineOrNull(ref, projectId);
    final n =
        timeline?.where((i) => i.path != null).length ??
        detail.photoPaths.length;
    final limit = compact ? 4 : 30;
    final tiles = <Widget>[
      if (timeline != null)
        for (final item in timeline.where((i) => i.path != null).take(limit))
          _PhotoTile(item: item, projectId: projectId)
      else
        for (final _ in detail.photoPaths.take(limit)) const _PhotoTile(),
    ];
    return Column(
      key: const Key('photos-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.projectDetailPhotos,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (n > 0)
              Text(
                l10n.projectDetailPhotoCount(n),
                style: t.labelMedium?.copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (n == 0)
          Text(
            l10n.projectDetailPhotosEmpty,
            style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
          )
        else
          SizedBox(
            height: 84,
            child: ListView(scrollDirection: Axis.horizontal, children: tiles),
          ),
      ],
    );
  }

  /// The loaded timeline, or null while loading / on any error (including a
  /// missing Supabase configuration in tests).
  List<CheckinTimelineItem>? _timelineOrNull(WidgetRef ref, String id) {
    try {
      return ref.watch(checkinTimelineProvider(id)).value;
    } catch (_) {
      return null;
    }
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({this.item, this.projectId});

  final CheckinTimelineItem? item;
  final String? projectId;

  @override
  Widget build(BuildContext context) {
    final url = item?.url;
    const placeholder = Icon(Icons.image_outlined, color: AppColors.green);
    final tile = Container(
      key: item == null ? null : Key('photo-${item!.id}'),
      width: 84,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: url == null
          ? placeholder
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
    final it = item;
    if (it == null || (it.status != 'analyzed' && it.status != 'approved')) {
      return tile;
    }
    return GestureDetector(
      onTap: () => context.push('/projects/$projectId/checkin/${it.id}'),
      child: tile,
    );
  }
}

class _Members extends ConsumerWidget {
  const _Members({required this.detail});

  final ProjectDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final bundle = ref.watch(planBundleProvider(detail.project.id)).value;
    final counts = <String, int>{};
    for (final task in bundle?.tasks ?? const []) {
      final a = task.assigneeId;
      if (a != null) counts[a] = (counts[a] ?? 0) + 1;
    }
    return Column(
      key: const Key('members-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.projectDetailMembers,
          style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (counts.isEmpty)
          Text(
            l10n.projectDetailNoMembers,
            style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        for (final e in counts.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GlassCard(
              radius: 16,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.green,
                    child: Text(
                      _initial(detail.memberNames[e.key]),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      detail.memberNames[e.key] ?? '—',
                      style: t.bodyLarge,
                    ),
                  ),
                  Text(l10n.projectDetailMemberTasks(e.value)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _initial(String? name) => (name == null || name.isEmpty)
      ? '?'
      : name.characters.first.toUpperCase();
}
