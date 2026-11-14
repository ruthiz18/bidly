import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/my_bids_state.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/item_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/status_tag.dart';
import 'item_detail_screen.dart';

/// Screen 12: the bidder's history, in Active / Won / Lost tabs.
class MyBidsScreen extends StatelessWidget {
  const MyBidsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MyBidsState>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bids'),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.tertiary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Active (${state.loading ? '…' : state.active.length})'),
              Tab(text: 'Won (${state.loading ? '…' : state.won.length})'),
              Tab(text: 'Lost (${state.loading ? '…' : state.lost.length})'),
            ],
          ),
        ),
        body: Builder(builder: (context) {
          if (state.error != null) {
            return ErrorView(message: state.error!, onRetry: state.retry);
          }
          if (state.loading) return const LoadingView();
          return TabBarView(
            children: [
              _list(state.active,
                  'No active bids.\nFind something on Home and place a bid.'),
              _list(state.won, 'You haven\'t won any auctions yet.'),
              _list(state.lost, 'No lost auctions. Keep it up!'),
            ],
          );
        }),
      ),
    );
  }

  Widget _list(List<MyBidEntry> entries, String emptyMessage) {
    if (entries.isEmpty) {
      return EmptyView(icon: Icons.gavel, message: emptyMessage);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) => MyBidCard(entry: entries[i]),
    );
  }
}

/// Card for one bid entry, shared by My Bids and Notifications.
class MyBidCard extends StatelessWidget {
  const MyBidCard({super.key, required this.entry});

  final MyBidEntry entry;

  static StatusTag tagFor(MyBidStatus s) => switch (s) {
        MyBidStatus.winning => const StatusTag('Winning', kind: TagKind.winning),
        MyBidStatus.outbid => const StatusTag('Outbid', kind: TagKind.outbid),
        MyBidStatus.won => const StatusTag('Won', kind: TagKind.winning),
        MyBidStatus.lost => const StatusTag('Lost'),
      };

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final text = Theme.of(context).textTheme;
    return ItemCard(
      title: item.title,
      currentBid: item.highestBid,
      endTime: item.endTime,
      imageUrl: item.imageUrl,
      bidCount: item.bidCount,
      tag: tagFor(entry.status),
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('Your top bid', style: text.bodySmall),
          Text(ItemCard.formatRwf(entry.myTopBid), style: text.titleMedium),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
      ),
    );
  }
}
