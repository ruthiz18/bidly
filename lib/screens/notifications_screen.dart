import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/my_bids_state.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/item_card.dart';
import '../widgets/loading_view.dart';
import 'item_detail_screen.dart';

/// Screen 4: notifications, derived from My Bids (no Cloud Function).
/// Outbid on a live auction first, then auctions the user has won.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MyBidsState>();

    Widget body;
    if (state.error != null) {
      body = ErrorView(message: state.error!, onRetry: state.retry);
    } else if (state.loading) {
      body = const LoadingView();
    } else {
      final outbid = state.outbid;
      final won = state.won;
      if (outbid.isEmpty && won.isEmpty) {
        body = const EmptyView(
          icon: Icons.notifications_none,
          message: 'You\'re all caught up.\nOutbid alerts and wins show here.',
        );
      } else {
        body = ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final e in outbid)
              _tile(
                context,
                e,
                icon: Icons.trending_up,
                color: AppColors.danger,
                title: 'You\'ve been outbid',
                message:
                    '${e.item.title}: now ${ItemCard.formatRwf(e.item.highestBid)}'
                    ' (your top bid ${ItemCard.formatRwf(e.myTopBid)}).',
              ),
            for (final e in won)
              _tile(
                context,
                e,
                icon: Icons.emoji_events_outlined,
                color: AppColors.success,
                title: 'You won!',
                message:
                    '${e.item.title} is yours for ${ItemCard.formatRwf(e.item.highestBid)}.',
              ),
          ],
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: body,
    );
  }

  Widget _tile(
    BuildContext context,
    MyBidEntry e, {
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(message),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ItemDetailScreen(itemId: e.item.id))),
        ),
      ),
    );
  }
}
