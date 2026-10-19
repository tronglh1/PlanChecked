/// Enums from docs/spec-mvp.md §4.1. Each carries the exact DB string.
library;

T _fromDb<T>(List<T> values, String Function(T) db, Object? v, String name) {
  for (final e in values) {
    if (db(e) == v) return e;
  }
  throw FormatException('Unknown $name value', v);
}

enum TaskWindow {
  morning('morning'),
  afternoon('afternoon'),
  allDay('all_day');

  const TaskWindow(this.db);
  final String db;

  static TaskWindow fromDb(Object? v) =>
      _fromDb(values, (e) => e.db, v, 'task_window');
}

enum Frequency {
  once('once'),
  everyNDays('every_n_days'),
  daily('daily'),
  fixedDate('fixed_date');

  const Frequency(this.db);
  final String db;

  static Frequency fromDb(Object? v) =>
      _fromDb(values, (e) => e.db, v, 'frequency');
}

enum AssignmentMode {
  once('once'),
  series('series'),
  rotation('rotation');

  const AssignmentMode(this.db);
  final String db;

  static AssignmentMode fromDb(Object? v) =>
      _fromDb(values, (e) => e.db, v, 'assignment_mode');
}

enum TaskAction {
  done('done'),
  skip('skip'),
  snooze('snooze');

  const TaskAction(this.db);
  final String db;

  static TaskAction fromDb(Object? v) =>
      _fromDb(values, (e) => e.db, v, 'task_action');
}

enum PlanSource {
  template('template'),
  ai('ai'),
  fallback('fallback');

  const PlanSource(this.db);
  final String db;

  static PlanSource fromDb(Object? v) =>
      _fromDb(values, (e) => e.db, v, 'plan_source');
}

enum PlanStatus {
  draft('draft'),
  approved('approved'),
  superseded('superseded');

  const PlanStatus(this.db);
  final String db;

  static PlanStatus fromDb(Object? v) =>
      _fromDb(values, (e) => e.db, v, 'plan_status');
}

/// `tasks.source` (template / ai / manual).
enum TaskSource {
  template('template'),
  ai('ai'),
  manual('manual');

  const TaskSource(this.db);
  final String db;

  static TaskSource fromDb(Object? v) =>
      _fromDb(values, (e) => e.db, v, 'task_source');
}
