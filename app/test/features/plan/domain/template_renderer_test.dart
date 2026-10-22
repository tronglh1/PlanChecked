import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/plan/domain/template_renderer.dart';

TextTemplate t(
  String kind,
  String code,
  String lang,
  String field,
  String body,
) => TextTemplate(kind: kind, code: code, lang: lang, field: field, body: body);

void main() {
  final r = TemplateRenderer([
    t('task', 'T_WATER', 'vi', 'name', 'Tưới nước {amount}ml/chậu'),
    t('task', 'T_WATER', 'en', 'name', 'Water {amount}ml per pot'),
    t('task', 'T_FERT_ORGANIC', 'vi', 'name', 'Bón phân trùn quế'),
    t(
      'task',
      'T_FERT_ORGANIC',
      'vi',
      'steps',
      '1. Rải 1 nắm tay phân quanh gốc.\n- Xới nhẹ lớp đất mặt.\n\n* Tưới đẫm nước.',
    ),
    t('task', 'T_FERT_ORGANIC', 'vi', 'why', 'Cây đang ra nhiều lá.'),
    t('task', 'T_FERT_ORGANIC', 'vi', 'safety', 'Làm theo liều trên nhãn.'),
    t('problem', 'P_APHID', 'vi', 'name', 'Rệp {where}'),
    t('reason', 'R_HOT_SEASON', 'vi', 'why', 'Mùa nóng, tưới sớm {n} lần.'),
    t('task', 'T_BLANK', 'vi', 'name', '   '),
  ]);

  test('renders vi by default with param substitution', () {
    expect(
      r.taskName('T_WATER', params: {'amount': 300}),
      'Tưới nước 300ml/chậu',
    );
  });

  test('en uses the en template when present', () {
    expect(
      r.taskName('T_WATER', lang: 'en', params: {'amount': 300}),
      'Water 300ml per pot',
    );
  });

  test('en falls back to vi when the en template is missing', () {
    expect(r.taskName('T_FERT_ORGANIC', lang: 'en'), 'Bón phân trùn quế');
  });

  test('unknown placeholders stay, null params stringify', () {
    expect(r.taskName('T_WATER'), 'Tưới nước {amount}ml/chậu');
    expect(r.problemName('P_APHID', params: {'where': null}), 'Rệp null');
  });

  test('repeated placeholder and non-identifier braces', () {
    expect(
      TemplateRenderer.substitute('{a}-{a} {1} {a b}', {'a': 'x'}),
      'x-x {1} {a b}',
    );
  });

  test('missing template falls back to a readable code', () {
    expect(r.taskName('T_PRUNE_SUCKERS'), 'Prune suckers');
    expect(r.problemName('P_YELLOW_LEAF_OVERWATER'), 'Yellow leaf overwater');
    expect(r.reasonText('R_UNKNOWN'), 'Unknown');
    expect(TemplateRenderer.readableCode('SPROUT'), 'Sprout');
    expect(TemplateRenderer.readableCode('___'), '___');
  });

  test('blank body counts as missing', () {
    expect(r.taskName('T_BLANK'), 'Blank');
  });

  test('steps split by line, bullets and numbers stripped, blanks dropped', () {
    expect(r.taskSteps('T_FERT_ORGANIC'), [
      'Rải 1 nắm tay phân quanh gốc.',
      'Xới nhẹ lớp đất mặt.',
      'Tưới đẫm nước.',
    ]);
    expect(r.taskSteps('T_NOPE'), isEmpty);
  });

  test('why/safety are nullable when absent', () {
    expect(r.taskWhy('T_FERT_ORGANIC'), 'Cây đang ra nhiều lá.');
    expect(r.taskSafety('T_FERT_ORGANIC'), 'Làm theo liều trên nhãn.');
    expect(r.taskWhy('T_WATER'), isNull);
    expect(r.taskSafety('T_WATER'), isNull);
  });

  test('reason text and fromRows', () {
    expect(
      r.reasonText('R_HOT_SEASON', params: {'n': 2}),
      'Mùa nóng, tưới sớm 2 lần.',
    );
    final r2 = TemplateRenderer.fromRows([
      {
        'kind': 'task',
        'code': 'T_A',
        'lang': 'vi',
        'field': 'name',
        'body': 'A',
      },
    ]);
    expect(r2.taskName('T_A'), 'A');
  });

  test('later duplicate rows win', () {
    final r3 = TemplateRenderer([
      t('task', 'T_A', 'vi', 'name', 'old'),
      t('task', 'T_A', 'vi', 'name', 'new'),
    ]);
    expect(r3.taskName('T_A'), 'new');
  });
}
