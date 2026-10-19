import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/gamification/domain/achievements_models.dart';

import '../../helpers/household_fakes.dart';

const _levels = [
  LevelRow(1, 0, 'Người mới', 'Newcomer'),
  LevelRow(2, 250, 'Người ươm mầm', 'Seed Starter'),
  LevelRow(3, 700, 'Người yêu cây', 'Plant Lover'),
  LevelRow(4, 1250, 'Người chăm chỉ', 'Dedicated'),
  LevelRow(5, 1500, 'Thợ vườn', 'Gardener'),
];

const _badges = [
  BadgeInfo(
    code: 'FIRST_SEED',
    nameVi: 'Hạt giống đầu tiên',
    nameEn: 'First Seed',
    earned: true,
  ),
  BadgeInfo(
    code: 'SPROUT',
    nameVi: 'Nảy mầm',
    nameEn: 'Sprouted',
    earned: true,
  ),
  BadgeInfo(code: 'BLOOM', nameVi: 'Ra hoa', nameEn: 'In Bloom', earned: false),
  BadgeInfo(
    code: 'STREAK_30',
    nameVi: '30 ngày liên tục',
    nameEn: '30-Day Streak',
    earned: false,
  ),
];

AchievementsData _data({
  int xp = 1250,
  List<LevelRow> levels = _levels,
  int pending = 0,
}) => AchievementsData(
  xpTotal: xp,
  levels: levels,
  badges: _badges,
  streak: 12,
  pendingPhotoMilestones: pending,
  xp: const XpBreakdown(
    taskDone: 620,
    checkin: 330,
    milestone: 300,
    todayTaskDone: 60,
  ),
);

