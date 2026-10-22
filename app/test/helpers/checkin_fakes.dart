import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:vuon_nha/core/db/local_prefs.dart';
import 'package:vuon_nha/features/checkin/checkin_routes.dart';
import 'package:vuon_nha/features/checkin/data/checkin_repository.dart';
import 'package:vuon_nha/features/checkin/domain/checkin_models.dart';
import 'package:vuon_nha/features/checkin/domain/image_quality.dart';
import 'package:vuon_nha/features/checkin/presentation/checkin_camera.dart';
import 'package:vuon_nha/features/checkin/presentation/checkin_providers.dart';
import 'package:vuon_nha/features/plan/domain/plan_bundle.dart';
import 'package:vuon_nha/features/plan/domain/enums.dart';
import 'package:vuon_nha/features/plants/data/plant_repository.dart';
import 'package:vuon_nha/features/plan/presentation/plan_providers.dart';
import 'package:vuon_nha/features/plants/presentation/plant_providers.dart';
import 'package:vuon_nha/features/projects/presentation/projects_providers.dart';
import 'package:vuon_nha/features/projects/projects_routes.dart';
import 'package:vuon_nha/features/settings/presentation/locale_provider.dart';
import 'package:vuon_nha/l10n/app_localizations.dart';

import 'projects_fakes.dart';

/// Image of random-colored [cell]-pixel squares: lots of edges, mean ~128.
img.Image sharpImage(int w, int h, {int cell = 8, int seed = 1}) {
  final rnd = math.Random(seed);
  final image = img.Image(width: w, height: h);
  final cols = (w / cell).ceil();
  final rows = (h / cell).ceil();
  final values = [for (var i = 0; i < cols * rows; i++) 40 + rnd.nextInt(176)];
  for (final p in image) {
    final v = values[(p.y ~/ cell) * cols + (p.x ~/ cell)];
    p.setRgb(v, v, v);
  }
  return image;
}

/// Heavily blurred copy of [i] (no sharp edges left).
img.Image blurImage(img.Image i) => img.gaussianBlur(i.clone(), radius: 24);

/// Almost black image (values 0..15).
img.Image darkImage(int w, int h) {
  final rnd = math.Random(3);
  final image = img.Image(width: w, height: h);
  for (final p in image) {
    final v = rnd.nextInt(16);
    p.setRgb(v, v, v);
  }
  return image;
}

Uint8List jpegOf(img.Image i) => Uint8List.fromList(img.encodeJpg(i));

class FakeImageSource implements CheckinImageSource {
  FakeImageSource(this.queue);

  /// Photos handed out one per tap, in order.
  final List<Uint8List> queue;
  int taken = 0;

  Uint8List? _next() => queue.isEmpty ? null : queue.removeAt(0);

  @override
  Future<Uint8List?> takePhoto() async {
    taken++;
    return _next();
  }

  @override
  Future<Uint8List?> pickFromGallery() async => _next();
}

class FakeCheckinRepository implements CheckinRepository {
  FakeCheckinRepository({
    this.outcome,
    this.analyzeError,
    this.result,
    this.timeline = const [],
  });

  CheckinOutcome? outcome;
  Object? analyzeError;
  CheckinResult? result;
  List<CheckinTimelineItem> timeline;

  final List<Uint8List> uploads = [];
  final List<
    ({
      String projectId,
      List<UploadedShot> shots,
      List<String> tags,
      String? note,
    })
  >
  created = [];
  final List<String> analyzed = [];
  final List<({String checkinId, List<String> ids})> applied = [];
  bool failApply = false;

  @override
  Future<String> uploadShot(String projectId, Uint8List jpeg) async {
    uploads.add(jpeg);
    return 'u1/$projectId/${uploads.length}.jpg';
  }

  @override
  Future<String> createCheckin({
    required String projectId,
    required List<UploadedShot> shots,
    List<String> tags = const [],
    String? note,
  }) async {
    created.add((projectId: projectId, shots: shots, tags: tags, note: note));
    return 'c1';
  }

  @override
  Future<CheckinOutcome> analyze(String checkinId) async {
    analyzed.add(checkinId);
    final e = analyzeError;
    if (e != null) throw e;
    return outcome ?? CheckinAnalyzed(result ?? fakeResult());
  }

  @override
  Future<CheckinResult> loadResult(String checkinId) async =>
      result ?? fakeResult(id: checkinId);

  @override
  Future<int> applyChanges(String checkinId, List<String> acceptedIds) async {
    if (failApply) throw Exception('rpc down');
    applied.add((checkinId: checkinId, ids: acceptedIds));
    return acceptedIds.length;
  }

  @override
  Future<List<CheckinTimelineItem>> listCheckins(String projectId) async =>
      timeline;

  @override
  Future<String?> signedUrl(String path) async => null;
}

