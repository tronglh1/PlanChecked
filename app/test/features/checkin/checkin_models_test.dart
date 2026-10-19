import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/checkin/data/checkin_repository.dart';
import 'package:vuon_nha/features/checkin/domain/checkin_models.dart';

const okBody = {
  'status': 'ok',
  'checkin_id': 'c1',
  'stage_est': {'code': 'S3_late', 'confidence': 0.82},
  'health': {'value': 'good', 'confidence': 0.8},
  'issues': [
    {
      'code': 'P_CALCIUM_LOW',
      'confidence': 0.58,
      'severity': 1,
      'actions': [
        {'task': 'T_EGGSHELL_ADD'},
      ],
    },
  ],
  'milestone_seen': {'code': 'HEIGHT_40', 'confidence': 0.9},
  'milestone': {'code': 'HEIGHT_40', 'confidence': 0.9, 'new': true},
  'changes': [
    {
      'id': 'a',
      'change_kind': 'add',
      'payload': {'op': 'add', 'task': 'T_EGGSHELL_ADD', 'stage': 'S3'},
    },
    {
      'id': 'b',
      'change_kind': 'change_freq',
      'payload': {'op': 'change_freq', 'task': 'T_WATER', 'every_d': 1},
    },
    {
      'id': 'c',
      'change_kind': 'shift',
      'payload': {'op': 'shift', 'milestone': 'FLOWER', 'to': '2026-10-20'},
    },
  ],
  'reason_codes': ['R_HOT_SEASON'],
  'confidence_band': 'medium',
  'low_confidence': false,
  'xp': {'xp_total': 1280, 'level': 4},
};

void main() {
  test('bandOf follows the server thresholds', () {
    expect(bandOf(0.86), ConfidenceBand.high);
    expect(bandOf(0.75), ConfidenceBand.high);
    expect(bandOf(0.58), ConfidenceBand.medium);
    expect(bandOf(0.5), ConfidenceBand.medium);
    expect(bandOf(0.49), ConfidenceBand.low);
  });

  test('parseOutcome: ok body', () {
    final o = parseOutcome(Map<String, dynamic>.from(okBody), 'c1');
    final r = (o as CheckinAnalyzed).result;
    expect(r.checkinId, 'c1');
    expect(r.stageCode, 'S3_late');
    expect(r.stagePrefix, 'S3');
    expect(r.stagePhase, 'late');
    expect(r.health, 'good');
    expect(r.issues.single.actions, ['T_EGGSHELL_ADD']);
    expect(r.milestoneIsNew, isTrue);
    expect(r.changes.map((c) => c.kind), [
      ChangeKind.add,
      ChangeKind.changeFreq,
      ChangeKind.shift,
    ]);
    expect(r.changes[1].everyD, 1);
    expect(r.changes[2].to, DateTime(2026, 10, 20));
    expect(r.band, ConfidenceBand.medium);
    expect(r.lowConfidence, isFalse);
    expect(r.xpTotal, 1280);
    expect(r.minConfidence, 0.58);
  });

  test('low band -> lowConfidence', () {
    final body = Map<String, dynamic>.from(okBody)
      ..['confidence_band'] = 'low'
      ..['low_confidence'] = true;
    final r = (parseOutcome(body, 'c1') as CheckinAnalyzed).result;
    expect(r.lowConfidence, isTrue);
  });

  test('parseOutcome: retake and skipped_recent', () {
    final r = parseOutcome({
      'status': 'retake',
      'reason': 'DARK',
      'hint_code': 'H_RETAKE_LIGHT',
      'checkin_id': 'c9',
    }, 'c1');
    expect(r, isA<CheckinRetake>());
    expect((r as CheckinRetake).hintCode, 'H_RETAKE_LIGHT');
    expect(r.checkinId, 'c9');

    final noHint = parseOutcome({'status': 'retake', 'reason': 'BLUR'}, 'c1');
    expect((noHint as CheckinRetake).hintCode, 'H_RETAKE_BLUR');

    final s = parseOutcome({
      'status': 'skipped_recent',
      'previous_checkin_id': 'p1',
    }, 'c1');
    expect((s as CheckinSkippedRecent).previousCheckinId, 'p1');

    expect(
      () => parseOutcome({'status': 'weird'}, 'c1'),
      throwsA(isA<CheckinException>()),
    );
  });

  test('mapFunctionError: 429 quota, 502 AI down, other', () {
    final q = mapFunctionError(429, {
      'error': 'ai_quota_exceeded',
      'quota': {
        'checkin': {'used': 10, 'cap': 10},
      },
    });
    expect(q, isA<CheckinQuotaExceeded>());
    expect((q as CheckinQuotaExceeded).used, 10);
    expect(q.cap, 10);

    expect(
      mapFunctionError(502, {'status': 'error', 'code': 'AI_UNAVAILABLE'}),
      isA<CheckinAiUnavailable>(),
    );
    expect(
      mapFunctionError(400, {'error': 'no_valid_shots'}).code,
      'no_valid_shots',
    );
    expect(mapFunctionError(500, 'oops').code, 'http_500');
  });

  test('firstShotPathOf', () {
    expect(
      firstShotPathOf([
        {'shot': 'whole_plant', 'path': 'a/b/c.jpg'},
      ]),
      'a/b/c.jpg',
    );
    expect(firstShotPathOf(null), isNull);
    expect(firstShotPathOf(const []), isNull);
  });
}
