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

  Future<void> save(Warranty warranty) {
    if (warranty.id.isEmpty) {
      return _warranties.doc().set({
        ...warranty.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return _warranties.doc(warranty.id).update(warranty.toMap());
  }

  Future<void> delete(String id) => _warranties.doc(id).delete();
}
