import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'glass_config.dart';
import 'top_highlight.dart';

/// Frosted glass surface. [blur] null = follow [GlassConfig]; false = solid
/// translucent fill without BackdropFilter (low-end devices).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.radius = AppRadius.card,
    this.blur,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool? blur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final useBlur = blur ?? GlassConfig.blurOf(context);
    final borderRadius = BorderRadius.circular(radius);
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: content,
        ),
      );
    }
    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: useBlur ? AppColors.glassFill : AppColors.glassFillSolid,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.glassEdge, width: 1),
      ),
      child: content,
    );
    final surface = Stack(
      fit: StackFit.passthrough,
      children: [
        decorated,
        TopHighlight(radius: radius),
      ],
    );
    final clipped = ClipRRect(
      borderRadius: borderRadius,
      child: useBlur
          ? BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppBlur.sigma,
                sigmaY: AppBlur.sigma,
              ),
              child: surface,
            )
          : surface,
    );
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: AppShadows.soft,
      ),
      child: clipped,
    );
  }
}
