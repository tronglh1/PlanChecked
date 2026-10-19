import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/plant.dart';

/// One localized `text_templates` row.
class TextTemplate {
  const TextTemplate({
    required this.kind,
    required this.code,
    required this.field,
    required this.body,
  });

  final String kind;
  final String code;
  final String field;
  final String body;
}

abstract class PlantRepository {
  Future<List<Plant>> fetchPlants();

  /// Localized text for the given [lang] (`vi` | `en`), optionally narrowed
  /// to one `kind` (task / problem / reason / milestone / safety).
  Future<List<TextTemplate>> fetchTextTemplates(String lang, {String? kind});
}

class SupabasePlantRepository implements PlantRepository {
  SupabasePlantRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<Plant>> fetchPlants() async {
    final rows = await _client
        .from('plants')
        .select(
          'id, group, name_vi, name_en, scientific_name, difficulty, days_to_harvest',
        )
        .order('name_vi');
    return [for (final r in rows) Plant.fromRow(r)];
  }

  @override
  Future<List<TextTemplate>> fetchTextTemplates(
    String lang, {
    String? kind,
  }) async {
    var query = _client
        .from('text_templates')
        .select('kind, code, field, body')
        .eq('lang', lang);
    if (kind != null) query = query.eq('kind', kind);
    final rows = await query;
    return [
      for (final r in rows)
        TextTemplate(
          kind: r['kind'] as String,
          code: r['code'] as String,
          field: r['field'] as String,
          body: r['body'] as String,
        ),
    ];
  }
}
