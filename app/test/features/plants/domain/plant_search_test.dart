import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/plants/domain/plant.dart';
import 'package:vuon_nha/features/plants/domain/plant_search.dart';

Plant p(String id, String vi, {String? en, String? sci, PlantGroup? g}) =>
    Plant(
      id: id,
      group: g ?? PlantGroup.rauQua,
      nameVi: vi,
      nameEn: en,
      scientificName: sci,
    );

void main() {
  final plants = [
    p('1', 'Rau muống', en: 'Water spinach', sci: 'Ipomoea aquatica'),
    p('2', 'Cà chua bi', en: 'Cherry tomato', sci: 'Solanum lycopersicum'),
    p('3', 'Cà chua thường', sci: 'Solanum lycopersicum'),
    p(
      '4',
      'Cà chua tím',
      en: 'Indigo Rose tomato',
      sci: 'Solanum lycopersicum',
    ),
    p('5', 'Ớt chỉ thiên', en: 'Chili'),
    p('6', 'Trầu bà', en: 'Pothos', g: PlantGroup.cayCanh),
    p('7', 'Rau muống nước', en: 'Aquatic water spinach'),
  ];

  List<String> ids(PlantSearchResult r) => [
    for (final m in r.matches) m.plant.id,
  ];

  test('diacritic-free match: "rau muong" finds Rau muống', () {
    final r = PlantSearch.search(plants, 'rau muong');
    expect(ids(r).first, '1');
    expect(r.matches.first.tier, MatchTier.exact);
  });

  test('is case and whitespace insensitive', () {
    final r = PlantSearch.search(plants, '  RAU   MUONG ');
    expect(ids(r).first, '1');
  });

  test('prefix ranks above contains; exact above prefix', () {
    final r = PlantSearch.search(plants, 'rau muong');
    expect(ids(r), ['1', '7']); // exact, then prefix
    final c = PlantSearch.search(plants, 'chua');
    expect(c.matches.every((m) => m.tier == MatchTier.contains), isTrue);
    final mixed = PlantSearch.search(plants, 'ca chua');
    expect(mixed.matches.map((m) => m.tier).toSet(), {MatchTier.prefix});
    final both = PlantSearch.search([
      p('a', 'Hoa cúc'),
      p('b', 'Cúc họa mi'),
    ], 'cuc');
    expect(ids(both), ['b', 'a']); // prefix before contains
  });

  test('matches English and scientific names', () {
    expect(ids(PlantSearch.search(plants, 'pothos')), ['6']);
    expect(ids(PlantSearch.search(plants, 'ipomoea')), ['1']);
    expect(ids(PlantSearch.search(plants, 'cherry')), ['2']);
  });

  test('typo within edit distance 2 becomes a suggestion', () {
    final r = PlantSearch.search(plants, 'ca chua tin');
    expect(r.matches.map((m) => m.plant.id), isNot(contains('4')));
    expect(r.suggestions.map((m) => m.plant.id), contains('4'));
    expect(r.suggestions.first.tier, MatchTier.fuzzy);
    expect(r.suggestions.first.distance, lessThanOrEqualTo(2));
  });

  test('distance above 2 is not suggested; short queries never go fuzzy', () {
    expect(PlantSearch.search(plants, 'xoai').suggestions, isEmpty);
    expect(PlantSearch.search(plants, 'zz').suggestions, isEmpty);
    expect(PlantSearch.maxDistanceFor(2), 0);
    expect(PlantSearch.maxDistanceFor(4), 1);
    expect(PlantSearch.maxDistanceFor(8), 2);
  });

  test('suggestions are ordered by distance and capped at 3', () {
    final many = [for (var i = 0; i < 6; i++) p('$i', 'Cà chua ${i}x')];
    final r = PlantSearch.search(many, 'ca chuq');
    expect(r.suggestions.length, lessThanOrEqualTo(3));
    final d = [for (final s in r.suggestions) s.distance];
    expect(d, [...d]..sort());
  });

  test('group filter restricts results', () {
    final r = PlantSearch.search(plants, 'a', group: PlantGroup.cayCanh);
    expect(ids(r), ['6']);
    final all = PlantSearch.search(plants, '', group: PlantGroup.rauQua);
    expect(all.matches.length, 6);
  });

  test('empty query lists everything alphabetically', () {
    final r = PlantSearch.search(plants, '');
    expect(r.matches.length, plants.length);
    expect(r.suggestions, isEmpty);
  });

  test('editDistance basics', () {
    expect(PlantSearch.editDistance('kitten', 'sitting', 3), 3);
    expect(PlantSearch.editDistance('kitten', 'sitting', 2), isNull);
    expect(PlantSearch.editDistance('abc', 'abc', 0), 0);
  });
}
