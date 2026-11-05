import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/error_text.dart';
import 'sync_status.dart';

/// Runs a Firestore write without blocking the UI.
///
/// Firestore applies the write to its local cache immediately, but the
/// returned future only completes once the server confirms it — which
/// never happens while offline. So screens close right away, the sync
/// banner shows progress, and a failure (e.g. permission denied) still
/// surfaces as a snackbar.
void saveInBackground(BuildContext context, Future<void> Function() write) {
  final messenger = ScaffoldMessenger.of(context);
  final t = AppLocalizations.of(context);
  syncController.track(write).catchError((Object e) {
    messenger.showSnackBar(SnackBar(content: Text(errorText(t, e))));
  });
}
