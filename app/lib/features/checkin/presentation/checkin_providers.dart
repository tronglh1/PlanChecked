import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/env.dart';
import '../data/checkin_repository.dart';
import '../domain/checkin_models.dart';
import '../domain/image_quality.dart';

final checkinRepositoryProvider = Provider<CheckinRepository>((ref) {
  if (!Env.isConfigured) throw StateError('Supabase is not configured');
  return SupabaseCheckinRepository();
});

/// Where raw photos come from (system camera or gallery). Overridden in tests.
abstract class CheckinImageSource {
  Future<Uint8List?> takePhoto();
  Future<Uint8List?> pickFromGallery();
}

class PickerImageSource implements CheckinImageSource {
  PickerImageSource([ImagePicker? picker]) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  @override
  Future<Uint8List?> takePhoto() async {
    final f = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );
    return f?.readAsBytes();
  }

  @override
  Future<Uint8List?> pickFromGallery() async {
    final f = await _picker.pickImage(source: ImageSource.gallery);
    return f?.readAsBytes();
  }
}

final checkinImageSourceProvider = Provider<CheckinImageSource>(
  (ref) => PickerImageSource(),
);

/// Resize / strip / blur-check pipeline; runs in an isolate. Overridden in
/// tests with the synchronous version.
final imageProcessorProvider =
    Provider<Future<ProcessedImage> Function(Uint8List)>(
      (ref) => processCheckinImage,
    );

/// How long the analyzing screen waits for `ai-checkin` (target <= 15 s,
/// plus slack for upload and network).
final checkinAnalyzeTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 40),
);

/// Photo timeline of a project (project detail, "Ảnh").
final checkinTimelineProvider = FutureProvider.autoDispose
    .family<List<CheckinTimelineItem>, String>(
      (ref, projectId) =>
          ref.watch(checkinRepositoryProvider).listCheckins(projectId),
    );

/// Results returned live by `ai-checkin` (they carry XP, which the database
/// does not keep), by check-in id.
class AnalyzedResultsCache extends Notifier<Map<String, CheckinResult>> {
  @override
  Map<String, CheckinResult> build() => const {};

  void put(CheckinResult r) => state = {...state, r.checkinId: r};
}

final analyzedResultsProvider =
    NotifierProvider<AnalyzedResultsCache, Map<String, CheckinResult>>(
      AnalyzedResultsCache.new,
    );

/// Result for screen 14: the live response when we have it, else the stored
/// result from the database.
final checkinResultProvider = FutureProvider.autoDispose
    .family<CheckinResult, String>((ref, checkinId) async {
      final cached = ref.read(analyzedResultsProvider)[checkinId];
      if (cached != null) return cached;
      return ref.watch(checkinRepositoryProvider).loadResult(checkinId);
    });

// --- Capture (screen 13) ----------------------------------------------------

class CapturedShot {
  const CapturedShot({required this.type, required this.jpeg});
  final ShotType type;
  final Uint8List jpeg;
}

/// Why the user has to retake (screen 15). [reason] is `BLUR | DARK |
/// UNREADABLE` locally or the server's `BLUR | DARK | TOO_FAR | NOT_PLANT`.
class RetakeInfo {
  const RetakeInfo({
    required this.reason,
    required this.hintCode,
    this.preview,
    this.fromServer = false,
  });

  final String reason;
  final String hintCode;

  /// The rejected photo (local rejections only).
  final Uint8List? preview;
  final bool fromServer;

  factory RetakeInfo.local(ImageIssue issue, Uint8List? preview) {
    final reason = switch (issue) {
      ImageIssue.blur => 'BLUR',
      ImageIssue.dark => 'DARK',
      ImageIssue.unreadable => 'UNREADABLE',
    };
    return RetakeInfo(
      reason: reason,
      hintCode: hintForReason(reason),
      preview: preview,
    );
  }
}

enum CapturePhase {
  capturing,
  processing,
  analyzing,
  quotaExceeded,
  aiUnavailable,
  skippedRecent,
  failed,
}

class CaptureState {
  const CaptureState({
    this.phase = CapturePhase.capturing,
    this.shots = const {},
    this.active = ShotType.wholePlant,
    this.tags = const {},
    this.note = '',
    this.step = 0,
    this.quotaUsed,
    this.quotaCap,
    this.previousCheckinId,
  });

  final CapturePhase phase;
  final Map<ShotType, CapturedShot> shots;
  final ShotType active;
  final Set<String> tags;
  final String note;

  /// 0 = uploading, 1 = analyzing.
  final int step;
  final int? quotaUsed;
  final int? quotaCap;
  final String? previousCheckinId;

  bool get canSubmit =>
      shots.isNotEmpty &&
      (phase == CapturePhase.capturing || phase == CapturePhase.failed);

  CaptureState copyWith({
    CapturePhase? phase,
    Map<ShotType, CapturedShot>? shots,
    ShotType? active,
    Set<String>? tags,
    String? note,
    int? step,
    int? quotaUsed,
    int? quotaCap,
    String? previousCheckinId,
  }) => CaptureState(
    phase: phase ?? this.phase,
    shots: shots ?? this.shots,
    active: active ?? this.active,
    tags: tags ?? this.tags,
    note: note ?? this.note,
    step: step ?? this.step,
    quotaUsed: quotaUsed ?? this.quotaUsed,
    quotaCap: quotaCap ?? this.quotaCap,
    previousCheckinId: previousCheckinId ?? this.previousCheckinId,
  );
}

