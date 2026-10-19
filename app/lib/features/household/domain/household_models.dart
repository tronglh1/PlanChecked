/// Household domain models (spec §4.2, §6.6). Pure Dart.
library;

enum HouseholdRole {
  owner,
  member;

  static HouseholdRole fromDb(Object? v) =>
      v == 'owner' ? HouseholdRole.owner : HouseholdRole.member;
  String get db => name;
}

class HouseholdMember {
  const HouseholdMember({
    required this.userId,
    required this.name,
    required this.role,
    required this.joinedAt,
    this.avatarPath,
    this.awayUntil,
    this.tasksThisWeek = 0,
    this.level = 1,
    this.xpTotal = 0,
  });

  final String userId;
  final String name;
  final HouseholdRole role;
  final DateTime joinedAt;
  final String? avatarPath;

  /// `household_members.away_until` (date). Rotation skips are P2.
  final DateTime? awayUntil;
  final int tasksThisWeek;
  final int level;
  final int xpTotal;

  bool isAway(DateTime today) =>
      awayUntil != null && !awayUntil!.isBefore(today);
}

class Household {
  const Household({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.members,
    required this.myUserId,
  });

  final String id;
  final String name;
  final String ownerId;
  final List<HouseholdMember> members;
  final String myUserId;

  HouseholdMember? get me {
    for (final m in members) {
      if (m.userId == myUserId) return m;
    }
    return null;
  }

  HouseholdRole get myRole => me?.role ?? HouseholdRole.member;

  /// HSH-03/04, invites, removals: Owner only (spec §6.6).
  bool get isOwner => myRole == HouseholdRole.owner;

  /// The member who receives ownership when the owner leaves: the
  /// longest-standing other member (backend `_leave_household`).
  HouseholdMember? get successor {
    final others = members.where((m) => m.userId != myUserId).toList()
      ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
    return others.isEmpty ? null : others.first;
  }

  /// True when leaving would delete the household (last member).
  bool get leavingDeletesHousehold => successor == null;
}

/// A project visible to the user (own or shared); only the project's owner,
/// when also household Owner, can (un)share it (HSH-03).
class ShareableProject {
  const ShareableProject({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.sharedWithHousehold,
  });
  final String id;
  final String name;
  final String ownerId;
  final bool sharedWithHousehold;
}

class InviteResult {
  const InviteResult({
    required this.code,
    required this.link,
    required this.expiresAt,
    required this.role,
    this.emailSent = false,
    this.emailError,
  });
  final String code;
  final String link;
  final DateTime expiresAt;
  final HouseholdRole role;
  final bool emailSent;
  final String? emailError;

  int daysLeft(DateTime now) {
    final d = expiresAt.difference(now).inHours / 24;
    return d.ceil().clamp(0, 99);
  }
}

enum JoinError {
  invalid,
  expired,
  alreadyInHousehold,
  tooManyAttempts,
  unknown,
}

class JoinResult {
  const JoinResult.ok({this.householdId, this.role = HouseholdRole.member})
    : error = null;
  const JoinResult.failed(JoinError this.error)
    : householdId = null,
      role = HouseholdRole.member;

  final String? householdId;
  final HouseholdRole role;
  final JoinError? error;
  bool get ok => error == null;

  /// Maps the RPC `accept_invite` error string.
  static JoinError errorFromCode(String? c) => switch (c) {
    'invite_invalid' => JoinError.invalid,
    'invite_expired' => JoinError.expired,
    'already_in_household' => JoinError.alreadyInHousehold,
    'too_many_attempts' => JoinError.tooManyAttempts,
    _ => JoinError.unknown,
  };
}

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.actorId,
    this.projectId,
    this.payload = const {},
  });
  final String id;

  /// task_done | checkin | milestone | member_joined | member_left |
  /// project_shared
  final String kind;
  final DateTime createdAt;
  final String? actorId;
  final String? projectId;
  final Map<String, dynamic> payload;
}

enum AssignMode {
  once,
  series,
  rotation;

  static AssignMode fromDb(Object? v) => AssignMode.values.firstWhere(
    (e) => e.name == v,
    orElse: () => AssignMode.series,
  );
  String get db => name;
}

/// What screen 19 needs about a task.
class AssignableTask {
  const AssignableTask({
    required this.taskId,
    required this.taskCode,
    required this.projectId,
    required this.projectName,
    required this.window,
    required this.mode,
    this.title,
    this.intervalDays,
    this.assigneeId,
    this.rotationOrder = const [],
    this.canManage = false,
  });
  final String taskId;
  final String taskCode;

  /// Localized task name if known, else the code is shown.
  final String? title;
  final String projectId;
  final String projectName;
  final String window; // morning | afternoon | all_day
  final int? intervalDays;
  final AssignMode mode;
  final String? assigneeId;
  final List<String> rotationOrder;

  /// Owner of the project or household Owner (assign is Owner-only).
  final bool canManage;
}

/// Failures surfaced by the repository, keyed by the backend message.
class HouseholdFailure implements Exception {
  const HouseholdFailure(this.code);
  final String code;

  static const alreadyInHousehold = 'already_in_household';
  static const notOwner = 'not_household_owner';
  static const tooManyInvites = 'too_many_invites';

  @override
  String toString() => 'HouseholdFailure($code)';
}

/// Parses invite deep links. Accepts:
/// - `vuonnha://join?code=VUON-1234`
/// - `https://vuonnha.app/join?code=VUON-1234`
/// - `https://vuonnha.app/i/VUON-1234` (the `link` the `invite` function returns)
/// Returns the upper-cased code, or null when the URI is something else
/// (e.g. the Supabase auth callback).
String? joinCodeFromUri(Uri uri) {
  final re = RegExp(r'^VUON-\d{4}$', caseSensitive: false);
  final q = uri.queryParameters['code'];
  final isJoin = uri.host == 'join' || uri.path == '/join';
  if (isJoin && q != null && re.hasMatch(q.trim())) {
    return q.trim().toUpperCase();
  }
  final segs = uri.pathSegments;
  if (segs.length == 2 && segs.first == 'i' && re.hasMatch(segs[1])) {
    return segs[1].toUpperCase();
  }
  return null;
}

/// Normalises user input of a code ("vuon-4821", " 4821 ").
String normalizeInviteCode(String raw) {
  final t = raw.trim().toUpperCase();
  if (RegExp(r'^\d{4}$').hasMatch(t)) return 'VUON-$t';
  return t;
}

bool isValidInviteCode(String raw) =>
    RegExp(r'^VUON-\d{4}$').hasMatch(normalizeInviteCode(raw));
