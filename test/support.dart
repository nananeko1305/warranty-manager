import 'package:flutter/material.dart';
import 'package:warranty_manager/l10n/app_localizations.dart';
import 'package:warranty_manager/theme/app_theme.dart';

/// [child] in the app's theme and localizations.
Widget app(Widget child, {bool dark = false, String locale = 'en'}) =>
    MaterialApp(
      theme: AppTheme.build(dark: dark),
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
