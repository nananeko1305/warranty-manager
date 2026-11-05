import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The languages of the app. Serbian names its script, because plain `sr` means
/// Cyrillic to the date formats and the date picker, which would put Cyrillic
/// months in a Latin interface.
const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'),
];

/// Holds the selected language and persists it on the device.
/// null = follow the phone language; otherwise picked manually (en or sr).
class LocaleController extends ChangeNotifier {
  static const _key = 'locale_code';

  Locale? _locale;
  Locale? get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) _locale = Locale(code);
    notifyListeners();
  }

  Future<void> select(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
  }
}

final LocaleController localeController = LocaleController();
