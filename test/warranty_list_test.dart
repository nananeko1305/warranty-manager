import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_manager/models/warranty.dart';
import 'package:warranty_manager/models/warranty_dates.dart';
import 'package:warranty_manager/models/warranty_list.dart';

Warranty _bought(String name, DateTime date, {String store = ''}) => Warranty(
  id: name,
  ownerId: 'u1',
  name: name,
  store: store,
  purchaseDate: date,
  warrantyAmount: 1,
  warrantyUnit: WarrantyUnit.years,
);

void main() {
  final now = DateTime(2026, 6, 15);

  group('WarrantyLists', () {
    test('sorts valid ones soonest to end first', () {
      final lists = WarrantyLists.of([
        _bought('later', DateTime(2026, 3, 1)),
        _bought('soon', DateTime(2025, 7, 1)),
        _bought('middle', DateTime(2026, 1, 1)),
      ], now);
      expect(lists.valid.map((w) => w.name), ['soon', 'middle', 'later']);
      expect(lists.expired, isEmpty);
    });

    test('sorts expired ones most recently ended first', () {
      final lists = WarrantyLists.of([
        _bought('ancient', DateTime(2020, 1, 1)),
        _bought('recent', DateTime(2025, 1, 1)),
      ], now);
      expect(lists.expired.map((w) => w.name), ['recent', 'ancient']);
    });

    test('keeps the warranty valid through its last day', () {
      final endsToday = _bought('today', DateTime(2025, 6, 15));
      final endedYesterday = _bought('yesterday', DateTime(2025, 6, 14));
      final lists = WarrantyLists.of([endsToday, endedYesterday], now);
      expect(lists.valid, [endsToday]);
      expect(lists.expired, [endedYesterday]);
    });

    test('settles a tie by name, so the order does not jump around', () {
      final date = DateTime(2026, 1, 1);
      final lists = WarrantyLists.of([
        _bought('b', date),
        _bought('a', date),
      ], now);
      expect(lists.valid.map((w) => w.name), ['a', 'b']);
    });
  });

  group('searchWarranties', () {
    final all = [
      _bought('Frižider', DateTime(2026, 1, 1), store: 'Tehnomanija'),
      _bought('Čajnik', DateTime(2026, 1, 1), store: 'Gigatron'),
      _bought('Usisivač', DateTime(2026, 1, 1)),
    ];

    List<String> names(String query) =>
        searchWarranties(all, query).map((w) => w.name).toList();

    test('an empty query finds everything', () {
      expect(names(''), hasLength(3));
      expect(names('   '), hasLength(3));
    });

    test('finds by name, ignoring case', () {
      expect(names('FRIŽIDER'), ['Frižider']);
    });

    test('finds by store', () {
      expect(names('giga'), ['Čajnik']);
    });

    test('finds without Serbian letters, the way phones usually type', () {
      expect(names('frizider'), ['Frižider']);
      expect(names('cajnik'), ['Čajnik']);
      expect(names('usisivac'), ['Usisivač']);
    });

    test('finds nothing when nothing matches', () {
      expect(names('televizor'), isEmpty);
    });
  });

  group('foldForSearch', () {
    test('folds every Serbian letter', () {
      expect(foldForSearch('ŠšŽžČčĆćĐđ'), 'sszzccccdjdj');
    });
  });
}
