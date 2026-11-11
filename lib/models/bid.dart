import 'package:cloud_firestore/cloud_firestore.dart';

/// One accepted bid, stored at items/{itemId}/bids/{bidId}.
/// Bids are only ever created (inside a transaction), never edited.
class Bid {
  const Bid({
    required this.id,
    required this.bidderId,
    required this.bidderName,
    required this.amount,
    this.createdAt,
  });

  final String id;
  final String bidderId;
  final String bidderName;
  final int amount;
  final DateTime? createdAt;

  factory Bid.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Bid(
      id: doc.id,
      bidderId: d['bidderId'] as String? ?? '',
      bidderName: d['bidderName'] as String? ?? 'Bidder',
      amount: (d['amount'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// createdAt is stamped by the server so clocks on phones can't lie.
  Map<String, dynamic> toCreateMap() => {
        'bidderId': bidderId,
        'bidderName': bidderName,
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
