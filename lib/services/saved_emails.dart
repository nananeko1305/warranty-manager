import 'package:shared_preferences/shared_preferences.dart';

/// Emails that signed in successfully on this device, newest first.
/// Only used to suggest them on the login screen; never synced.
class SavedEmails {
  SavedEmails._();
  static final SavedEmails instance = SavedEmails._();

  static const _key = 'saved_emails';
  static const _max = 5;

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const [];
  }

  Future<List<String>> add(String email) async {
    final e = email.trim().toLowerCase();
    final list = [
      e,
      ...(await load()).where((x) => x != e),
    ].take(_max).toList();
    await _store(list);
    return list;
  }

  Future<List<String>> remove(String email) async {
    final list = (await load()).where((x) => x != email).toList();
    await _store(list);
    return list;
  }

  Future<void> _store(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, list);
  }
}
