import 'dart:ui';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import '../widgets/glass_config.dart';

class _TabSpec {
  const _TabSpec(this.icon, this.activeIcon);
  final IconData icon;
  final IconData activeIcon;
}

const _tabs = [
  _TabSpec(Icons.today_outlined, Icons.today_rounded),
  _TabSpec(Icons.yard_outlined, Icons.yard_rounded),
  _TabSpec(Icons.family_restroom_outlined, Icons.family_restroom_rounded),
  _TabSpec(Icons.emoji_events_outlined, Icons.emoji_events_rounded),
  _TabSpec(Icons.settings_outlined, Icons.settings_rounded),
];

/// Floating glass bottom bar. Active tab is green (allowed: active tab).
class GlassBottomBar extends StatelessWidget {
  const GlassBottomBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    this.blur,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final bool? blur;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.tabToday,
      l10n.tabGarden,
      l10n.tabFamily,
      l10n.tabAchievements,
      l10n.tabSettings,
    ];
    final useBlur = blur ?? GlassConfig.blurOf(context);
    final radius = BorderRadius.circular(AppRadius.bar);
    final bar = DecoratedBox(
      decoration: BoxDecoration(
        color: useBlur ? AppColors.glassFill : AppColors.glassFillSolid,
        borderRadius: radius,
        border: Border.all(color: AppColors.glassEdge),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Expanded(
              child: _Item(
                label: labels[i],
                icon: i == currentIndex ? _tabs[i].activeIcon : _tabs[i].icon,
                selected: i == currentIndex,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: AppShadows.soft,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: useBlur
                ? BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: AppBlur.sigma,
                      sigmaY: AppBlur.sigma,
                    ),
                    child: bar,
                  )
                : bar,
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.bar),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected
                      ? AppFontWeights.tabActive
                      : AppFontWeights.tabInactive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
