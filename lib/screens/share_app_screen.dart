import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../services/update_checker.dart';

/// Hands the app to someone else: a QR code to scan, or the link to copy or send.
class ShareAppScreen extends StatelessWidget {
  const ShareAppScreen({super.key});

  Future<void> _copy(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(const ClipboardData(text: kAppDownloadUrl));
    messenger.showSnackBar(SnackBar(content: Text(t.linkCopied)));
  }

  Future<void> _send(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SharePlus.instance.share(
      ShareParams(
        text: '${t.shareAppMessage}\n$kAppDownloadUrl',
        title: t.appTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.shareApp)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            // Dark on white in both themes: scanners read an inverted code badly.
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: kAppDownloadUrl,
                  size: 240,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                  semanticsLabel: t.shareApp,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(t.shareAppHint, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          const SelectableText(
            kAppDownloadUrl,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _copy(context),
            icon: const Icon(Icons.copy_rounded),
            label: Text(t.copyLink),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _send(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.share_rounded),
            label: Text(t.sendLink),
          ),
        ],
      ),
    );
  }
}
