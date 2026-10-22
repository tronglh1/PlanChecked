/// Derived progress of a project against its plan stages. Pure Dart.
library;

import '../../../core/utils/date_only.dart';
import '../../plan/domain/models.dart';
import '../../plan/domain/task_scheduler.dart';

class ProjectProgress {
  const ProjectProgress({
    required this.day,
    required this.totalDays,
    required this.stages,
    this.currentStage,
    required this.stageNumber,
    this.nextMilestone,
    this.nextMilestoneDate,
    required this.milestonesReached,
    required this.milestonesTotal,
  });

  /// 1-based project day of today (<= 0 before start).
  final int day;
  final int totalDays;
  final List<Stage> stages;
  final Stage? currentStage;

  /// 1-based position of [currentStage] in [stages].
  final int stageNumber;
  final String? nextMilestone;
  final DateTime? nextMilestoneDate;
  final int milestonesReached;
  final int milestonesTotal;

  int get stageCount => stages.length;

  /// 0..1 over the whole plan.
  double get fraction => totalDays <= 0 ? 0 : (day / totalDays).clamp(0.0, 1.0);

  int get daysLeftInStage {
    final s = currentStage;
    if (s == null) return 0;
    final left = s.dayTo - day;
    return left < 0 ? 0 : left;
  }

  /// Null when [stages] is empty. Before the start the first stage is the
  /// current one; after the last day the last stage is.
  static ProjectProgress? compute({
    required List<Stage> stages,
    required DateTime projectStart,
    required DateTime today,
  }) {
    if (stages.isEmpty) return null;
    final sorted = [...stages]..sort((a, b) => a.idx.compareTo(b.idx));
    final start = dateOnly(projectStart);
    final day = TaskScheduler.dayNumber(start, today);
    final total = sorted.map((s) => s.dayTo).reduce((a, b) => a > b ? a : b);
    final current =
        TaskScheduler.stageOn(sorted, start, today) ??
        (day < sorted.first.dayFrom ? sorted.first : sorted.last);
    final number = sorted.indexOf(current) + 1;

    Stage? next;
    for (final s in sorted.skip(number - 1)) {
      if (s.milestoneCode != null && s.dayTo >= day) {
        next = s;
        break;
      }
    }
    final withMilestone = sorted.where((s) => s.milestoneCode != null);
    final reached = withMilestone.where((s) => s.dayTo < day).length;
    return ProjectProgress(
      day: day,
      totalDays: total,
      stages: sorted,
      currentStage: current,
      stageNumber: number,
      nextMilestone: next?.milestoneCode,
      nextMilestoneDate: next == null
          ? null
          : TaskScheduler.dateOfDay(start, next.dayTo),
      milestonesReached: reached,
      milestonesTotal: withMilestone.length,
    );
  }
}
