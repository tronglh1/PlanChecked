/// Level table and progress (display only). Spec §6.3 only pins two data
/// points: "Cấp 4 · Người chăm chỉ" at 1,250 XP and "Cấp 5 · Thợ vườn" at
/// 1,500 XP; the hero bar shows 62%. The other thresholds/names below are
/// PLACEHOLDERS chosen so that data point reproduces (level 4 starts at 850:
/// (1250-850)/(1500-850) = 61.5% ~ 62%). Level UI is badged P2.
library;

class LevelDef {
  const LevelDef(this.level, this.minXp, this.nameVi);
  final int level;
  final int minXp;
  final String nameVi;
}

class LevelProgress {
  const LevelProgress({
    required this.current,
    required this.next,
    required this.xp,
  });

  final LevelDef current;

  /// Null at the top level.
  final LevelDef? next;
  final int xp;

  /// 0..1 inside the current level; 1 at the top level.
  double get fraction {
    final n = next;
    if (n == null) return 1;
    final span = n.minXp - current.minXp;
    if (span <= 0) return 1;
    return ((xp - current.minXp) / span).clamp(0.0, 1.0);
  }

  /// XP missing for the next level ("Còn 250 XP"); 0 at the top level.
  int get xpToNext => next == null ? 0 : next!.minXp - xp;
}

class Levels {
  const Levels._();

  static const List<LevelDef> defaults = [
    LevelDef(1, 0, 'Người mới'),
    LevelDef(2, 150, 'Biết chăm cây'),
    LevelDef(3, 400, 'Quen tay'),
    LevelDef(4, 850, 'Người chăm chỉ'),
    LevelDef(5, 1500, 'Thợ vườn'),
    LevelDef(6, 2400, 'Thợ vườn lão luyện'),
    LevelDef(7, 3600, 'Chủ vườn'),
    LevelDef(8, 5200, 'Nhà vườn'),
  ];

  /// Progress for [xp] (negative treated as 0). [table] must be ascending by
  /// `minXp` and non-empty.
  static LevelProgress progress(int xp, {List<LevelDef> table = defaults}) {
    final x = xp < 0 ? 0 : xp;
    var idx = 0;
    for (var i = 0; i < table.length; i++) {
      if (x >= table[i].minXp) idx = i;
    }
    return LevelProgress(
      current: table[idx],
      next: idx + 1 < table.length ? table[idx + 1] : null,
      xp: x,
    );
  }
}
