import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_manager/widgets/receipt_field.dart';

import 'support.dart';

const _url = 'https://res.cloudinary.com/x/image/upload/v1/abc.jpg';

Future<void> _pump(
  WidgetTester tester, {
  required String url,
  bool configured = true,
  ValueChanged<String>? onChanged,
}) => tester.pumpWidget(
  app(
    ReceiptField(
      url: url,
      configured: configured,
      onChanged: onChanged ?? (_) {},
    ),
  ),
);

void main() {
  testWidgets('a build without upload settings hides the field', (
    tester,
  ) async {
    await _pump(tester, url: '', configured: false);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('without a photo it invites one', (tester) async {
    await _pump(tester, url: '');
    expect(find.text('Add a photo of the receipt'), findsOneWidget);
  });

  testWidgets('without a photo, a tap offers the camera and the gallery', (
    tester,
  ) async {
    await _pump(tester, url: '');
    await tester.tap(find.text('Add a photo of the receipt'));
    await tester.pumpAndSettle();
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Pick from the gallery'), findsOneWidget);
  });

  testWidgets('with a photo it offers to replace or remove it', (tester) async {
    await _pump(tester, url: _url);
    expect(find.text('Add a photo of the receipt'), findsNothing);
    expect(find.byTooltip('Change the photo'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsOneWidget);
  });

  testWidgets('removing the photo clears the link', (tester) async {
    String? changed;
    await _pump(tester, url: _url, onChanged: (url) => changed = url);
    await tester.tap(find.byTooltip('Delete'));
    expect(changed, '');
  });
}
