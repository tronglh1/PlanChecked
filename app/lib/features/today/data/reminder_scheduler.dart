import '../../plan/domain/models.dart';
import '../../settings/domain/notification_settings.dart';
import '../domain/outbox_entry.dart';
import '../domain/reminder_planner.dart';
import '../domain/today_builder.dart';
import 'notification_gateway.dart';

/// Schedules local notifications for the user's own upcoming occurrences
/// (next 7 days) and check-ins. Call [reschedule] after every sync.
class ReminderScheduler {
  ReminderScheduler(this._gateway, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final NotificationGateway _gateway;
  final DateTime Function() _clock;

  /// The plan applied by the last [reschedule] (for diagnostics / tests).
  List<PlannedNotification> lastPlan = const [];

  Future<List<PlannedNotification>> reschedule({
    required List<TodayProject> projects,
    required List<TaskLog> logs,
    required List<OutboxEntry> outbox,
    required NotificationSettings settings,
    required String? userId,
    required String Function(Task) taskName,
    required ReminderTexts texts,
    Map<String, DateTime> lastCheckins = const {},
    QuietHours? quiet,
  }) async {
    final granted = await _gateway.isPermissionGranted();
    final plan = granted
        ? ReminderPlanner.plan(
            now: _clock(),
            projects: projects,
            logs: logs,
            outbox: outbox,
            settings: settings,
            userId: userId,
            taskName: taskName,
            texts: texts,
            lastCheckins: lastCheckins,
            quiet: quiet,
          )
        : const <PlannedNotification>[];
    await _gateway.replaceAll(plan, channels: texts.channels);
    lastPlan = plan;
    return plan;
  }
}
