/// A warranty reminder, read from the data part of a push.
class ReminderPush {
  const ReminderPush({
    required this.warrantyId,
    required this.name,
    required this.daysLeft,
  });

  static const type = 'warranty';

  final String warrantyId;
  final String name;
  final int daysLeft;

  /// The reminder in [data], or null when the push is something else or does
  /// not say which warranty it is about.
  static ReminderPush? fromData(Map<String, dynamic> data) {
    final id = data['warrantyId'];
    if (data['type'] != type || id is! String || id.isEmpty) return null;
    final name = data['name'];
    return ReminderPush(
      warrantyId: id,
      name: name is String ? name : '',
      daysLeft: int.tryParse('${data['daysLeft']}') ?? 0,
    );
  }
}
