import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_manager/models/warranty.dart';
import 'package:warranty_manager/models/warranty_dates.dart';
import 'package:warranty_manager/money/money.dart';
import 'package:warranty_manager/widgets/warranty_card.dart';

import 'support.dart';

Warranty _w({bool notify = true, String store = ''}) => Warranty(
  id: 'w1',
  ownerId: 'u1',
  name: 'Frižider',
  store: store,
  purchaseDate: DateTime(2026, 1, 10),
  warrantyAmount: 2,
  warrantyUnit: WarrantyUnit.years,
  amountMinor: 150000,
  currency: Currency.rsd,
  notify: notify,
);

Future<void> _pump(WidgetTester tester, Warranty warranty) => tester.pumpWidget(
  app(
    WarrantyCard(warranty: warranty, now: DateTime(2026, 6, 15), onTap: () {}),
  ),
);

void main() {
  testWidgets('shows the store, the date and the price', (tester) async {
    await _pump(tester, _w(store: 'Tehnomanija'));
    expect(find.textContaining('Tehnomanija'), findsOneWidget);
    expect(find.textContaining('Jan 10, 2026'), findsOneWidget);
    expect(find.textContaining('1,500.00 RSD'), findsOneWidget);
  });

  testWidgets('leaves out a store it does not have', (tester) async {
    await _pump(tester, _w());
    expect(find.textContaining('· Jan'), findsNothing);
  });

  testWidgets('marks only a warranty without reminders', (tester) async {
    await _pump(tester, _w());
    expect(find.byIcon(Icons.notifications_off_rounded), findsNothing);
    await _pump(tester, _w(notify: false));
    expect(find.byIcon(Icons.notifications_off_rounded), findsOneWidget);
  });

  // The locale is sr-Latn, which goes through the number and date formats too.
  // Neither may throw on it: that would break the app on every Serbian phone.
  testWidgets('a Serbian phone gets Latin dates and local numbers', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        WarrantyCard(
          warranty: _w(store: 'Tehnomanija'),
          now: DateTime(2026, 6, 15),
          onTap: () {},
        ),
        locale: 'sr',
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('10. jan 2026.'), findsOneWidget);
    expect(find.textContaining('1.500,00 RSD'), findsOneWidget);
  });
}
