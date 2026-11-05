import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_manager/models/warranty.dart';
import 'package:warranty_manager/models/warranty_dates.dart';
import 'package:warranty_manager/widgets/warranty_card.dart';
import 'package:warranty_manager/widgets/warranty_list_view.dart';

import 'support.dart';

final _now = DateTime(2026, 6, 15);

Warranty _w(String name, DateTime bought, {String store = ''}) => Warranty(
  id: name,
  ownerId: 'u1',
  name: name,
  store: store,
  purchaseDate: bought,
  warrantyAmount: 1,
  warrantyUnit: WarrantyUnit.years,
);

Future<void> _pump(
  WidgetTester tester,
  List<Warranty>? warranties, {
  Object? error,
  ValueChanged<Warranty>? onOpen,
}) => tester.pumpWidget(
  app(
    WarrantyListView(
      warranties: warranties,
      error: error,
      now: _now,
      onOpen: onOpen ?? (_) {},
    ),
  ),
);

void main() {
  testWidgets('spins while nothing has arrived', (tester) async {
    await _pump(tester, null);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // Regression from car_expenses: a failing listener left the list null
  // forever, so the screen spun instead of saying what was wrong.
  testWidgets('says what went wrong instead of spinning', (tester) async {
    await _pump(
      tester,
      null,
      error: FirebaseException(plugin: 'x', code: 'permission-denied'),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.text("You don't have permission for this action."),
      findsOneWidget,
    );
  });

  testWidgets('guides a new account to its first warranty', (tester) async {
    await _pump(tester, const []);
    expect(find.text('No warranties yet'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('files warranties by their dates, with counts', (tester) async {
    await _pump(tester, [
      _w('valid', DateTime(2026, 1, 1)),
      _w('old', DateTime(2020, 1, 1)),
    ]);
    expect(find.text('Valid (1)'), findsOneWidget);
    expect(find.text('Expired (1)'), findsOneWidget);
    expect(find.text('valid'), findsOneWidget);
    expect(find.text('old'), findsNothing);

    await tester.tap(find.text('Expired (1)'));
    await tester.pump();
    expect(find.text('old'), findsOneWidget);
    expect(find.text('valid'), findsNothing);
  });

  testWidgets('search narrows the list and updates the counts', (tester) async {
    await _pump(tester, [
      _w('Frižider', DateTime(2026, 1, 1), store: 'Tehnomanija'),
      _w('Televizor', DateTime(2026, 1, 1), store: 'Gigatron'),
    ]);
    await tester.enterText(find.byType(TextField), 'frizider');
    await tester.pump();
    expect(find.text('Valid (1)'), findsOneWidget);
    expect(find.byType(WarrantyCard), findsOneWidget);
    expect(find.text('Frižider'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nema toga');
    await tester.pump();
    expect(find.text('Nothing found.'), findsOneWidget);
  });

  testWidgets('tapping a card opens that warranty', (tester) async {
    Warranty? opened;
    final warranty = _w('Frižider', DateTime(2026, 1, 1));
    await _pump(tester, [warranty], onOpen: (w) => opened = w);
    await tester.tap(find.text('Frižider'));
    expect(opened, warranty);
  });
}
