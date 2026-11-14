import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/auction_state.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/item_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/status_tag.dart';
import 'item_detail_screen.dart';

/// Screen 7: search and filters. All the filtering is the `filtered` getter
/// in [AuctionState], applied to the list already held in memory.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _query;
  late final TextEditingController _min;
  late final TextEditingController _max;
  String? _rangeError;

  @override
  void initState() {
    super.initState();
    final s = context.read<AuctionState>();
    _query = TextEditingController(text: s.query);
    _min = TextEditingController(text: s.minPrice?.toString() ?? '');
    _max = TextEditingController(text: s.maxPrice?.toString() ?? '');
  }

  @override
  void dispose() {
    _query.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _applyRange() {
    final min = int.tryParse(_min.text.trim());
    final max = int.tryParse(_max.text.trim());
    if (min != null && max != null && min > max) {
      setState(() => _rangeError = 'Minimum must not be above maximum.');
      return; // keep the last valid range applied
    }
    setState(() => _rangeError = null);
    context.read<AuctionState>().setPriceRange(min, max);
  }

  void _clear(AuctionState s) {
    s.clearFilters();
    _query.clear();
    _min.clear();
    _max.clear();
    setState(() => _rangeError = null);
  }

  static String _sortLabel(AuctionSort s) => switch (s) {
        AuctionSort.endingSoon => 'Ending soonest',
        AuctionSort.priceLow => 'Price: low to high',
        AuctionSort.priceHigh => 'Price: high to low',
        AuctionSort.mostBids => 'Most bids',
      };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuctionState>();
    final text = Theme.of(context).textTheme;
    final results = state.filtered;

    Widget body;
    if (state.loading) {
      body = const LoadingView();
    } else if (state.error != null) {
      body = ErrorView(message: state.error!, onRetry: state.start);
    } else if (!state.hasAny) {
      body = const EmptyView(
          icon: Icons.gavel, message: 'No live auctions to search yet.');
    } else if (results.isEmpty) {
      body = EmptyView(
        icon: Icons.search_off,
        message: 'No auctions match your search.\nTry removing a filter.',
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: results.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final item = results[i];
          return ItemCard(
            title: item.title,
            currentBid: item.highestBid,
            endTime: item.endTime,
            imageUrl: item.imageUrl,
            bidCount: item.bidCount,
            tag: item.hasBuyNow ? const StatusTag('Buy Now') : null,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ItemDetailScreen(itemId: item.id))),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          if (state.hasActiveFilters)
            TextButton(onPressed: () => _clear(state), child: const Text('Clear')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _query,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: state.setQuery,
                  decoration: InputDecoration(
                    hintText: 'Search treasures, books, gadgets',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _query.clear();
                              state.setQuery('');
                            },
                          ),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _min,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => _applyRange(),
                        decoration: const InputDecoration(
                            hintText: 'Min RWF',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _max,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => _applyRange(),
                        decoration: const InputDecoration(
                            hintText: 'Max RWF',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12)),
                      ),
                    ),
                  ],
                ),
                if (_rangeError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 8),
                    child: Text(_rangeError!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12)),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('${results.length} result(s)', style: text.bodySmall),
                    const Spacer(),
                    DropdownButton<AuctionSort>(
                      value: state.sort,
                      underline: const SizedBox.shrink(),
                      onChanged: (v) {
                        if (v != null) state.setSort(v);
                      },
                      items: [
                        for (final s in AuctionSort.values)
                          DropdownMenuItem(value: s, child: Text(_sortLabel(s))),
                      ],
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
}
