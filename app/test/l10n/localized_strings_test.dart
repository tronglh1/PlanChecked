import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/gamification/domain/levels.dart';
import 'package:vuon_nha/features/gamification/domain/streak_badges.dart';
import 'package:vuon_nha/features/today/presentation/today_providers.dart';
import 'package:vuon_nha/l10n/app_localizations.dart';

void main() {
  final vi = lookupAppLocalizations(const Locale('vi'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('notification channel names and descriptions are localized', () {
    final v = reminderTextsFor(vi).channels;
    final e = reminderTextsFor(en).channels;
    expect(v.taskName, 'Nhắc việc chăm cây');
    expect(e.taskName, 'Plant care reminders');
    expect(v.checkinName, isNot(e.checkinName));
    for (final c in [v, e]) {
      expect(c.taskDescription, isNotEmpty);
      expect(c.checkinDescription, isNotEmpty);
    }
  });

  test('XP suffix goes through the ARB files', () {
    expect(vi.gamXpGain('1.200'), '+1.200 XP');
    expect(en.gamXpGain('1,200'), '+1,200 XP');
  });

  test('fallback level and badge names exist in vi and en', () {
    for (final l in Levels.defaults) {
      expect(l.name('vi'), l.nameVi);
      expect(l.nameEn, isNotEmpty, reason: 'level ${l.level}');
      expect(l.name('en'), l.nameEn);
      expect(l.nameEn, isNot(l.nameVi));
    }
    for (final b in Badges.catalog) {
      expect(b.nameEn, isNotEmpty, reason: b.code);
      expect(b.name('en'), b.nameEn);
      expect(b.name('vi'), b.nameVi);
    }
  });
}
