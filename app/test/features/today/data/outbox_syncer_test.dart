import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/core/db/app_database.dart';
import 'package:vuon_nha/features/plan/domain/enums.dart';
import 'package:vuon_nha/features/today/data/outbox_syncer.dart';
import 'package:vuon_nha/features/today/data/today_local_store.dart';
import 'package:vuon_nha/features/today/domain/today_snapshot.dart';

import '../helpers/today_fixtures.dart';

void main() {
  late MemoryTodayLocalStore store;
  late FakeTaskRepository repo;
  late DateTime now;
  late OutboxSyncer syncer;

  setUp(() {
    store = MemoryTodayLocalStore();
    repo = FakeTaskRepository();
    now = kNow;
    syncer = OutboxSyncer(store: store, repository: repo, clock: () => now);
  });

  test('flushes the queue in order and empties it', () async {
    await store.enqueue(entry('c1', 't-water', TaskAction.done));
    await store.enqueue(
      entry('c2', 't-fert', TaskAction.skip, reason: 'Trời mưa'),
    );
    final r = await syncer.flush();
    expect(r.sent, 2);
    expect(r.remaining, 0);
    expect(repo.inserted.map((e) => e.clientId), ['c1', 'c2']);
    expect(repo.inserted.last.skipReason, 'Trời mưa');
    expect(await store.readOutbox(), isEmpty);
  });

  test('enqueue ignores a duplicate client_id', () async {
    expect(await store.enqueue(entry('c1', 't-water', TaskAction.done)), true);
    expect(await store.enqueue(entry('c1', 't-water', TaskAction.done)), false);
    expect((await store.readOutbox()).length, 1);
  });

  test('offline: keeps everything queued and stops', () async {
    repo.offline = true;
    await store.enqueue(entry('c1', 't-water', TaskAction.done));
    await store.enqueue(entry('c2', 't-fert', TaskAction.done));
    final r = await syncer.flush();
    expect(r.offline, true);
    expect(r.sent, 0);
    expect(r.remaining, 2);
    expect(repo.insertCalls, 1); // stopped after the first network failure

    repo.offline = false;
    final r2 = await syncer.flush();
    expect(r2.sent, 2);
    expect(r2.remaining, 0);
  });

  test('retry after the server stored the row does not duplicate it', () async {
    await store.enqueue(entry('c1', 't-water', TaskAction.done));
    await syncer.flush();
    // Same action replayed (e.g. the local delete was lost): server dedups.
    await store.enqueue(entry('c1', 't-water', TaskAction.done));
    await syncer.flush();
    expect(repo.inserted, hasLength(1));
    expect(repo.insertCalls, 2);
  });

  test('concurrent flushes share one run', () async {
    await store.enqueue(entry('c1', 't-water', TaskAction.done));
    final a = syncer.flush();
    final b = syncer.flush();
    await Future.wait([a, b]);
    expect(repo.insertCalls, 1);
  });

  test('server error backs off, then retries after the delay', () async {
    repo.failWith = StateError('rls');
    await store.enqueue(entry('c1', 't-water', TaskAction.done));
    var r = await syncer.flush();
    expect(r.failed, 1);
    var q = (await store.readOutbox()).single;
    expect(q.attempts, 1);
    expect(q.nextAttemptAt, now.add(outboxBackoff(1)));

    // Within the backoff window nothing is tried.
    r = await syncer.flush();
    expect(repo.insertCalls, 1);
    expect(r.remaining, 1);

    now = now.add(const Duration(minutes: 1));
    repo.failWith = null;
    r = await syncer.flush();
    expect(r.sent, 1);
  });

  test('a poisoned entry is dropped after maxAttempts', () async {
    syncer = OutboxSyncer(
      store: store,
      repository: repo,
      clock: () => now,
      maxAttempts: 2,
    );
    repo.failWith = StateError('rls');
    await store.enqueue(entry('c1', 't-water', TaskAction.done));
    await syncer.flush();
    final r = await syncer.flush(force: true);
    expect(r.dropped, 1);
    expect(r.remaining, 0);
  });

  test('backoff doubles and is capped at 15 minutes', () {
    expect(outboxBackoff(1), const Duration(seconds: 5));
    expect(outboxBackoff(2), const Duration(seconds: 10));
    expect(outboxBackoff(3), const Duration(seconds: 20));
    expect(outboxBackoff(30), const Duration(minutes: 15));
    expect(isNetworkError(const SocketException('x')), true);
    expect(isNetworkError(StateError('x')), false);
  });

  group('DriftTodayLocalStore', () {
    late AppDatabase db;
    late DriftTodayLocalStore drift;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      drift = DriftTodayLocalStore(db, clock: () => kNow);
    });
    tearDown(() => db.close());

    test('outbox: enqueue, dedup, failure bookkeeping, remove', () async {
      expect(
        await drift.enqueue(entry('c1', 't-water', TaskAction.done)),
        true,
      );
      expect(
        await drift.enqueue(entry('c1', 't-water', TaskAction.done)),
        false,
      );
      await drift.enqueue(
        entry(
          'c2',
          't-fert',
          TaskAction.snooze,
          snoozeUntil: DateTime.utc(2026, 10, 20),
        ),
      );
      await drift.recordFailure(
        'c2',
        attempts: 3,
        nextAttemptAt: kNow.add(const Duration(minutes: 1)),
      );
      final q = await drift.readOutbox();
      expect(q.map((e) => e.entry.clientId), ['c1', 'c2']);
      expect(q[1].attempts, 3);
      expect(q[1].entry.snoozeUntil, DateTime.utc(2026, 10, 20));
      await drift.removeOutbox('c1');
      expect((await drift.readOutbox()).length, 1);
    });

    test('cache round trip keeps tasks, stages, logs, check-ins', () async {
      final repo2 = FakeTaskRepository(projects: [project()]);
      repo2.lastCheckins = {'p1': DateTime.utc(2026, 10, 17)};
      await repo2.insertLog(entry('c9', 't-water', TaskAction.done));
      final snap = await repo2.fetchSnapshot(today: kToday);
      await drift.writeCache(
        userId: 'u1',
        snapshot: snap,
        templates: kTemplates,
      );
      final c = await drift.readCache();
      expect(c.userId, 'u1');
      final p = c.snapshot.projects.single;
      expect(p.name, 'Cà chua bi');
      expect(p.tasks.map((t) => t.id).toSet(), {'t-water', 't-fert'});
      expect(p.stages.single.code, 'S2_growth');
      expect(c.snapshot.logs.single.clientId, 'c9');
      expect(c.snapshot.lastCheckins, {'p1': DateTime.utc(2026, 10, 17)});
      expect(c.templates.length, kTemplates.length);

      // A refresh without check-ins / templates keeps the cached ones.
      await drift.writeCache(
        userId: 'u1',
        snapshot: TaskSnapshot(projects: [project()]),
      );
      final c2 = await drift.readCache();
      expect(c2.snapshot.lastCheckins, isNotEmpty);
      expect(c2.templates, isNotEmpty);
      expect(c2.snapshot.logs, isEmpty);

      await drift.enqueue(entry('c1', 't-water', TaskAction.done));
      await drift.clear();
      expect((await drift.readCache()).snapshot.projects, isEmpty);
      expect(await drift.readOutbox(), isEmpty);
    });
  });
}
