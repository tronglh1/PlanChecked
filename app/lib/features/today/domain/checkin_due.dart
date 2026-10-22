/// Check-in reminders (CHK-01). Pure Dart.
library;

import '../../../core/utils/date_only.dart';
import '../../plan/domain/task_scheduler.dart';
import 'today_builder.dart';

class CheckinDue {
  const CheckinDue({
    required this.projectId,
    required this.projectName,
    required this.dueDate,
  });

  final String projectId;
  final String projectName;
  final DateTime dueDate;
}

/// Projects whose photo check-in is due on or before [today]. A project that
/// has not started yet is never due.
List<CheckinDue> checkinsDue({
  required DateTime today,
  required List<TodayProject> projects,
  required Map<String, DateTime> lastCheckins,
}) {
  final day = dateOnly(today);
  final out = <CheckinDue>[];
  for (final p in projects) {
    if (dateOnly(p.startDate).isAfter(day)) continue;
    final due = CheckinCadence.nextDue(
      stages: p.stages,
      projectStart: p.startDate,
      lastCheckin: lastCheckins[p.id],
    );
    if (!due.isAfter(day)) {
      out.add(CheckinDue(projectId: p.id, projectName: p.name, dueDate: due));
    }
  }
  out.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return out;
}

/// Next check-in date per project (for scheduling local reminders).
Map<String, DateTime> nextCheckinDates({
  required List<TodayProject> projects,
  required Map<String, DateTime> lastCheckins,
}) => {
  for (final p in projects)
    p.id: CheckinCadence.nextDue(
      stages: p.stages,
      projectStart: p.startDate,
      lastCheckin: lastCheckins[p.id],
    ),
};
