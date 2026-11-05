/// Warranty maths, kept free of Firestore so the UI, the model and the
/// tests can all share it.
library;

enum WarrantyUnit { months, years }

WarrantyUnit warrantyUnitFromName(String? name) =>
    name == 'months' ? WarrantyUnit.months : WarrantyUnit.years;

/// How a warranty reads at a glance. A full progress bar alone cannot
/// tell "expires today" from "expired three years ago".
enum WarrantyStatus { active, expiringSoon, expired }

/// A warranty counts as expiring this many days before it ends, which is
/// also when the first reminder goes out.
const int kWarrantyWarnDays = 30;

const int kMaxWarrantyMonths = 120;
const int kMaxWarrantyYears = 30;

/// A calendar date as `firestore.rules` and the push worker expect it.
///
/// Stored as text because a date is not an instant: a midnight timestamp
/// reads as the day before on a phone further west.
String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

final RegExp _dateKeyPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// The local date a [dateKey] names, or null when it does not name one.
DateTime? parseDateKey(String? key) {
  final match = _dateKeyPattern.firstMatch(key ?? '');
  if (match == null) return null;
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  final date = DateTime(year, month, day);
  // DateTime rolls 2025-02-31 over to March instead of refusing it.
  return date.month == month && date.day == day ? date : null;
}

/// Adds whole months, clamping to the last day of the target month.
///
/// Plain `DateTime(y, m + n, d)` overflows instead: 31 January plus one
/// month becomes 3 March, which skips February altogether and is not
/// even monotonic.
DateTime addMonthsClamped(DateTime start, int months) {
  final total = start.month - 1 + months;
  final year = start.year + total ~/ 12;
  final month = total % 12 + 1;
  // Day zero of the next month is the last day of this one.
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, start.day < lastDay ? start.day : lastDay);
}

/// The last day the warranty covers, inclusive.
DateTime warrantyEndOf(DateTime purchase, int amount, WarrantyUnit unit) =>
    addMonthsClamped(
      purchase,
      unit == WarrantyUnit.years ? amount * 12 : amount,
    );

/// Whole days between two calendar dates.
///
/// Counted in UTC because a local day is 23 or 25 hours long around the
/// daylight saving switch, which makes `difference().inDays` lose a day.
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// 0.0 on the purchase date, 1.0 once the warranty is over.
///
/// Always a finite value within [0, 1]: a progress bar asserts on
/// anything else, and a malformed document must not crash the list.
double warrantyProgress(DateTime start, DateTime end, DateTime now) {
  final total = daysBetween(start, end);
  if (total <= 0) return 1;
  return (daysBetween(start, now) / total).clamp(0, 1).toDouble();
}

WarrantyStatus warrantyStatusOf(int daysLeft) {
  if (daysLeft < 0) return WarrantyStatus.expired;
  return daysLeft <= kWarrantyWarnDays
      ? WarrantyStatus.expiringSoon
      : WarrantyStatus.active;
}

/// Months go past 12 so that 18 months can be entered as such. The upper
/// limits match `firestore.rules`, and keep the end date a four-digit year.
bool isValidWarrantyAmount(int? amount, WarrantyUnit unit) {
  if (amount == null || amount < 1) return false;
  return amount <=
      (unit == WarrantyUnit.years ? kMaxWarrantyYears : kMaxWarrantyMonths);
}
