import 'package:flutter/widgets.dart';

import '../money/money.dart';
import 'warranty.dart';
import 'warranty_dates.dart';

/// The editable state behind the warranty form.
class WarrantyDraft {
  WarrantyDraft({Warranty? warranty, DateTime? today})
    : id = warranty?.id ?? '',
      name = TextEditingController(text: warranty?.name ?? ''),
      store = TextEditingController(text: warranty?.store ?? ''),
      note = TextEditingController(text: warranty?.note ?? ''),
      amount = TextEditingController(
        text: warranty?.amountMinor == null
            ? ''
            : moneyToInput(warranty!.amountMinor!),
      ),
      duration = TextEditingController(
        text: (warranty?.warrantyAmount ?? _defaultYears).toString(),
      ),
      unit = warranty?.warrantyUnit ?? WarrantyUnit.years,
      purchaseDate = warranty?.purchaseDate ?? _dateOnly(today),
      currency = warranty?.currency ?? Currency.rsd,
      receiptUrl = warranty?.receiptUrl ?? '',
      notify = warranty?.notify ?? true;

  /// Two years is the legal period for new goods here, so it is the guess
  /// that needs correcting least often.
  static const _defaultYears = 2;

  static DateTime _dateOnly(DateTime? day) {
    final d = day ?? DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }

  final String id;
  final TextEditingController name;
  final TextEditingController store;
  final TextEditingController note;
  final TextEditingController amount;
  final TextEditingController duration;
  WarrantyUnit unit;
  DateTime purchaseDate;
  Currency currency;
  String receiptUrl;
  bool notify;

  void dispose() {
    name.dispose();
    store.dispose();
    note.dispose();
    amount.dispose();
    duration.dispose();
  }

  /// The warranty to save. Call it only once the form has validated.
  Warranty build({required String ownerId}) {
    final price = parseMoney(amount.text);
    return Warranty(
      id: id,
      ownerId: ownerId,
      name: name.text.trim(),
      store: store.text.trim(),
      note: note.text.trim(),
      purchaseDate: purchaseDate,
      warrantyAmount: int.parse(duration.text.trim()),
      warrantyUnit: unit,
      amountMinor: price,
      // A currency without an amount would mean nothing.
      currency: price == null ? null : currency,
      receiptUrl: receiptUrl,
      notify: notify,
    );
  }
}
