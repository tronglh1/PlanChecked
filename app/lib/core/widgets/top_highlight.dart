import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Approximates CSS `inset 0 1px 0 <color>`: a 1px bright line along the top
/// edge, inset from the rounded corners. Flutter has no inset shadow.
/// Place as a child of a [Stack] over the decorated surface.
class TopHighlight extends StatelessWidget {
  const TopHighlight({
    super.key,
    required this.radius,
    this.color = AppColors.glassHighlight,
  });

  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: radius * 0.6,
      right: radius * 0.6,
      height: 1,
      child: IgnorePointer(child: ColoredBox(color: color)),
    );
  }
}
