import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_manager/models/warranty.dart';
import 'package:warranty_manager/models/warranty_dates.dart';
import 'package:warranty_manager/money/money.dart';
import 'package:warranty_manager/screens/warranty_form_screen.dart';

import 'support.dart';

Warranty _w({String store = '', int? price}) => Warranty(
  id: 'w1',
  ownerId: 'u1',
  name: 'Frižider',
  store: store,
  purchaseDate: DateTime(2026, 1, 10),
  warrantyAmount: 2,
  warrantyUnit: WarrantyUnit.years,
  amountMinor: price,
  currency: price == null ? null : Currency.rsd,
);

Future<void> _pump(WidgetTester tester, {Warranty? warranty}) async {
  // A phone, so that "fits on one screen" means something.
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    app(WarrantyFormScreen(ownerId: 'u1', warranty: warranty)),
  );
}

void main() {
  testWidgets('the save button fits on the first screen of a new warranty', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Save').hitTestable(), findsOneWidget);
  });

  testWidgets('a new warranty starts with the details closed', (tester) async {
    await _pump(tester);
    expect(find.text('Store (optional)'), findsNothing);
    await tester.tap(find.text('Store, price and note'));
    await tester.pump();
    expect(find.text('Store (optional)'), findsOneWidget);
  });

  testWidgets('an existing warranty shows the details it has', (tester) async {
    await _pump(tester, warranty: _w(store: 'Tehnomanija'));
    expect(find.text('Tehnomanija'), findsOneWidget);
    expect(find.text('Store (optional)'), findsOneWidget);
  });

  testWidgets('one without any details keeps them closed', (tester) async {
    await _pump(tester, warranty: _w());
    expect(find.text('Store (optional)'), findsNothing);
  });

  testWidgets('a missing name stops the save and says so', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
    expect(find.byType(WarrantyFormScreen), findsOneWidget);
  });

  // A bad price typed before closing the details would otherwise block the save
  // with nothing on screen to explain why.
  testWidgets('a bad price behind closed details opens them', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Store, price and note'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(3), 'abc');
    await tester.enterText(find.byType(TextFormField).at(0), 'Frižider');
    await tester.tap(find.text('Store, price and note'));
    await tester.pump();
    expect(find.text('Price (optional)'), findsNothing);

    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Price (optional)'), findsOneWidget);
    expect(find.text('Enter an amount greater than 0'), findsOneWidget);
  });

  testWidgets('18 months can be entered, and 121 cannot', (tester) async {
    await _pump(tester, warranty: _w());
    await tester.tap(find.text('Months'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(1), '18');
    await tester.pump();
    expect(find.text('Warranty until Jul 10, 2027'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), '121');
    await tester.pump();
    expect(find.text('1 to 120 months'), findsWidgets);
  });
}
