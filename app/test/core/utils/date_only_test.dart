import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/core/utils/date_only.dart';

void main() {
  test('dateOnly strips time and normalizes to UTC', () {
    expect(
      dateOnly(DateTime(2026, 10, 19, 23, 59)),
      DateTime.utc(2026, 10, 19),
    );
  });

  test('addDays crosses month, year and leap day', () {
    expect(addDays(DateTime.utc(2026, 1, 31), 1), DateTime.utc(2026, 2, 1));
    expect(addDays(DateTime.utc(2026, 12, 31), 1), DateTime.utc(2027, 1, 1));
    expect(addDays(DateTime.utc(2028, 2, 28), 1), DateTime.utc(2028, 2, 29));
    expect(addDays(DateTime.utc(2026, 3, 1), -1), DateTime.utc(2026, 2, 28));
  });

  test('daysBetween is exact and signed', () {
    expect(
      daysBetween(DateTime.utc(2026, 10, 1), DateTime.utc(2026, 11, 1)),
      31,
    );
    expect(
      daysBetween(DateTime.utc(2026, 11, 1), DateTime.utc(2026, 10, 1)),
      -31,
    );
    expect(daysBetween(DateTime.utc(2026, 3, 1), DateTime.utc(2026, 3, 1)), 0);
  });

  test('format/parse ISO date round trip and validation', () {
    expect(formatIsoDate(DateTime.utc(2026, 2, 3)), '2026-02-03');
    expect(parseIsoDate('2026-02-03'), DateTime.utc(2026, 2, 3));
    expect(parseIsoDate('2026-02-03T10:00:00Z'), DateTime.utc(2026, 2, 3));
    expect(() => parseIsoDate('2026-02-30'), throwsFormatException);
    expect(() => parseIsoDate('nope'), throwsFormatException);
  });
}
