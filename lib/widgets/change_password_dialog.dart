import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/error_text.dart';
import '../services/auth_service.dart';

/// Current password + new password twice. Needs the network.
Future<void> showChangePasswordDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _ChangePasswordDialog(),
  );
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.changePassword(_current.text, _next.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(t.passwordChanged)));
    } catch (e) {
      if (mounted) setState(() => _error = errorText(t, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    TextEditingController c,
    String label,
    String? Function(String?) v,
  ) {
    return TextFormField(
      controller: c,
      obscureText: true,
      decoration: InputDecoration(labelText: label),
      validator: v,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(t.changePassword),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(
              _current,
              t.currentPassword,
              (v) => (v == null || v.isEmpty) ? t.required : null,
            ),
            const SizedBox(height: 12),
            _field(
              _next,
              t.newPassword,
              (v) => (v == null || v.length < 6) ? t.minChars6 : null,
            ),
            const SizedBox(height: 12),
            _field(
              _confirm,
              t.confirmPassword,
              (v) => v != _next.text ? t.passwordsNoMatch : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        TextButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? t.wait : t.save),
        ),
      ],
    );
  }
}
