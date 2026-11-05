import 'package:warranty_manager/money/money.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  group('parseMoney', () {
    final cases = <String, int?>{
      '1500': 150000,
      '1500,5': 150050,
      '1500.5': 150050,
      '12,99': 1299,
      '1.500': 150000,
      '1,500': 150000,
      '1.250.000': 125000000,
      '12.345,50': 1234550,
      '12,345.50': 1234550,
      '12 345': 1234500,
      '0.5': 50,
      '': null,
      '0': null,
      '-5': null,
      'abc': null,
    };
    cases.forEach((input, want) {
      test('"$input" -> $want', () => expect(parseMoney(input), want));
    });
  });

  test('moneyToInput round-trips through parseMoney', () {
    for (final minor in [1, 50, 100, 150050, 1234599]) {
      expect(parseMoney(moneyToInput(minor)), minor);
    }
  });

  test('formatMoney uses locale separators and currency', () async {
    await initializeDateFormatting();
    expect(formatMoney(1234550, Currency.rsd, 'sr'), '12.345,50 RSD');
    expect(formatMoney(1234550, Currency.eur, 'en'), '12,345.50 €');
  });
}
