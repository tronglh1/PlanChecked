import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'top_highlight.dart';

/// Option chip. Selected: white->#FFE6D6 gradient, 3px orange ring and ORANGE
/// text (spec §1.2). Green is reserved for progress and the active tab.
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.chip);
    final fg = selected ? AppColors.orangeText : AppColors.text;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: selected ? AppGradients.chipSelected : null,
        color: selected ? null : AppColors.glassFill,
        border: Border.all(
          color: selected
              ? const Color.fromRGBO(255, 255, 255, 0.95)
              : AppColors.glassEdge,
        ),
        boxShadow: selected ? AppShadows.chipSelected : null,
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 16,
                        color: selected
                            ? AppColors.orangeText
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: selected
                            ? AppFontWeights.chipSelected
                            : AppFontWeights.chip,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (selected)
            const TopHighlight(radius: AppRadius.chip, color: Colors.white),
        ],
      ),
    );
  }
}
