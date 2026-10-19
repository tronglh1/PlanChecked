/// Project models (docs/spec-mvp.md §4.1/§4.2). Pure Dart.
library;

import '../../../core/utils/date_only.dart';
import '../../plan/domain/models.dart';
import '../../plants/domain/plant.dart';
import 'project_progress.dart';

/// `space` enum. `rooftop` has no label in the mockup (spec §7).
enum Space {
  indoor('indoor'),
  balcony('balcony'),
  yard('yard'),
  rooftop('rooftop');

  const Space(this.db);
  final String db;

  static Space fromDb(Object? v) =>
      values.firstWhere((e) => e.db == v, orElse: () => Space.balcony);
}

/// `sun_level` (1-4 in the AI doc, three labelled options in the mockup).
/// Mapping used: under 3h = 2, 3-6h = 3 (matches the `sun3` example key),
/// over 6h = 4.
enum SunLevel {
  low(2),
  medium(3),
  high(4);

  const SunLevel(this.db);
  final int db;

  static SunLevel fromDb(Object? v) {
    final n = v is num ? v.toInt() : int.tryParse('$v') ?? 3;
    if (n <= 2) return SunLevel.low;
    if (n == 3) return SunLevel.medium;
    return SunLevel.high;
  }
}

/// `start_stage` (proposed values).
enum StartStage {
  seed('seed'),
  seedling('seedling'),
  mature('mature');

  const StartStage(this.db);
  final String db;

  static StartStage fromDb(Object? v) =>
      values.firstWhere((e) => e.db == v, orElse: () => StartStage.seed);
}

enum Watering {
  manual('manual'),
  auto('auto');

  const Watering(this.db);
  final String db;

  static Watering fromDb(Object? v) =>
      values.firstWhere((e) => e.db == v, orElse: () => Watering.manual);
}

enum ProjectStatus {
  active('active'),
  done('done'),
  failed('failed'),
  archived('archived');

  const ProjectStatus(this.db);
  final String db;

  static ProjectStatus fromDb(Object? v) =>
      values.firstWhere((e) => e.db == v, orElse: () => ProjectStatus.active);
}

/// Row of `projects`.
class Project {
  const Project({
    required this.id,
    this.householdId,
    required this.ownerId,
    this.plantId,
    required this.name,
    required this.startDate,
    this.startStage = StartStage.seed,
    this.potCount = 1,
    this.space = Space.balcony,
    this.sunLevel = SunLevel.medium,
    this.potType,
    this.watering = Watering.manual,
    this.coverPath,
    this.status = ProjectStatus.active,
  });

  final String id;
  final String? householdId;
  final String ownerId;
  final String? plantId;
  final String name;
  final DateTime startDate;
  final StartStage startStage;
  final int potCount;
  final Space space;
  final SunLevel sunLevel;
  final String? potType;
  final Watering watering;
  final String? coverPath;
  final ProjectStatus status;

  bool get isShared => householdId != null;

  factory Project.fromJson(Map<String, dynamic> j) => Project(
    id: j['id'].toString(),
    householdId: j['household_id'] as String?,
    ownerId: (j['owner_id'] ?? '').toString(),
    plantId: j['plant_id']?.toString(),
    name: (j['name'] as String?) ?? '',
    startDate: parseIsoDate(j['start_date'] as String),
    startStage: StartStage.fromDb(j['start_stage']),
    potCount: (j['pot_count'] as num?)?.toInt() ?? 1,
    space: Space.fromDb(j['space']),
    sunLevel: SunLevel.fromDb(j['sun_level']),
    potType: j['pot_type'] as String?,
    watering: Watering.fromDb(j['watering']),
    coverPath: j['cover_path'] as String?,
    status: ProjectStatus.fromDb(j['status']),
  );
}

/// Input of screen 08 (PRJ-02/03).
class NewProject {
  const NewProject({
    this.plantId,
    this.plantName,
    required this.name,
    required this.startDate,
    this.startStage = StartStage.seed,
    this.potCount = 1,
    this.space = Space.balcony,
    this.sunLevel = SunLevel.medium,
    this.potType,
    this.watering = Watering.manual,
    this.coverPath,
  });

  /// Catalogue plant, or null for a free-text plant (then [plantName] set).
  final String? plantId;
  final String? plantName;
  final String name;
  final DateTime startDate;
  final StartStage startStage;
  final int potCount;
  final Space space;
  final SunLevel sunLevel;
  final String? potType;
  final Watering watering;
  final String? coverPath;
}

/// One card of the project list (PRJ-01, PRJ-04).
class ProjectSummary {
  const ProjectSummary({
    required this.project,
    this.plantNameVi,
    this.plantNameEn,
    this.group,
    this.progress,
    this.planStatus,
    this.todayTaskCount = 0,
    this.latestPhotoPath,
    this.latestPhotoAt,
  });

  final Project project;
  final String? plantNameVi;
  final String? plantNameEn;
  final PlantGroup? group;

  /// Null when the project has no usable plan yet.
  final ProjectProgress? progress;

  /// `draft` / `approved` of the plan that was used, null = no plan.
  final String? planStatus;
  final int todayTaskCount;
  final String? latestPhotoPath;
  final DateTime? latestPhotoAt;

  Stage? get currentStage => progress?.currentStage;

  String plantName(String lang) =>
      (lang == 'en' && (plantNameEn?.isNotEmpty ?? false))
      ? plantNameEn!
      : (plantNameVi ?? project.name);
}

/// A logged action on a task (TSK-06 history). [action] is the
/// `task_logs.action` string (done / skip / snooze).
class TaskHistoryEntry {
  const TaskHistoryEntry({
    required this.taskId,
    required this.taskCode,
    required this.action,
    required this.occurrenceDate,
    this.userId,
    this.userName,
    required this.createdAt,
  });

  final String taskId;
  final String taskCode;
  final String action;
  final DateTime occurrenceDate;
  final String? userId;
  final String? userName;
  final DateTime createdAt;
}

/// Everything the project detail screen needs besides the plan.
class ProjectDetail {
  const ProjectDetail({
    required this.project,
    this.plantNameVi,
    this.plantNameEn,
    this.group,
    this.memberNames = const {},
    this.checkinCount = 0,
    this.photoPaths = const [],
  });

  final Project project;
  final String? plantNameVi;
  final String? plantNameEn;
  final PlantGroup? group;

  /// user id -> display name for household members.
  final Map<String, String> memberNames;
  final int checkinCount;

  /// Newest first (storage paths).
  final List<String> photoPaths;

  String plantName(String lang) =>
      (lang == 'en' && (plantNameEn?.isNotEmpty ?? false))
      ? plantNameEn!
      : (plantNameVi ?? project.name);
}
