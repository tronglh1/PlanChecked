import 'package:flutter/material.dart';

/// Design tokens for the light frosted-glass look. Screens must use these
/// instead of ad-hoc colors.
class AppColors {
  const AppColors._();

  // Background gradient (cream -> mint)
  static const Color bgTop = Color(0xFFFFF8EC);
  static const Color bgMid = Color(0xFFF4F7E8);
  static const Color bgBottom = Color(0xFFDFF3E6);

  // Blobs
  static const Color blobYellow = Color(0xFFFFE9A8);
  static const Color blobPeach = Color(0xFFFFCFB0);
  static const Color blobMint = Color(0xFFBFEBD2);

  // Text
  static const Color text = Color(0xFF16211A);
  static const Color textSecondary = Color(0xFF5B6A60);
  static const Color textOnPrimary = Colors.white;

  // Primary orange gradient
  static const Color orangeLight = Color(0xFFFFB070);
  static const Color orangeMid = Color(0xFFFF7F32);
  static const Color orangeDark = Color(0xFFF2600F);
  static const Color orangeGlow = Color(0x66FF7F32);

  // Green: ONLY progress, selected state, active tab.
  static const Color green = Color(0xFF1E6B43);
  static const Color greenSoft = Color(0x261E6B43);

  // Glass
  static const Color glassFill = Color.fromRGBO(255, 255, 255, 0.62);
  static const Color glassEdge = Color.fromRGBO(255, 255, 255, 0.85);
  static const Color glassFillSolid = Color(0xF5FFFFFF); // blur disabled
  static const Color glassShadow = Color(0x14163A22);

  // Chip / misc
  static const Color cream = Color(0xFFFFF4E0);
  static const Color divider = Color(0x1F16211A);
  static const Color danger = Color(0xFFC0392B);
}

class AppGradients {
  const AppGradients._();

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bgTop, AppColors.bgMid, AppColors.bgBottom],
  );

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.orangeLight, AppColors.orangeMid, AppColors.orangeDark],
  );

  static const LinearGradient chipSelected = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, AppColors.cream],
  );
}

class AppRadius {
  const AppRadius._();
  static const double card = 24;
  static const double button = 18;
  static const double chip = 14;
  static const double bar = 28;
}

class AppSpacing {
  const AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> glow = [
    BoxShadow(
      color: AppColors.orangeGlow,
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.glassShadow,
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}

class AppBlur {
  const AppBlur._();
  static const double sigma = 18;
}
