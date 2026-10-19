/// Timezone-free calendar-date helpers. A "date" is a `DateTime.utc(y, m, d)`
/// at 00:00 UTC, so arithmetic never crosses a DST boundary and day counts are
/// exact. Pure Dart (no Flutter imports).
library;

/// Strips the time part. Local or UTC input is read by its own y/m/d fields.
DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Adds [days] (may be negative) calendar days; month/year rollover handled.
DateTime addDays(DateTime d, int days) =>
    DateTime.utc(d.year, d.month, d.day + days);

/// Whole calendar days from [a] to [b] (b - a). Negative when b is earlier.
int daysBetween(DateTime a, DateTime b) =>
    dateOnly(b).difference(dateOnly(a)).inDays;

bool isSameDate(DateTime a, DateTime b) => daysBetween(a, b) == 0;

/// `yyyy-MM-dd` (the Postgres `date` text form).
String formatIsoDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Parses `yyyy-MM-dd` (a trailing time part is ignored) into a date-only
/// value. Throws [FormatException] on malformed input.
DateTime parseIsoDate(String s) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
  if (m == null) throw FormatException('Not an ISO date', s);
  final y = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final d = int.parse(m.group(3)!);
  final out = DateTime.utc(y, mo, d);
  if (out.month != mo || out.day != d) {
    throw FormatException('Invalid calendar date', s);
  }
  return out;
}
