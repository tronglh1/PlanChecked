import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/gamification/domain/levels.dart';
import 'package:vuon_nha/features/gamification/domain/streak_badges.dart';
import 'package:vuon_nha/features/gamification/domain/xp.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  group('XP rules', () {
    test('base amounts from spec §6.3', () {
      expect(XpPreview.award(XpSource.taskDone).amount, 10);
      expect(XpPreview.award(XpSource.checkin).amount, 30);
      expect(
        XpPreview.award(XpSource.milestone, photoConfirmed: true).amount,
        100,
      );
    });

    test('late task gives nothing', () {
      final a = XpPreview.award(XpSource.taskDone, onTime: false);
      expect(a.amount, 0);
      expect(a.outcome, XpOutcome.late);
    });

    test('milestone needs a photo-confirmed check-in', () {
      final a = XpPreview.award(XpSource.milestone);
      expect(a.amount, 0);
      expect(a.outcome, XpOutcome.needsPhoto);
    });

    test('project completed is undefined in the spec => 0', () {
      final a = XpPreview.award(XpSource.projectDone, photoConfirmed: true);
      expect(a.outcome, XpOutcome.notDefined);
      expect(a.amount, 0);
    });

    test('daily cap: full, partial, reached', () {
      expect(
        XpPreview.award(XpSource.taskDone, earnedOrdinaryToday: 140).amount,
        10,
      );
      final p = XpPreview.award(XpSource.checkin, earnedOrdinaryToday: 140);
      expect(p.amount, 10);
      expect(p.outcome, XpOutcome.partialCap);
      final r = XpPreview.award(XpSource.taskDone, earnedOrdinaryToday: 150);
      expect(r.amount, 0);
      expect(r.outcome, XpOutcome.capReached);
      expect(
        XpPreview.award(XpSource.taskDone, earnedOrdinaryToday: 999).amount,
        0,
      );
    });

    test('milestone XP ignores the daily cap', () {
      expect(
        XpPreview.award(
          XpSource.milestone,
          earnedOrdinaryToday: 150,
          photoConfirmed: true,
        ).amount,
        100,
      );
    });

    test('remaining and capped display (60/150)', () {
      expect(XpPreview.remainingToday(60), 90);
      expect(XpPreview.remainingToday(400), 0);
      expect(XpPreview.cappedToday(60), 60);
      expect(XpPreview.cappedToday(400), 150);
    });

    test('isOnTime compares dates only', () {
      expect(
        XpPreview.isOnTime(dueDate: d(2026, 11, 1), actedOn: d(2026, 11, 1)),
        isTrue,
      );
      expect(
        XpPreview.isOnTime(dueDate: d(2026, 11, 1), actedOn: d(2026, 10, 31)),
        isTrue,
      );
      expect(
        XpPreview.isOnTime(dueDate: d(2026, 10, 31), actedOn: d(2026, 11, 1)),
        isFalse,
      );
      // time-of-day does not matter
      expect(
        XpPreview.isOnTime(
          dueDate: DateTime(2026, 11, 1, 0, 1),
          actedOn: DateTime(2026, 11, 1, 23, 59),
        ),
        isTrue,
      );
    });

    test('totalForDay applies the cap in order', () {
      final actions = [
        for (var i = 0; i < 14; i++)
          (source: XpSource.taskDone, onTime: true, photoConfirmed: false),
        (
          source: XpSource.checkin,
          onTime: true,
          photoConfirmed: false,
        ), // 140 -> +10
        (source: XpSource.taskDone, onTime: true, photoConfirmed: false), // 0
        (
          source: XpSource.milestone,
          onTime: true,
          photoConfirmed: true,
        ), // +100
      ];
      expect(XpPreview.totalForDay(actions), 140 + 10 + 100);
    });

    test('source db strings', () {
      expect(XpSource.fromDb('task_done'), XpSource.taskDone);
      expect(() => XpSource.fromDb('x'), throwsFormatException);
    });
  });

  group('levels', () {
    test('1250 XP is level 4 "Người chăm chỉ", 250 to level 5, ~62%', () {
      final p = Levels.progress(1250);
      expect(p.current.level, 4);
      expect(p.current.nameVi, 'Người chăm chỉ');
      expect(p.next!.level, 5);
      expect(p.next!.nameVi, 'Thợ vườn');
      expect(p.xpToNext, 250);
      expect((p.fraction * 100).round(), 62);
    });

    test('boundaries: exact threshold enters the level', () {
      expect(Levels.progress(0).current.level, 1);
      expect(Levels.progress(1499).current.level, 4);
      expect(Levels.progress(1500).current.level, 5);
      expect(Levels.progress(1500).fraction, 0);
    });

    test('negative XP is treated as 0; top level is full', () {
      expect(Levels.progress(-5).xp, 0);
      final top = Levels.progress(999999);
      expect(top.next, isNull);
      expect(top.fraction, 1);
      expect(top.xpToNext, 0);
      expect(top.current.nameVi, 'Nhà vườn');
    });
  });

  group('streak', () {
    test('current streak counts back from today across a month boundary', () {
      final days = [d(2026, 10, 30), d(2026, 10, 31), d(2026, 11, 1)];
      expect(StreakCalculator.current(days, d(2026, 11, 1)), 3);
    });

    test('streak survives an empty today if yesterday was active', () {
      final days = [d(2026, 10, 30), d(2026, 10, 31)];
      expect(StreakCalculator.current(days, d(2026, 11, 1)), 2);
    });

    test('streak is broken after a missed day', () {
      final days = [d(2026, 10, 29), d(2026, 10, 30)];
      expect(StreakCalculator.current(days, d(2026, 11, 1)), 0);
    });

    test('duplicates and time parts are ignored', () {
      final days = [
        DateTime.utc(2026, 11, 1, 3),
        DateTime.utc(2026, 11, 1, 20),
        DateTime.utc(2026, 10, 31),
      ];
      expect(StreakCalculator.current(days, d(2026, 11, 1)), 2);
    });

    test('longest streak', () {
      final days = [
        d(2026, 1, 1),
        d(2026, 1, 2),
        d(2026, 1, 3),
        d(2026, 2, 27),
        d(2026, 2, 28),
        d(2026, 3, 1),
        d(2026, 3, 2),
      ];
      expect(StreakCalculator.longest(days), 4);
      expect(StreakCalculator.longest(const []), 0);
    });
  });

  group('badges', () {
    test('catalog has the 8 mockup badges', () {
      expect(Badges.catalog.length, 8);
      expect(Badges.totalInSpec, 16);
    });

    test('progress from stats', () {
      const stats = GamificationStats(
        projectsStarted: 2,
        checkins: 4,
        milestones: {'SPROUT', 'HEIGHT_40'},
        longestStreak: 12,
      );
      final p = {for (final b in Badges.progress(stats)) b.badge.code: b};
      expect(p['FIRST_SEED']!.earned, isTrue);
      expect(p['SPROUT']!.earned, isTrue);
      expect(p['TALL_40']!.earned, isTrue);
      expect(p['STREAK_7']!.earned, isTrue);
      expect(p['STREAK_7']!.current, 7); // clamped to target
      expect(p['STREAK_30']!.earned, isFalse);
      expect(p['STREAK_30']!.fraction, closeTo(12 / 30, 1e-9));
      expect(p['PHOTOGRAPHER']!.fraction, closeTo(0.4, 1e-9));
      expect(p['BLOOM']!.earned, isFalse);
      expect(p['FIRST_HARVEST']!.fraction, 0);
      expect(Badges.earnedCount(Badges.progress(stats)), 4);
    });

    test('empty stats earn nothing', () {
      expect(Badges.earnedCount(Badges.progress(const GamificationStats())), 0);
    });
  });
}
