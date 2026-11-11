import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/item_card.dart';

/// Screen 13: auction ended. Same data, different view per person:
/// trophy + confetti for the winner, a plain closed state for everyone else.
class AuctionEndedPanel extends StatelessWidget {
  const AuctionEndedPanel({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthState>().uid;
    final text = Theme.of(context).textTheme;
    final won = item.isWonBy(uid);
    final isSeller = uid == item.sellerId;
    final price = ItemCard.formatRwf(item.highestBid);
    final early = item.boughtNow ? ' (bought with Buy Now)' : '';

    final String title;
    final String body;
    if (won) {
      title = 'You won!';
      body = 'You won this auction for $price$early. The seller will be in touch.';
    } else if (item.isSold) {
      title = 'Auction ended';
      body = isSeller
          ? 'Sold to ${item.highestBidderName ?? 'the highest bidder'} for $price$early.'
          : 'Sold to ${item.highestBidderName ?? 'another bidder'} for $price$early.';
    } else {
      title = 'Auction ended';
      body = isSeller
          ? 'No one bid on your item.'
          : 'This item received no bids.';
    }

    return Stack(
      children: [
        Card(
          color: won ? AppColors.accentSoft : null,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  won ? Icons.emoji_events_rounded : Icons.lock_clock_outlined,
                  size: won ? 72 : 48,
                  color: won ? const Color(0xFFF2A900) : AppColors.tertiary,
                ),
                const SizedBox(height: 12),
                Text(title, style: text.headlineMedium),
                const SizedBox(height: 8),
                Text(body, textAlign: TextAlign.center, style: text.bodyLarge),
              ],
            ),
          ),
        ),
        if (won) const Positioned.fill(child: ConfettiBurst(height: 260)),
      ],
    );
  }
}
