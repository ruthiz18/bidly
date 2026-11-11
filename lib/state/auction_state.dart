import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/item.dart';
import '../repositories/bid_repository.dart';
import '../repositories/item_repository.dart';

enum AuctionFilter { all, endingSoon, buyNow }

/// The brain for auctions: holds the live list and the filters.
/// Screens talk to this, never to Firestore.
class AuctionState extends ChangeNotifier {
  AuctionState(this._repo, this._bids) {
    start();
  }

  final ItemRepository _repo;
  final BidRepository _bids;
  StreamSubscription<List<Item>>? _sub;

  List<Item> _items = const [];
  bool _loading = true;
  String? _error;
  String _query = '';
  AuctionFilter _filter = AuctionFilter.all;

  bool get loading => _loading;
  String? get error => _error;
  bool get hasAny => _items.isNotEmpty;
  String get query => _query;
  AuctionFilter get filter => _filter;

  /// Live items after search + chip filter.
  List<Item> get filtered {
    final q = _query.trim().toLowerCase();
    return _items.where((i) {
      if (i.isClosed) return false;
      if (q.isNotEmpty && !i.title.toLowerCase().contains(q)) return false;
      switch (_filter) {
        case AuctionFilter.all:
          return true;
        case AuctionFilter.endingSoon:
          return i.timeLeft < const Duration(hours: 1);
        case AuctionFilter.buyNow:
          return i.hasBuyNow;
      }
    }).toList();
  }

  /// (Re)subscribe to the live stream. Also used by "Try again".
  void start() {
    _sub?.cancel();
    _loading = true;
    _error = null;
    notifyListeners();
    _sub = _repo.watchLive().listen(
      (items) {
        _items = items;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = 'Could not load auctions. Check your connection and try again.';
        notifyListeners();
      },
    );
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setFilter(AuctionFilter f) {
    _filter = f;
    notifyListeners();
  }

  Stream<Item?> watchItem(String id) => _repo.watchById(id);

  Stream<List<Item>> watchMine(String sellerId) =>
      _repo.watchBySeller(sellerId);

  Future<String> createItem(Item item) => _repo.create(item);

  /// Throws [BidRejectedException] if the server refuses the bid.
  Future<void> placeBid({
    required String itemId,
    required String bidderId,
    required String bidderName,
    required int amount,
  }) =>
      _bids.placeBid(
        itemId: itemId,
        bidderId: bidderId,
        bidderName: bidderName,
        amount: amount,
      );

  /// Buy Now. Throws [BidRejectedException] if it can no longer be bought.
  Future<void> buyNow({
    required String itemId,
    required String buyerId,
    required String buyerName,
  }) =>
      _bids.buyNow(itemId: itemId, buyerId: buyerId, buyerName: buyerName);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
