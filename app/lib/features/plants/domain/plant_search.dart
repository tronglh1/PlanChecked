import '../../../core/utils/vi_normalize.dart';
import 'plant.dart';

/// Ranking tier; lower is better.
enum MatchTier { exact, prefix, contains, fuzzy }

class PlantMatch {
  const PlantMatch(this.plant, this.tier, this.distance);

  final Plant plant;
  final MatchTier tier;

  /// Edit distance for [MatchTier.fuzzy]; 0 otherwise.
  final int distance;
}

class PlantSearchResult {
  const PlantSearchResult({
    this.matches = const [],
    this.suggestions = const [],
  });

  /// Exact / prefix / contains matches, best first.
  final List<PlantMatch> matches;

  /// Typo-tolerant matches (edit distance <= 2), best first, at most
  /// [PlantSearch.maxSuggestions]. Drives "Có phải bạn muốn nói…?".
  final List<PlantMatch> suggestions;
}

/// Pure-Dart diacritic-free fuzzy search over VN / EN / scientific names.
///
/// Ranking: exact > prefix > contains > edit-distance (<= 2). Within a tier:
/// smaller distance, then the field (VN name before EN before scientific),
/// then shorter name, then alphabetical.
class PlantSearch {
  const PlantSearch._();

  static const int maxSuggestions = 3;

  /// Allowed edit distance for a query of [length] characters. Very short
  /// queries never go fuzzy (too noisy); the cap is 2.
  static int maxDistanceFor(int length) {
    if (length < 3) return 0;
    if (length < 6) return 1;
    return 2;
  }

  static String normalize(String s) =>
      viNormalize(s).replaceAll(RegExp(r'\s+'), ' ').trim();

  static PlantSearchResult search(
    List<Plant> plants,
    String query, {
    PlantGroup? group,
  }) {
    final q = normalize(query);
    final pool = group == null
        ? plants
        : plants.where((p) => p.group == group).toList();
    if (q.isEmpty) {
      final sorted = [...pool]..sort((a, b) => a.nameVi.compareTo(b.nameVi));
      return PlantSearchResult(
        matches: [for (final p in sorted) PlantMatch(p, MatchTier.exact, 0)],
      );
    }

    final strict = <_Scored>[];
    final fuzzy = <_Scored>[];
    for (final p in pool) {
      final s = _score(p, q);
      if (s == null) continue;
      (s.tier == MatchTier.fuzzy ? fuzzy : strict).add(s);
    }
    strict.sort(_compare);
    fuzzy.sort(_compare);
    return PlantSearchResult(
      matches: [for (final s in strict) s.toMatch()],
      suggestions: [for (final s in fuzzy.take(maxSuggestions)) s.toMatch()],
    );
  }

  static int _compare(_Scored a, _Scored b) {
    var c = a.tier.index.compareTo(b.tier.index);
    if (c != 0) return c;
    c = a.distance.compareTo(b.distance);
    if (c != 0) return c;
    c = a.field.compareTo(b.field);
    if (c != 0) return c;
    c = a.nameLength.compareTo(b.nameLength);
    if (c != 0) return c;
    return a.plant.nameVi.compareTo(b.plant.nameVi);
  }

  static _Scored? _score(Plant p, String q) {
    final fields = [p.nameVi, p.nameEn, p.scientificName];
    _Scored? best;
    for (var i = 0; i < fields.length; i++) {
      final raw = fields[i];
      if (raw == null || raw.trim().isEmpty) continue;
      final name = normalize(raw);
      final s = _scoreField(p, i, name, q);
      if (s != null && (best == null || _compare(s, best) < 0)) best = s;
    }
    return best;
  }

  static _Scored? _scoreField(Plant p, int field, String name, String q) {
    MatchTier? tier;
    if (name == q) {
      tier = MatchTier.exact;
    } else if (name.startsWith(q)) {
      tier = MatchTier.prefix;
    } else if (name.contains(q)) {
      tier = MatchTier.contains;
    }
    if (tier != null) return _Scored(p, tier, 0, field, name.length);

    final limit = maxDistanceFor(q.length);
    if (limit == 0) return null;
    final d = _fuzzyDistance(name, q, limit);
    if (d == null) return null;
    return _Scored(p, MatchTier.fuzzy, d, field, name.length);
  }

  /// Smallest edit distance (<= [limit]) between [q] and the whole name, the
  /// name's leading characters, or any window of whole words.
  static int? _fuzzyDistance(String name, String q, int limit) {
    int? best;
    void consider(String candidate) {
      final d = editDistance(candidate, q, limit);
      if (d != null && (best == null || d < best!)) best = d;
    }

    consider(name);
    // Prefix-style typo: compare against the same-length head of the name.
    if (name.length > q.length) {
      consider(name.substring(0, q.length));
    }
    final words = name.split(' ');
    final n = q.split(' ').length;
    for (var i = 0; i + n <= words.length; i++) {
      consider(words.sublist(i, i + n).join(' '));
    }
    return best;
  }

  /// Levenshtein distance, or null when it exceeds [limit].
  static int? editDistance(String a, String b, int limit) {
    if ((a.length - b.length).abs() > limit) return null;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0);
      cur[0] = i;
      var rowMin = cur[0];
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        var v = prev[j - 1] + cost;
        if (prev[j] + 1 < v) v = prev[j] + 1;
        if (cur[j - 1] + 1 < v) v = cur[j - 1] + 1;
        cur[j] = v;
        if (v < rowMin) rowMin = v;
      }
      if (rowMin > limit) return null;
      prev = cur;
    }
    return prev[b.length] <= limit ? prev[b.length] : null;
  }
}

class _Scored {
  _Scored(this.plant, this.tier, this.distance, this.field, this.nameLength);

  final Plant plant;
  final MatchTier tier;
  final int distance;
  final int field;
  final int nameLength;

  PlantMatch toMatch() => PlantMatch(plant, tier, distance);
}
