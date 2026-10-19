import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/date_only.dart';
import '../../plan/domain/models.dart';
import '../../plan/domain/template_renderer.dart';
import '../domain/outbox_entry.dart';
import '../domain/today_builder.dart';
import '../domain/today_snapshot.dart';
import 'task_repository.dart' show parseTaskLog;

/// An outbox entry plus its retry bookkeeping.
class QueuedAction {
  const QueuedAction(this.entry, {this.attempts = 0, this.nextAttemptAt});

  final OutboxEntry entry;
  final int attempts;
  final DateTime? nextAttemptAt;
}

/// Local persistence for Today: the offline cache and the write outbox.
abstract class TodayLocalStore {
  Future<CachedToday> readCache();

  /// Replaces cached tasks / projects / logs. `lastCheckins`, `memberNames`
  /// and [templates] are replaced only when non-null.
  Future<void> writeCache({
    required String userId,
    required TaskSnapshot snapshot,
    List<TextTemplate>? templates,
  });

  /// Drops the cache and the outbox (user changed / signed out).
  Future<void> clear();

  /// Pending actions, oldest first.
  Future<List<QueuedAction>> readOutbox();

  /// Queues [entry]. Returns false (and stores nothing) when an entry with
  /// the same clientId is already queued.
  Future<bool> enqueue(OutboxEntry entry);

  Future<void> removeOutbox(String clientId);

  Future<void> recordFailure(
    String clientId, {
    required int attempts,
    required DateTime nextAttemptAt,
  });
}

// ---------------------------------------------------------------------------
// Drift implementation
// ---------------------------------------------------------------------------

