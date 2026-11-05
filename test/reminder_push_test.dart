import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_manager/models/reminder_push.dart';

void main() {
  test('reads a reminder from the data of a push', () {
    final push = ReminderPush.fromData({
      'type': 'warranty',
      'warrantyId': 'w1',
      'name': 'Frižider',
      'daysLeft': '10',
    })!;
    expect(push.warrantyId, 'w1');
    expect(push.name, 'Frižider');
    expect(push.daysLeft, 10);
  });

  test('ignores a push of another kind', () {
    expect(
      ReminderPush.fromData({'type': 'release', 'warrantyId': 'w1'}),
      isNull,
    );
  });

  test('ignores a reminder that does not say which warranty', () {
    expect(ReminderPush.fromData({'type': 'warranty'}), isNull);
    expect(
      ReminderPush.fromData({'type': 'warranty', 'warrantyId': ''}),
      isNull,
    );
  });

  test('survives a garbled day count', () {
    final push = ReminderPush.fromData({
      'type': 'warranty',
      'warrantyId': 'w1',
      'daysLeft': 'soon',
    })!;
    expect(push.daysLeft, 0);
    expect(push.name, '');
  });
}
