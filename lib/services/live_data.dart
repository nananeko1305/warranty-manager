import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/warranty.dart';

/// Live snapshot of the account's warranties. One instance per signed-in
/// session, owned by the home screen.
class LiveData extends ChangeNotifier {
  LiveData(this._open) {
    _watch(_firstRetry);
  }

  static const _firstRetry = Duration(seconds: 5);
  static const _longestRetry = Duration(minutes: 1);

  final Stream<List<Warranty>> Function() _open;

  StreamSubscription<List<Warranty>>? _sub;
  Timer? _retry;
  bool _disposed = false;

  /// Null until the first answer: not here yet, as opposed to there being
  /// none.
  List<Warranty>? warranties;

  Object? error;

  Warranty? byId(String id) {
    for (final w in warranties ?? const <Warranty>[]) {
      if (w.id == id) return w;
    }
    return null;
  }

  /// Subscribes, and subscribes again after a failure.
  ///
  /// A Firestore listener that errors is finished: it never recovers on its
  /// own. Rules deployed a moment ago would otherwise leave the app waiting on
  /// data that will never arrive until it is force-closed. Backs off, so a
  /// collection nobody may read is not retried in a tight loop.
  void _watch(Duration wait) {
    _sub = _open().listen(
      (value) {
        warranties = value;
        error = null;
        notifyListeners();
      },
      onError: (Object e) {
        error = e;
        notifyListeners();
        _sub?.cancel();
        _retry = Timer(wait, () {
          if (_disposed) return;
          final next = wait * 2;
          _watch(next > _longestRetry ? _longestRetry : next);
        });
      },
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _retry?.cancel();
    super.dispose();
  }
}
