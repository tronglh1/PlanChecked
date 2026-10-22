/// Offline action queue entry and server task log row (docs/spec-mvp.md
/// §4.2 `task_logs`, §6.2). Pure Dart.
library;

import '../../../core/utils/date_only.dart';
import '../../plan/domain/enums.dart';

/// A Done / Skip / Snooze performed (possibly offline) and not yet confirmed
/// by the server. [clientId] is a client-generated UUID sent as
/// `task_logs.client_id` so retries are idempotent.
class OutboxEntry {
  OutboxEntry({
    required this.clientId,
    required this.taskId,
    required DateTime occurrenceDate,
    required this.action,
    required this.userId,
    required this.createdAt,
    DateTime? actedOn,
    DateTime? snoozeUntil,
    this.skipReason,
  }) : occurrenceDate = dateOnly(occurrenceDate),
       actedOn = dateOnly(actedOn ?? createdAt),
       snoozeUntil = snoozeUntil == null ? null : dateOnly(snoozeUntil);

  final String clientId;
  final String taskId;
  final DateTime occurrenceDate;
  final TaskAction action;
  final String userId;

  /// Device time of the tap; only used for ordering. The server recomputes
  /// XP from its own action time (spec §6.5).
  final DateTime createdAt;

  /// User-local calendar date of the tap (defaults to [createdAt]'s y/m/d).
  final DateTime actedOn;

  /// Only for [TaskAction.snooze]: first date the task is due again.
  final DateTime? snoozeUntil;
  final String? skipReason;

  String get occurrenceKey => '$taskId|${formatIsoDate(occurrenceDate)}';

  factory OutboxEntry.fromJson(Map<String, dynamic> j) => OutboxEntry(
    clientId: j['client_id'] as String,
    taskId: j['task_id'] as String,
    occurrenceDate: parseIsoDate(j['occurrence_date'] as String),
    action: TaskAction.fromDb(j['action']),
    userId: j['user_id'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
    actedOn: j['acted_on'] == null
        ? null
        : parseIsoDate(j['acted_on'] as String),
    snoozeUntil: j['snooze_until'] == null
        ? null
        : parseIsoDate(j['snooze_until'] as String),
    skipReason: j['skip_reason'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'client_id': clientId,
    'task_id': taskId,
    'occurrence_date': formatIsoDate(occurrenceDate),
    'action': action.db,
    'user_id': userId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'acted_on': formatIsoDate(actedOn),
    'snooze_until': snoozeUntil == null ? null : formatIsoDate(snoozeUntil!),
    'skip_reason': skipReason,
  };

  /// Drops duplicate [clientId]s, keeping the first occurrence of each (a
  /// retry or double-tap must not create two server rows). Order preserved.
  static List<OutboxEntry> dedupe(Iterable<OutboxEntry> entries) {
    final seen = <String>{};
    return [
      for (final e in entries)
        if (seen.add(e.clientId)) e,
    ];
  }
}

/// A confirmed row from `task_logs`.
class TaskLog {
  TaskLog({
    required this.id,
    required this.taskId,
    required DateTime occurrenceDate,
    required this.userId,
    required this.action,
    required this.createdAt,
    DateTime? actedOn,
    DateTime? snoozeUntil,
    this.skipReason,
    this.clientId,
  }) : occurrenceDate = dateOnly(occurrenceDate),
       actedOn = dateOnly(actedOn ?? createdAt),
       snoozeUntil = snoozeUntil == null ? null : dateOnly(snoozeUntil);

  final String id;
  final String taskId;
  final DateTime occurrenceDate;
  final String userId;
  final TaskAction action;
  final DateTime createdAt;
  final DateTime actedOn;
  final DateTime? snoozeUntil;
  final String? skipReason;
  final String? clientId;

  String get occurrenceKey => '$taskId|${formatIsoDate(occurrenceDate)}';

  factory TaskLog.fromJson(Map<String, dynamic> j) => TaskLog(
    id: j['id'] as String,
    taskId: j['task_id'] as String,
    occurrenceDate: parseIsoDate(j['occurrence_date'] as String),
    userId: j['user_id'] as String,
    action: TaskAction.fromDb(j['action']),
    createdAt: DateTime.parse(j['created_at'] as String),
    actedOn: j['acted_on'] == null
        ? null
        : parseIsoDate(j['acted_on'] as String),
    snoozeUntil: j['snooze_until'] == null
        ? null
        : parseIsoDate(j['snooze_until'] as String),
    skipReason: j['skip_reason'] as String?,
    clientId: j['client_id'] as String?,
  );
}
