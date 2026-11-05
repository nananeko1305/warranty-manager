import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/warranty.dart';

/// CRUD for one account's warranties.
class WarrantyRepository {
  WarrantyRepository._();
  static final WarrantyRepository instance = WarrantyRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _warranties =>
      _db.collection('warranties');

  /// The owner's warranties, in no particular order: the rules refuse a query
  /// without this filter, and sorting here as well would take a composite
  /// index. See `WarrantyLists`.
  Stream<List<Warranty>> watchMine(String uid) => _warranties
      .where('ownerId', isEqualTo: uid)
      .snapshots()
      .map((snap) => snap.docs.map(Warranty.fromDoc).toList());

  /// [before] is the warranty as the form received it; null for a new one.
  Future<void> save(Warranty warranty, {required Warranty? before}) {
    if (before == null) {
      return _warranties.doc().set({
        ...warranty.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return _warranties.doc(warranty.id).update(warranty.toEditMap(before));
  }

  Future<void> delete(String id) => _warranties.doc(id).delete();
}