class DriftTodayLocalStore implements TodayLocalStore {
  DriftTodayLocalStore(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  static const _metaUser = 'user';

  @override
  Future<CachedToday> readCache() async {
    final rows = await _db.select(_db.cachedTasks).get();
    String? userId;
    final stages = <String, Map<String, dynamic>>{};
    final tasksByProject = <String, List<Task>>{};
    final logs = <TaskLog>[];
    final checkins = <String, DateTime>{};
    final members = <String, String>{};
    final templates = <TextTemplate>[];
    final projectRows = <Map<String, dynamic>>[];
    for (final r in rows) {
      final data = jsonDecode(r.payload);
      final rid = r.id.substring(r.kind.length + 1); // ids are `kind:id`
      try {
        switch (r.kind) {
          case 'meta':
            if (rid == _metaUser) userId = (data as Map)['value'] as String?;
          case 'project':
            projectRows.add(Map<String, dynamic>.from(data as Map));
          case 'task':
            (tasksByProject[r.projectId ?? ''] ??= []).add(
              Task.fromJson(Map<String, dynamic>.from(data as Map)),
            );
          case 'log':
            logs.add(parseTaskLog(Map<String, dynamic>.from(data as Map)));
          case 'checkin':
            checkins[rid] = parseIsoDate((data as Map)['date'] as String);
          case 'member':
            members[rid] = (data as Map)['name'] as String? ?? '';
          case 'template':
            templates.add(
              TextTemplate.fromJson(Map<String, dynamic>.from(data as Map)),
            );
        }
      } on FormatException {
        continue;
      }
    }
    stages.clear();
    final projects = <TodayProject>[
      for (final p in projectRows)
        TodayProject(
          id: p['id'] as String,
          name: (p['name'] as String?) ?? '',
          startDate: parseIsoDate(p['start_date'] as String),
          stages: [
            for (final s in (p['stages'] as List? ?? const []))
              Stage.fromJson(Map<String, dynamic>.from(s as Map)),
          ],
          tasks: tasksByProject[p['id']] ?? const [],
        ),
    ]..sort((a, b) => a.name.compareTo(b.name));
    logs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return CachedToday(
      userId: userId,
      snapshot: TaskSnapshot(
        projects: projects,
        logs: logs,
        lastCheckins: checkins,
        memberNames: members,
      ),
      templates: templates,
    );
  }

  CachedTasksCompanion _row(
    String id,
    String kind,
    Object payload, {
    String? projectId,
  }) => CachedTasksCompanion.insert(
    id: '$kind:$id',
    payload: jsonEncode(payload),
    updatedAt: _clock(),
    projectId: Value(projectId),
    kind: Value(kind),
  );

  @override
  Future<void> writeCache({
    required String userId,
    required TaskSnapshot snapshot,
    List<TextTemplate>? templates,
  }) async {
    await _db.transaction(() async {
      final kinds = <String>{
        'task',
        'project',
        'log',
        'meta',
        if (snapshot.lastCheckins != null) 'checkin',
        if (snapshot.memberNames != null) 'member',
        if (templates != null) 'template',
      };
      await (_db.delete(
        _db.cachedTasks,
      )..where((t) => t.kind.isIn(kinds))).go();
      final rows = <CachedTasksCompanion>[
        _row(_metaUser, 'meta', {'value': userId}),
        for (final p in snapshot.projects) ...[
          _row(p.id, 'project', {
            'id': p.id,
            'name': p.name,
            'start_date': formatIsoDate(p.startDate),
            'stages': [for (final s in p.stages) s.toJson()],
          }),
          for (final t in p.tasks)
            _row(t.id, 'task', t.toJson(), projectId: p.id),
        ],
        for (final l in snapshot.logs)
          _row(l.id, 'log', {
            'id': l.id,
            'task_id': l.taskId,
            'occurrence_date': formatIsoDate(l.occurrenceDate),
            'user_id': l.userId,
            'action': l.action.db,
            'skip_reason': l.skipReason,
            'snooze_until': l.snoozeUntil == null
                ? null
                : formatIsoDate(l.snoozeUntil!),
            'client_id': l.clientId,
            'created_at': l.createdAt.toUtc().toIso8601String(),
            'acted_on': formatIsoDate(l.actedOn),
          }),
        for (final e
            in (snapshot.lastCheckins ?? const <String, DateTime>{}).entries)
          _row(e.key, 'checkin', {'date': formatIsoDate(e.value)}),
        for (final e
            in (snapshot.memberNames ?? const <String, String>{}).entries)
          _row(e.key, 'member', {'name': e.value}),
        for (final t in templates ?? const <TextTemplate>[])
          _row('${t.lang}|${t.kind}|${t.code}|${t.field}', 'template', {
            'kind': t.kind,
            'code': t.code,
            'lang': t.lang,
            'field': t.field,
            'body': t.body,
          }),
      ];
      await _db.batch((b) => b.insertAll(_db.cachedTasks, rows));
    });
  }

  @override
  Future<void> clear() async {
    await _db.transaction(() async {
      await _db.delete(_db.cachedTasks).go();
      await _db.delete(_db.outbox).go();
    });
  }

  @override
  Future<List<QueuedAction>> readOutbox() async {
    final rows = await (_db.select(
      _db.outbox,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final out = <QueuedAction>[];
    for (final r in rows) {
      try {
        out.add(
          QueuedAction(
            OutboxEntry.fromJson(
              Map<String, dynamic>.from(jsonDecode(r.payload) as Map),
            ),
            attempts: r.attempts,
            nextAttemptAt: r.nextAttemptAt,
          ),
        );
      } on FormatException {
        continue;
      }
    }
    return out;
  }

  @override
  Future<bool> enqueue(OutboxEntry entry) async {
    final existing = await (_db.select(
      _db.outbox,
    )..where((t) => t.clientId.equals(entry.clientId))).get();
    if (existing.isNotEmpty) return false;
    await _db
        .into(_db.outbox)
        .insert(
          OutboxCompanion.insert(
            op: entry.action.db,
            payload: jsonEncode(entry.toJson()),
            createdAt: entry.createdAt,
            clientId: Value(entry.clientId),
          ),
        );
    return true;
  }

  @override
  Future<void> removeOutbox(String clientId) =>
      (_db.delete(_db.outbox)..where((t) => t.clientId.equals(clientId))).go();

  @override
  Future<void> recordFailure(
    String clientId, {
    required int attempts,
    required DateTime nextAttemptAt,
  }) =>
      (_db.update(_db.outbox)..where((t) => t.clientId.equals(clientId))).write(
        OutboxCompanion(
          attempts: Value(attempts),
          nextAttemptAt: Value(nextAttemptAt),
        ),
      );
}

// ---------------------------------------------------------------------------
// In-memory implementation (tests, and fallback when drift is unavailable)
// ---------------------------------------------------------------------------

class MemoryTodayLocalStore implements TodayLocalStore {
  String? _userId;
  TaskSnapshot _snap = TaskSnapshot.empty;
  List<TextTemplate> _templates = const [];
  final List<QueuedAction> _outbox = [];

  @override
  Future<CachedToday> readCache() async =>
      CachedToday(userId: _userId, snapshot: _snap, templates: _templates);

  @override
  Future<void> writeCache({
    required String userId,
    required TaskSnapshot snapshot,
    List<TextTemplate>? templates,
  }) async {
    _userId = userId;
    _snap = TaskSnapshot(
      projects: snapshot.projects,
      logs: snapshot.logs,
      lastCheckins: snapshot.lastCheckins ?? _snap.lastCheckins,
      memberNames: snapshot.memberNames ?? _snap.memberNames,
    );
    if (templates != null) _templates = templates;
  }

  @override
  Future<void> clear() async {
    _userId = null;
    _snap = TaskSnapshot.empty;
    _templates = const [];
    _outbox.clear();
  }

  @override
  Future<List<QueuedAction>> readOutbox() async => List.of(_outbox);

  @override
  Future<bool> enqueue(OutboxEntry entry) async {
    if (_outbox.any((q) => q.entry.clientId == entry.clientId)) return false;
    _outbox.add(QueuedAction(entry));
    return true;
  }

  @override
  Future<void> removeOutbox(String clientId) async =>
      _outbox.removeWhere((q) => q.entry.clientId == clientId);

  @override
  Future<void> recordFailure(
    String clientId, {
    required int attempts,
    required DateTime nextAttemptAt,
  }) async {
    final i = _outbox.indexWhere((q) => q.entry.clientId == clientId);
    if (i < 0) return;
    _outbox[i] = QueuedAction(
      _outbox[i].entry,
      attempts: attempts,
      nextAttemptAt: nextAttemptAt,
    );
  }
}
