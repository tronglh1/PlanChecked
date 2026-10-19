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
}

/// Placeholder cache of Today's tasks (columns finalised in a later milestone).
class CachedTasks extends Table {
  TextColumn get id => text()();
  TextColumn get payload => text()(); // JSON snapshot
  DateTimeColumn get updatedAt => dateTime()();

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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(localSettings);
    },
  );
}
