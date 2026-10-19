import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_only.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/template_renderer.dart';
import 'plan_providers.dart';

/// Renderer for the current locale; an empty one (readable codes) while the
/// templates load or if they fail to.
TemplateRenderer watchRenderer(WidgetRef ref) =>
    ref.watch(templateRendererProvider).value ?? TemplateRenderer(const []);

String frequencyLabel(AppLocalizations l10n, Task t) {
  switch (t.frequency) {
    case Frequency.once:
      return l10n.planFreqOnce;
    case Frequency.daily:
      return l10n.planFreqDaily;
    case Frequency.everyNDays:
      return l10n.planFreqEveryN(t.intervalDays ?? 1);
    case Frequency.fixedDate:
      if (t.fixedDate != null) {
        final d = t.fixedDate!;
        return l10n.planFreqFixedDate(
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}',
        );
      }
      return l10n.planFreqFixedDay(t.intervalDays ?? 1);
  }
}

String windowLabel(AppLocalizations l10n, TaskWindow w) => switch (w) {
  TaskWindow.morning => l10n.planWindowMorning,
  TaskWindow.afternoon => l10n.planWindowAfternoon,
  TaskWindow.allDay => l10n.planWindowAllDay,
};

String windowShortLabel(AppLocalizations l10n, TaskWindow w) => switch (w) {
  TaskWindow.morning => l10n.planWindowMorningShort,
  TaskWindow.afternoon => l10n.planWindowAfternoonShort,
  TaskWindow.allDay => l10n.planWindowAllDay,
};

String confidenceLabel(AppLocalizations l10n, double confidence) {
  final pct = (confidence * 100).round();
  if (confidence >= 0.8) return l10n.planConfidenceHigh(pct);
  if (confidence >= 0.5) return l10n.planConfidenceMedium(pct);
  return l10n.planConfidenceLow(pct);
}

String shortDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

String dowLabel(AppLocalizations l10n, DateTime d) {
  // DateTime.weekday: Monday = 1 ... Sunday = 7.
  return switch (dateOnly(d).weekday) {
    1 => l10n.planDow1,
    2 => l10n.planDow2,
    3 => l10n.planDow3,
    4 => l10n.planDow4,
    5 => l10n.planDow5,
    6 => l10n.planDow6,
    _ => l10n.planDow7,
  };
}
