import 'warranty.dart';

/// The two lists on the home screen. Which list a warranty belongs to
/// follows from its dates, so nobody has to file anything away.
class WarrantyLists {
  const WarrantyLists({required this.valid, required this.expired});

  /// Soonest to end first: what needs attention is at the top.
  final List<Warranty> valid;

  /// Most recently ended first: an ended warranty may still be worth a look,
  /// one from years ago rarely is.
  final List<Warranty> expired;

  factory WarrantyLists.of(Iterable<Warranty> all, DateTime now) {
    final valid = <Warranty>[];
    final expired = <Warranty>[];
    for (final w in all) {
      (w.daysLeft(now) < 0 ? expired : valid).add(w);
    }
    valid.sort(_soonestFirst);
    expired.sort((a, b) => _soonestFirst(b, a));
    return WarrantyLists(valid: valid, expired: expired);
  }

  static int _soonestFirst(Warranty a, Warranty b) {
    final byEnd = a.warrantyEnd.compareTo(b.warrantyEnd);
    return byEnd != 0 ? byEnd : a.name.compareTo(b.name);
  }
}

const _folds = {'š': 's', 'ž': 'z', 'č': 'c', 'ć': 'c', 'đ': 'dj'};

/// Lower case without Serbian diacritics, so "frizider" finds "Frižider".
String foldForSearch(String text) =>
    text.toLowerCase().split('').map((c) => _folds[c] ?? c).join();

/// The warranties whose name or store contains [query]. Everything matches
/// an empty query.
List<Warranty> searchWarranties(Iterable<Warranty> all, String query) {
  final needle = foldForSearch(query.trim());
  if (needle.isEmpty) return all.toList();
  return all
      .where(
        (w) =>
            foldForSearch(w.name).contains(needle) ||
            foldForSearch(w.store).contains(needle),
      )
      .toList();
}
