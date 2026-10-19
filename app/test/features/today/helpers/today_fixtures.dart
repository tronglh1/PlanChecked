import 'dart:async';
import 'dart:io';

import 'package:vuon_nha/features/plan/domain/enums.dart';
import 'package:vuon_nha/features/plan/domain/models.dart';
import 'package:vuon_nha/features/plan/domain/template_renderer.dart';
import 'package:vuon_nha/features/today/data/notification_gateway.dart';
import 'package:vuon_nha/features/today/data/task_repository.dart';
import 'package:vuon_nha/features/today/domain/outbox_entry.dart';
import 'package:vuon_nha/features/today/domain/reminder_planner.dart';
import 'package:vuon_nha/features/today/domain/today_builder.dart';
import 'package:vuon_nha/features/today/domain/today_snapshot.dart';

/// Monday 19/10/2026, 07:00 local.
final DateTime kNow = DateTime(2026, 10, 19, 7, 0);
final DateTime kToday = DateTime.utc(2026, 10, 19);

const kStage = Stage(
  id: 's1',
  planId: 'pl1',
  idx: 0,
  code: 'S2_growth',
  name: 'Sinh trưởng',
  dayFrom: 1,
  dayTo: 60,
);

const kWater = Task(
  id: 't-water',
  projectId: 'p1',
  stageId: 's1',
  taskCode: 'T_WATER',
  window: TaskWindow.morning,
  frequency: Frequency.daily,
  reminderTime: '06:30',
);

const kFert = Task(
  id: 't-fert',
  projectId: 'p1',
  stageId: 's1',
  taskCode: 'T_FERT_ORGANIC',
  window: TaskWindow.afternoon,
  frequency: Frequency.everyNDays,
  intervalDays: 3,
  reminderTime: '16:30',
);

const kPrune = Task(
  id: 't-prune',
  projectId: 'p2',
  stageId: 's1',
  taskCode: 'T_PRUNE',
  window: TaskWindow.morning,
  frequency: Frequency.daily,
);

TodayProject project({
  String id = 'p1',
  String name = 'Cà chua bi',
  List<Task> tasks = const [kWater, kFert],
  DateTime? start,
}) => TodayProject(
  id: id,
  name: name,
  startDate: start ?? DateTime.utc(2026, 10, 19),
  stages: const [kStage],
  tasks: tasks,
);

final kTemplates = <TextTemplate>[
  const TextTemplate(
    kind: 'task',
    code: 'T_WATER',
    lang: 'vi',
    field: 'name',
    body: 'Tưới nước',
  ),
  const TextTemplate(
    kind: 'task',
    code: 'T_WATER',
    lang: 'vi',
    field: 'steps',
    body: '- Tưới đẫm gốc\n- Tránh ướt lá',
  ),
  const TextTemplate(
    kind: 'task',
    code: 'T_WATER',
    lang: 'vi',
    field: 'why',
    body: 'Đất cần ẩm đều.',
  ),
  const TextTemplate(
    kind: 'task',
    code: 'T_FERT_ORGANIC',
    lang: 'vi',
    field: 'name',
    body: 'Bón phân hữu cơ',
  ),
  const TextTemplate(
    kind: 'task',
    code: 'T_PRUNE',
    lang: 'vi',
    field: 'name',
    body: 'Tỉa lá',
  ),
];

ReminderTexts testTexts() => ReminderTexts(
  windowTitle: (w) => 'W:${w.db}',
  taskBody: (names) => names.join('+'),
  dailyTitle: (n) => 'Daily:$n',
  checkinTitle: () => 'Checkin',
  checkinBody: (p) => 'Chup $p',
  channels: const ReminderChannels(
    taskName: 'Task channel',
    taskDescription: 'Task channel description',
    checkinName: 'Check-in channel',
    checkinDescription: 'Check-in channel description',
  ),
);

OutboxEntry entry(
  String clientId,
  String taskId,
  TaskAction action, {
  DateTime? date,
  DateTime? at,
  DateTime? snoozeUntil,
  String? reason,
}) => OutboxEntry(
  clientId: clientId,
  taskId: taskId,
  occurrenceDate: date ?? kToday,
  action: action,
  userId: 'u1',
  createdAt: at ?? kNow,
  snoozeUntil: snoozeUntil,
  skipReason: reason,
);

/// Server stand-in: dedups on client_id, can be switched offline.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({this.projects = const [], this.lastCheckins});

  List<TodayProject> projects;
  Map<String, DateTime>? lastCheckins;
  bool offline = false;
  Object? failWith;
  final List<OutboxEntry> inserted = [];
  final Set<String> _ids = {};
  int insertCalls = 0;
  int fetchCalls = 0;

  @override
  Future<TaskSnapshot> fetchSnapshot({required DateTime today}) async {
    fetchCalls++;
    if (offline) throw const SocketException('offline');
    return TaskSnapshot(
      projects: projects,
      logs: [
        for (final e in inserted)
          TaskLog(
            id: 'log-${e.clientId}',
            taskId: e.taskId,
            occurrenceDate: e.occurrenceDate,
            userId: e.userId,
            action: e.action,
            createdAt: e.createdAt,
            actedOn: e.actedOn,
            snoozeUntil: e.snoozeUntil,
            skipReason: e.skipReason,
            clientId: e.clientId,
          ),
      ],
      lastCheckins: lastCheckins ?? const {},
      memberNames: const {},
    );
  }

  @override
  Future<void> insertLog(OutboxEntry entry) async {
    insertCalls++;
    if (offline) throw const SocketException('offline');
    if (failWith != null) throw failWith!;
    if (!_ids.add(entry.clientId)) return; // server unique(user_id, client_id)
    inserted.add(entry);
  }

  @override
  Stream<void> changes() => const Stream.empty();
}

class FakeNotificationGateway implements NotificationGateway {
  FakeNotificationGateway({this.granted = true});

  bool granted;
  int permissionRequests = 0;
  List<PlannedNotification> scheduled = const [];
  int replaceCalls = 0;

  @override
  Future<void> init({String timezone = 'Asia/Ho_Chi_Minh'}) async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    granted = true;
    return true;
  }

  /// Channel texts passed with the last [replaceAll].
  ReminderChannels? lastChannels;

  @override
  Future<bool> isPermissionGranted() async => granted;

  @override
  Future<void> replaceAll(
    List<PlannedNotification> items, {
    ReminderChannels? channels,
  }) async {
    replaceCalls++;
    scheduled = items;
    lastChannels = channels;
  }

  @override
  Stream<String> get taps => const Stream.empty();
}
