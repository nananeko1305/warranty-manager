import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_manager/models/warranty.dart';
import 'package:warranty_manager/models/warranty_dates.dart';
import 'package:warranty_manager/money/money.dart';

Warranty _warranty({
  DateTime? purchaseDate,
  int amount = 2,
  WarrantyUnit unit = WarrantyUnit.years,
}) => Warranty(
  id: 'w1',
  ownerId: 'u1',
  name: 'Frižider',
  store: 'Tehnomanija',
  purchaseDate: purchaseDate ?? DateTime(2025, 1, 31),
  warrantyAmount: amount,
  warrantyUnit: unit,
  amountMinor: 8999000,
  currency: Currency.rsd,
);

void main() {
  group('Warranty', () {
    test('ends on the same date, clamped to the month', () {
      final w = _warranty(amount: 1, unit: WarrantyUnit.months);
      expect(w.warrantyEnd, DateTime(2025, 2, 28));
    });

    test('counts the last day as still covered', () {
      final w = _warranty();
      final lastDay = DateTime(2027, 1, 31);
      expect(w.daysLeft(lastDay), 0);
      expect(w.status(lastDay), WarrantyStatus.expiringSoon);
      expect(w.status(DateTime(2027, 2, 1)), WarrantyStatus.expired);
    });
  });

  group('toMap', () {
    test('stores dates as text, which the worker queries', () {
      final map = _warranty().toMap();
      expect(map['purchaseDate'], '2025-01-31');
      expect(map['endsOn'], '2027-01-31');
    });

    test('keeps endsOn in step with the duration', () {
      final map = _warranty(amount: 18, unit: WarrantyUnit.months).toMap();
      expect(map['endsOn'], '2026-07-31');
    });

    test('never writes the fields the rules keep for the worker', () {
      // The rules refuse a client write to remindersSent, so every save would
      // fail.
      expect(_warranty().toMap().containsKey('remindersSent'), isFalse);
    });

    test('stamps the time of the change on the server', () {
      expect(_warranty().toMap()['updatedAt'], isA<FieldValue>());
    });

    test('leaves the owner in place, so the rules can compare it', () {
      expect(_warranty().toMap()['ownerId'], 'u1');
    });
  });
}
