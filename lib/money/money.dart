import 'package:intl/intl.dart';

enum Currency { rsd, eur }

Currency currencyFromCode(String? code) =>
    code == 'EUR' ? Currency.eur : Currency.rsd;

extension CurrencyCode on Currency {
  String get code => this == Currency.eur ? 'EUR' : 'RSD';
}

/// Formats an amount in minor units, e.g. 1234550 RSD -> "12.345,50 RSD".
String formatMoney(int amountMinor, Currency currency, String locale) {
  final number = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: 2,
  ).format(amountMinor / 100);
  return currency == Currency.eur ? '$number €' : '$number RSD';
}

/// Parses user input such as "12.345,50", "12345.5" or "12 345" into
/// minor units. Returns null when the input is not a positive amount.
int? parseMoney(String input) {
  var s = input.trim().replaceAll(' ', '');
  if (s.isEmpty) return null;
  final lastComma = s.lastIndexOf(',');
  final lastDot = s.lastIndexOf('.');
  if (lastComma >= 0 && lastDot >= 0) {
    // Both present: whichever comes last is the decimal separator.
    final decimal = lastComma > lastDot ? ',' : '.';
    final group = decimal == ',' ? '.' : ',';
    s = s.replaceAll(group, '').replaceAll(decimal, '.');
  } else if (lastComma >= 0 || lastDot >= 0) {
    final sep = lastComma >= 0 ? ',' : '.';
    final parts = s.split(sep);
    // "1.500" or "1.250.000" group thousands; "1500,5" is a decimal.
    final grouping =
        parts.length > 2 || (parts.last.length == 3 && parts.first.isNotEmpty);
    s = grouping ? parts.join() : parts.join('.');
  }
  final value = double.tryParse(s);
  if (value == null || value <= 0) return null;
  return (value * 100).round();
}

/// Minor units back to an editable string, e.g. 1234550 -> "12345.50".
String moneyToInput(int amountMinor) {
  final whole = amountMinor ~/ 100;
  final fraction = amountMinor % 100;
  return fraction == 0
      ? '$whole'
      : '$whole.${fraction.toString().padLeft(2, '0')}';
}
