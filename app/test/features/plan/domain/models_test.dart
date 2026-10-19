import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/plan/domain/enums.dart';
import 'package:vuon_nha/features/plan/domain/models.dart';

void main() {
  group('enums', () {
    test('DB values match spec §4.1', () {
      expect(TaskWindow.allDay.db, 'all_day');
      expect(Frequency.everyNDays.db, 'every_n_days');
      expect(Frequency.fixedDate.db, 'fixed_date');
      expect(AssignmentMode.rotation.db, 'rotation');
      expect(TaskAction.snooze.db, 'snooze');
      expect(PlanSource.fallback.db, 'fallback');
      expect(PlanStatus.superseded.db, 'superseded');
    });

    test('fromDb round trips every value and rejects unknown', () {
      for (final v in TaskWindow.values) {
        expect(TaskWindow.fromDb(v.db), v);
      }
      for (final v in Frequency.values) {
        expect(Frequency.fromDb(v.db), v);
      }
      for (final v in TaskAction.values) {
        expect(TaskAction.fromDb(v.db), v);
      }
      expect(() => TaskWindow.fromDb('night'), throwsFormatException);
      expect(() => Frequency.fromDb(null), throwsFormatException);
    });
  });

  group('models JSON', () {
    test('Task round trip', () {
      final json = {
        'id': 't1',
        'project_id': 'p1',
        'stage_id': 's1',
        'task_code': 'T_WATER',
        'window': 'morning',
        'frequency': 'every_n_days',
        'interval_days': 2,
        'reminder_time': '06:30',
        'assignee_id': 'u1',
        'assignment_mode': 'rotation',
        'rotation_order': 1,
        'source': 'ai',
        'status': 'active',
        'xp': 10,
      };
      final t = Task.fromJson(json);
      expect(t.window, TaskWindow.morning);
      expect(t.frequency, Frequency.everyNDays);
      expect(t.assignmentMode, AssignmentMode.rotation);
      expect(t.source, TaskSource.ai);
      final out = t.toJson();
      for (final k in json.keys) {
        expect(out[k], json[k], reason: k);
      }
    });

    test('Task defaults for missing optional columns', () {
      final t = Task.fromJson({
        'id': 't',
        'project_id': 'p',
        'task_code': 'T_WATER',
        'window': 'all_day',
        'frequency': 'daily',
      });
      expect(t.stageId, isNull);
      expect(t.assignmentMode, AssignmentMode.once);
      expect(t.source, TaskSource.template);
      expect(t.isActive, isTrue);
      expect(t.xp, 10);
    });

    test('fixed_date parses as date-only', () {
      final t = Task.fromJson({
        'id': 't',
        'project_id': 'p',
        'task_code': 'T_X',
        'window': 'morning',
        'frequency': 'fixed_date',
        'fixed_date': '2026-11-20',
      });
      expect(t.fixedDate, DateTime.utc(2026, 11, 20));
      expect(t.toJson()['fixed_date'], '2026-11-20');
    });

    test('Plan with stages sorts stages by idx and parses confidence', () {
      final p = Plan.fromJson({
        'id': 'pl',
        'project_id': 'p',
        'version': 2,
        'source': 'template',
        'confidence': 0.86,
        'status': 'approved',
        'approved_at': '2026-10-19T03:00:00Z',
        'stages': [
          {
            'id': 's2',
            'plan_id': 'pl',
            'idx': 1,
            'code': 'veg',
            'name': 'Sinh trưởng',
            'day_from': 15,
            'day_to': 40,
          },
          {
            'id': 's1',
            'plan_id': 'pl',
            'idx': 0,
            'code': 'seedling',
            'name': 'Cây con',
            'day_from': 1,
            'day_to': 14,
            'milestone_code': 'SPROUT',
          },
        ],
      });
      expect(p.stages.map((s) => s.id), ['s1', 's2']);
      expect(p.confidence, 0.86);
      expect(p.status, PlanStatus.approved);
      expect(p.approvedAt, DateTime.utc(2026, 10, 19, 3));
      expect(p.stages.first.milestoneCode, 'SPROUT');
      expect(p.stages.first.lengthDays, 14);
      expect(Plan.fromJson(p.toJson()).stages.length, 2);
    });

    test('unknown enum value in a row throws FormatException', () {
      expect(
        () => Task.fromJson({
          'id': 't',
          'project_id': 'p',
          'task_code': 'T',
          'window': 'night',
          'frequency': 'daily',
        }),
        throwsFormatException,
      );
    });

    test('occurrence key is stable', () {
      final o = TaskOccurrence(
        taskId: 'a',
        projectId: 'p',
        date: DateTime.utc(2026, 3, 4),
        window: TaskWindow.morning,
      );
      expect(o.key, 'a|2026-03-04');
    });
  });
}