/// The example from docs/backend.md (stage `S2_late` to match the fake plan).
CheckinResult fakeResult({
  String id = 'c1',
  double issueConfidence = 0.58,
  ConfidenceBand? band,
  bool withChanges = true,
  bool applied = false,
  bool newMilestone = true,
}) => CheckinResult(
  checkinId: id,
  stageCode: 'S2_late',
  stageConfidence: 0.82,
  health: 'good',
  healthConfidence: 0.8,
  issues: [
    CheckinIssue(
      code: 'P_CALCIUM_LOW',
      confidence: issueConfidence,
      actions: const ['T_FERT_ORGANIC'],
    ),
  ],
  milestoneSeen: const CodeConfidence('TRUE_LEAVES', 0.9),
  milestoneIsNew: newMilestone,
  band: band ?? bandOf(issueConfidence),
  xpTotal: 1280,
  level: 4,
  applied: applied,
  changes: withChanges
      ? [
          const ProposedChange(
            id: 'ch1',
            kind: ChangeKind.add,
            task: 'T_SOAK',
            stage: 'S2',
          ),
          const ProposedChange(
            id: 'ch2',
            kind: ChangeKind.changeFreq,
            task: 'T_PRUNE',
            everyD: 1,
            why: 'R_HOT_SEASON',
          ),
          ProposedChange(
            id: 'ch3',
            kind: ChangeKind.shift,
            milestone: 'TRUE_LEAVES',
            to: DateTime.utc(2026, 10, 20),
          ),
        ]
      : const [],
);

/// Templates used by the check-in screens.
class CheckinTemplatePlantRepository extends TemplatePlantRepository {
  @override
  Future<List<TextTemplate>> fetchTextTemplates(
    String lang, {
    String? kind,
  }) async => [
    ...TemplatePlantRepository.rows,
    const TextTemplate(
      kind: 'problem',
      code: 'P_CALCIUM_LOW',
      field: 'name',
      body: 'Nghi thiếu canxi nhẹ',
    ),
    const TextTemplate(
      kind: 'problem',
      code: 'P_CALCIUM_LOW',
      field: 'why',
      body: 'Mép lá non hơi vàng.',
    ),
    const TextTemplate(
      kind: 'reason',
      code: 'R_HOT_SEASON',
      field: 'why',
      body: 'Đợt nắng nóng',
    ),
    const TextTemplate(
      kind: 'hint',
      code: 'H_RETAKE_BLUR',
      field: 'steps',
      body: 'Giữ máy chắc tay rồi chụp lại.',
    ),
  ];
}

/// Pumps [initial] with the project and check-in routes and fakes for every
/// repository.
Future<GoRouter> pumpCheckinApp(
  WidgetTester tester, {
  required String initial,
  FakeCheckinRepository? checkins,
  CheckinImageSource? source,
  CheckinCamera Function()? camera,
  PlanBundle? bundle,
  List<Override> extra = const [],
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/garden', builder: (_, _) => const Text('GARDEN')),
      GoRoute(
        path: '/projects/:id/milestone/:code',
        builder: (_, s) => Text('MILESTONE-${s.pathParameters['code']}'),
      ),
      ...projectsRoutes,
      ...checkinRoutes,
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(MemoryLocalPrefs()),
        plantRepositoryProvider.overrideWithValue(
          CheckinTemplatePlantRepository(),
        ),
        projectRepositoryProvider.overrideWithValue(FakeProjectRepository()),
        planRepositoryProvider.overrideWithValue(
          FakePlanRepository(
            bundle: bundle ?? fakeBundle(status: PlanStatus.approved),
          ),
        ),
        checkinRepositoryProvider.overrideWithValue(
          checkins ?? FakeCheckinRepository(),
        ),
        checkinImageSourceProvider.overrideWithValue(
          source ?? FakeImageSource([]),
        ),
        // Default: live camera unavailable, so the shutter uses the image source.
        checkinCameraFactoryProvider.overrideWithValue(
          camera ?? () => FakeCheckinCamera(failInit: true),
        ),
        imageProcessorProvider.overrideWithValue(
          (b) async => processImageBytes(b),
        ),
        ...extra,
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          locale: ref.watch(localeProvider),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

/// A camera that fails the way image_picker does on a broken device.
class FailingImageSource implements CheckinImageSource {
  @override
  Future<Uint8List?> takePhoto() async => throw PlatformException(
    code: 'no_available_camera',
    message: 'No cameras available for taking pictures.',
  );

  @override
  Future<Uint8List?> pickFromGallery() async => null;
}

class FakeCheckinCamera implements CheckinCamera {
  FakeCheckinCamera({this.failInit = false, List<Uint8List>? photos})
    : photos = photos ?? [];

  final bool failInit;

  /// Photos handed out one per capture, in order.
  final List<Uint8List> photos;
  int captured = 0;
  bool disposed = false;

  @override
  Future<void> initialize() async {
    if (failInit) throw StateError('permission denied');
  }

  @override
  Future<Uint8List> capture() async {
    captured++;
    return photos.removeAt(0);
  }

  @override
  double get previewAspect => 0.75;

  @override
  Widget buildPreview() =>
      const ColoredBox(key: Key('fake-camera-preview'), color: Colors.teal);

  @override
  Future<void> dispose() async => disposed = true;
}
