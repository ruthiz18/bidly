import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bid.dart';
import '../models/item.dart';
import '../state/auction_state.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/countdown_text.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/item_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/status_tag.dart';
import 'edit_listing_screen.dart';

/// Screen 17: a seller's view of one listing, with the full bid history
/// (newest first: bidder, amount, time).
class SaleDetailScreen extends StatefulWidget {
  const SaleDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  late final Stream<Item?> _item;
  late final Stream<List<Bid>> _bids;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuctionState>();
    _item = state.watchItem(widget.itemId);
    _bids = state.watchBidHistory(widget.itemId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Item?>(
      stream: _item,
      builder: (context, snap) {
        final item = snap.data;
        final canEdit = item != null && !item.isClosed;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Sale Details'),
            actions: [
              if (canEdit)
                IconButton(
                  tooltip: 'Edit listing',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => EditListingScreen(itemId: item.id)),
                  ),
                ),
            ],
          ),
          body: () {
            if (snap.hasError) {
              return const ErrorView(
                  message: 'Could not load this sale. Please go back and try again.');
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            if (item == null) {
              return const EmptyView(
                  icon: Icons.search_off, message: 'This listing no longer exists.');
            }
            return _Body(item: item, bids: _bids);
          }(),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.item, required this.bids});

  final Item item;
  final Stream<List<Bid>> bids;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final closed = item.isClosed;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Row(children: [
          if (closed)
            StatusTag(item.isSold ? 'Sold' : 'Unsold',
                kind: item.isSold ? TagKind.sold : TagKind.neutral)
          else
            const StatusTag('Live auction', kind: TagKind.live),
        ]),
        const SizedBox(height: 12),
        Text(item.title, style: text.headlineMedium),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    closed
                        ? (item.isSold ? 'FINAL PRICE' : 'STARTING BID')
                        : (item.bidCount == 0
                            ? 'STARTING BID'
                            : 'CURRENT HIGHEST BID'),
                    style: text.labelSmall),
                const SizedBox(height: 6),
                Text(ItemCard.formatRwf(item.highestBid),
                    style: text.headlineMedium),
                const SizedBox(height: 8),
                Text('${item.bidCount} bids', style: text.bodyMedium),
                if (item.highestBidderName != null)
                  Text(
                      closed
                          ? 'Winner: ${item.highestBidderName}'
                          : 'Leading: ${item.highestBidderName}',
                      style: text.bodyMedium),
                const Divider(height: 28),
                Row(children: [
                  Text(closed ? 'Ended' : 'Ends in', style: text.bodyMedium),
                  const Spacer(),
                  closed
                      ? Text(
                          formatDateTime(item.closedEarlyAt ?? item.endTime),
                          style: text.titleMedium)
                      : CountdownText(
                          endTime: item.endTime, style: text.titleMedium),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Bid history', style: text.titleLarge),
        const SizedBox(height: 12),
        StreamBuilder<List<Bid>>(
          stream: bids,
          builder: (context, snap) {
            if (snap.hasError) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: ErrorView(message: 'Could not load the bid history.'),
              );
            }
            if (!snap.hasData) {
              return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: LoadingView());
            }
            final list = snap.data!;
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: EmptyView(
                    icon: Icons.gavel, message: 'No bids yet.'),
              );
            }
            return Card(
              child: Column(
                children: [
                  for (var i = 0; i < list.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.accentSoft,
                        child: Text(
                          list[i].bidderName.isEmpty
                              ? '?'
                              : list[i].bidderName[0].toUpperCase(),
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ),
                      title: Text(list[i].bidderName,
                          style: text.titleMedium),
                      subtitle: Text(formatDateTime(list[i].createdAt)),
                      trailing: Text(ItemCard.formatRwf(list[i].amount),
                          style: text.titleMedium?.copyWith(
                              color: i == 0
                                  ? AppColors.success
                                  : AppColors.text)),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
