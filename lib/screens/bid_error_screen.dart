import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../repositories/bid_repository.dart';
import '../state/auction_state.dart';
import '../theme/app_theme.dart';
import '../widgets/item_card.dart';
import '../widgets/primary_button.dart';

/// Screen 10: the bid was refused (usually because someone else won the
/// race). Shows the live highest bid and lets the user bid again.
/// Pops with `true` when the user wants to try again.
class BidErrorScreen extends StatelessWidget {
  const BidErrorScreen({
    super.key,
    required this.itemId,
    required this.rejection,
    required this.attemptedAmount,
  });

  final String itemId;
  final BidRejectedException rejection;
  final int attemptedAmount;

  String get _title {
    switch (rejection.reason) {
      case BidRejection.closed:
        return 'This auction has ended';
      case BidRejection.ownItem:
        return "You can't bid on your own item";
      case BidRejection.notFound:
        return 'Auction not found';
      case BidRejection.buyNowUnavailable:
        return 'Buy Now is no longer available';
      case BidRejection.tooLow:
      case BidRejection.failed:
        return 'Someone bid before you';
    }
  }

  String get _message {
    final amt = ItemCard.formatRwf(attemptedAmount);
    switch (rejection.reason) {
      case BidRejection.closed:
        return 'This auction closed (the time ran out or the item was bought) before your request of $amt went through. Nothing was charged.';
      case BidRejection.ownItem:
        return 'Sellers cannot bid on their own listings.';
      case BidRejection.notFound:
        return 'This listing was removed, so your bid was not placed.';
      case BidRejection.buyNowUnavailable:
        return 'The highest bid has reached the Buy Now price, so the item can only be won by bidding now.';
      case BidRejection.tooLow:
        return 'Another bid landed first, so your bid of $amt is no longer high enough. Nothing was charged.';
      case BidRejection.failed:
        return 'We could not place your bid of $amt. Please check your connection and try again.';
    }
  }

  bool get _canRetry =>
      rejection.reason == BidRejection.tooLow ||
      rejection.reason == BidRejection.buyNowUnavailable ||
      rejection.reason == BidRejection.failed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final stream = context.read<AuctionState>().watchItem(itemId);
    return Scaffold(
      appBar: AppBar(title: const Text('Bid not placed')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.gavel_rounded, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(_title,
                  textAlign: TextAlign.center, style: text.headlineMedium),
              const SizedBox(height: 12),
              Text(_message, textAlign: TextAlign.center, style: text.bodyLarge),
              const SizedBox(height: 24),
              StreamBuilder<Item?>(
                stream: stream,
                builder: (context, snap) {
                  final item = snap.data;
                  final highest = item?.highestBid ?? rejection.currentHighest;
                  if (highest == null) return const SizedBox.shrink();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text('CURRENT HIGHEST BID', style: text.labelSmall),
                          const SizedBox(height: 6),
                          Text(ItemCard.formatRwf(highest),
                              style: text.headlineMedium),
                          if (item != null && !item.isClosed) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Bid at least ${ItemCard.formatRwf(item.minimumBid)} to lead',
                              style: text.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              if (_canRetry) ...[
                PrimaryButton(
                  label: 'Bid again',
                  icon: Icons.refresh,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: 12),
              ],
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Back to auction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
