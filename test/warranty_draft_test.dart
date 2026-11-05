import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_manager/models/warranty.dart';
import 'package:warranty_manager/models/warranty_dates.dart';
import 'package:warranty_manager/models/warranty_draft.dart';
import 'package:warranty_manager/money/money.dart';

void main() {
  group('a new draft', () {
    test('needs only a name: today and two years are already filled in', () {
      final draft = WarrantyDraft(today: DateTime(2026, 6, 15, 18, 30));
      addTearDown(draft.dispose);
      draft.name.text = '  Frižider  ';
      final w = draft.build(ownerId: 'u1');
      expect(w.name, 'Frižider');
      expect(w.purchaseDate, DateTime(2026, 6, 15));
      expect(w.warrantyAmount, 2);
      expect(w.warrantyUnit, WarrantyUnit.years);
      expect(w.notify, isTrue);
      expect(w.id, isEmpty);
      expect(w.ownerId, 'u1');
    });

    test('has no price and no currency when no amount was typed', () {
      final draft = WarrantyDraft();
      addTearDown(draft.dispose);
      draft.name.text = 'x';
      final w = draft.build(ownerId: 'u1');
      expect(w.amountMinor, isNull);
      expect(w.currency, isNull);
    });

    test('takes the price and the currency together', () {
      final draft = WarrantyDraft();
      addTearDown(draft.dispose);
      draft
        ..name.text = 'x'
        ..amount.text = '1.500,50'
        ..currency = Currency.eur;
      final w = draft.build(ownerId: 'u1');
      expect(w.amountMinor, 150050);
      expect(w.currency, Currency.eur);
    });
  });

  test('editing keeps every field and the id', () {
    final old = Warranty(
      id: 'w1',
      ownerId: 'u1',
      name: 'Frižider',
      store: 'Tehnomanija',
      note: 'SN 1234',
      purchaseDate: DateTime(2025, 1, 31),
      warrantyAmount: 18,
      warrantyUnit: WarrantyUnit.months,
      amountMinor: 8999050,
      currency: Currency.eur,
      receiptUrl: 'https://res.cloudinary.com/x/image/upload/a.jpg',
      notify: false,
    );
    final draft = WarrantyDraft(warranty: old);
    addTearDown(draft.dispose);
    final w = draft.build(ownerId: old.ownerId);
    expect(w.toMap()..remove('updatedAt'), old.toMap()..remove('updatedAt'));
    expect(w.id, 'w1');
  });
}
