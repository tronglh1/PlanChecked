import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.orangeMid,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.orangeMid,
          onPrimary: AppColors.textOnPrimary,
          secondary: AppColors.green,
          surface: Colors.white,
          onSurface: AppColors.text,
          error: AppColors.danger,
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      splashFactory: InkRipple.splashFactory,
    );
    final textTheme = GoogleFonts.beVietnamProTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text);
    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.text,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerColor: AppColors.divider,
    );
  }
}
