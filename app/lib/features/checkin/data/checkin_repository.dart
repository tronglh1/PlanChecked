import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/checkin_models.dart';

/// Check-in backend access (docs/backend.md): Storage bucket `checkins`,
/// tables `checkins` / `checkin_changes`, Edge Function `ai-checkin`, RPC
/// `apply_checkin_changes`.
abstract class CheckinRepository {
  /// Uploads one processed JPEG to `checkins/{user_id}/{project_id}/{uuid}.jpg`
  /// and returns its storage path.
  Future<String> uploadShot(String projectId, Uint8List jpeg);

  /// Inserts the `checkins` row (status forced to `pending` by the server)
  /// and returns its id. [note] is trimmed to [kCheckinNoteMax].
  Future<String> createCheckin({
    required String projectId,
    required List<UploadedShot> shots,
    List<String> tags = const [],
    String? note,
  });

  /// Invokes `ai-checkin`. Throws [CheckinQuotaExceeded] (HTTP 429),
  /// [CheckinAiUnavailable] (502) or [CheckinException].
  Future<CheckinOutcome> analyze(String checkinId);

  /// Loads a stored result: `checkins.ai_result` + `checkin_changes`.
  Future<CheckinResult> loadResult(String checkinId);

  /// Calls `apply_checkin_changes(p_checkin, p_accepted)`; returns the number
  /// applied. Ids not listed stay discarded, so `[]` rejects everything.
  Future<int> applyChanges(String checkinId, List<String> acceptedIds);

  /// Newest-first check-ins of a project with signed thumbnail URLs.
  Future<List<CheckinTimelineItem>> listCheckins(String projectId);

  /// Signed URL for a storage path (null when it cannot be signed).
  Future<String?> signedUrl(String path);
}

class SupabaseCheckinRepository implements CheckinRepository {
  SupabaseCheckinRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _bucket = 'checkins';
  static const _urlTtlSeconds = 3600;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Not signed in');
    return id;
  }

  @override
  Future<String> uploadShot(String projectId, Uint8List jpeg) async {
    final path = '$_uid/$projectId/${const Uuid().v4()}.jpg';
    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          jpeg,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return path;
  }

  @override
  Future<String> createCheckin({
    required String projectId,
    required List<UploadedShot> shots,
    List<String> tags = const [],
    String? note,
  }) async {
    final trimmed = note?.trim() ?? '';
    final row = await _client
        .from('checkins')
        .insert({
          'project_id': projectId,
          'shots': [for (final s in shots) s.toJson()],
          'tags': tags,
          if (trimmed.isNotEmpty)
            'note': trimmed.length > kCheckinNoteMax
                ? trimmed.substring(0, kCheckinNoteMax)
                : trimmed,
        })
        .select('id')
        .single();
    return row['id'].toString();
  }

  @override
  Future<CheckinOutcome> analyze(String checkinId) async {
    final Map<String, dynamic> body;
    try {
      final res = await _client.functions.invoke(
        'ai-checkin',
        body: {'checkin_id': checkinId},
      );
      body = res.data is Map
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};
    } on FunctionException catch (e) {
      throw mapFunctionError(e.status, e.details);
    }
    if (body['status'] == 'already_processed') {
      return _fromProcessed(body, checkinId);
    }
    return parseOutcome(body, checkinId);
  }

  Future<CheckinOutcome> _fromProcessed(
    Map<String, dynamic> body,
    String checkinId,
  ) async {
    final status = body['checkin_status'] as String?;
    final stored = body['result'];
    if (status == 'retake' && stored is Map) {
      return parseOutcome(Map<String, dynamic>.from(stored), checkinId);
    }
    if (status == 'analyzed' || status == 'approved') {
      return CheckinAnalyzed(await loadResult(checkinId));
    }
    if (stored is Map && stored['previous_checkin_id'] != null) {
      return CheckinSkippedRecent(
        previousCheckinId: stored['previous_checkin_id'] as String?,
      );
    }
    throw CheckinException('already_processed:$status');
  }

  @override
  Future<CheckinResult> loadResult(String checkinId) async {
    final row = await _client
        .from('checkins')
        .select('id, status, ai_result, shots, created_at')
        .eq('id', checkinId)
        .single();
    final ai = row['ai_result'];
    if (ai is! Map || ai['status'] != 'ok') {
      throw CheckinException('no_result', '${row['status']}');
    }
    final rows = await _client
        .from('checkin_changes')
        .select('id, change_kind, payload, accepted')
        .eq('checkin_id', checkinId)
        .order('created_at');
    final changes = [
      for (final r in rows)
        ?ProposedChange.fromRow(Map<String, dynamic>.from(r)),
    ];
    final path = firstShotPathOf(row['shots']);
    return CheckinResult.fromJson(
      Map<String, dynamic>.from(ai),
      checkinId: checkinId,
      changes: changes,
      thumbUrl: path == null ? null : await signedUrl(path),
      createdAt: DateTime.tryParse('${row['created_at']}'),
      applied: row['status'] == 'approved',
    );
  }

  @override
  Future<int> applyChanges(String checkinId, List<String> acceptedIds) async {
    final res = await _client.rpc(
      'apply_checkin_changes',
      params: {'p_checkin': checkinId, 'p_accepted': acceptedIds},
    );
    return res is num ? res.toInt() : 0;
  }

  @override
  Future<List<CheckinTimelineItem>> listCheckins(String projectId) async {
    final rows = await _client
        .from('checkins')
        .select('id, status, shots, created_at')
        .eq('project_id', projectId)
        .order('created_at', ascending: false);
    final items = <CheckinTimelineItem>[];
    for (final r in rows) {
      final path = firstShotPathOf(r['shots']);
      items.add(
        CheckinTimelineItem(
          id: r['id'].toString(),
          status: '${r['status']}',
          createdAt: DateTime.parse('${r['created_at']}'),
          path: path,
          url: path == null ? null : await signedUrl(path),
        ),
      );
    }
    return items;
  }

  @override
  Future<String?> signedUrl(String path) async {
    try {
      return await _client.storage
          .from(_bucket)
          .createSignedUrl(path, _urlTtlSeconds);
    } catch (_) {
      return null;
    }
  }
}

/// `checkins.shots` is `[{shot, path}]`.
String? firstShotPathOf(Object? shots) {
  if (shots is List) {
    for (final s in shots) {
      if (s is Map && s['path'] is String) return s['path'] as String;
    }
  }
  return null;
}

/// Maps an Edge Function error response to a typed exception.
CheckinException mapFunctionError(int status, Object? details) {
  final map = details is Map ? details : const {};
  final code = '${map['error'] ?? map['code'] ?? ''}';
  if (status == 429 || code == 'ai_quota_exceeded') {
    final quota = map['quota'];
    int? used;
    int? cap;
    if (quota is Map) {
      final c = quota['checkin'];
      if (c is Map) {
        used = (c['used'] as num?)?.toInt();
        cap = (c['cap'] as num?)?.toInt();
      }
    }
    return CheckinQuotaExceeded(used: used, cap: cap);
  }
  if (status == 502 || code == 'AI_UNAVAILABLE') {
    return const CheckinAiUnavailable();
  }
  return CheckinException(code.isEmpty ? 'http_$status' : code);
}
