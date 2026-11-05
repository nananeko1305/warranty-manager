import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  await themeController.load();
  await localeController.load();
  runApp(const WarrantyManagerApp());
}

class WarrantyManagerApp extends StatelessWidget {
  const WarrantyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole app when the theme or the language changes.
    return AnimatedBuilder(
      animation: Listenable.merge([themeController, localeController]),
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.mode,
          locale: localeController.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kSupportedLocales,
          // Screens without an AppBar (login) get the right status-bar icon
          // color from here. The mode may follow the phone, so it is read
          // from the theme in force rather than from the controller.
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppTheme.overlayStyle(
              Theme.of(context).brightness == Brightness.dark,
            ),
            child: child!,
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}
