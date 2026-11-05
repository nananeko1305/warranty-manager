import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_manager/models/warranty.dart';
import 'package:warranty_manager/models/warranty_dates.dart';
import 'package:warranty_manager/theme/app_colors.dart';
import 'package:warranty_manager/widgets/warranty_bar.dart';

import 'support.dart';

final _warranty = Warranty(
  id: 'w1',
  ownerId: 'u1',
  name: 'Frižider',
  purchaseDate: DateTime(2024, 6, 15),
  warrantyAmount: 2,
  warrantyUnit: WarrantyUnit.years,
);

Future<void> _pump(WidgetTester tester, DateTime now, {String? locale}) =>
    tester.pumpWidget(
      app(
        WarrantyBar(warranty: _warranty, now: now),
        locale: locale ?? 'en',
      ),
    );

Color? _labelColor(WidgetTester tester) =>
    tester.widget<Text>(find.byType(Text)).style?.color;

void main() {
  testWidgets('a warranty in force says until when', (tester) async {
    await _pump(tester, DateTime(2025, 6, 15));
    expect(find.text('Warranty until Jun 15, 2026'), findsOneWidget);
  });

  testWidgets('counts the days once it is about to end', (tester) async {
    await _pump(tester, DateTime(2026, 6, 5));
    expect(find.text('10 days left'), findsOneWidget);
    expect(_labelColor(tester), AppColors.light.warning);
  });

  testWidgets('uses the singular for the last day but one', (tester) async {
    await _pump(tester, DateTime(2026, 6, 14));
    expect(find.text('1 day left'), findsOneWidget);
  });

  testWidgets('says so on the last day', (tester) async {
    await _pump(tester, DateTime(2026, 6, 15));
    expect(find.text('Warranty ends today'), findsOneWidget);
  });

  testWidgets('says when it ended afterwards', (tester) async {
    await _pump(tester, DateTime(2026, 6, 16));
    expect(find.text('Warranty ended Jun 15, 2026'), findsOneWidget);
    expect(_labelColor(tester), AppColors.light.danger);
  });

  testWidgets('follows Serbian plurals', (tester) async {
    for (final (now, label) in [
      (DateTime(2026, 6, 14), 'Još 1 dan'),
      (DateTime(2026, 6, 13), 'Još 2 dana'),
      (DateTime(2026, 6, 5), 'Još 10 dana'),
      // 21 takes the singular in Serbian.
      (DateTime(2026, 5, 25), 'Još 21 dan'),
    ]) {
      await _pump(tester, now, locale: 'sr');
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  // Regression: plain `sr` means Cyrillic to the date formats, which put
  // "15. јун 2026." in the middle of a Latin interface.
  testWidgets('dates in Serbian are in Latin script', (tester) async {
    await _pump(tester, DateTime(2025, 6, 15), locale: 'sr');
    expect(find.text('Garancija do 15. jun 2026.'), findsOneWidget);
    await _pump(tester, DateTime(2026, 6, 16), locale: 'sr');
    expect(find.text('Garancija istekla 15. jun 2026.'), findsOneWidget);
  });
}
