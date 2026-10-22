import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Glass-styled text field with an optional label above it.
class GlassTextField extends StatelessWidget {
  const GlassTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.maxLength,
    this.inputFormatters,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
    this.semanticLabel,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? prefixIcon;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final TextAlign textAlign;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppRadius.chip);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: c, width: w),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Semantics(
          label: semanticLabel,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            autofocus: autofocus,
            textAlign: textAlign,
            style: t.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorText,
              counterText: '',
              filled: true,
              fillColor: AppColors.glassFillSolid,
              prefixIcon: prefixIcon == null
                  ? null
                  : Icon(prefixIcon, color: AppColors.textSecondary),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              border: border(AppColors.glassEdge),
              enabledBorder: border(AppColors.glassEdge),
              focusedBorder: border(AppColors.orangeMid, 1.5),
              errorBorder: border(AppColors.danger),
              focusedErrorBorder: border(AppColors.danger, 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
