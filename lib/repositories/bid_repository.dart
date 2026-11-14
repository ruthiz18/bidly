import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bid.dart';
import '../models/item.dart';

enum BidRejection {
  tooLow,
  closed,
  ownItem,
  notFound,
  buyNowUnavailable,
  failed
}

/// Thrown when the server-side check refuses a bid. [currentHighest] is the
/// value the transaction actually saw, so the UI can show the real number.
class BidRejectedException implements Exception {
  const BidRejectedException(this.reason, {this.currentHighest});

  final BidRejection reason;
  final int? currentHighest;

  @override
  String toString() => 'BidRejectedException($reason, $currentHighest)';
}

/// Every Firestore call about bids lives here.
class BidRepository {
  BidRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Places a bid atomically.
  ///
  /// The read of the item and the writes (new bid doc + updated highestBid,
  /// highestBidderId/Name, bidCount) happen in ONE transaction. If another
  /// bid commits to the same item between our read and our commit, Firestore
  /// throws our attempt away and re-runs this function with fresh data, so
  /// the loser sees the winner's higher highestBid and is rejected here.
  ///
  /// Note: the function passed to runTransaction may run several times, so it
  /// must have no side effects other than the transaction's own reads/writes.
  Future<void> placeBid({
    required String itemId,
    required String bidderId,
    required String bidderName,
    required int amount,
  }) async {
    final itemRef = _db.collection('items').doc(itemId);
    final bidRef = itemRef.collection('bids').doc();

    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(itemRef);
        if (!snap.exists) {
          throw const BidRejectedException(BidRejection.notFound);
        }
        final item = Item.fromDoc(snap);

        if (item.sellerId == bidderId) {
          throw BidRejectedException(BidRejection.ownItem,
              currentHighest: item.highestBid);
        }
        // Friendly early exit only; the rules enforce the real deadline with
        // request.time on the server.
        if (item.isClosed) {
          throw BidRejectedException(BidRejection.closed,
              currentHighest: item.highestBid);
        }
        if (amount < item.minimumBid) {
          throw BidRejectedException(BidRejection.tooLow,
              currentHighest: item.highestBid);
        }

        tx.set(
          bidRef,
          Bid(
            id: bidRef.id,
            bidderId: bidderId,
            bidderName: bidderName,
            amount: amount,
          ).toCreateMap(),
        );
        tx.update(itemRef, {
          'highestBid': amount,
          'highestBidderId': bidderId,
          'highestBidderName': bidderName,
          'bidCount': item.bidCount + 1,
        });
      });
    } on FirebaseException catch (e) {
      // The rules said no (e.g. the clock passed endTime, or a competing bid
      // landed). Surface it as a rejection, not a crash.
      if (e.code == 'permission-denied' || e.code == 'aborted') {
        final latest = await _latestHighest(itemRef);
        throw BidRejectedException(
          latest == null ? BidRejection.failed : BidRejection.tooLow,
          currentHighest: latest,
        );
      }
      rethrow;
    }
  }

  /// Buy Now: ends the auction early, in its own transaction.
  ///
  /// Because it reads and writes the same item document as [placeBid], the
  /// two are serialised by Firestore: a bid that commits first makes Buy Now
  /// re-run and (if highestBid reached the price) fail; a Buy Now that
  /// commits first makes the bid re-run, see boughtNow == true and fail.
  Future<void> buyNow({
    required String itemId,
    required String buyerId,
    required String buyerName,
  }) async {
    final itemRef = _db.collection('items').doc(itemId);
    final bidRef = itemRef.collection('bids').doc();

    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(itemRef);
        if (!snap.exists) {
          throw const BidRejectedException(BidRejection.notFound);
        }
        final item = Item.fromDoc(snap);
        final price = item.buyNowPrice;

        if (item.sellerId == buyerId) {
          throw BidRejectedException(BidRejection.ownItem,
              currentHighest: item.highestBid);
        }
        if (item.isClosed) {
          throw BidRejectedException(BidRejection.closed,
              currentHighest: item.highestBid);
        }
        if (price == null || item.highestBid >= price) {
          throw BidRejectedException(BidRejection.buyNowUnavailable,
              currentHighest: item.highestBid);
        }

        // The winning "bid" is recorded too, so the bid list always matches
        // highestBid.
        tx.set(bidRef, {
          ...Bid(
            id: bidRef.id,
            bidderId: buyerId,
            bidderName: buyerName,
            amount: price,
          ).toCreateMap(),
          'buyNow': true,
        });
        tx.update(itemRef, {
          'highestBid': price,
          'highestBidderId': buyerId,
          'highestBidderName': buyerName,
          'bidCount': item.bidCount + 1,
          'boughtNow': true,
          'closedEarlyAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'aborted') {
        final latest = await _latestHighest(itemRef);
        throw BidRejectedException(
          latest == null ? BidRejection.failed : BidRejection.closed,
          currentHighest: latest,
        );
      }
      rethrow;
    }
  }

  Future<int?> _latestHighest(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      final s = await ref.get(const GetOptions(source: Source.server));
      return s.exists ? Item.fromDoc(s).highestBid : null;
    } catch (_) {
      return null;
    }
  }

  /// Every bid [uid] has ever placed, across all items, newest first.
  ///
  /// A collection-group query. The first run throws a failed-precondition
  /// error containing a link that creates the required index; open it,
  /// click Create, and wait a minute.
  Stream<List<Bid>> watchMyBids(String uid) => _db
      .collectionGroup('bids')
      .where('bidderId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Bid.fromDoc).toList());

  /// Full bid history for an item, newest first (sale detail screen).
  Stream<List<Bid>> watchBidsNewestFirst(String itemId) => _db
      .collection('items')
      .doc(itemId)
      .collection('bids')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Bid.fromDoc).toList());

  /// Bid history for an item, highest first.
  Stream<List<Bid>> watchBids(String itemId) => _db
      .collection('items')
      .doc(itemId)
      .collection('bids')
      .orderBy('amount', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Bid.fromDoc).toList());
}
