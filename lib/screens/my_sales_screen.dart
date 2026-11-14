import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../state/auction_state.dart';
import '../state/auth_state.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/item_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/status_tag.dart';
import 'earnings_screen.dart';
import 'list_item_screen.dart';
import 'sale_detail_screen.dart';

/// Screen 16: the seller's listings, split into Live / Sold / Unsold by the
/// computed getters on [Item] (nothing is stored).
class MySalesScreen extends StatefulWidget {
  const MySalesScreen({super.key});

  @override
  State<MySalesScreen> createState() => _MySalesScreenState();
}

class _MySalesScreenState extends State<MySalesScreen> {
  Stream<List<Item>>? _stream;
  String? _uid;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    // Auctions end by the clock; redraw so Live moves to Sold/Unsold.
    _clock = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _retry() => setState(() => _stream = null);

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthState>().uid;
    if (uid == null) return const SizedBox.shrink();
    if (_stream == null || _uid != uid) {
      _uid = uid;
      _stream = context.read<AuctionState>().watchMine(uid);
    }

    return DefaultTabController(
      length: 3,
      child: StreamBuilder<List<Item>>(
        stream: _stream,
        builder: (context, snap) {
          final items = snap.data ?? const <Item>[];
          final live = items.where((i) => !i.isClosed).toList()
            ..sort((a, b) => a.endTime.compareTo(b.endTime));
          final sold = items.where((i) => i.isSold).toList();
          final unsold = items.where((i) => i.isUnsold).toList();
          final ready = snap.hasData;

          String count(List<Item> l) => ready ? '${l.length}' : '…';

          Widget body;
          if (snap.hasError) {
            body = ErrorView(
                message: 'Could not load your sales. Please try again.',
                onRetry: _retry);
          } else if (!ready) {
            body = const LoadingView();
          } else {
            body = TabBarView(children: [
              _list(live, 'Nothing live right now.\nTap Sell to list an item.'),
              _list(sold, 'No sales yet.'),
              _list(unsold, 'No unsold items.'),
            ]);
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('My Sales'),
              actions: [
                IconButton(
                  tooltip: 'Earnings',
                  icon: const Icon(Icons.bar_chart),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EarningsScreen()),
                  ),
                ),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(text: 'Live (${count(live)})'),
                  Tab(text: 'Sold (${count(sold)})'),
                  Tab(text: 'Unsold (${count(unsold)})'),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Sell'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ListItemScreen()),
              ),
            ),
            body: body,
          );
        },
      ),
    );
  }

  Widget _list(List<Item> items, String emptyMessage) {
    if (items.isEmpty) {
      return EmptyView(icon: Icons.sell_outlined, message: emptyMessage);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final item = items[i];
        return ItemCard(
          title: item.title,
          currentBid: item.highestBid,
          endTime: item.endTime,
          imageUrl: item.imageUrl,
          bidCount: item.bidCount,
          tag: item.isSold
              ? const StatusTag('Sold', kind: TagKind.sold)
              : item.isUnsold
                  ? const StatusTag('Unsold')
                  : const StatusTag('Live', kind: TagKind.live),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SaleDetailScreen(itemId: item.id))),
        );
      },
    );
  }
}
