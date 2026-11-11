import 'package:cloud_firestore/cloud_firestore.dart';

/// An auction listing, stored at items/{itemId}.
///
/// Status is worked out from the data, never stored, so it cannot be wrong.
class Item {
  const Item({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    required this.startingPrice,
    required this.highestBid,
    required this.endTime,
    this.imageUrl,
    this.highestBidderId,
    this.highestBidderName,
    this.bidCount = 0,
    this.buyNowPrice,
    this.boughtNow = false,
    this.createdAt,
    this.closedEarlyAt,
  });

  /// Smallest step a new bid must add to the current highest bid (RWF).
  static const int bidIncrement = 1000;

  final String id;
  final String sellerId;
  final String sellerName;
  final String title;
  final String description;
  final String? imageUrl;
  final int startingPrice;
  final int highestBid;
  final String? highestBidderId;
  final String? highestBidderName;
  final int bidCount;
  final int? buyNowPrice;
  final bool boughtNow;
  final DateTime endTime;
  final DateTime? createdAt;

  /// Set by the server when Buy Now ended the auction early.
  final DateTime? closedEarlyAt;

  // ---- computed, never stored ----

  /// Closed by the clock or by a buy-now. (The server enforces the real
  /// deadline with request.time; this is only for drawing the UI.)
  bool get isClosed => boughtNow || !endTime.isAfter(DateTime.now());
  bool get isSold => isClosed && highestBidderId != null;
  bool get isUnsold => isClosed && highestBidderId == null;

  /// True when [uid] holds the winning bid of a closed auction.
  bool isWonBy(String? uid) => isSold && uid != null && highestBidderId == uid;
  bool get hasBuyNow => buyNowPrice != null && !isClosed;

  Duration get timeLeft {
    final d = endTime.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  /// Lowest amount the next bid may be. Rules require strictly more than
  /// highestBid, so this holds even for the first bid.
  int get minimumBid => highestBid + bidIncrement;

  factory Item.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    int n(String k) => (d[k] as num?)?.toInt() ?? 0;
    return Item(
      id: doc.id,
      sellerId: d['sellerId'] as String? ?? '',
      sellerName: d['sellerName'] as String? ?? 'Seller',
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      imageUrl: (d['imageUrl'] as String?)?.isEmpty ?? true
          ? null
          : d['imageUrl'] as String,
      startingPrice: n('startingPrice'),
      highestBid: n('highestBid'),
      highestBidderId: d['highestBidderId'] as String?,
      highestBidderName: d['highestBidderName'] as String?,
      bidCount: n('bidCount'),
      buyNowPrice: (d['buyNowPrice'] as num?)?.toInt(),
      boughtNow: d['boughtNow'] as bool? ?? false,
      // A pending serverTimestamp is null for a moment on local writes.
      endTime: (d['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      closedEarlyAt: (d['closedEarlyAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Map for creating a listing. Shaped to pass the Firestore rules:
  /// highestBid == startingPrice, no bidder, bidCount 0, boughtNow false.
  /// endTime is a Timestamp; createdAt is stamped by the server.
  Map<String, dynamic> toCreateMap() => {
        'sellerId': sellerId,
        'sellerName': sellerName,
        'title': title,
        'description': description,
        'imageUrl': imageUrl ?? '',
        'startingPrice': startingPrice,
        'highestBid': startingPrice,
        'highestBidderId': null,
        'highestBidderName': null,
        'bidCount': 0,
        'buyNowPrice': buyNowPrice,
        'boughtNow': false,
        'closedEarlyAt': null,
        'endTime': Timestamp.fromDate(endTime),
        'createdAt': FieldValue.serverTimestamp(),
      };
}
