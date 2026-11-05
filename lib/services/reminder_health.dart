import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What can keep a reminder from showing up, without anyone noticing: FCM
/// reports the push as delivered in both cases.
enum ReminderIssue {
  /// The user denied the notification permission, or switched it off.
  notificationsOff,

  /// Android may hibernate the app if it is not opened for months, which stops
  /// pushes and resets the permission. A warranty app is opened rarely, so this
  /// is the normal case for it.
  mayHibernate,
}

/// Looks for a [ReminderIssue] and opens the system screen that fixes it. The
/// platform side is in `MainActivity.kt`.
class ReminderHealth {
  ReminderHealth._();
  static final ReminderHealth instance = ReminderHealth._();

  static const _channel = MethodChannel('warranty_manager/reminder_health');
  static const _dismissedKey = 'hibernation_notice_dismissed';

  /// The issue that matters most right now, or null when there is none.
  Future<ReminderIssue?> check() async {
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return ReminderIssue.notificationsOff;
      }
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_dismissedKey) ?? false) return null;
      final restricted = await _channel.invokeMethod<bool>(
        'unusedRestrictionsOn',
      );
      return restricted == true ? ReminderIssue.mayHibernate : null;
    } catch (_) {
      // A notice that cannot be worked out is simply not shown.
      return null;
    }
  }

  /// Only the hibernation notice can be dismissed; with notifications off the
  /// app has no way of reminding anyone.
  Future<void> dismissHibernationNotice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
  }

  Future<void> fix(ReminderIssue issue) => _channel.invokeMethod<void>(
    issue == ReminderIssue.notificationsOff
        ? 'openNotificationSettings'
        : 'openUnusedRestrictionsSettings',
  );
}
