import '../../../l10n/app_localizations.dart';
import '../../plan/domain/template_renderer.dart';
import '../domain/checkin_models.dart';

String shotLabel(AppLocalizations l10n, ShotType t) => switch (t) {
  ShotType.wholePlant => l10n.checkinShotWhole,
  ShotType.closeLeaf => l10n.checkinShotLeaf,
  ShotType.leafUnderside => l10n.checkinShotUnder,
};

/// Condition tag label: `text_templates` (kind `tag`) first, else the
/// built-in string.
String tagLabel(
  AppLocalizations l10n,
  TemplateRenderer renderer,
  String tag,
  String lang,
) {
  final fromDb = renderer.lookup('tag', tag, 'name', lang: lang);
  if (fromDb != null) return fromDb;
  return switch (tag) {
    'LEAF_YELLOW' => l10n.checkinTagLeafYellow,
    'WILT' => l10n.checkinTagWilt,
    'PESTS' => l10n.checkinTagPests,
    'SPOTS' => l10n.checkinTagSpots,
    _ => TemplateRenderer.readableCode(tag),
  };
}

/// "Tin cậy cao · 86%" with the check-in band thresholds (0.75 / 0.5).
String bandLabel(AppLocalizations l10n, double confidence) {
  final pct = (confidence * 100).round();
  return switch (bandOf(confidence)) {
    ConfidenceBand.high => l10n.planConfidenceHigh(pct),
    ConfidenceBand.medium => l10n.planConfidenceMedium(pct),
    ConfidenceBand.low => l10n.planConfidenceLow(pct),
  };
}

String? healthLabel(AppLocalizations l10n, String? health) => switch (health) {
  'good' => l10n.checkinHealthGood,
  'fair' => l10n.checkinHealthFair,
  'poor' => l10n.checkinHealthPoor,
  _ => health,
};

String retakeReasonLabel(AppLocalizations l10n, String reason) =>
    switch (reason.toUpperCase()) {
      'BLUR' => l10n.checkinRetakeReasonBlur,
      'DARK' => l10n.checkinRetakeReasonDark,
      'NOT_PLANT' => l10n.checkinRetakeReasonNotPlant,
      'UNREADABLE' => l10n.checkinRetakeReasonUnreadable,
      _ => l10n.checkinRetakeReasonFar,
    };

/// Hint sentence for a `H_RETAKE_*` code: template `steps` text, else null
/// (the screen still shows the static tips).
String? retakeHintText(
  TemplateRenderer renderer,
  String hintCode,
  String lang,
) => renderer.lookup('hint', hintCode, 'steps', lang: lang);
