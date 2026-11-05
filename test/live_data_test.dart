import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_manager/models/warranty.dart';
import 'package:warranty_manager/models/warranty_dates.dart';
import 'package:warranty_manager/services/live_data.dart';

final _warranty = Warranty(
  id: 'w1',
  ownerId: 'u1',
  name: 'x',
  purchaseDate: DateTime(2026, 1, 1),
  warrantyAmount: 1,
  warrantyUnit: WarrantyUnit.years,
);

void main() {
  testWidgets('tells "not here yet" from "none"', (tester) async {
    final source = StreamController<List<Warranty>>();
    addTearDown(source.close);
    final data = LiveData(() => source.stream);
    addTearDown(data.dispose);
    expect(data.warranties, isNull);
    source.add(const []);
    await tester.pump();
    expect(data.warranties, isEmpty);
  });

  testWidgets('finds a warranty by id, and not one it does not have', (
    tester,
  ) async {
    final data = LiveData(() => Stream.value([_warranty]));
    addTearDown(data.dispose);
    await tester.pump();
    expect(data.byId('w1'), _warranty);
    expect(data.byId('other'), isNull);
  });

  // A Firestore listener that errors never recovers, so without this the app
  // would wait for data until it was force-closed.
  testWidgets('subscribes again after a failure, and recovers', (tester) async {
    var opens = 0;
    final data = LiveData(() {
      opens++;
      return opens == 1
          ? Stream<List<Warranty>>.error(StateError('denied'))
          : Stream.value([_warranty]);
    });
    addTearDown(data.dispose);
    await tester.pump();
    expect(data.error, isA<StateError>());
    expect(opens, 1);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(opens, 2);
    expect(data.warranties, [_warranty]);
    expect(data.error, isNull);
  });

  testWidgets('backs off when it keeps failing', (tester) async {
    var opens = 0;
    final data = LiveData(() {
      opens++;
      return Stream<List<Warranty>>.error(StateError('denied'));
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(opens, 2);
    // The second wait is ten seconds, so five more do nothing.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(opens, 2);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(opens, 3);
    // Here, not in a tear-down: the test binding checks for pending timers
    // first, and the next retry is still waiting.
    data.dispose();
  });
}
