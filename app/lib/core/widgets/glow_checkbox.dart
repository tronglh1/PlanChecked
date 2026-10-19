import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Round checkbox: checked = orange gradient with white tick and glow.
class GlowCheckbox extends StatelessWidget {
  const GlowCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 28,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: value ? AppGradients.primary : null,
            color: value ? null : AppColors.glassFillSolid,
            border: value
                ? null
                : Border.all(color: AppColors.glassEdge, width: 1.5),
            boxShadow: value ? AppShadows.glow : AppShadows.soft,
          ),
          child: value
              ? Icon(
                  Icons.check_rounded,
                  color: AppColors.textOnPrimary,
                  size: size * 0.65,
                )
              : null,
        ),
      ),
    );
  }
}
