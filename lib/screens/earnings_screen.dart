import 'package:fl_chart/fl_chart.dart';
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
import 'sale_detail_screen.dart';

/// Screen 19: total raised from sold items, plus RWF raised per day over
/// the last 7 days. Everything is computed from the seller's own items.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  Stream<List<Item>>? _stream;

  void _load() {
    final uid = context.read<AuthState>().uid;
    _stream = uid == null
        ? const Stream.empty()
        : context.read<AuctionState>().watchMine(uid);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// When the money was earned: the buy-now moment, else the deadline.
  static DateTime _soldAt(Item i) => (i.closedEarlyAt ?? i.endTime).toLocal();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: StreamBuilder<List<Item>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorView(
              message: 'Could not load your earnings. Please try again.',
              onRetry: () => setState(_load),
            );
          }
          if (!snap.hasData) return const LoadingView();

          final sold = snap.data!.where((i) => i.isSold).toList()
            ..sort((a, b) => _soldAt(b).compareTo(_soldAt(a)));
          if (sold.isEmpty) {
            return const EmptyView(
              icon: Icons.savings_outlined,
              message: 'No earnings yet.\nWhen an item sells, it shows up here.',
            );
          }
          final total = sold.fold<int>(0, (s, i) => s + i.highestBid);
          return _Content(sold: sold, total: total);
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.sold, required this.total});

  final List<Item> sold;
  final int total;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    // Last 7 calendar days, oldest first.
    final today = DateTime.now();
    final days = [
      for (var d = 6; d >= 0; d--)
        DateTime(today.year, today.month, today.day).subtract(Duration(days: d))
    ];
    final perDay = List<int>.filled(7, 0);
    for (final i in sold) {
      final t = _EarningsScreenState._soldAt(i);
      final day = DateTime(t.year, t.month, t.day);
      final idx = days.indexWhere((d) => d == day);
      if (idx >= 0) perDay[idx] += i.highestBid;
    }
    final maxY = perDay.reduce((a, b) => a > b ? a : b);
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL RAISED',
                  style: text.labelSmall?.copyWith(color: Colors.white70)),
              const SizedBox(height: 6),
              Text(ItemCard.formatRwf(total),
                  style: text.headlineLarge?.copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                '${sold.length} item(s) sold · average '
                '${ItemCard.formatRwf((total / sold.length).round())}',
                style: text.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Last 7 days', style: text.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 24, 20, 12),
            child: SizedBox(
              height: 220,
              child: maxY == 0
                  ? const Center(child: Text('Nothing sold in the last 7 days.'))
                  : BarChart(
                      BarChartData(
                        maxY: maxY * 1.2,
                        gridData: const FlGridData(drawVerticalLine: false),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (g, _, rod, _) => BarTooltipItem(
                              ItemCard.formatRwf(rod.toY.round()),
                              const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 44,
                              getTitlesWidget: (v, meta) {
                                if (v == meta.max || v == 0) {
                                  return const SizedBox.shrink();
                                }
                                final k = v >= 1000000
                                    ? '${(v / 1000000).toStringAsFixed(1)}M'
                                    : '${(v / 1000).round()}k';
                                return Text(k, style: text.bodySmall);
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) => Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                    weekdays[days[v.toInt()].weekday - 1],
                                    style: text.bodySmall),
                              ),
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < 7; i++)
                            BarChartGroupData(x: i, barRods: [
                              BarChartRodData(
                                toY: perDay[i].toDouble(),
                                width: 18,
                                color: AppColors.primary,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6)),
                              ),
                            ]),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Sales', style: text.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < sold.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  title: Text(sold[i].title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('To ${sold[i].highestBidderName ?? 'a bidder'}'),
                  trailing: Text(ItemCard.formatRwf(sold[i].highestBid),
                      style: text.titleMedium),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SaleDetailScreen(itemId: sold[i].id))),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
