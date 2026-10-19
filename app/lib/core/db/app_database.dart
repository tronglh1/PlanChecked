import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Offline write queue: Done/Skip/Snooze ops flushed when online.
class Outbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get op => text()();
  TextColumn get payload => text()(); // JSON
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// `task_logs.client_id` of the queued action (dedup key). v3.
  TextColumn get clientId => text().withDefault(const Constant(''))();

  /// Backoff: do not retry before this time. v3.
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
}

/// Offline cache of everything Today needs to render and schedule reminders.
/// One row per cached object; [kind] says what [payload] (JSON) holds:
/// `task`, `project` (with stages), `log` (task_logs row), `checkin`
/// (id = project id), `member` (id = user id), `template` (text_templates
/// row) and `meta`.
class CachedTasks extends Table {
  TextColumn get id => text()();
  TextColumn get payload => text()(); // JSON snapshot
  DateTimeColumn get updatedAt => dateTime()();

  /// Owning project, for `task` rows. v3.
  TextColumn get projectId => text().nullable()();

  /// Row type, see class doc. v3.
  TextColumn get kind => text().withDefault(const Constant('task'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Small key/value store for local preferences (language, notification toggles).
class LocalSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Outbox, CachedTasks, LocalSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'vuon_nha'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(localSettings);
      if (from < 3) {
        await m.addColumn(outbox, outbox.clientId);
        await m.addColumn(outbox, outbox.nextAttemptAt);
        await m.addColumn(cachedTasks, cachedTasks.projectId);
        await m.addColumn(cachedTasks, cachedTasks.kind);
      }
    },
  );
}
