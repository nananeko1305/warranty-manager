import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/error_text.dart';
import '../services/auth_service.dart';
import '../services/saved_emails.dart';
import '../theme/app_colors.dart';
import '../widgets/email_autocomplete_field.dart';

/// Email + password, both to sign in and to open a new account. One screen for
/// both, so signing up leaves nothing on the navigator to clean up: the auth
/// state decides what comes next.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  List<String> _savedEmails = const [];
  bool _busy = false;
  bool _obscure = true;
  bool _registering = false;

  @override
  void initState() {
    super.initState();
    SavedEmails.instance.load().then((list) {
      if (mounted) setState(() => _savedEmails = list);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _removeSaved(String email) async {
    final list = await SavedEmails.instance.remove(email);
    if (!mounted) return;
    setState(() => _savedEmails = list);
    // Nudge the text so the suggestion list rebuilds without the removed one.
    final v = _email.value;
    _email.value = v.copyWith(text: '${v.text} ');
    _email.value = v;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final t = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      if (_registering) {
        await AuthService.instance.register(_email.text, _password.text);
      } else {
        await AuthService.instance.signIn(_email.text, _password.text);
      }
      await SavedEmails.instance.add(_email.text);
    } catch (e) {
      _show(errorText(t, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final t = AppLocalizations.of(context);
    if (!_email.text.contains('@')) {
      _show(t.invalidEmail);
      return;
    }
    try {
      await AuthService.instance.sendPasswordReset(_email.text);
      _show(t.resetSent);
    } catch (e) {
      _show(errorText(t, e));
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: context.colors.softGradient,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/icon/logo.png',
                        width: 112,
                        height: 112,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t.appTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(t.appTagline, textAlign: TextAlign.center),
                    const SizedBox(height: 36),
                    EmailAutocompleteField(
                      controller: _email,
                      focusNode: _emailFocus,
                      suggestions: _savedEmails,
                      onSelected: (_) => _passwordFocus.requestFocus(),
                      onRemove: _removeSaved,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      focusNode: _passwordFocus,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: t.password,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6) ? t.minChars6 : null,
                    ),
                    if (_registering) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirm,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: t.confirmAccountPassword,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                        ),
                        validator: (v) =>
                            v != _password.text ? t.passwordsNoMatch : null,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Text(
                        _busy
                            ? t.wait
                            : (_registering ? t.createAccount : t.signIn),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _registering = !_registering),
                      child: Text(
                        _registering ? t.haveAccount : t.noAccountYet,
                      ),
                    ),
                    if (!_registering)
                      TextButton(
                        onPressed: _busy ? null : _resetPassword,
                        child: Text(t.forgotPassword),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
