/// Display models for the Thành tích tab and the milestone screen (spec
/// §6.3-6.5). XP, levels and badges are computed on the server; the app only
/// shows them. Pure Dart.
library;

import 'levels.dart';
import 'xp.dart';

/// A row of the server `levels` table.
class LevelRow {
  const LevelRow(this.level, this.xpMin, this.nameVi, this.nameEn);
  final int level;
  final int xpMin;
  final String nameVi;
  final String nameEn;
}

class BadgeInfo {
  const BadgeInfo({
    required this.code,
    required this.nameVi,
    required this.nameEn,
    required this.earned,
    this.earnedAt,
    this.sortOrder = 0,
  });
  final String code;
  final String nameVi;
  final String nameEn;
  final bool earned;
  final DateTime? earnedAt;
  final int sortOrder;

  String name(String lang) => lang == 'en' ? nameEn : nameVi;
}

/// XP summed per source from `xp_events`.
class XpBreakdown {
  const XpBreakdown({
    this.taskDone = 0,
    this.checkin = 0,
    this.milestone = 0,
    this.projectDone = 0,
    this.todayTaskDone = 0,
  });
  final int taskDone;
  final int checkin;
  final int milestone;
  final int projectDone;

  /// Ordinary (capped) XP earned today: `task_done` only (backend rule).
  final int todayTaskDone;

  static XpBreakdown fromEvents(
    Iterable<({String source, int amount, DateTime day})> events,
    DateTime today,
  ) {
    var task = 0, checkin = 0, milestone = 0, project = 0, todayTask = 0;
    for (final e in events) {
      switch (e.source) {
        case 'task_done':
          task += e.amount;
          if (e.day.year == today.year &&
              e.day.month == today.month &&
              e.day.day == today.day) {
            todayTask += e.amount;
          }
        case 'checkin':
          checkin += e.amount;
        case 'milestone':
          milestone += e.amount;
        case 'project_done':
          project += e.amount;
      }
    }
    return XpBreakdown(
      taskDone: task,
      checkin: checkin,
      milestone: milestone,
      projectDone: project,
      todayTaskDone: todayTask,
    );
  }
}

class AchievementsData {
  const AchievementsData({
    required this.xpTotal,
    required this.levels,
    required this.badges,
    required this.streak,
    required this.xp,
    this.pendingPhotoMilestones = 0,
  });

  final int xpTotal;

  /// Server `levels` rows; empty = fall back to [Levels.defaults].
  final List<LevelRow> levels;
  final List<BadgeInfo> badges;
  final int streak;
  final XpBreakdown xp;

  /// Milestones claimed manually (no photo): they earn no XP (GAM-08).
  final int pendingPhotoMilestones;

  List<LevelDef> get _table => levels.isEmpty
      ? Levels.defaults
      : [
          for (final l in levels)
            LevelDef(l.level, l.xpMin, l.nameVi, l.nameEn),
        ];

  LevelProgress get progress => Levels.progress(xpTotal, table: _table);

  String levelName(LevelDef def, String lang) => def.name(lang);

  int get earnedCount => badges.where((b) => b.earned).length;

  /// Remaining ordinary XP today for the "60/150" tile.
  int get todayOrdinary => XpPreview.cappedToday(xp.todayTaskDone);
}

class MilestoneInfo {
  const MilestoneInfo({
    required this.projectId,
    required this.projectName,
    required this.code,
    required this.photoConfirmed,
    required this.xpAwarded,
    this.title,
    this.badge,
    this.reachedOn,
  });
  final String projectId;
  final String projectName;
  final String code;

  /// Localized milestone name from `text_templates`, if any.
  final String? title;

  /// True when attached to a check-in (server awards XP only then).
  final bool photoConfirmed;
  final int xpAwarded;
  final BadgeInfo? badge;
  final DateTime? reachedOn;
}
