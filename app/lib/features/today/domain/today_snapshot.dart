/// Data pulled from the server (or the offline cache) that Today renders
/// from. Pure Dart.
library;

import '../../plan/domain/template_renderer.dart';
import 'outbox_entry.dart';
import 'today_builder.dart';

class TaskSnapshot {
  const TaskSnapshot({
    this.projects = const [],
    this.logs = const [],
    this.lastCheckins,
    this.memberNames,
  });

  /// Active projects with their approved plan's stages and active tasks.
  final List<TodayProject> projects;

  /// Recent `task_logs` rows (own and household).
  final List<TaskLog> logs;

  /// Latest check-in date per project id. Null = unknown (keep the cached
  /// value instead of overwriting it).
  final Map<String, DateTime>? lastCheckins;

  /// `users.display_name` by id for task assignees. Null = unknown.
  final Map<String, String>? memberNames;

  static const empty = TaskSnapshot();
}

/// Everything restored from the drift cache.
class CachedToday {
  const CachedToday({
    this.userId,
    this.snapshot = TaskSnapshot.empty,
    this.templates = const [],
  });

  final String? userId;
  final TaskSnapshot snapshot;
  final List<TextTemplate> templates;
}
