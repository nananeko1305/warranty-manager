import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/reminder_health.dart';
import '../theme/app_colors.dart';

/// Warns about what would keep reminders from arriving. A reminder that never
/// shows up looks exactly like no reminder being due, so without this nobody
/// finds out until a warranty has lapsed.
class ReminderBanner extends StatefulWidget {
  const ReminderBanner({super.key});

  @override
  State<ReminderBanner> createState() => _ReminderBannerState();
}

class _ReminderBannerState extends State<ReminderBanner>
    with WidgetsBindingObserver {
  ReminderIssue? _issue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Coming back from the permission prompt or the settings screen may have
  /// fixed the issue.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final issue = await ReminderHealth.instance.check();
    if (mounted) setState(() => _issue = issue);
  }

  Future<void> _dismiss() async {
    setState(() => _issue = null);
    await ReminderHealth.instance.dismissHibernationNotice();
  }

  @override
  Widget build(BuildContext context) {
    final issue = _issue;
    if (issue == null) return const SizedBox.shrink();
    return ReminderNotice(
      issue: issue,
      onFix: () => ReminderHealth.instance.fix(issue),
      onDismiss: issue == ReminderIssue.mayHibernate ? _dismiss : null,
    );
  }
}

/// The notice itself, apart from where the issue comes from.
class ReminderNotice extends StatelessWidget {
  const ReminderNotice({
    super.key,
    required this.issue,
    required this.onFix,
    this.onDismiss,
  });

  final ReminderIssue issue;
  final VoidCallback onFix;

  /// Null when the notice cannot be dismissed.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = context.colors;
    final off = issue == ReminderIssue.notificationsOff;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    off
                        ? Icons.notifications_off_rounded
                        : Icons.bedtime_rounded,
                    color: colors.warning,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          off ? t.notificationsOffTitle : t.hibernationTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          off ? t.notificationsOffBody : t.hibernationBody,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onDismiss != null)
                    TextButton(onPressed: onDismiss, child: Text(t.notNow)),
                  TextButton(
                    onPressed: onFix,
                    child: Text(off ? t.turnOn : t.openSettings),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
