import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/checkin/domain/checkin_models.dart';

import '../../helpers/checkin_fakes.dart';

Future<void> tapKey(WidgetTester t, String key) async {
  final f = find.byKey(Key(key));
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  group('result screen (14)', () {
    testWidgets('renders stage, health, issue band, actions and changes', (
      t,
    ) async {
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin/c1',
        checkins: FakeCheckinRepository(result: fakeResult()),
      );
      expect(find.text('Kết quả check-in'), findsOneWidget);
      expect(find.byKey(const Key('ai-label')), findsOneWidget);
      expect(find.text('Gợi ý từ AI'), findsOneWidget);
      expect(find.text('Giai đoạn: cuối Cây con (82%)'), findsOneWidget);
      expect(find.text('Sức khỏe: Tốt'), findsOneWidget);
      expect(find.text('Nghi thiếu canxi nhẹ'), findsOneWidget);
      expect(find.text('Tin cậy trung bình · 58%'), findsOneWidget);
      // Safe action text comes from templates.
      expect(find.textContaining('Bón phân hữu cơ'), findsOneWidget);
      expect(find.textContaining('không tự pha liều'), findsOneWidget);
      expect(find.byKey(const Key('milestone-note')), findsOneWidget);
      expect(find.byKey(const Key('low-confidence')), findsNothing);
      // Proposed changes with kind labels.
      expect(find.text('THÊM VIỆC'), findsOneWidget);
      expect(find.text('ĐỔI TẦN SUẤT'), findsOneWidget);
      expect(find.text('DỜI MỐC'), findsOneWidget);
      expect(find.text('Ngâm hạt nước ấm'), findsOneWidget);
      expect(
        find.text('Tỉa chồi nách: 7 ngày/lần → Hằng ngày'),
        findsOneWidget,
      );
      expect(find.text('Ra lá thật: dời đến 20/10'), findsOneWidget);
      expect(find.text('Đợt nắng nóng'), findsOneWidget);
      expect(find.text('Áp dụng 3 thay đổi'), findsOneWidget);
      expect(find.byKey(const Key('xp-chip')), findsOneWidget);
    });

    testWidgets('approving a subset sends exactly those ids', (t) async {
      final repo = FakeCheckinRepository(result: fakeResult());
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin/c1',
        checkins: repo,
      );
      await tapKey(t, 'check-ch2'); // skip the frequency change
      expect(find.text('Áp dụng 2 thay đổi'), findsOneWidget);
      await tapKey(t, 'apply');
      expect(repo.applied, hasLength(1));
      expect(repo.applied.single.checkinId, 'c1');
      expect(repo.applied.single.ids.toSet(), {'ch1', 'ch3'});
      expect(repo.applied.single.ids, hasLength(2));
    });

    testWidgets('a new milestone opens the celebration screen after apply', (
      t,
    ) async {
      final repo = FakeCheckinRepository(result: fakeResult());
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin/c1',
        checkins: repo,
      );
      await tapKey(t, 'apply');
      expect(repo.applied, hasLength(1));
      expect(find.text('MILESTONE-TRUE_LEAVES'), findsOneWidget);
    });

    testWidgets('no new milestone: back to the project', (t) async {
      final repo = FakeCheckinRepository(
        result: fakeResult(newMilestone: false),
      );
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin/c1',
        checkins: repo,
      );
      await tapKey(t, 'apply');
      expect(find.textContaining('MILESTONE-'), findsNothing);
      expect(find.text('Kết quả check-in'), findsNothing);
    });

    testWidgets('skipping every change rejects them all', (t) async {
      final repo = FakeCheckinRepository(result: fakeResult());
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin/c1',
        checkins: repo,
      );
      for (final id in ['ch1', 'ch2', 'ch3']) {
        await tapKey(t, 'check-$id');
      }
      expect(find.text('Bỏ qua tất cả'), findsOneWidget);
      await tapKey(t, 'apply');
      expect(repo.applied.single.ids, isEmpty);
    });

    testWidgets('failed apply shows an error and keeps the screen', (t) async {
      final repo = FakeCheckinRepository(result: fakeResult())
        ..failApply = true;
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin/c1',
        checkins: repo,
      );
      await tapKey(t, 'apply');
      expect(find.byKey(const Key('apply-error')), findsOneWidget);
      expect(find.text('Kết quả check-in'), findsOneWidget);
    });

    testWidgets('low confidence suggests an agricultural store, no doses', (
      t,
    ) async {
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin/c1',
        checkins: FakeCheckinRepository(
          result: fakeResult(issueConfidence: 0.3),
        ),
      );
      expect(find.byKey(const Key('low-confidence')), findsOneWidget);
      expect(find.textContaining('cửa hàng nông nghiệp'), findsOneWidget);
      expect(find.text('Tin cậy thấp · 30%'), findsOneWidget);
      expect(
        find.textContaining(
          RegExp(r'\d+\s?(ml|mg|g/|gram)', caseSensitive: false),
        ),
        findsNothing,
      );
    });

    testWidgets('already answered results are read-only', (t) async {
      final repo = FakeCheckinRepository(result: fakeResult(applied: true));
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin/c1',
        checkins: repo,
      );
      expect(find.byKey(const Key('already-answered')), findsOneWidget);
      expect(find.text('Xong'), findsOneWidget);
      expect(find.text('Áp dụng 3 thay đổi'), findsNothing);
    });

    testWidgets('no changes: Done button, nothing sent', (t) async {
      final repo = FakeCheckinRepository(
        result: fakeResult(withChanges: false),
      );
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin/c1',
        checkins: repo,
      );
      expect(find.byKey(const Key('no-changes')), findsOneWidget);
      await tapKey(t, 'apply');
      expect(repo.applied, isEmpty);
    });
  });

  group('capture (13) and retake (15)', () {
    testWidgets('dark photo is rejected on the device, before any upload', (
      t,
    ) async {
      final repo = FakeCheckinRepository();
      final src = FakeImageSource([jpegOf(darkImage(640, 480))]);
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin',
        checkins: repo,
        source: src,
      );
      await tapKey(t, 'shutter');
      expect(find.text('Cần chụp lại'), findsOneWidget);
      expect(find.text('Ảnh thiếu sáng'), findsOneWidget);
      expect(find.byKey(const Key('retake-preview')), findsOneWidget);
      expect(repo.uploads, isEmpty);
      expect(repo.created, isEmpty);

      await tapKey(t, 'retake-cta');
      expect(find.byKey(const Key('shutter')), findsOneWidget);
      // Nothing was stored, so analyzing is still disabled.
      await t.tap(find.byKey(const Key('analyze')));
      await t.pumpAndSettle();
      expect(repo.analyzed, isEmpty);
      expect(find.byKey(const Key('shutter')), findsOneWidget);
    });

    testWidgets('blurry photo shows the blur reason', (t) async {
      final blurred = jpegOf(blurImage(sharpImage(640, 480)));
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin',
        source: FakeImageSource([blurred]),
      );
      await tapKey(t, 'shutter');
      expect(find.text('Ảnh bị mờ'), findsOneWidget);
    });

    testWidgets('happy path: tags and note are sent, then the result opens', (
      t,
    ) async {
      final repo = FakeCheckinRepository(result: fakeResult());
      final src = FakeImageSource([jpegOf(sharpImage(800, 600))]);
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin',
        checkins: repo,
        source: src,
      );
      await tapKey(t, 'tag-LEAF_YELLOW');
      await t.enterText(find.byType(TextField), 'Lá non vàng mép');
      await tapKey(t, 'shutter');
      expect(find.text('Cần chụp lại'), findsNothing);
      await tapKey(t, 'analyze');

      expect(repo.uploads, hasLength(1));
      expect(repo.created.single.tags, ['LEAF_YELLOW']);
      expect(repo.created.single.note, 'Lá non vàng mép');
      expect(repo.created.single.shots.single.type, ShotType.wholePlant);
      expect(repo.analyzed, ['c1']);
      expect(find.text('Kết quả check-in'), findsOneWidget);
      // The live response carries XP; the chip shows.
      expect(find.byKey(const Key('xp-chip')), findsOneWidget);
    });

    testWidgets('server retake leads to screen 15 with the template hint', (
      t,
    ) async {
      final repo = FakeCheckinRepository(
        outcome: const CheckinRetake(
          checkinId: 'c1',
          reason: 'BLUR',
          hintCode: 'H_RETAKE_BLUR',
        ),
      );
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin',
        checkins: repo,
        source: FakeImageSource([jpegOf(sharpImage(800, 600))]),
      );
      await tapKey(t, 'shutter');
      await tapKey(t, 'analyze');
      expect(find.text('Cần chụp lại'), findsOneWidget);
      expect(find.text('Ảnh bị mờ'), findsOneWidget);
      expect(find.text('Giữ máy chắc tay rồi chụp lại.'), findsOneWidget);
      await tapKey(t, 'retake-cta');
      // Back on a fresh camera screen: the old shots are gone.
      expect(find.byKey(const Key('shutter')), findsOneWidget);
      expect(find.text('Đã chụp 0/3 ảnh'), findsOneWidget);
    });

    testWidgets('quota exceeded shows a friendly message', (t) async {
      final repo = FakeCheckinRepository(
        analyzeError: const CheckinQuotaExceeded(used: 10, cap: 10),
      );
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin',
        checkins: repo,
        source: FakeImageSource([jpegOf(sharpImage(800, 600))]),
      );
      await tapKey(t, 'shutter');
      await tapKey(t, 'analyze');
      expect(find.byKey(const Key('checkin-quota')), findsOneWidget);
      expect(find.text('Hôm nay đã hết lượt phân tích'), findsOneWidget);
      expect(find.textContaining('10/10'), findsOneWidget);
      expect(find.text('Kết quả check-in'), findsNothing);
    });

    testWidgets('AI unavailable: plan untouched, retry calls analyze again', (
      t,
    ) async {
      final repo = FakeCheckinRepository(
        analyzeError: const CheckinAiUnavailable(),
      );
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin',
        checkins: repo,
        source: FakeImageSource([jpegOf(sharpImage(800, 600))]),
      );
      await tapKey(t, 'shutter');
      await tapKey(t, 'analyze');
      expect(find.byKey(const Key('checkin-ai-down')), findsOneWidget);
      repo.analyzeError = null;
      await tapKey(t, 'stop-primary');
      // Same check-in, uploaded once.
      expect(repo.uploads, hasLength(1));
      expect(repo.created, hasLength(1));
      expect(repo.analyzed, ['c1', 'c1']);
      expect(find.text('Kết quả check-in'), findsOneWidget);
    });

    testWidgets('skipped_recent offers the previous result', (t) async {
      final repo = FakeCheckinRepository(
        outcome: const CheckinSkippedRecent(previousCheckinId: 'old'),
      );
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin',
        checkins: repo,
        source: FakeImageSource([jpegOf(sharpImage(800, 600))]),
      );
      await tapKey(t, 'shutter');
      await tapKey(t, 'analyze');
      expect(find.byKey(const Key('checkin-skipped')), findsOneWidget);
      await tapKey(t, 'stop-primary');
      expect(find.text('Kết quả check-in'), findsOneWidget);
    });

    testWidgets('a camera failure is shown instead of doing nothing', (
      t,
    ) async {
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin',
        source: FailingImageSource(),
      );
      await tapKey(t, 'shutter');
      // The in-frame fallback hint also starts with "Không mở được máy ảnh".
      expect(
        find.textContaining('Không mở được máy ảnh hoặc thư viện'),
        findsOneWidget,
      );
      expect(find.textContaining('No cameras available'), findsOneWidget);
      expect(find.text('Đã chụp 0/3 ảnh'), findsOneWidget);
    });

    testWidgets('live camera: preview shows when ready', (t) async {
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin',
        camera: () => FakeCheckinCamera(),
      );
      expect(find.byKey(const Key('fake-camera-preview')), findsOneWidget);
      expect(find.byKey(const Key('camera-unavailable')), findsNothing);
      expect(find.text('Đặt cả cây trong khung'), findsOneWidget);
    });

    testWidgets('live camera: shutter captures via the fake camera', (t) async {
      final cam = FakeCheckinCamera(photos: [jpegOf(sharpImage(800, 600))]);
      final src = FakeImageSource([]);
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin',
        camera: () => cam,
        source: src,
      );
      expect(find.text('Đã chụp 0/3 ảnh'), findsOneWidget);
      await tapKey(t, 'shutter');
      expect(cam.captured, 1);
      expect(src.taken, 0);
      expect(find.text('Đã chụp 1/3 ảnh'), findsOneWidget);
    });

    testWidgets('camera init failure falls back to the image source', (
      t,
    ) async {
      final src = FakeImageSource([jpegOf(sharpImage(800, 600))]);
      await pumpCheckinApp(
        t,
        initial: '/projects/new1/checkin',
        camera: () => FakeCheckinCamera(failInit: true),
        source: src,
      );
      expect(find.byKey(const Key('fake-camera-preview')), findsNothing);
      expect(find.byKey(const Key('camera-unavailable')), findsOneWidget);
      expect(
        find.textContaining('Bấm nút chụp để dùng máy ảnh của điện thoại'),
        findsOneWidget,
      );
      await tapKey(t, 'shutter');
      expect(src.taken, 1);
      expect(find.text('Đã chụp 1/3 ảnh'), findsOneWidget);
    });

    testWidgets('gallery fallback adds a photo', (t) async {
      final src = FakeImageSource([jpegOf(sharpImage(800, 600))]);
      await pumpCheckinApp(t, initial: '/projects/new1/checkin', source: src);
      await tapKey(t, 'pick-gallery');
      expect(src.taken, 0);
      expect(find.text('Đã chụp 1/3 ảnh'), findsOneWidget);
      // The next missing shot type is selected.
      expect(find.text('Ảnh 2/3 · Cận lá'), findsOneWidget);
    });
  });

  group('project detail', () {
    testWidgets('has a check-in entry and shows timeline thumbnails', (
      t,
    ) async {
      final repo = FakeCheckinRepository(
        timeline: [
          CheckinTimelineItem(
            id: 'c9',
            createdAt: DateTime(2026, 10, 15),
            status: 'analyzed',
            path: 'u1/new1/a.jpg',
            url: 'https://example.invalid/a.jpg',
          ),
        ],
      );
      await pumpCheckinApp(t, initial: '/projects/new1', checkins: repo);
      expect(find.byKey(const Key('checkin-entry')), findsOneWidget);
      await tapKey(t, 'tab-photos');
      expect(find.byKey(const Key('photo-c9')), findsOneWidget);
      expect(find.byType(Image), findsWidgets);

      await tapKey(t, 'checkin-entry');
      expect(find.byKey(const Key('shutter')), findsOneWidget);
    });
  });
}
