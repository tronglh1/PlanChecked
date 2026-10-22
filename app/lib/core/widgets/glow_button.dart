import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'top_highlight.dart';

enum GlowButtonVariant { primary, secondary }

/// Primary: glossy orange gradient, white text/icon, orange glow.
/// Secondary: white glass pill with dark text, no outline.
class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GlowButtonVariant.primary,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GlowButtonVariant variant;
  final bool expanded;

  bool get _primary => variant == GlowButtonVariant.primary;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = _primary ? AppColors.textOnPrimary : AppColors.text;
    final radius = BorderRadius.circular(AppRadius.button);
    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: fg, fontWeight: AppFontWeights.cta),
          ),
        ),
      ],
    );
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: _primary ? AppGradients.primary : null,
          color: _primary ? null : AppColors.glassFillSolid,
          boxShadow: _primary ? AppShadows.glow : AppShadows.soft,
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: radius,
                onTap: onPressed,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
            if (_primary)
              const TopHighlight(
                radius: AppRadius.button,
                color: AppColors.ctaHighlight,
              ),
          ],
        ),
      ),
    );
  }
}
