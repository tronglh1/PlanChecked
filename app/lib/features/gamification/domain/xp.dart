/// Client-side XP preview (docs/spec-mvp.md §6.3, §6.5). DISPLAY ONLY: the
/// server (`xp_events`, award-xp function) is authoritative and recomputes XP
/// from its own action time.
library;

import '../../../core/utils/date_only.dart';

enum XpSource {
  taskDone('task_done'),
  checkin('checkin'),
  milestone('milestone'),
  projectDone('project_done');

  const XpSource(this.db);
  final String db;

  static XpSource fromDb(Object? v) {
    for (final e in values) {
      if (e.db == v) return e;
    }
    throw FormatException('Unknown xp source', v);
  }
}

enum XpOutcome {
  /// Full amount awarded.
  awarded,

  /// Reduced to what is left under the daily cap.
  partialCap,

  /// Daily cap already reached.
  capReached,

  /// Task finished after its due date: no XP.
  late,

  /// Milestone without a photo-confirmed check-in: no XP.
  needsPhoto,

  /// Source has no defined XP (project_done, spec §7).
  notDefined,
}

class XpAward {
  const XpAward(this.amount, this.outcome, {this.base = 0});
  final int amount;
  final XpOutcome outcome;

  /// Amount before cap/lateness rules.
  final int base;

  @override
  String toString() => 'XpAward($amount, ${outcome.name})';
}

class XpRules {
  const XpRules._();

  static const int taskDone = 10;
  static const int checkin = 30;
  static const int milestone = 100;

  /// GAM-01 names "project completed" but gives no value (spec §7).
  static const int projectDone = 0;

  /// "Mỗi ngày tối đa 150 XP từ việc thường".
  static const int dailyCap = 150;

  /// Sources counted against the cap. Spec §6.5 says "ordinary activity";
  /// we count task_done and checkin. Milestone/project XP is uncapped but
  /// gated by photo evidence.
  static const Set<XpSource> cappedSources = {
    XpSource.taskDone,
    XpSource.checkin,
  };

  static int baseAmount(XpSource s) => switch (s) {
    XpSource.taskDone => taskDone,
    XpSource.checkin => checkin,
    XpSource.milestone => milestone,
    XpSource.projectDone => projectDone,
  };
}

class XpPreview {
  const XpPreview._();

  /// Done on time = acted on or before the (possibly snoozed) due date.
  static bool isOnTime({
    required DateTime dueDate,
    required DateTime actedOn,
  }) => !dateOnly(actedOn).isAfter(dateOnly(dueDate));

  /// XP shown for one action.
  ///
  /// [earnedOrdinaryToday] is XP already counted today from capped sources.
  /// [onTime] only matters for task_done. [photoConfirmed] only for milestone
  /// (and project_done).
  static XpAward award(
    XpSource source, {
    int earnedOrdinaryToday = 0,
    bool onTime = true,
    bool photoConfirmed = false,
  }) {
    final base = XpRules.baseAmount(source);
    if (source == XpSource.projectDone && base == 0) {
      return const XpAward(0, XpOutcome.notDefined);
    }
    if (source == XpSource.taskDone && !onTime) {
      return XpAward(0, XpOutcome.late, base: base);
    }
    if ((source == XpSource.milestone || source == XpSource.projectDone) &&
        !photoConfirmed) {
      return XpAward(0, XpOutcome.needsPhoto, base: base);
    }
    if (!XpRules.cappedSources.contains(source)) {
      return XpAward(base, XpOutcome.awarded, base: base);
    }
    final left = remainingToday(earnedOrdinaryToday);
    if (left <= 0) return XpAward(0, XpOutcome.capReached, base: base);
    if (left < base) return XpAward(left, XpOutcome.partialCap, base: base);
    return XpAward(base, XpOutcome.awarded, base: base);
  }

  /// XP still available today under the daily cap (never negative).
  static int remainingToday(int earnedOrdinaryToday) {
    final left = XpRules.dailyCap - earnedOrdinaryToday;
    return left < 0 ? 0 : left;
  }

  /// "Hôm nay 60/150": earned ordinary XP clamped to the cap.
  static int cappedToday(int earnedOrdinaryToday) =>
      earnedOrdinaryToday > XpRules.dailyCap
      ? XpRules.dailyCap
      : earnedOrdinaryToday;

  /// Applies [awards] in order against the cap, returning the total shown.
  /// Useful to preview a day's list of actions.
  static int totalForDay(
    Iterable<({XpSource source, bool onTime, bool photoConfirmed})> actions, {
    int alreadyEarnedOrdinary = 0,
  }) {
    var ordinary = alreadyEarnedOrdinary;
    var total = 0;
    for (final a in actions) {
      final r = award(
        a.source,
        earnedOrdinaryToday: ordinary,
        onTime: a.onTime,
        photoConfirmed: a.photoConfirmed,
      );
      total += r.amount;
      if (XpRules.cappedSources.contains(a.source)) ordinary += r.amount;
    }
    return total;
  }
}
