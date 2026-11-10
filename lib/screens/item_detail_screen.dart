import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../state/auction_state.dart';
import '../theme/app_theme.dart';
import '../widgets/countdown_text.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/item_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/status_tag.dart';

/// Screen 8: item detail. No bid button yet.
class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    final stream = context.read<AuctionState>().watchItem(itemId);
    return Scaffold(
      appBar: AppBar(title: const Text('Auction Details')),
      body: StreamBuilder<Item?>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return const ErrorView(
                message: 'Could not load this auction. Please go back and try again.');
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final item = snap.data;
          if (item == null) {
            return const EmptyView(
                icon: Icons.search_off, message: 'This auction no longer exists.');
          }
          return _Body(item: item);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final closed = item.isClosed;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: item.imageUrl == null
                ? Container(
                    color: AppColors.field,
                    child: const Icon(Icons.image_outlined,
                        size: 56, color: AppColors.tertiary),
                  )
                : Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.field,
                      child: const Icon(Icons.broken_image_outlined,
                          size: 48, color: AppColors.tertiary),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (closed)
              StatusTag(item.isSold ? 'Sold' : 'Unsold',
                  kind: item.isSold ? TagKind.sold : TagKind.neutral)
            else
              const StatusTag('Live auction', kind: TagKind.live),
            if (item.hasBuyNow) ...[
              const SizedBox(width: 8),
              const StatusTag('Buy Now'),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(item.title, style: text.headlineMedium),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.accentSoft,
              child: Text(
                item.sellerName.isEmpty ? '?' : item.sellerName[0].toUpperCase(),
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
            title: Text(item.sellerName, style: text.titleMedium),
            subtitle: const Text('Seller'),
          ),
        ),
        const SizedBox(height: 16),
        // Big countdown
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Column(
            children: [
              Text(closed ? 'AUCTION' : 'TIME LEFT',
                  style: text.labelSmall?.copyWith(color: Colors.white70)),
              const SizedBox(height: 6),
              CountdownText(
                endTime: item.endTime,
                endedText: 'Ended',
                style: text.headlineLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Highest-bid panel
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.bidCount == 0 ? 'STARTING BID' : 'CURRENT HIGHEST BID',
                    style: text.labelSmall),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(ItemCard.formatRwf(item.highestBid),
                          style: text.headlineMedium),
                    ),
                    Text('${item.bidCount} bids', style: text.bodyMedium),
                  ],
                ),
                if (item.highestBidderName != null) ...[
                  const SizedBox(height: 4),
                  Text('Leading: ${item.highestBidderName}',
                      style: text.bodyMedium),
                ],
                if (!closed) ...[
                  const Divider(height: 28),
                  Text(
                    'New bid must be at least ${ItemCard.formatRwf(item.minimumBid)}',
                    style: text.bodyMedium,
                  ),
                  if (item.hasBuyNow) ...[
                    const SizedBox(height: 4),
                    Text('Buy Now: ${ItemCard.formatRwf(item.buyNowPrice!)}',
                        style: text.bodyMedium),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Seller's Description", style: text.titleMedium),
                const SizedBox(height: 8),
                Text(item.description, style: text.bodyLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
