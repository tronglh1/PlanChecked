import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Tiny async key/value store for per-device preferences.
abstract class LocalPrefs {
  Future<String?> get(String key);
  Future<void> set(String key, String value);
}

class DriftLocalPrefs implements LocalPrefs {
  DriftLocalPrefs(this._db);
  final AppDatabase _db;

  @override
  Future<String?> get(String key) async {
    final row = await (_db.select(
      _db.localSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> set(String key, String value) => _db
      .into(_db.localSettings)
      .insertOnConflictUpdate(
        LocalSettingsCompanion.insert(key: key, value: value),
      );
}

/// In-memory implementation for tests.
class MemoryLocalPrefs implements LocalPrefs {
  final Map<String, String> _map = {};

  @override
  Future<String?> get(String key) async => _map[key];

  @override
  Future<void> set(String key, String value) async => _map[key] = value;
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final localPrefsProvider = Provider<LocalPrefs>(
  (ref) => DriftLocalPrefs(ref.watch(appDatabaseProvider)),
);