/// What [CaptureController.submit] decided; the screen navigates on it.
sealed class SubmitResult {
  const SubmitResult();
}

class SubmitDone extends SubmitResult {
  const SubmitDone(this.checkinId);
  final String checkinId;
}

class SubmitRetake extends SubmitResult {
  const SubmitRetake(this.info);
  final RetakeInfo info;
}

/// Quota, AI error, skipped or failure: [CaptureState.phase] says which.
class SubmitStopped extends SubmitResult {
  const SubmitStopped();
}

class CaptureController extends Notifier<CaptureState> {
  CaptureController(this.projectId);
  final String projectId;

  // Kept across retries so a timeout does not upload twice.
  final Map<ShotType, String> _uploaded = {};
  String? _checkinId;

  @override
  CaptureState build() => const CaptureState();

  void selectShot(ShotType t) => state = state.copyWith(active: t);

  void toggleTag(String tag) {
    final next = {...state.tags};
    if (!next.remove(tag)) next.add(tag);
    state = state.copyWith(tags: next);
  }

  void setNote(String v) => state = state.copyWith(
    note: v.length > kCheckinNoteMax ? v.substring(0, kCheckinNoteMax) : v,
  );

  void removeShot(ShotType t) {
    final next = {...state.shots}..remove(t);
    _uploaded.remove(t);
    _checkinId = null;
    state = state.copyWith(shots: next);
  }

  /// Runs [raw] through the pipeline for the active shot. Returns a
  /// [RetakeInfo] (CHK-06) when the photo is too blurry / dark / unreadable:
  /// nothing is stored or uploaded then.
  Future<RetakeInfo?> addPhoto(Uint8List raw) async {
    final type = state.active;
    state = state.copyWith(phase: CapturePhase.processing);
    final processed = await ref.read(imageProcessorProvider)(raw);
    if (!processed.ok) {
      state = state.copyWith(phase: CapturePhase.capturing);
      return RetakeInfo.local(processed.issue!, processed.jpeg);
    }
    final next = {
      ...state.shots,
      type: CapturedShot(type: type, jpeg: processed.jpeg!),
    };
    _uploaded.remove(type);
    _checkinId = null;
    // Move on to the next missing shot type.
    final missing = ShotType.values.where((t) => !next.containsKey(t));
    state = state.copyWith(
      phase: CapturePhase.capturing,
      shots: next,
      active: missing.isEmpty ? type : missing.first,
    );
    return null;
  }

  void _reset() {
    _uploaded.clear();
    _checkinId = null;
    state = CaptureState(tags: state.tags, note: state.note);
  }

  /// Uploads the shots, creates the check-in row and calls `ai-checkin`.
  Future<SubmitResult> submit() async {
    final repo = ref.read(checkinRepositoryProvider);
    final timeout = ref.read(checkinAnalyzeTimeoutProvider);
    state = state.copyWith(phase: CapturePhase.analyzing, step: 0);
    try {
      var id = _checkinId;
      if (id == null) {
        final uploaded = <UploadedShot>[];
        for (final s in state.shots.values) {
          final path =
              _uploaded[s.type] ??
              await repo.uploadShot(projectId, s.jpeg).timeout(timeout);
          _uploaded[s.type] = path;
          uploaded.add(UploadedShot(type: s.type, path: path));
        }
        id = await repo.createCheckin(
          projectId: projectId,
          shots: uploaded,
          tags: state.tags.toList(),
          note: state.note,
        );
        _checkinId = id;
      }
      state = state.copyWith(step: 1);
      final outcome = await repo.analyze(id).timeout(timeout);
      switch (outcome) {
        case CheckinAnalyzed(:final result):
          ref.read(analyzedResultsProvider.notifier).put(result);
          return SubmitDone(result.checkinId);
        case CheckinRetake(:final reason, :final hintCode):
          _reset();
          return SubmitRetake(
            RetakeInfo(reason: reason, hintCode: hintCode, fromServer: true),
          );
        case CheckinSkippedRecent(:final previousCheckinId):
          state = state.copyWith(
            phase: CapturePhase.skippedRecent,
            previousCheckinId: previousCheckinId,
          );
          return const SubmitStopped();
      }
    } on CheckinQuotaExceeded catch (e) {
      state = state.copyWith(
        phase: CapturePhase.quotaExceeded,
        quotaUsed: e.used,
        quotaCap: e.cap,
      );
    } on CheckinAiUnavailable {
      state = state.copyWith(phase: CapturePhase.aiUnavailable);
    } catch (_) {
      state = state.copyWith(phase: CapturePhase.failed);
    }
    return const SubmitStopped();
  }

  /// Back to capturing after a stop screen.
  void dismissStop() => state = state.copyWith(phase: CapturePhase.capturing);
}

final captureControllerProvider = NotifierProvider.autoDispose
    .family<CaptureController, CaptureState, String>(CaptureController.new);
