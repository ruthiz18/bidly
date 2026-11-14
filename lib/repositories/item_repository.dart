import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item.dart';

/// Every Firestore call about items lives here.
class ItemRepository {
  ItemRepository({FirebaseFirestore? firestore})
      : _col = (firestore ?? FirebaseFirestore.instance).collection('items');

  final CollectionReference<Map<String, dynamic>> _col;

  /// Items whose end time is still in the future, soonest-ending first.
  /// (Single inequality + orderBy on the same field: no composite index.)
  Stream<List<Item>> watchLive() => _col
      .where('endTime', isGreaterThan: Timestamp.now())
      .orderBy('endTime')
      .snapshots()
      .map((s) => s.docs.map(Item.fromDoc).where((i) => !i.boughtNow).toList());

  Stream<Item?> watchById(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Item.fromDoc(d) : null);

  /// A seller's own items, newest first (sorted here to avoid an index).
  Stream<List<Item>> watchBySeller(String sellerId) => _col
      .where('sellerId', isEqualTo: sellerId)
      .snapshots()
      .map((s) {
        final items = s.docs.map(Item.fromDoc).toList();
        items.sort((a, b) => (b.createdAt ?? b.endTime)
            .compareTo(a.createdAt ?? a.endTime));
        return items;
      });

  /// Seller edit. Only the keys in [fields] are written. The rules refuse
  /// price / end-time changes once bidCount > 0.
  Future<void> update(String id, Map<String, dynamic> fields) =>
      _col.doc(id).update(fields);

  /// Returns the new item's id.
  Future<String> create(Item item) async {
    final ref = await _col.add(item.toCreateMap());
    return ref.id;
  }
}
