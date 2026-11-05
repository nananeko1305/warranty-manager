import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:warranty_manager/screens/share_app_screen.dart';
import 'package:warranty_manager/services/update_checker.dart';

import 'support.dart';

/// [ShareAppScreen] brings its own Scaffold, so it goes in as the whole body.
Future<void> _pump(WidgetTester tester, {bool dark = false}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app(const ShareAppScreen(), dark: dark));
}

void main() {
  testWidgets('the code holds the download link', (tester) async {
    await _pump(tester);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text(kAppDownloadUrl), findsOneWidget);
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr.backgroundColor, Colors.white);
  });

  testWidgets('the code stays dark on white in the dark theme', (tester) async {
    await _pump(tester, dark: true);
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr.backgroundColor, Colors.white);
    expect(qr.dataModuleStyle.color, Colors.black);
    expect(qr.eyeStyle.color, Colors.black);
  });

  testWidgets('copying puts the link on the clipboard, and says so', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    await _pump(tester);
    await tester.tap(find.text('Copy link'));
    await tester.pump();
    expect(copied, kAppDownloadUrl);
    expect(find.text('Link copied.'), findsOneWidget);
  });

  // Renaming the APK in CI would quietly break every code already handed out.
  test('the link names the file the release publishes', () {
    final workflow = File('.github/workflows/release-apk.yml')
        .readAsStringSync();
    final name = RegExp(r'APK_NAME: (\S+)').firstMatch(workflow)!.group(1)!;
    expect(kAppDownloadUrl, endsWith('/releases/latest/download/$name'));
  });
}
