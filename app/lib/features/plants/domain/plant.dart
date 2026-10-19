/// `plant_group` enum (spec §4.1).
enum PlantGroup {
  rauQua('rau_qua'),
  cayCanh('cay_canh');

  const PlantGroup(this.code);
  final String code;

  static PlantGroup? fromCode(String? code) {
    for (final g in values) {
      if (g.code == code) return g;
    }
    return null;
  }
}

/// Row of the `plants` table (PLT-02 card fields).
class Plant {
  const Plant({
    required this.id,
    required this.group,
    required this.nameVi,
    this.nameEn,
    this.scientificName,
    this.difficulty,
    this.daysToHarvest,
  });

  final String id;
  final PlantGroup group;
  final String nameVi;
  final String? nameEn;
  final String? scientificName;

  /// `easy` | `medium` | `hard` (full range not fixed by the sources).
  final String? difficulty;
  final int? daysToHarvest;

  factory Plant.fromRow(Map<String, dynamic> row) => Plant(
    id: row['id'].toString(),
    group: PlantGroup.fromCode(row['group'] as String?) ?? PlantGroup.rauQua,
    nameVi: (row['name_vi'] as String?) ?? '',
    nameEn: row['name_en'] as String?,
    scientificName: row['scientific_name'] as String?,
    difficulty: row['difficulty'] as String?,
    daysToHarvest: (row['days_to_harvest'] as num?)?.toInt(),
  );
}
