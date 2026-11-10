import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../state/auction_state.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/item_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/status_tag.dart';
import 'item_detail_screen.dart';
import 'list_item_screen.dart';

/// Screen 6: live auctions. Four states: loading, error, empty, data.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuctionState>();
    final text = Theme.of(context).textTheme;

    Widget body;
    if (state.loading) {
      body = const LoadingView();
    } else if (state.error != null) {
      body = ErrorView(message: state.error!, onRetry: state.start);
    } else if (!state.hasAny) {
      body = const EmptyView(
        icon: Icons.gavel,
        message: 'No live auctions yet.\nTap + Sell to list the first item.',
      );
    } else if (state.filtered.isEmpty) {
      body = const EmptyView(
        icon: Icons.search_off,
        message: 'No auctions match your search.',
      );
    } else {
      final items = state.filtered;
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, i) => _card(context, items[i]),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/logo.png',
                  width: 32, height: 32),
            ),
            const SizedBox(width: 10),
            const Text('Bidly'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: context.read<AuthState>().logOut,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Sell'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ListItemScreen()),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Curated Collectibles\n& Electronics',
                    style: text.headlineMedium),
                const SizedBox(height: 12),
                TextField(
                  onChanged: state.setQuery,
                  decoration: const InputDecoration(
                    hintText: 'Search treasures, books, gadgets',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (f, label) in const [
                      (AuctionFilter.all, 'All'),
                      (AuctionFilter.endingSoon, 'Ending Soon'),
                      (AuctionFilter.buyNow, 'Buy Now Available'),
                    ])
                      ChoiceChip(
                        label: Text(label),
                        selected: state.filter == f,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                            color: state.filter == f
                                ? Colors.white
                                : AppColors.text),
                        onSelected: (_) => state.setFilter(f),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, Item item) {
    return ItemCard(
      title: item.title,
      currentBid: item.highestBid,
      endTime: item.endTime,
      imageUrl: item.imageUrl,
      bidCount: item.bidCount,
      tag: item.hasBuyNow ? const StatusTag('Buy Now') : null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
      ),
    );
  }
}
