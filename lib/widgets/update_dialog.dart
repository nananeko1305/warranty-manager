import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/update_checker.dart';

/// "New version available" with Download (opens the APK link in the
/// browser, which downloads it) and Later.
Future<void> showUpdateDialog(BuildContext context, UpdateAvailable update) {
  final t = AppLocalizations.of(context);
  final r = update.release;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.system_update_rounded, size: 36),
      title: Text(t.newVersionTitle),
      content: Text(t.newVersionBody(r.version, update.currentVersion)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.later)),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () {
            Navigator.pop(ctx);
            launchUrl(
              Uri.parse(r.downloadUrl),
              mode: LaunchMode.externalApplication,
            );
          },
          child: Text(t.download),
        ),
      ],
    ),
  );
}
