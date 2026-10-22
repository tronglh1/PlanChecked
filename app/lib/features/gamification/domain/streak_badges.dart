/// Streak and badge progress (display only; server awards badges, spec §6.4).
///
/// Spec gaps (§7): streak definition/freeze and most badge criteria are not
/// given. Rules here are proposals, easy to swap:
/// - A streak day is a calendar day with at least one task done.
/// - The current streak survives if today has no activity yet but yesterday
///   did (the user still has today to keep it).
library;

import '../../../core/utils/date_only.dart';

class StreakCalculator {
  const StreakCalculator._();

  /// Consecutive active days ending today (or yesterday if today is empty).
  static int current(Iterable<DateTime> activeDays, DateTime today) {
    final days = {for (final d in activeDays) dateOnly(d)};
    var cursor = dateOnly(today);
    if (!days.contains(cursor)) cursor = addDays(cursor, -1);
    var n = 0;
    while (days.contains(cursor)) {
      n++;
      cursor = addDays(cursor, -1);
    }
    return n;
  }

  /// Longest run of consecutive active days ever.
  static int longest(Iterable<DateTime> activeDays) {
    final sorted = ({for (final d in activeDays) dateOnly(d)}).toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? prev;
    for (final d in sorted) {
      run = (prev != null && daysBetween(prev, d) == 1) ? run + 1 : 1;
      if (run > best) best = run;
      prev = d;
    }
    return best;
  }
}

/// Inputs for badge progress, all derived from synced data.
class GamificationStats {
  const GamificationStats({
    this.projectsStarted = 0,
    this.checkins = 0,
    this.milestones = const {},
    this.longestStreak = 0,
  });

  final int projectsStarted;
  final int checkins;

  /// Milestone codes reached (SPROUT, HEIGHT_40, FLOWER, HARVEST, ...).
  final Set<String> milestones;
  final int longestStreak;
}

sealed class BadgeCriterion {
  const BadgeCriterion();
  int target(GamificationStats s);
  int current(GamificationStats s);
}

class MilestoneCriterion extends BadgeCriterion {
  const MilestoneCriterion(this.code);
  final String code;
  @override
  int target(GamificationStats s) => 1;
  @override
  int current(GamificationStats s) => s.milestones.contains(code) ? 1 : 0;
}

class StreakCriterion extends BadgeCriterion {
  const StreakCriterion(this.days);
  final int days;
  @override
  int target(GamificationStats s) => days;
  @override
  int current(GamificationStats s) => s.longestStreak;
}

class CheckinCountCriterion extends BadgeCriterion {
  const CheckinCountCriterion(this.count);
  final int count;
  @override
  int target(GamificationStats s) => count;
  @override
  int current(GamificationStats s) => s.checkins;
}

class ProjectCountCriterion extends BadgeCriterion {
  const ProjectCountCriterion(this.count);
  final int count;
  @override
  int target(GamificationStats s) => count;
  @override
  int current(GamificationStats s) => s.projectsStarted;
}

class BadgeDef {
  const BadgeDef(this.code, this.nameVi, this.nameEn, this.criterion);
  final String code;
  final String nameVi;
  final String nameEn;

  String name(String lang) =>
      lang == 'en' && nameEn.isNotEmpty ? nameEn : nameVi;
  final BadgeCriterion criterion;
}

class BadgeProgress {
  const BadgeProgress({
    required this.badge,
    required this.current,
    required this.target,
  });

  final BadgeDef badge;
  final int current;
  final int target;

  bool get earned => current >= target;
  double get fraction => target <= 0 ? 1 : (current / target).clamp(0.0, 1.0);
}

class Badges {
  const Badges._();

  /// The 8 badges drawn in the mockup (spec §3 screen 20). The header says
  /// "x/16"; the other 8 are undefined. Codes and the "Thợ chụp ảnh"
  /// threshold (10 check-ins) are proposals.
  static const List<BadgeDef> catalog = [
    BadgeDef(
      'FIRST_SEED',
      'Hạt giống đầu tiên',
      'First Seed',
      ProjectCountCriterion(1),
    ),
    BadgeDef('SPROUT', 'Nảy mầm', 'Sprouted', MilestoneCriterion('SPROUT')),
    BadgeDef('STREAK_7', '7 ngày liên tục', '7-Day Streak', StreakCriterion(7)),
    BadgeDef(
      'TALL_40',
      'Vươn cao',
      'Reaching Up',
      MilestoneCriterion('HEIGHT_40'),
    ),
    BadgeDef(
      'PHOTOGRAPHER',
      'Thợ chụp ảnh',
      'Photographer',
      CheckinCountCriterion(10),
    ),
    BadgeDef('BLOOM', 'Ra hoa', 'In Bloom', MilestoneCriterion('FLOWER')),
    BadgeDef(
      'FIRST_HARVEST',
      'Thu hoạch đầu tiên',
      'First Harvest',
      MilestoneCriterion('HARVEST'),
    ),
    BadgeDef(
      'STREAK_30',
      '30 ngày liên tục',
      '30-Day Streak',
      StreakCriterion(30),
    ),
  ];

  static const int totalInSpec = 16;

  static List<BadgeProgress> progress(
    GamificationStats stats, {
    List<BadgeDef> defs = catalog,
  }) {
    final out = <BadgeProgress>[];
    for (final b in defs) {
      final target = b.criterion.target(stats);
      final cur = b.criterion.current(stats);
      out.add(
        BadgeProgress(
          badge: b,
          current: cur > target ? target : cur,
          target: target,
        ),
      );
    }
    return out;
  }

  static int earnedCount(List<BadgeProgress> p) =>
      p.where((b) => b.earned).length;
}
