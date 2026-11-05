import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../money/money.dart';

/// An optional price: the amount, plus the RSD / EUR switch.
class MoneyFields extends StatelessWidget {
  const MoneyFields({
    super.key,
    required this.amount,
    required this.currency,
    required this.onCurrency,
  });

  final TextEditingController amount;
  final Currency currency;
  final ValueChanged<Currency> onCurrency;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: t.priceOptional,
            prefixIcon: const Icon(Icons.payments_rounded),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            return parseMoney(v) == null ? t.invalidAmount : null;
          },
        ),
        const SizedBox(height: 10),
        SegmentedButton<Currency>(
          segments: const [
            ButtonSegment(value: Currency.rsd, label: Text('RSD')),
            ButtonSegment(value: Currency.eur, label: Text('EUR €')),
          ],
          selected: {currency},
          onSelectionChanged: (s) => onCurrency(s.first),
        ),
      ],
    );
  }
}
