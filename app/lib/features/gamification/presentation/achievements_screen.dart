import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/achievements_models.dart';
import '../domain/xp.dart';
import 'gamification_providers.dart';

/// Screen 20 (tab 4): XP, level progress, XP tiles, anti-cheat note, badges.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(achievementsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => EmptyState(
        title: l10n.gamLoadError,
        actionLabel: l10n.commonRetry,
        onAction: () => ref.invalidate(achievementsProvider),
      ),
      data: (d) => _Body(data: d),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data});
  final AchievementsData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;
    final nf = NumberFormat.decimalPattern(lang == 'en' ? 'en' : 'vi');
    final p = data.progress;
    final next = p.next;
    final badges = data.badges;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        120,
      ),
      children: [
        Text(
          l10n.gamTitle,
          style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Hero (ink block, spec §1.4).
        Container(
          key: const Key('hero'),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.text,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.gamTotalXp,
                style: t.bodySmall?.copyWith(color: const Color(0xFFB8C4BB)),
              ),
              Text(
                l10n.gamXpUnit(nf.format(data.xpTotal)),
                key: const Key('xp-total'),
                style: t.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.gamLevelLine(
                  p.current.level,
                  data.levelName(p.current, lang),
                ),
                key: const Key('level-line'),
                style: t.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  key: const Key('level-bar'),
                  value: p.fraction,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF2E3B32),
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.orangeSolid,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                next == null
                    ? l10n.gamTopLevel
                    : l10n.gamToNext(
                        p.xpToNext,
                        next.level,
                        data.levelName(next, lang),
                      ),
                key: const Key('level-next'),
                style: t.bodySmall?.copyWith(color: const Color(0xFFD2E6D8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.orangeTint,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 18,
                    color: AppColors.orangeTintInk,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    data.streak > 0
                        ? l10n.gamStreak(data.streak)
                        : l10n.gamStreakNone,
                    key: const Key('streak'),
                    style: t.labelLarge?.copyWith(
                      color: AppColors.orangeTintInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _Tile(
                label: l10n.gamOnTime,
                value: '+${nf.format(data.xp.taskDone)} XP',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _Tile(
                label: l10n.gamCheckin,
                value: '+${nf.format(data.xp.checkin)} XP',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _Tile(
                label: l10n.gamMilestone,
                value: '+${nf.format(data.xp.milestone)} XP',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _Tile(
                key: const Key('tile-today'),
                label: l10n.gamToday,
                value: l10n.gamTodayCap(data.todayOrdinary, XpRules.dailyCap),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // GAM-08 anti-cheat messaging.
        DecoratedBox(
          key: const Key('anti-cheat'),
          decoration: BoxDecoration(
            color: const Color(0xFFE6EEFA),
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.gamAntiCheat(XpRules.dailyCap),
              style: t.bodySmall?.copyWith(color: const Color(0xFF1D4785)),
            ),
          ),
        ),
        if (data.pendingPhotoMilestones > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          DecoratedBox(
            key: const Key('pending-photo'),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D6),
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.gamPendingPhoto(data.pendingPhotoMilestones),
                style: t.bodySmall?.copyWith(color: const Color(0xFF6B4200)),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.gamBadges(data.earnedCount, badges.length),
          key: const Key('badges-header'),
          style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        if (badges.isEmpty)
          Text(
            l10n.gamBadgesEmpty,
            style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
          )
        else
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [for (final b in badges) BadgeTile(badge: b, lang: lang)],
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// One cell of the badge grid. Earned = colored medal; locked = faded with a
/// lock and a "Chưa đạt" caption.
class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.badge, required this.lang});
  final BadgeInfo badge;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final earned = badge.earned;
    return SizedBox(
      key: Key('badge-${badge.code}'),
      width: 76,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: earned ? AppColors.orangeSolid : AppColors.glassFill,
              border: Border.all(
                color: earned ? Colors.white : AppColors.divider,
                width: 2,
              ),
              boxShadow: earned ? AppShadows.soft : null,
            ),
            child: Icon(
              earned ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
              color: earned ? Colors.white : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            badge.name(lang),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.labelSmall?.copyWith(
              color: earned ? AppColors.text : AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!earned)
            Text(
              l10n.gamBadgeLocked,
              style: t.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}
