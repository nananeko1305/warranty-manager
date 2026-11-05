import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Asks "Delete …?" and resolves to true only on an explicit yes.
Future<bool> confirmDelete(
  BuildContext context,
  String question, {
  String? body,
}) async {
  final t = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(question),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(t.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(t.delete),
        ),
      ],
    ),
  );
  return ok == true;
}
