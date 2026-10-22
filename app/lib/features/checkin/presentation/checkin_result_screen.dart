import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../gamification/gamification_routes.dart' show GamificationPaths;
import '../../plan/domain/plan_bundle.dart';
import '../../plan/domain/template_renderer.dart';
import '../../plan/presentation/plan_labels.dart';
import '../../plan/presentation/plan_providers.dart';
import '../../projects/presentation/projects_providers.dart';
import '../domain/checkin_models.dart';
import 'checkin_labels.dart';
import 'checkin_providers.dart';

/// Screen 14 "Kết quả check-in" (CHK-04, CHK-05, AI-02): estimated stage,
/// health, suspected problems with confidence bands, safe actions from
/// templates and the proposed plan changes the user approves or skips.
class CheckinResultScreen extends ConsumerStatefulWidget {
  const CheckinResultScreen({
    super.key,
    required this.projectId,
    required this.checkinId,
  });

  final String projectId;
  final String checkinId;

  @override
  ConsumerState<CheckinResultScreen> createState() =>
      _CheckinResultScreenState();
}

class _CheckinResultScreenState extends ConsumerState<CheckinResultScreen> {
  /// Ids of the changes the user keeps ticked; null until first build.
  Set<String>? _selected;
  bool _applying = false;
  bool _failed = false;

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/projects/${widget.projectId}');
    }
  }

  Future<void> _apply(CheckinResult r) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ids = (_selected ?? {}).toList();
    setState(() {
      _applying = true;
      _failed = false;
    });
    try {
      await ref
          .read(checkinRepositoryProvider)
          .applyChanges(widget.checkinId, ids);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _failed = true;
      });
      return;
    }
    ref.invalidate(planBundleProvider(widget.projectId));
    ref.invalidate(projectDetailProvider(widget.projectId));
    ref.invalidate(checkinTimelineProvider(widget.projectId));
    ref.invalidate(checkinResultProvider(widget.checkinId));
    if (ids.isNotEmpty) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.checkinApplied(ids.length))),
      );
    }
    if (!mounted) return;
    // GAM-03: a milestone confirmed by this check-in opens the celebration
    // screen (replacing this one, so closing it returns to the project).
    final code = r.milestoneSeen?.code;
    if (r.milestoneIsNew && !r.applied && code != null) {
      context.pushReplacement(
        GamificationPaths.milestone(widget.projectId, code),
      );
      return;
    }
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(checkinResultProvider(widget.checkinId));
    return GlassScaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _leave,
              ),
            ),
            Expanded(
              child: EmptyState(
                icon: Icons.cloud_off_rounded,
                title: l10n.checkinResultLoadError,
                actionLabel: l10n.commonRetry,
                onAction: () =>
                    ref.invalidate(checkinResultProvider(widget.checkinId)),
              ),
            ),
          ],
        ),
        data: _content,
      ),
    );
  }

  Widget _content(CheckinResult r) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;
    final renderer = watchRenderer(ref);
    final bundle = ref.watch(planBundleProvider(widget.projectId)).value;
    final answered = r.applied || r.changes.any((c) => c.accepted);
    final selected = _selected ??= {
      if (!answered)
        for (final c in r.changes) c.id,
    };

    String? stageName;
    final prefix = r.stagePrefix;
    if (prefix != null && bundle != null) {
      for (final s in bundle.stages) {
        if (s.code == prefix) stageName = s.name;
      }
    }
    final stageText = switch ((stageName, r.stagePhase)) {
      (null, _) => r.stageCode,
      (final n?, 'early') => l10n.checkinStageEarly(n),
      (final n?, 'mid') => l10n.checkinStageMid(n),
      (final n?, 'late') => l10n.checkinStageLate(n),
      (final n?, _) => n,
    };

    final count = selected.length;
    final hasChanges = r.changes.isNotEmpty && !answered;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  IconButton(
                    key: const Key('result-back'),
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _leave,
                  ),
                  Expanded(
                    child: Text(
                      l10n.checkinResultTitle,
                      style: t.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (r.xpTotal != null)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: TagChip(
                        key: const Key('xp-chip'),
                        label: l10n.checkinXpChip(30),
                        selected: true,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                key: const Key('summary-card'),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (r.thumbUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.md),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            r.thumbUrl!,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox(
                              width: 76,
                              height: 76,
                              child: Icon(Icons.image_outlined),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.checkinAiLabel,
                            key: const Key('ai-label'),
                            style: t.labelMedium?.copyWith(
                              color: AppColors.orangeTintInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          if (stageText != null)
                            Text(
                              l10n.checkinStageLine(
                                stageText,
                                (r.stageConfidence * 100).round(),
                              ),
                              key: const Key('stage-line'),
                              style: t.bodyMedium,
                            ),
                          if (r.health != null)
                            Text(
                              l10n.checkinHealthLine(
                                healthLabel(l10n, r.health) ?? '',
                              ),
                              key: const Key('health-line'),
                              style: t.bodyMedium,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (r.issues.isEmpty)
                Text(
                  l10n.checkinNoIssues,
                  key: const Key('no-issues'),
                  style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
                )
              else ...[
                Text(
                  l10n.checkinIssuesTitle,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final issue in r.issues)
                  _IssueCard(issue: issue, renderer: renderer, lang: lang),
              ],
              if (r.milestoneSeen != null && r.milestoneIsNew)
                Container(
                  key: const Key('milestone-note'),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.greenTint,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Text(
                    l10n.checkinMilestoneNote(
                      renderer.render(
                        'milestone',
                        r.milestoneSeen!.code,
                        'name',
                        lang: lang,
                      ),
                    ),
                    style: t.bodyMedium?.copyWith(color: AppColors.greenDeep),
                  ),
                ),
              if (r.lowConfidence)
                Container(
                  key: const Key('low-confidence'),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.orangeTint,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.checkinLowConfTitle,
                        style: t.titleSmall?.copyWith(
                          color: AppColors.orangeTintInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.checkinLowConfBody,
                        style: t.bodyMedium?.copyWith(
                          color: AppColors.orangeTintInk,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                l10n.checkinChangesTitle,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (r.changes.isEmpty)
                Text(
                  l10n.checkinNoChanges,
                  key: const Key('no-changes'),
                  style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
                )
              else ...[
                if (answered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      l10n.checkinAlreadyAnswered,
                      key: const Key('already-answered'),
                      style: t.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                for (final c in r.changes)
                  _ChangeRow(
                    change: c,
                    renderer: renderer,
                    lang: lang,
                    bundle: bundle,
                    checked: answered ? c.accepted : selected.contains(c.id),
                    enabled: !answered && !_applying,
                    onChanged: (v) => setState(() {
                      v ? selected.add(c.id) : selected.remove(c.id);
                    }),
                  ),
              ],
              if (_failed)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    l10n.checkinApplyError,
                    key: const Key('apply-error'),
                    style: t.bodyMedium?.copyWith(color: AppColors.danger),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              Expanded(
                child: GlowButton(
                  key: const Key('later'),
                  label: l10n.checkinLater,
                  variant: GlowButtonVariant.secondary,
                  onPressed: _applying ? null : _leave,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: GlowButton(
                  key: const Key('apply'),
                  label: !hasChanges
                      ? l10n.checkinDone
                      : count == 0
                      ? l10n.checkinSkipAll
                      : l10n.checkinApply(count),
                  onPressed: _applying
                      ? null
                      : hasChanges
                      ? () => _apply(r)
                      : _leave,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.issue,
    required this.renderer,
    required this.lang,
  });

  final CheckinIssue issue;
  final TemplateRenderer renderer;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final why = renderer.lookup('problem', issue.code, 'why', lang: lang);
    final actions = [
      for (final code in issue.actions)
        (
          name: renderer.taskName(code, lang: lang),
          safety: renderer.taskSafety(code, lang: lang),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        key: Key('issue-${issue.code}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.orangeMid,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    renderer.problemName(issue.code, lang: lang),
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              bandLabel(l10n, issue.confidence),
              key: Key('band-${issue.code}'),
              style: t.labelMedium?.copyWith(color: AppColors.orangeTintInk),
            ),
            if (why != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(why, style: t.bodyMedium),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.checkinSafeActions,
                style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              for (final a in actions)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: a.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (a.safety != null) TextSpan(text: ' · ${a.safety}'),
                      ],
                    ),
                    style: t.bodyMedium,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({
    required this.change,
    required this.renderer,
    required this.lang,
    required this.bundle,
    required this.checked,
    required this.enabled,
    required this.onChanged,
  });

  final ProposedChange change;
  final TemplateRenderer renderer;
  final String lang;
  final PlanBundle? bundle;
  final bool checked;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  String _everyLabel(AppLocalizations l10n, int? n) => switch (n) {
    null => '',
    0 => l10n.planFreqOnce,
    1 => l10n.planFreqDaily,
    _ => l10n.planFreqEveryN(n),
  };

  String _title(AppLocalizations l10n) {
    final task = change.task == null
        ? ''
        : renderer.taskName(change.task!, lang: lang);
    switch (change.kind) {
      case ChangeKind.add:
      case ChangeKind.remove:
        return task;
      case ChangeKind.changeFreq:
        final to = _everyLabel(l10n, change.everyD);
        final current = bundle?.tasks
            .where((x) => x.taskCode == change.task)
            .firstOrNull;
        return current == null
            ? l10n.checkinChangeFreqTo(task, to)
            : l10n.checkinChangeFreq(task, frequencyLabel(l10n, current), to);
      case ChangeKind.shift:
        final ms = change.milestone == null
            ? ''
            : renderer.render(
                'milestone',
                change.milestone!,
                'name',
                lang: lang,
              );
        return l10n.checkinChangeShift(
          ms,
          change.to == null ? '' : shortDate(change.to!),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final kind = switch (change.kind) {
      ChangeKind.add => l10n.checkinKindAdd,
      ChangeKind.changeFreq => l10n.checkinKindFreq,
      ChangeKind.shift => l10n.checkinKindShift,
      ChangeKind.remove => l10n.checkinKindRemove,
    };
    final why = change.why == null
        ? null
        : renderer.reasonText(change.why!, lang: lang);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        key: Key('change-${change.id}'),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            GlowCheckbox(
              key: Key('check-${change.id}'),
              value: checked,
              onChanged: enabled ? onChanged : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kind,
                    style: t.labelSmall?.copyWith(
                      color: AppColors.orangeTintInk,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    _title(l10n),
                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (why != null)
                    Text(
                      why,
                      style: t.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              checked ? l10n.checkinChangeApprove : l10n.checkinChangeSkip,
              style: t.labelMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
