import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/plan/domain/enums.dart';
import 'package:vuon_nha/features/today/domain/outbox_entry.dart';

void main() {
  test('JSON round trip keeps client_id, dates and snooze', () {
    final e = OutboxEntry(
      clientId: 'c-1',
      taskId: 't1',
      occurrenceDate: DateTime(2026, 11, 1, 13, 5),
      action: TaskAction.snooze,
      userId: 'u1',
      createdAt: DateTime.utc(2026, 11, 1, 8),
      snoozeUntil: DateTime.utc(2026, 11, 2),
      skipReason: null,
    );
    final j = e.toJson();
    expect(j['occurrence_date'], '2026-11-01');
    expect(j['snooze_until'], '2026-11-02');
    expect(j['action'], 'snooze');
    final back = OutboxEntry.fromJson(j);
    expect(back.clientId, 'c-1');
    expect(back.occurrenceDate, DateTime.utc(2026, 11, 1));
    expect(back.snoozeUntil, DateTime.utc(2026, 11, 2));
    expect(back.occurrenceKey, 't1|2026-11-01');
  });

  test('actedOn defaults to createdAt date, explicit value wins', () {
    final a = OutboxEntry(
      clientId: 'c',
      taskId: 't',
      occurrenceDate: DateTime.utc(2026, 11, 1),
      action: TaskAction.done,
      userId: 'u',
      createdAt: DateTime.utc(2026, 11, 1, 23, 30),
    );
    expect(a.actedOn, DateTime.utc(2026, 11, 1));
    final b = OutboxEntry(
      clientId: 'c',
      taskId: 't',
      occurrenceDate: DateTime.utc(2026, 11, 1),
      action: TaskAction.done,
      userId: 'u',
      createdAt: DateTime.utc(2026, 11, 1, 23, 30),
      actedOn: DateTime.utc(2026, 11, 2), // user in UTC+7
    );
    expect(b.actedOn, DateTime.utc(2026, 11, 2));
  });

  test('dedupe keeps first of each client_id and order', () {
    OutboxEntry e(String c, TaskAction a) => OutboxEntry(
      clientId: c,
      taskId: 't',
      occurrenceDate: DateTime.utc(2026, 11, 1),
      action: a,
      userId: 'u',
      createdAt: DateTime.utc(2026, 11, 1),
    );
    final r = OutboxEntry.dedupe([
      e('a', TaskAction.done),
      e('b', TaskAction.skip),
      e('a', TaskAction.skip),
    ]);
    expect(r.map((x) => '${x.clientId}:${x.action.db}'), ['a:done', 'b:skip']);
  });

  test('TaskLog.fromJson parses a server row', () {
    final l = TaskLog.fromJson({
      'id': 'l1',
      'task_id': 't1',
      'occurrence_date': '2026-10-31',
      'user_id': 'u1',
      'action': 'done',
      'created_at': '2026-11-01T01:00:00Z',
      'client_id': 'c1',
    });
    expect(l.action, TaskAction.done);
    expect(l.occurrenceDate, DateTime.utc(2026, 10, 31));
    expect(l.clientId, 'c1');
    expect(l.occurrenceKey, 't1|2026-10-31');
  });
}
