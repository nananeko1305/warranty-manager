import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_manager/services/reminder_health.dart';
import 'package:warranty_manager/widgets/reminder_banner.dart';

import 'support.dart';

void main() {
  testWidgets('notifications off cannot be dismissed', (tester) async {
    var fixed = false;
    await tester.pumpWidget(
      app(
        ReminderNotice(
          issue: ReminderIssue.notificationsOff,
          onFix: () => fixed = true,
        ),
      ),
    );
    expect(find.text('Notifications are off'), findsOneWidget);
    expect(find.text('Not now'), findsNothing);
    await tester.tap(find.text('Turn on'));
    expect(fixed, isTrue);
  });

  testWidgets('hibernation can be dismissed', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      app(
        ReminderNotice(
          issue: ReminderIssue.mayHibernate,
          onFix: () {},
          onDismiss: () => dismissed = true,
        ),
      ),
    );
    expect(find.text('Keep reminders coming'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    expect(dismissed, isTrue);
  });
}
