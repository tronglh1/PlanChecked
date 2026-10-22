import 'package:flutter/material.dart';

/// Design tokens for the light frosted-glass look. Values come from the
/// mockup (docs/spec-mvp.md §1). Screens must use these instead of ad-hoc
/// colors.
class AppColors {
  const AppColors._();

  // Canvas background: linear-gradient(170deg, #FBF8EF 0%, #EAF4EA 100%)
  static const Color bgTop = Color(0xFFFBF8EF);
  static const Color bgBottom = Color(0xFFEAF4EA);

  // Canvas blobs (radial gradients, alpha as in the mockup)
  static const Color blobPeach = Color.fromRGBO(255, 175, 125, 0.55);
  static const Color blobCoral = Color.fromRGBO(255, 165, 135, 0.5);
  static const Color blobMint = Color.fromRGBO(150, 220, 175, 0.55);

  // Text
  static const Color text = Color(0xFF16211A); // ink
  static const Color textSecondary = Color(0xFF55625A); // ink-2
  static const Color textTertiary = Color(0xFF3B463E); // ink-3
  static const Color textMuted = Color(0xFF7D8C81); // ink-muted
  static const Color textOnPrimary = Colors.white;

  // Primary orange gradient (orange-1/2/3)
  static const Color orangeLight = Color(0xFFFF9A52);
  static const Color orangeMid = Color(0xFFF26A1B);
  static const Color orangeDark = Color(0xFFD9510A);
  static const Color orangeSolid = Color(0xFFFF8A3D);
  static const Color orangeTab = Color(0xFFF2600F);

  /// CTA glow: rgba(242,96,15,0.45)
  static const Color orangeGlow = Color.fromRGBO(242, 96, 15, 0.45);

  /// Selected-chip ring: rgba(255,127,50,0.45)
  static const Color orangeRing = Color.fromRGBO(255, 127, 50, 0.45);

  /// Selected-chip drop shadow: rgba(242,96,15,0.3)
  static const Color orangeChipShadow = Color.fromRGBO(242, 96, 15, 0.3);

  /// Selected option chip: gradient end and text.
  static const Color orangeChip = Color(0xFFFFE6D6);
  static const Color orangeText = Color(0xFFA63A00);
  static const Color orangeTint = Color(0xFFFCEBDD);
  static const Color orangeTintInk = Color(0xFF9A4508);

  // Green: ONLY progress, active tab, done circles, links.
  static const Color green = Color(0xFF1E6B43);
  static const Color greenDeep = Color(0xFF14502F);
  static const Color greenTint = Color(0xFFE3EFE6);
  static const Color greenSoft = Color(0x261E6B43);

  // Glass
  static const Color glassFill = Color.fromRGBO(255, 255, 255, 0.62);
  static const Color glassEdge = Color.fromRGBO(255, 255, 255, 0.8);
  static const Color glassFillSolid = Color(0xF5FFFFFF); // blur disabled

  /// Glass drop shadow: rgba(40,70,50,0.10)
  static const Color glassShadow = Color.fromRGBO(40, 70, 50, 0.10);

  /// Inset top highlight on glass: rgba(255,255,255,0.9)
  static const Color glassHighlight = Color.fromRGBO(255, 255, 255, 0.9);

  /// Inset top highlight on the primary CTA: rgba(255,255,255,0.75)
  static const Color ctaHighlight = Color.fromRGBO(255, 255, 255, 0.75);

  /// 1px ring around the primary CTA: rgba(255,255,255,0.55)
  static const Color ctaRing = Color.fromRGBO(255, 255, 255, 0.55);

  // Chip / misc
  static const Color cream = orangeChip;
  static const Color divider = Color(0xFFDCE3DA); // line
  static const Color dividerSoft = Color(0xFFEEF1EC); // line-soft
  static const Color danger = Color(0xFFB42318);
  static const Color dangerLine = Color(0xFFF1C4BF);

  /// Check-in camera screen background (spec screen 13).
  static const Color cameraDark = Color(0xFF0F1712);
}

class AppGradients {
  const AppGradients._();

  /// CSS 170deg: points almost straight down, tilted slightly to the right.
  static const LinearGradient background = LinearGradient(
    begin: Alignment(-0.17, -0.98),
    end: Alignment(0.17, 0.98),
    colors: [AppColors.bgTop, AppColors.bgBottom],
  );

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.orangeLight, AppColors.orangeMid, AppColors.orangeDark],
    stops: [0, 0.5, 1],
  );

  static const LinearGradient chipSelected = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, AppColors.orangeChip],
  );
}

class AppRadius {
  const AppRadius._();
  static const double card = 20;
  static const double section = 18; // section cards 16-18
  static const double button = 14; // CTA, rows, day cells
  static const double input = 12;
  static const double chip = 18; // pill chips 17-20
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

  /// Primary CTA: 0 8 22 glow + 1px white ring (inset highlight is drawn by
  /// TopHighlight, Flutter has no inset shadow).
  static const List<BoxShadow> glow = [
    BoxShadow(
      color: AppColors.orangeGlow,
      blurRadius: 22,
      offset: Offset(0, 8),
    ),
    BoxShadow(color: AppColors.ctaRing, spreadRadius: 1),
  ];

  /// Glass: 0 8 24 rgba(40,70,50,.10)
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.glassShadow,
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Selected option chip: 3px orange ring + soft orange drop shadow.
  static const List<BoxShadow> chipSelected = [
    BoxShadow(color: AppColors.orangeRing, spreadRadius: 3),
    BoxShadow(
      color: AppColors.orangeChipShadow,
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
}

class AppBlur {
  const AppBlur._();
  static const double sigma = 18;
}

class AppFontWeights {
  const AppFontWeights._();
  static const FontWeight cta = FontWeight.w600;
  static const FontWeight tabActive = FontWeight.w600;
  static const FontWeight tabInactive = FontWeight.w500;
  static const FontWeight chipSelected = FontWeight.w600;
  static const FontWeight chip = FontWeight.w500;
}
