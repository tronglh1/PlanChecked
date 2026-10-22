/// Check-in models (pure Dart): the `ai-checkin` response, `checkins` rows and
/// `checkin_changes` rows. See docs/backend.md §3.
library;

/// Shot types accepted by `ai-checkin` (`SHOT_TYPES` in the Edge Function).
enum ShotType {
  wholePlant('whole_plant'),
  closeLeaf('close_leaf'),
  leafUnderside('leaf_underside');

  const ShotType(this.code);
  final String code;

  static ShotType? fromCode(String? c) {
    for (final s in values) {
      if (s.code == c) return s;
    }
    return null;
  }
}

/// Condition tags (enum `condition_tag`) in display order (CHK-03).
const List<String> kConditionTags = ['LEAF_YELLOW', 'WILT', 'PESTS', 'SPOTS'];

/// Max note length enforced by `checkins.note`.
const int kCheckinNoteMax = 200;

/// Max shots per check-in (`checkins.shots` check constraint).
const int kMaxShots = 3;

/// A shot that is already in Storage.
class UploadedShot {
  const UploadedShot({required this.type, required this.path});
  final ShotType type;
  final String path;

  Map<String, dynamic> toJson() => {'shot': type.code, 'path': path};
}

enum ConfidenceBand { high, medium, low }

/// Thresholds mirror `app_config` (`band_high` 0.75, `band_medium` 0.5).
ConfidenceBand bandOf(double confidence) {
  if (confidence >= 0.75) return ConfidenceBand.high;
  if (confidence >= 0.5) return ConfidenceBand.medium;
  return ConfidenceBand.low;
}

enum ChangeKind {
  add,
  remove,
  changeFreq,
  shift;

  static ChangeKind? fromCode(String? c) => switch (c) {
    'add' => ChangeKind.add,
    'remove' => ChangeKind.remove,
    'change_freq' => ChangeKind.changeFreq,
    'shift' => ChangeKind.shift,
    _ => null,
  };
}

/// One row of `checkin_changes`: a proposed plan change the user may accept.
class ProposedChange {
  const ProposedChange({
    required this.id,
    required this.kind,
    this.task,
    this.stage,
    this.everyD,
    this.window,
    this.why,
    this.milestone,
    this.to,
    this.accepted = false,
  });

  final String id;
  final ChangeKind kind;

  /// Task code (`T_*`) for add / remove / change_freq.
  final String? task;
  final String? stage;

  /// New interval in days (`change_freq`; 1 = daily, 0 = once).
  final int? everyD;
  final String? window;

  /// Reason code (`R_*`).
  final String? why;

  /// Milestone code for `shift`, and the new date (`yyyy-mm-dd`).
  final String? milestone;
  final DateTime? to;

  /// Already applied (loaded from a past check-in).
  final bool accepted;

  /// [kindCode] is the row's `change_kind`; [payload] the delta item.
  static ProposedChange? fromRow(Map<String, dynamic> row) {
    final payload = row['payload'] is Map
        ? Map<String, dynamic>.from(row['payload'] as Map)
        : <String, dynamic>{};
    final kind =
        ChangeKind.fromCode(row['change_kind'] as String?) ??
        ChangeKind.fromCode(payload['op'] as String?);
    if (kind == null) return null;
    final every = payload['every_d'];
    return ProposedChange(
      id: row['id'].toString(),
      kind: kind,
      task: payload['task'] as String?,
      stage: payload['stage'] as String?,
      everyD: every is num ? every.toInt() : null,
      window: payload['window'] as String?,
      why: payload['why'] as String?,
      milestone: payload['milestone'] as String?,
      to: payload['to'] is String
          ? DateTime.tryParse(payload['to'] as String)
          : null,
      accepted: row['accepted'] == true,
    );
  }
}

class CheckinIssue {
  const CheckinIssue({
    required this.code,
    required this.confidence,
    this.severity = 1,
    this.actions = const [],
  });

  /// Problem code (`P_*`).
  final String code;
  final double confidence;
  final int severity;

  /// Safe action task codes (`T_*`).
  final List<String> actions;

  factory CheckinIssue.fromJson(Map<String, dynamic> j) => CheckinIssue(
    code: j['code'].toString(),
    confidence: _num(j['confidence']),
    severity: j['severity'] is num ? (j['severity'] as num).toInt() : 1,
    actions: [
      if (j['actions'] is List)
        for (final a in j['actions'] as List)
          if (a is Map && a['task'] != null) a['task'].toString(),
    ],
  );
}

