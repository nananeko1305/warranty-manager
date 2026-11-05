import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/error_text.dart';
import '../services/account_deletion.dart';
import '../theme/app_colors.dart';

/// Asks for the password, then deletes the account. Stays open until the
/// answer is in, because this one cannot be finished later.
Future<void> showDeleteAccountDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _DeleteAccountDialog(),
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty) return;
    final t = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AccountDeletion.instance.delete(_password.text);
      // Signed out now, and the login screen is under everything else.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = errorText(t, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final danger = context.colors.danger;
    return AlertDialog(
      title: Text(t.deleteAccount),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.deleteAccountBody),
          const SizedBox(height: 14),
          TextField(
            controller: _password,
            enabled: !_busy,
            obscureText: true,
            decoration: InputDecoration(labelText: t.password),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: danger)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        TextButton(
          onPressed: _busy ? null : _submit,
          style: TextButton.styleFrom(foregroundColor: danger),
          child: Text(_busy ? t.wait : t.delete),
        ),
      ],
    );
  }
}
