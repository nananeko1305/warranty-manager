import 'package:warranty_manager/models/warranty_dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('addMonthsClamped', () {
    final cases = {
      // The headline case: naive month arithmetic gives 3 March.
      (DateTime(2025, 1, 31), 1): DateTime(2025, 2, 28),
      (DateTime(2024, 1, 31), 1): DateTime(2024, 2, 29),
      (DateTime(2024, 2, 29), 12): DateTime(2025, 2, 28),
      (DateTime(2025, 3, 31), 1): DateTime(2025, 4, 30),
      (DateTime(2025, 8, 31), 6): DateTime(2026, 2, 28),
      (DateTime(2025, 1, 15), 1): DateTime(2025, 2, 15),
      (DateTime(2025, 12, 15), 1): DateTime(2026, 1, 15),
      (DateTime(2025, 10, 31), 12): DateTime(2026, 10, 31),
    };

    cases.forEach((input, expected) {
      final (start, months) = input;
      test('$start + $months months -> $expected', () {
        expect(addMonthsClamped(start, months), expected);
      });
    });

    test('adding more months never moves the date backwards', () {
      for (
        var day = DateTime(2024, 1, 1);
        day.isBefore(DateTime(2026, 1, 1));
        day = day.add(const Duration(days: 1))
      ) {
        for (var n = 1; n <= 24; n++) {
          final earlier = addMonthsClamped(day, n - 1);
          final later = addMonthsClamped(day, n);
          expect(
            later.isBefore(earlier),
            isFalse,
            reason: '$day: $n months landed before ${n - 1}',
          );
        }
      }
    });

    test('the time of day is dropped', () {
      final end = addMonthsClamped(DateTime(2025, 5, 4, 23, 47), 3);
      expect(end, DateTime(2025, 8, 4));
    });
  });

  group('warrantyEndOf', () {
    test('two years and twenty-four months are the same warranty', () {
      final purchase = DateTime(2025, 6, 10);
      expect(
        warrantyEndOf(purchase, 2, WarrantyUnit.years),
        warrantyEndOf(purchase, 24, WarrantyUnit.months),
      );
    });

    test('twelve months equal one year', () {
      final purchase = DateTime(2025, 6, 10);
      expect(
        warrantyEndOf(purchase, 12, WarrantyUnit.months),
        warrantyEndOf(purchase, 1, WarrantyUnit.years),
      );
    });

    test('clamping survives the unit conversion', () {
      expect(
        warrantyEndOf(DateTime(2025, 1, 31), 1, WarrantyUnit.months),
        DateTime(2025, 2, 28),
      );
    });
  });

  group('daysBetween', () {
    test('the same day is zero days', () {
      expect(daysBetween(DateTime(2025, 9, 25), DateTime(2025, 9, 25)), 0);
    });

    test('swapping the arguments negates the count', () {
      final a = DateTime(2025, 1, 1);
      final b = DateTime(2025, 3, 15);
      expect(daysBetween(b, a), -daysBetween(a, b));
    });

    // Regression: difference().inDays counts a 23-hour spring-forward day
    // as no day at all, so every "days left" was short by one for half of
    // the year. Only reproducible in a DST timezone; CI runs on UTC.
    test('daylight saving does not swallow a day', () {
      expect(daysBetween(DateTime(2025, 3, 29), DateTime(2025, 3, 31)), 2);
      expect(daysBetween(DateTime(2025, 10, 25), DateTime(2025, 10, 27)), 2);
    });

    test('the leap day is counted', () {
      expect(daysBetween(DateTime(2024, 2, 28), DateTime(2024, 3, 1)), 2);
    });

    test('a common year is 365 days', () {
      expect(daysBetween(DateTime(2025, 1, 1), DateTime(2026, 1, 1)), 365);
    });
  });

  group('warrantyProgress', () {
    final start = DateTime(2025, 1, 1);
    final end = DateTime(2025, 7, 1);

    test('starts at zero and ends at one', () {
      expect(warrantyProgress(start, end, start), 0);
      expect(warrantyProgress(start, end, end), 1);
    });

    test('halfway through is about half', () {
      expect(
        warrantyProgress(start, end, DateTime(2025, 4, 1)),
        closeTo(0.497, 0.01),
      );
    });

    test('stays within bounds outside the warranty', () {
      expect(warrantyProgress(start, end, DateTime(2030, 1, 1)), 1);
      expect(warrantyProgress(start, end, DateTime(2020, 1, 1)), 0);
    });

    test('a zero-length warranty is over, not a division by zero', () {
      final value = warrantyProgress(start, start, DateTime(2025, 2, 1));
      expect(value.isFinite, isTrue);
      expect(value, 1);
    });

    test('never decreases as time passes', () {
      var previous = 0.0;
      for (
        var day = start;
        day.isBefore(end);
        day = day.add(const Duration(days: 1))
      ) {
        final value = warrantyProgress(start, end, day);
        expect(value, greaterThanOrEqualTo(previous), reason: '$day');
        previous = value;
      }
    });
  });

  group('warrantyStatusOf', () {
    test('turns amber inside the reminder window and red once past', () {
      expect(warrantyStatusOf(kWarrantyWarnDays + 1), WarrantyStatus.active);
      expect(warrantyStatusOf(kWarrantyWarnDays), WarrantyStatus.expiringSoon);
      expect(warrantyStatusOf(1), WarrantyStatus.expiringSoon);
      // The last covered day still counts as under warranty.
      expect(warrantyStatusOf(0), WarrantyStatus.expiringSoon);
      expect(warrantyStatusOf(-1), WarrantyStatus.expired);
    });
  });

  group('isValidWarrantyAmount', () {
    test('months run from 1 to 120, so 18 months can be entered', () {
      for (final n in [1, 6, 12, 18, 120]) {
        expect(
          isValidWarrantyAmount(n, WarrantyUnit.months),
          isTrue,
          reason: '$n',
        );
      }
      for (final n in [-1, 0, 121]) {
        expect(
          isValidWarrantyAmount(n, WarrantyUnit.months),
          isFalse,
          reason: '$n',
        );
      }
    });

    test('years run from 1 to 30', () {
      expect(isValidWarrantyAmount(0, WarrantyUnit.years), isFalse);
      expect(isValidWarrantyAmount(1, WarrantyUnit.years), isTrue);
      expect(isValidWarrantyAmount(30, WarrantyUnit.years), isTrue);
      expect(isValidWarrantyAmount(31, WarrantyUnit.years), isFalse);
    });

    test('an unparsed number is not a warranty', () {
      expect(isValidWarrantyAmount(null, WarrantyUnit.months), isFalse);
      expect(isValidWarrantyAmount(null, WarrantyUnit.years), isFalse);
    });
  });

  group('dateKey', () {
    test('pads every part, as the rules and the worker expect', () {
      expect(dateKey(DateTime(2026, 3, 5)), '2026-03-05');
    });

    test('ignores the time of day', () {
      expect(dateKey(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
    });

    test('survives the way back', () {
      final day = DateTime(2024, 2, 29);
      expect(parseDateKey(dateKey(day)), day);
    });

    test('sorts as text the same way the dates sort', () {
      final keys = [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 1),
        DateTime(2027, 1, 1),
      ].map(dateKey).toList();
      expect([...keys]..sort(), keys);
    });
  });

  group('parseDateKey', () {
    test('refuses what is not a date', () {
      for (final key in [null, '', 'yesterday', '2026-3-5', '2026-13-01']) {
        expect(parseDateKey(key), isNull, reason: '$key');
      }
    });

    test('refuses a day the month does not have', () {
      expect(parseDateKey('2025-02-31'), isNull);
      expect(parseDateKey('2025-02-29'), isNull);
    });
  });
}