void main() {
  group('Thành tích (20)', () {
    testWidgets('renders XP, level, progress, tiles, streak and badges', (
      t,
    ) async {
      await pumpRouted(
        t,
        location: '/achievements',
        gamification: FakeGamificationRepository(data: _data()),
      );
      expect(find.text('Thành tích'), findsOneWidget);
      expect(find.text('1.250 XP'), findsOneWidget);
      expect(find.text('Cấp 4 · Người chăm chỉ'), findsOneWidget);
      expect(find.text('Còn 250 XP để lên Cấp 5 · Thợ vườn'), findsOneWidget);
      // Server table: level 4 starts at 1250 -> 0% of the way to 1500.
      final bar = t.widget<LinearProgressIndicator>(
        find.byKey(const Key('level-bar')),
      );
      expect(bar.value, 0.0);
      expect(find.text('12 ngày liên tục'), findsOneWidget);
      expect(find.text('+620 XP'), findsOneWidget);
      expect(find.text('+330 XP'), findsOneWidget);
      expect(find.text('+300 XP'), findsOneWidget);
      expect(find.text('60/150 XP'), findsOneWidget);

      expect(find.text('Huy hiệu · 2/4'), findsOneWidget);
      expect(find.byKey(const Key('badge-FIRST_SEED')), findsOneWidget);
      expect(find.text('Hạt giống đầu tiên'), findsOneWidget);
      // Two locked badges are captioned.
      expect(find.text('Chưa đạt'), findsNWidgets(2));
    });

    testWidgets('shows the anti-cheat message (GAM-08)', (t) async {
      await pumpRouted(
        t,
        location: '/achievements',
        gamification: FakeGamificationRepository(data: _data()),
      );
      expect(find.byKey(const Key('anti-cheat')), findsOneWidget);
      expect(
        find.text(
          'Mỗi ngày tối đa 150 XP từ việc thường. Điểm milestone chỉ cộng khi có ảnh check-in xác nhận.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('pending-photo')), findsNothing);
    });

    testWidgets('milestones awaiting a photo are flagged', (t) async {
      await pumpRouted(
        t,
        location: '/achievements',
        gamification: FakeGamificationRepository(data: _data(pending: 2)),
      );
      expect(
        find.text('2 mốc đang chờ ảnh check-in xác nhận, chưa tính XP.'),
        findsOneWidget,
      );
    });

    testWidgets('falls back to domain defaults without server levels', (
      t,
    ) async {
      await pumpRouted(
        t,
        location: '/achievements',
        gamification: FakeGamificationRepository(
          data: _data(xp: 1250, levels: const []),
        ),
      );
      // Domain defaults: level 4 starts at 850, level 5 at 1500.
      expect(find.text('Cấp 4 · Người chăm chỉ'), findsOneWidget);
      final bar = t.widget<LinearProgressIndicator>(
        find.byKey(const Key('level-bar')),
      );
      expect(bar.value, closeTo(0.615, 0.01));
    });

    test('model: top level and breakdown', () {
      final top = _data(xp: 9999);
      expect(top.progress.next, isNull);
      expect(top.progress.fraction, 1);
      final b = XpBreakdown.fromEvents([
        (source: 'task_done', amount: 10, day: DateTime(2026, 5, 1)),
        (source: 'task_done', amount: 10, day: DateTime(2026, 5, 2)),
        (source: 'checkin', amount: 30, day: DateTime(2026, 5, 2)),
        (source: 'milestone', amount: 100, day: DateTime(2026, 5, 2)),
      ], DateTime(2026, 5, 2));
      expect(b.taskDone, 20);
      expect(b.todayTaskDone, 10);
      expect(b.checkin, 30);
      expect(b.milestone, 100);
    });
  });

  group('Chúc mừng milestone (16)', () {
    MilestoneInfo info({bool photo = true}) => MilestoneInfo(
      projectId: 'p1',
      projectName: 'Cà chua bi ban công',
      code: 'HEIGHT_40',
      title: 'Cao 40cm rồi!',
      photoConfirmed: photo,
      xpAwarded: photo ? 100 : 0,
      reachedOn: DateTime(2026, 10, 12),
      badge: BadgeInfo(
        code: 'TALL',
        nameVi: 'Vươn cao',
        nameEn: 'Reaching Up',
        earned: photo,
      ),
    );

    testWidgets('renders the celebration on the dark green background', (
      t,
    ) async {
      await pumpRouted(
        t,
        location: '/projects/p1/milestone/HEIGHT_40',
        gamification: FakeGamificationRepository(milestone: info()),
      );
      expect(find.text('ĐẠT MỐC MỚI'), findsOneWidget);
      expect(find.text('Cao 40cm rồi!'), findsWidgets);
      expect(
        find.text(
          'Cà chua bi ban công đã qua một mốc mới. Ảnh check-in hôm nay đã xác nhận.',
        ),
        findsOneWidget,
      );
      expect(find.text('+100 XP'), findsOneWidget);
      expect(find.text('“Vươn cao”'), findsWidgets);
      expect(find.byKey(const Key('milestone-pending-note')), findsNothing);
      expect(find.byKey(const Key('confetti')), findsOneWidget);
      final scaffold = t.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, const Color(0xFF14502F));
    });

    testWidgets('without a photo: no XP and an anti-cheat note', (t) async {
      await pumpRouted(
        t,
        location: '/projects/p1/milestone/HEIGHT_40',
        gamification: FakeGamificationRepository(milestone: info(photo: false)),
      );
      expect(find.text('Chờ ảnh'), findsOneWidget);
      expect(find.text('+100 XP'), findsNothing);
      expect(find.byKey(const Key('milestone-pending-note')), findsOneWidget);
    });

    testWidgets('share renders the keepsake card to a PNG', (t) async {
      final share = FakeShareService();
      await pumpRouted(
        t,
        location: '/projects/p1/milestone/HEIGHT_40',
        gamification: FakeGamificationRepository(milestone: info()),
        share: share,
      );
      await t.ensureVisible(find.byKey(const Key('milestone-share')));
      await t.tap(find.byKey(const Key('milestone-share')));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await t.pumpAndSettle();
      expect(share.images, hasLength(1));
      // PNG signature.
      expect(share.images.single.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      expect(
        share.imageTexts.single,
        'Cà chua bi ban công vừa đạt mốc “Cao 40cm rồi!” trên Vườn Nhà!',
      );
    });

    testWidgets('"Xem thành tích" opens the achievements tab', (t) async {
      await pumpRouted(
        t,
        location: '/projects/p1/milestone/HEIGHT_40',
        gamification: FakeGamificationRepository(
          milestone: info(),
          data: _data(),
        ),
      );
      await t.ensureVisible(find.byKey(const Key('milestone-achievements')));
      await t.tap(find.byKey(const Key('milestone-achievements')));
      await t.pumpAndSettle();
      expect(find.text('Thành tích'), findsOneWidget);
      expect(find.text('1.250 XP'), findsOneWidget);
    });
  });
}
