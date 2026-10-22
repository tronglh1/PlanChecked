/// Turns task/problem/reason codes into localized text from the
/// `text_templates` table (kind, code, lang, field, body). Pure Dart.
library;

class TextTemplate {
  const TextTemplate({
    required this.kind,
    required this.code,
    required this.lang,
    required this.field,
    required this.body,
  });

  /// task | problem | reason | milestone | safety
  final String kind;
  final String code;
  final String lang;

  /// name | steps | why | safety
  final String field;
  final String body;

  factory TextTemplate.fromJson(Map<String, dynamic> j) => TextTemplate(
    kind: j['kind'] as String,
    code: j['code'] as String,
    lang: j['lang'] as String,
    field: j['field'] as String,
    body: (j['body'] as String?) ?? '',
  );
}

class TemplateRenderer {
  /// [templates] are indexed by kind/code/lang/field. Later rows win on
  /// duplicates.
  TemplateRenderer(Iterable<TextTemplate> templates, {this.defaultLang = 'vi'})
    : _index = {
        for (final t in templates)
          _key(t.kind, t.code, t.lang, t.field): t.body,
      };

  factory TemplateRenderer.fromRows(
    Iterable<Map<String, dynamic>> rows, {
    String defaultLang = 'vi',
  }) => TemplateRenderer(
    rows.map(TextTemplate.fromJson),
    defaultLang: defaultLang,
  );

  /// Fallback language when the requested one has no template. Vietnamese is
  /// the default content language.
  final String defaultLang;
  final Map<String, String> _index;

  static String _key(String kind, String code, String lang, String field) =>
      '$kind\u0000$code\u0000$lang\u0000$field';

  static final RegExp _placeholder = RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}');

  /// Raw template body for [lang], else [defaultLang], else null. Blank bodies
  /// count as missing.
  String? lookup(String kind, String code, String field, {String lang = 'vi'}) {
    for (final l in {lang, defaultLang}) {
      final body = _index[_key(kind, code, l, field)];
      if (body != null && body.trim().isNotEmpty) return body;
    }
    return null;
  }

  /// Substitutes `{param}` placeholders. Unknown placeholders are left
  /// as-is; values are stringified.
  static String substitute(String body, Map<String, Object?> params) {
    return body.replaceAllMapped(_placeholder, (m) {
      final name = m.group(1)!;
      return params.containsKey(name) ? '${params[name]}' : m.group(0)!;
    });
  }

  /// Readable fallback for a missing template: `T_FERT_ORGANIC` ->
  /// `Fert organic`, `P_YELLOW_LEAF_OVERWATER` -> `Yellow leaf overwater`.
  static String readableCode(String code) {
    var c = code.trim();
    c = c.replaceFirst(RegExp(r'^[A-Za-z]_(?=.)'), '');
    c = c.replaceAll('_', ' ').toLowerCase().trim();
    if (c.isEmpty) return code;
    return c[0].toUpperCase() + c.substring(1);
  }

  String render(
    String kind,
    String code,
    String field, {
    String lang = 'vi',
    Map<String, Object?> params = const {},
  }) {
    final body = lookup(kind, code, field, lang: lang);
    if (body == null) return readableCode(code);
    return substitute(body, params);
  }

  /// Step lists are stored as one body, one step per line (a leading `-`,
  /// `*`, or `1.` is stripped). Missing -> empty list.
  List<String> steps(
    String kind,
    String code, {
    String lang = 'vi',
    Map<String, Object?> params = const {},
  }) {
    final body = lookup(kind, code, 'steps', lang: lang);
    if (body == null) return const [];
    return substitute(body, params)
        .split(RegExp(r'\r?\n'))
        .map(
          (l) => l.replaceFirst(RegExp(r'^\s*(?:[-*•]|\d+[.)])\s*'), '').trim(),
        )
        .where((l) => l.isNotEmpty)
        .toList();
  }

  String taskName(
    String code, {
    String lang = 'vi',
    Map<String, Object?> params = const {},
  }) => render('task', code, 'name', lang: lang, params: params);

  List<String> taskSteps(
    String code, {
    String lang = 'vi',
    Map<String, Object?> params = const {},
  }) => steps('task', code, lang: lang, params: params);

  /// Null when no "why" text exists (UI hides the line).
  String? taskWhy(
    String code, {
    String lang = 'vi',
    Map<String, Object?> params = const {},
  }) {
    final body = lookup('task', code, 'why', lang: lang);
    return body == null ? null : substitute(body, params);
  }

  String? taskSafety(
    String code, {
    String lang = 'vi',
    Map<String, Object?> params = const {},
  }) {
    final body = lookup('task', code, 'safety', lang: lang);
    return body == null ? null : substitute(body, params);
  }

  String problemName(
    String code, {
    String lang = 'vi',
    Map<String, Object?> params = const {},
  }) => render('problem', code, 'name', lang: lang, params: params);

  /// Reason text lives in field `why`; `name` is accepted as a fallback.
  String reasonText(
    String code, {
    String lang = 'vi',
    Map<String, Object?> params = const {},
  }) {
    final body =
        lookup('reason', code, 'why', lang: lang) ??
        lookup('reason', code, 'name', lang: lang);
    return body == null ? readableCode(code) : substitute(body, params);
  }
}
