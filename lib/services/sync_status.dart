import 'package:flutter/foundation.dart';

/// Sync phase shown by the banner.
enum SyncPhase { idle, syncing, done }

/// Tracks whether a save is in progress. `track` wraps an action: shows
/// "syncing" before it, "done" after success, then hides itself.
class SyncController extends ValueNotifier<SyncPhase> {
  SyncController() : super(SyncPhase.idle);

  int _seq = 0;

  Future<T> track<T>(Future<T> Function() action) async {
    final my = ++_seq;
    value = SyncPhase.syncing;
    try {
      final result = await action();
      if (my == _seq) {
        value = SyncPhase.done;
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (my == _seq && value == SyncPhase.done) value = SyncPhase.idle;
        });
      }
      return result;
    } catch (e) {
      if (my == _seq) value = SyncPhase.idle;
      rethrow;
    }
  }
}

final SyncController syncController = SyncController();
