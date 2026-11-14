import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/bid.dart';
import '../models/item.dart';
import '../repositories/bid_repository.dart';
import '../repositories/item_repository.dart';

enum MyBidStatus { winning, outbid, won, lost }

/// One item the user has bid on, with where they stand right now.
class MyBidEntry {
  const MyBidEntry({
    required this.item,
    required this.myTopBid,
    required this.myBidCount,
    required this.status,
  });

  final Item item;
  final int myTopBid;
  final int myBidCount;
  final MyBidStatus status;

  bool get isActive =>
      status == MyBidStatus.winning || status == MyBidStatus.outbid;
}

/// Requirement 4 (outbid alerts) with no Cloud Function and no cost.
///
/// Listens to the user's bids (collection-group query), then to each of
/// those items. "Outbid" is never stored: it is derived by comparing the
/// item's current highestBidderId against the signed-in user.
class MyBidsState extends ChangeNotifier {
  MyBidsState(this._bids, this._items);

  final BidRepository _bids;
  final ItemRepository _items;

  String? _uid;
  StreamSubscription<List<Bid>>? _bidsSub;
  final Map<String, StreamSubscription<Item?>> _itemSubs = {};
  final Map<String, Item> _itemById = {};
  final Set<String> _itemsReady = {};
  final Map<String, MyBidStatus> _lastStatus = {};
  final List<MyBidEntry> _alerts = [];
  Timer? _clock;

  List<Bid> _myBids = const [];
  bool _bidsReady = false;
  String? _error;
  int _closedCount = 0;

  /// Follows the signed-in user. Called by the provider on auth changes, so
  /// it must not notify listeners synchronously (that would be mid-build).
  void setUser(String? uid) {
    if (uid == _uid) return;
    _reset();
    _uid = uid;
    if (uid != null) _start();
  }

  void _reset() {
    _bidsSub?.cancel();
    _bidsSub = null;
    for (final s in _itemSubs.values) {
      s.cancel();
    }
    _itemSubs.clear();
    _itemById.clear();
    _itemsReady.clear();
    _lastStatus.clear();
    _alerts.clear();
    _clock?.cancel();
    _clock = null;
    _myBids = const [];
    _bidsReady = false;
    _error = null;
    _closedCount = 0;
  }

  /// (Re)subscribe. Also used by "Try again".
  void retry() {
    final uid = _uid;
    _reset();
    _uid = uid;
    if (uid != null) {
      _start();
      notifyListeners();
    }
  }

  void _start() {
    _bidsSub = _bids.watchMyBids(_uid!).listen(
      _onBids,
      onError: (Object e) {
        // The first run usually lands here: the message holds the link that
        // creates the collection-group index. Print it for the developer.
        debugPrint('My Bids query failed (create the index via the link): $e');
        _error = 'Could not load your bids. Check your connection and try again.';
        notifyListeners();
      },
    );
    // Auctions end by the clock, not by a write, so re-check now and then.
    _clock = Timer.periodic(const Duration(seconds: 10), (_) {
      final closed = _itemById.values.where((i) => i.isClosed).length;
      if (closed != _closedCount) {
        _closedCount = closed;
        notifyListeners();
      }
    });
  }

  void _onBids(List<Bid> bids) {
    _myBids = bids;
    _bidsReady = true;
    _error = null;

    final ids = bids.map((b) => b.itemId).where((i) => i.isNotEmpty).toSet();

    for (final id in _itemSubs.keys.where((k) => !ids.contains(k)).toList()) {
      _itemSubs.remove(id)?.cancel();
      _itemById.remove(id);
      _itemsReady.remove(id);
      _lastStatus.remove(id);
    }
    for (final id in ids) {
      if (_itemSubs.containsKey(id)) continue;
      _itemSubs[id] = _items.watchById(id).listen(
        (item) => _onItem(id, item),
        onError: (Object _) {
          _itemsReady.add(id); // don't spin forever on one bad item
          notifyListeners();
        },
      );
    }
    notifyListeners();
  }

  void _onItem(String id, Item? item) {
    _itemsReady.add(id);
    if (item == null) {
      _itemById.remove(id);
    } else {
      _itemById[id] = item;
      final now = _statusOf(item);
      final before = _lastStatus[id];
      // Winning -> outbid while the app is open: raise the alert (screen 11).
      // The very first snapshot of an item (before == null) never alerts.
      if (before == MyBidStatus.winning && now == MyBidStatus.outbid) {
        _alerts.add(MyBidEntry(
          item: item,
          myTopBid: _topBidOn(id),
          myBidCount: _bidCountOn(id),
          status: now,
        ));
      }
      _lastStatus[id] = now;
    }
    notifyListeners();
  }

  MyBidStatus _statusOf(Item item) {
    final mine = item.highestBidderId == _uid;
    if (item.isClosed) return mine ? MyBidStatus.won : MyBidStatus.lost;
    return mine ? MyBidStatus.winning : MyBidStatus.outbid;
  }

  int _topBidOn(String itemId) => _myBids
      .where((b) => b.itemId == itemId)
      .fold(0, (m, b) => b.amount > m ? b.amount : m);

  int _bidCountOn(String itemId) =>
      _myBids.where((b) => b.itemId == itemId).length;

  // ---- what the screens read ----

  bool get loading =>
      _uid != null &&
      _error == null &&
      (!_bidsReady ||
          _myBids.any(
              (b) => b.itemId.isNotEmpty && !_itemsReady.contains(b.itemId)));
  String? get error => _error;

  List<MyBidEntry> get entries {
    final ids = _myBids.map((b) => b.itemId).toSet();
    final out = <MyBidEntry>[];
    for (final id in ids) {
      final item = _itemById[id];
      if (item == null) continue;
      out.add(MyBidEntry(
        item: item,
        myTopBid: _topBidOn(id),
        myBidCount: _bidCountOn(id),
        status: _statusOf(item),
      ));
    }
    return out;
  }

  /// Live auctions, ending soonest first.
  List<MyBidEntry> get active => entries.where((e) => e.isActive).toList()
    ..sort((a, b) => a.item.endTime.compareTo(b.item.endTime));

  List<MyBidEntry> get won => _closed(MyBidStatus.won);
  List<MyBidEntry> get lost => _closed(MyBidStatus.lost);

  List<MyBidEntry> _closed(MyBidStatus s) =>
      entries.where((e) => e.status == s).toList()
        ..sort((a, b) => b.item.endTime.compareTo(a.item.endTime));

  /// Live auctions where someone has topped the user (screen 4 + badge).
  List<MyBidEntry> get outbid =>
      active.where((e) => e.status == MyBidStatus.outbid).toList();

  /// Next outbid alert waiting to be shown, if any.
  MyBidEntry? get pendingAlert => _alerts.isEmpty ? null : _alerts.first;

  void dismissAlert() {
    if (_alerts.isEmpty) return;
    _alerts.removeAt(0);
    notifyListeners();
  }

  @override
  void dispose() {
    _reset();
    super.dispose();
  }
}
