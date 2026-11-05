import 'package:cloud_firestore/cloud_firestore.dart';

import '../money/money.dart';
import 'warranty_dates.dart';

/// A warranty in `warranties/{id}`, which only its owner can see.
class Warranty {
  const Warranty({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.purchaseDate,
    required this.warrantyAmount,
    required this.warrantyUnit,
    this.store = '',
    this.note = '',
    this.amountMinor,
    this.currency,
    this.receiptUrl = '',
    this.notify = true,
  });

  final String id;
  final String ownerId;
  final String name;

  /// Where it was bought, since that is where a claim goes. May be empty.
  final String store;

  final String note;

  /// The date on the receipt. The warranty starts the same day.
  final DateTime purchaseDate;

  final int warrantyAmount;
  final WarrantyUnit warrantyUnit;

  /// What it cost. Null when it was entered without a price.
  final int? amountMinor;
  final Currency? currency;

  /// Photo of the receipt, hosted outside Firebase, or empty.
  final String receiptUrl;

  /// Whether the owner is reminded before the warranty ends.
  final bool notify;

  /// The last day the warranty covers, inclusive.
  DateTime get warrantyEnd =>
      warrantyEndOf(purchaseDate, warrantyAmount, warrantyUnit);

  /// 0 on the day the warranty expires, negative once it has.
  int daysLeft(DateTime now) => daysBetween(now, warrantyEnd);

  double progress(DateTime now) =>
      warrantyProgress(purchaseDate, warrantyEnd, now);

  WarrantyStatus status(DateTime now) => warrantyStatusOf(daysLeft(now));

  factory Warranty.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final currency = data['currency'] as String?;
    return Warranty(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      store: data['store'] as String? ?? '',
      note: data['note'] as String? ?? '',
      purchaseDate:
          parseDateKey(data['purchaseDate'] as String?) ?? DateTime.now(),
      warrantyAmount: (data['warrantyAmount'] as num?)?.toInt() ?? 1,
      warrantyUnit: warrantyUnitFromName(data['warrantyUnit'] as String?),
      amountMinor: (data['amountMinor'] as num?)?.toInt(),
      currency: currency == null ? null : currencyFromCode(currency),
      receiptUrl: data['receiptUrl'] as String? ?? '',
      notify: data['notify'] as bool? ?? true,
    );
  }

  /// Deliberately never writes `remindersSent`: that field belongs to the
  /// push worker, and `update()` only touches the keys it is given.
  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'name': name,
    'store': store,
    'note': note,
    'purchaseDate': dateKey(purchaseDate),
    // Mirrors [warrantyEnd] so the push worker can query it. The app always
    // computes the date instead of reading this back.
    'endsOn': dateKey(warrantyEnd),
    'warrantyAmount': warrantyAmount,
    'warrantyUnit': warrantyUnit.name,
    'amountMinor': amountMinor,
    'currency': currency?.code,
    'receiptUrl': receiptUrl,
    'notify': notify,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
