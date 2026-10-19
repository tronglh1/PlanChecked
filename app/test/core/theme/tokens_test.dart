import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/core/theme/tokens.dart';
import 'package:vuon_nha/core/widgets/glass_scaffold.dart';

void main() {
  test('primary gradient is #FF9A52 -> #F26A1B -> #D9510A at 0/50/100%', () {
    expect(AppGradients.primary.colors, const [
      Color(0xFFFF9A52),
      Color(0xFFF26A1B),
      Color(0xFFD9510A),
    ]);
    expect(AppGradients.primary.stops, const [0.0, 0.5, 1.0]);
  });

  test('canvas background is #FBF8EF -> #EAF4EA', () {
    expect(AppGradients.background.colors, const [
      Color(0xFFFBF8EF),
      Color(0xFFEAF4EA),
    ]);
  });

  test('ink, ink-2 and danger match the spec', () {
    expect(AppColors.text, const Color(0xFF16211A));
    expect(AppColors.textSecondary, const Color(0xFF55625A));
    expect(AppColors.danger, const Color(0xFFB42318));
    expect(AppColors.green, const Color(0xFF1E6B43));
  });

  test('radii: card 20, section 18, CTA 14, input 12, pill chip 18', () {
    expect(AppRadius.card, 20);
    expect(AppRadius.section, 18);
    expect(AppRadius.button, 14);
    expect(AppRadius.input, 12);
    expect(AppRadius.chip, 18);
  });

  test('glass: fill .62, border .8, shadow 0 8 24 rgba(40,70,50,.10)', () {
    expect(AppColors.glassFill, const Color.fromRGBO(255, 255, 255, 0.62));
    expect(AppColors.glassEdge, const Color.fromRGBO(255, 255, 255, 0.8));
    final s = AppShadows.soft.single;
    expect(s.color, const Color.fromRGBO(40, 70, 50, 0.10));
    expect(s.blurRadius, 24);
    expect(s.offset, const Offset(0, 8));
  });

  test('CTA glow: 0 8 22 rgba(242,96,15,.45) plus 1px white ring', () {
    final glow = AppShadows.glow.first;
    expect(glow.color, const Color.fromRGBO(242, 96, 15, 0.45));
    expect(glow.blurRadius, 22);
    expect(glow.offset, const Offset(0, 8));
    expect(AppShadows.glow.last.spreadRadius, 1);
  });

  test('selected chip ring is 3px and text is orange, not green', () {
    expect(AppShadows.chipSelected.first.spreadRadius, 3);
    expect(AppColors.orangeText, const Color(0xFFA63A00));
    expect(AppGradients.chipSelected.colors, const [
      Color(0xFFFFFFFF),
      Color(0xFFFFE6D6),
    ]);
  });

  test('CTA and active tab use weight 600', () {
    expect(AppFontWeights.cta, FontWeight.w600);
    expect(AppFontWeights.tabActive, FontWeight.w600);
    expect(AppFontWeights.tabInactive, FontWeight.w500);
  });

  test('canvas blob positions follow the mockup', () {
    expect(canvasBlobs.map((b) => (b.x, b.y, b.stop)), const [
      (0.08, 0.04, 0.40),
      (0.96, 0.30, 0.42),
      (0.18, 0.92, 0.46),
    ]);
  });
}
