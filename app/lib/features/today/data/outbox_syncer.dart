import 'dart:async';

import '../domain/outbox_entry.dart';
import 'task_repository.dart';
import 'today_local_store.dart';

/// Retry delay after the [attempts]-th failure: 5s, 10s, 20s ... capped at
/// 15 minutes.
Duration outboxBackoff(int attempts) {
  final n = attempts < 1 ? 1 : attempts;
  final secs = 5 * (1 << (n > 10 ? 10 : n - 1));
  return Duration(seconds: secs > 900 ? 900 : secs);
}

/// True for failures that mean "no connection" (retry later, stop the run).
bool isNetworkError(Object e) {
  if (e is TimeoutException) return true;
  final s = e.runtimeType.toString() + e.toString();
  return s.contains('SocketException') ||
      s.contains('ClientException') ||
      s.contains('Failed host lookup') ||
      s.contains('AuthRetryableFetchException') ||
      s.contains('Connection');
}

class FlushResult {
  const FlushResult({
    this.sent = 0,
    this.failed = 0,
    this.dropped = 0,
    this.remaining = 0,
    this.offline = false,
  });

  /// Entries accepted by the server in this run.
  final int sent;

  /// Entries that failed and were rescheduled with backoff.
  final int failed;

  /// Entries discarded after too many non-network failures.
  final int dropped;

  /// Entries still queued afterwards.
  final int remaining;

  /// The run stopped because the network was unreachable.
  final bool offline;
}

/// Flushes the outbox to `task_logs`. Safe to call repeatedly; concurrent
/// calls share one run. Order is preserved; duplicates (same clientId) are
/// collapsed; the server also dedups on `client_id`.
class OutboxSyncer {
  OutboxSyncer({
    required TodayLocalStore store,
    required TaskRepository repository,
    DateTime Function()? clock,
    this.maxAttempts = 12,
  }) : _store = store,
       _repo = repository,
       _clock = clock ?? DateTime.now;

  final TodayLocalStore _store;
  final TaskRepository _repo;
  final DateTime Function() _clock;

  /// Non-network failures (e.g. RLS rejection) are dropped after this many
  /// attempts so one poisoned entry cannot block the queue forever.
  final int maxAttempts;

  Future<FlushResult>? _running;

  /// [force] ignores backoff timers (e.g. user pulled to refresh).
  Future<FlushResult> flush({bool force = false}) =>
      _running ??= _run(force).whenComplete(() => _running = null);

  Future<FlushResult> _run(bool force) async {
    final queue = await _store.readOutbox();
    final seen = <String>{};
    final now = _clock();
    var sent = 0, failed = 0, dropped = 0;
    var offline = false;
    for (final q in queue) {
      if (!seen.add(q.entry.clientId)) continue;
      final next = q.nextAttemptAt;
      if (!force && next != null && next.isAfter(now)) continue;
      try {
        await _repo.insertLog(q.entry);
        await _store.removeOutbox(q.entry.clientId);
        sent++;
      } catch (e) {
        final attempts = q.attempts + 1;
        if (isNetworkError(e)) {
          // No connection: leave the queue untouched and retry on the next
          // trigger (timer / app resume / new action).
          offline = true;
          break;
        }
        if (attempts >= maxAttempts) {
          await _store.removeOutbox(q.entry.clientId);
          dropped++;
        } else {
          await _store.recordFailure(
            q.entry.clientId,
            attempts: attempts,
            nextAttemptAt: now.add(outboxBackoff(attempts)),
          );
          failed++;
        }
      }
    }
    final remaining = (await _store.readOutbox()).length;
    return FlushResult(
      sent: sent,
      failed: failed,
      dropped: dropped,
      remaining: remaining,
      offline: offline,
    );
  }
}