double _num(Object? v) => v is num ? v.toDouble() : 0;

class CodeConfidence {
  const CodeConfidence(this.code, this.confidence);
  final String code;
  final double confidence;

  static CodeConfidence? fromJson(Object? j) {
    if (j is! Map || j['code'] == null) return null;
    return CodeConfidence(j['code'].toString(), _num(j['confidence']));
  }
}

class CheckinResult {
  const CheckinResult({
    required this.checkinId,
    this.stageCode,
    this.stageConfidence = 0,
    this.health,
    this.healthConfidence = 0,
    this.issues = const [],
    this.milestoneSeen,
    this.milestoneIsNew = false,
    this.changes = const [],
    this.reasonCodes = const [],
    this.band = ConfidenceBand.medium,
    this.xpTotal,
    this.level,
    this.thumbUrl,
    this.createdAt,
    this.applied = false,
  });

  final String checkinId;

  /// e.g. `S3_late`.
  final String? stageCode;
  final double stageConfidence;

  /// `good | fair | poor`.
  final String? health;
  final double healthConfidence;
  final List<CheckinIssue> issues;
  final CodeConfidence? milestoneSeen;
  final bool milestoneIsNew;
  final List<ProposedChange> changes;
  final List<String> reasonCodes;
  final ConfidenceBand band;

  /// Only present on the live response.
  final int? xpTotal;
  final int? level;

  /// Signed URL of the first shot (set when loaded from the database).
  final String? thumbUrl;
  final DateTime? createdAt;

  /// `checkins.status == approved`: the user already answered the changes.
  final bool applied;

  /// Band `low` -> suggest a local agricultural store (CHK-08).
  bool get lowConfidence => band == ConfidenceBand.low;

  /// Lowest confidence among stage, health and issues (the same rule the
  /// Edge Function uses for the band).
  double get minConfidence {
    final values = <double>[
      if (stageCode != null) stageConfidence,
      if (health != null) healthConfidence,
      for (final i in issues) i.confidence,
    ];
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a < b ? a : b);
  }

  /// Stage prefix of [stageCode]: `S3_late` -> `S3`.
  String? get stagePrefix => stageCode?.split('_').first;

  /// `early | mid | late` suffix of [stageCode], if any.
  String? get stagePhase {
    final parts = stageCode?.split('_');
    return parts != null && parts.length > 1 ? parts[1] : null;
  }

  /// Parses the `ai-checkin` 200 body (`status: ok`) or a stored `ai_result`.
  /// [changes] come from `checkin_changes`, not from the JSON, when given.
  factory CheckinResult.fromJson(
    Map<String, dynamic> j, {
    String? checkinId,
    List<ProposedChange>? changes,
    String? thumbUrl,
    DateTime? createdAt,
    bool applied = false,
    ConfidenceBand? band,
  }) {
    final stage = CodeConfidence.fromJson(j['stage_est']);
    final health = j['health'];
    final issues = [
      if (j['issues'] is List)
        for (final i in j['issues'] as List)
          if (i is Map) CheckinIssue.fromJson(Map<String, dynamic>.from(i)),
    ];
    final seen = CodeConfidence.fromJson(j['milestone_seen']);
    final ms = j['milestone'];
    final xp = j['xp'];
    final parsedChanges =
        changes ??
        [
          if (j['changes'] is List)
            for (final c in j['changes'] as List)
              if (c is Map)
                ?ProposedChange.fromRow(Map<String, dynamic>.from(c)),
        ];
    final result = CheckinResult(
      checkinId: checkinId ?? j['checkin_id'].toString(),
      stageCode: stage?.code,
      stageConfidence: stage?.confidence ?? 0,
      health: health is Map ? health['value'] as String? : null,
      healthConfidence: health is Map ? _num(health['confidence']) : 0,
      issues: issues,
      milestoneSeen: seen,
      milestoneIsNew: ms is Map && ms['new'] == true,
      changes: parsedChanges,
      reasonCodes: [
        if (j['reason_codes'] is List)
          for (final r in j['reason_codes'] as List) r.toString(),
      ],
      xpTotal: xp is Map && xp['xp_total'] is num
          ? (xp['xp_total'] as num).toInt()
          : null,
      level: xp is Map && xp['level'] is num
          ? (xp['level'] as num).toInt()
          : null,
      thumbUrl: thumbUrl,
      createdAt: createdAt,
      applied: applied,
    );
    final serverBand = switch (j['confidence_band']) {
      'high' => ConfidenceBand.high,
      'medium' => ConfidenceBand.medium,
      'low' => ConfidenceBand.low,
      _ => null,
    };
    return result._withBand(band ?? serverBand ?? bandOf(result.minConfidence));
  }

  CheckinResult _withBand(ConfidenceBand b) => CheckinResult(
    checkinId: checkinId,
    stageCode: stageCode,
    stageConfidence: stageConfidence,
    health: health,
    healthConfidence: healthConfidence,
    issues: issues,
    milestoneSeen: milestoneSeen,
    milestoneIsNew: milestoneIsNew,
    changes: changes,
    reasonCodes: reasonCodes,
    band: b,
    xpTotal: xpTotal,
    level: level,
    thumbUrl: thumbUrl,
    createdAt: createdAt,
    applied: applied,
  );
}

