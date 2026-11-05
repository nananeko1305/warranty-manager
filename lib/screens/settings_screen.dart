import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/delete_account_dialog.dart';
import '../widgets/update_tiles.dart';
import 'share_app_screen.dart';

/// Language and appearance, stored on the device, plus the account.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final email = AuthService.instance.currentUser?.email ?? '';
    return AnimatedBuilder(
      animation: Listenable.merge([themeController, localeController]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(t.settings)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header(t.appearance),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(t.themeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(t.themeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(t.themeDark),
                  ),
                ],
                selected: {themeController.mode},
                showSelectedIcon: false,
                onSelectionChanged: (s) => themeController.select(s.first),
              ),
              const SizedBox(height: 20),
              _header(t.language),
              RadioGroup<String?>(
                groupValue: localeController.locale?.languageCode,
                onChanged: (c) =>
                    localeController.select(c == null ? null : Locale(c)),
                child: Column(
                  children: [
                    RadioListTile<String?>(
                      value: null,
                      title: Text(t.systemLanguage),
                    ),
                    const RadioListTile<String?>(
                      value: 'en',
                      title: Text('English'),
                    ),
                    const RadioListTile<String?>(
                      value: 'sr',
                      title: Text('Srpski'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _header(t.account),
              ListTile(
                leading: const Icon(Icons.alternate_email_rounded),
                title: Text(email),
              ),
              ListTile(
                leading: const Icon(Icons.lock_reset_rounded),
                title: Text(t.changePassword),
                onTap: () => showChangePasswordDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: Text(t.signOut),
                onTap: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  AuthService.instance.signOut();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.person_remove_rounded,
                  color: context.colors.danger,
                ),
                title: Text(
                  t.deleteAccount,
                  style: TextStyle(color: context.colors.danger),
                ),
                onTap: () => showDeleteAccountDialog(context),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.qr_code_2_rounded),
                title: Text(t.shareApp),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ShareAppScreen()),
                ),
              ),
              const UpdateTiles(),
            ],
          ),
        );
      },
    );
  }

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
  );
}
