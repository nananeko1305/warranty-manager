import 'package:warranty_manager/l10n/app_localizations.dart';
import 'package:warranty_manager/screens/receipt_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression: the zoom area shrank to the size of the picture and clipped
  // to it, so a long, narrow receipt stayed a narrow strip when zoomed.
  testWidgets('the zoom area fills the screen, whatever the picture', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ReceiptScreen(
          url: 'https://res.cloudinary.com/demo/image/upload/v1/receipt.jpg',
          title: 'Receipt',
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(InteractiveViewer)),
      const Size(800, 600 - kToolbarHeight),
    );
  });
}