/// What `ai-checkin` answered (HTTP 200).
sealed class CheckinOutcome {
  const CheckinOutcome();
}

class CheckinAnalyzed extends CheckinOutcome {
  const CheckinAnalyzed(this.result);
  final CheckinResult result;
}

/// `status: retake` from the server (BLUR | DARK | TOO_FAR | NOT_PLANT).
class CheckinRetake extends CheckinOutcome {
  const CheckinRetake({
    required this.checkinId,
    required this.reason,
    required this.hintCode,
  });
  final String? checkinId;
  final String reason;
  final String hintCode;
}

/// `status: skipped_recent`: analyzed less than 24 h ago and no new tag.
class CheckinSkippedRecent extends CheckinOutcome {
  const CheckinSkippedRecent({this.previousCheckinId});
  final String? previousCheckinId;
}

/// Hint code for a retake reason, when the server sent none.
String hintForReason(String reason) => switch (reason.toUpperCase()) {
  'BLUR' => 'H_RETAKE_BLUR',
  'DARK' => 'H_RETAKE_LIGHT',
  _ => 'H_RETAKE_FRAMING',
};

/// Parses an `ai-checkin` 200 body. [checkinId] is the id we invoked with.
/// `already_processed` bodies carry only the stored `ai_result`; callers
/// handle that case by reloading from the database.
CheckinOutcome parseOutcome(Map<String, dynamic> body, String checkinId) {
  switch (body['status']) {
    case 'ok':
      return CheckinAnalyzed(
        CheckinResult.fromJson(body, checkinId: checkinId),
      );
    case 'retake':
      final reason = (body['reason'] as String?) ?? 'BLUR';
      return CheckinRetake(
        checkinId: (body['checkin_id'] as String?) ?? checkinId,
        reason: reason,
        hintCode: (body['hint_code'] as String?) ?? hintForReason(reason),
      );
    case 'skipped_recent':
      return CheckinSkippedRecent(
        previousCheckinId: body['previous_checkin_id'] as String?,
      );
  }
  throw CheckinException('unexpected_status:${body['status']}');
}

/// One thumbnail of the project's photo timeline.
class CheckinTimelineItem {
  const CheckinTimelineItem({
    required this.id,
    required this.createdAt,
    required this.status,
    this.path,
    this.url,
  });

  final String id;
  final DateTime createdAt;
  final String status;

  /// Storage path of the first shot and its signed URL.
  final String? path;
  final String? url;
}

class CheckinException implements Exception {
  const CheckinException(this.code, [this.message]);
  final String code;
  final String? message;

  @override
  String toString() =>
      'CheckinException($code${message == null ? '' : ': $message'})';
}

/// 429 `ai_quota_exceeded`: the daily check-in cap is used up.
class CheckinQuotaExceeded extends CheckinException {
  const CheckinQuotaExceeded({this.used, this.cap})
    : super('ai_quota_exceeded');
  final int? used;
  final int? cap;
}

/// 502 `AI_UNAVAILABLE`: nothing was applied, quota refunded.
class CheckinAiUnavailable extends CheckinException {
  const CheckinAiUnavailable({this.reason, this.detail})
    : super('AI_UNAVAILABLE');

  /// Server-reported reason code and short provider error (may be null).
  final String? reason;
  final String? detail;
}
