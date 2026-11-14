import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../state/auction_state.dart';
import '../state/auth_state.dart';
import '../state/my_bids_state.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import 'earnings_screen.dart';

/// Screen 5: profile and settings. The two stats are computed, never stored:
/// items sold from the seller's own items, auctions won from My Bids.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Stream<List<Item>>? _sales;
  String? _uid;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final bids = context.watch<MyBidsState>();
    final text = Theme.of(context).textTheme;
    final user = auth.user;
    final uid = auth.uid;
    if (uid == null) return const SizedBox.shrink();
    if (_sales == null || _uid != uid) {
      _uid = uid;
      _sales = context.read<AuctionState>().watchMine(uid);
    }

    final name = (user?.name.isNotEmpty ?? false) ? user!.name : 'Bidly member';
    final role = user?.role == 'seller' ? 'Seller' : 'Buyer / Bidder';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary,
              child: Text(name[0].toUpperCase(),
                  style: text.headlineLarge?.copyWith(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          Text(name, textAlign: TextAlign.center, style: text.headlineMedium),
          if (user != null && user.email.isNotEmpty)
            Text(user.email, textAlign: TextAlign.center, style: text.bodyMedium),
          const SizedBox(height: 8),
          Center(
            child: Chip(
              avatar: Icon(
                  user?.role == 'seller' ? Icons.sell_outlined : Icons.gavel,
                  size: 16),
              label: Text(role),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<List<Item>>(
                  stream: _sales,
                  builder: (context, snap) => _StatCard(
                    icon: Icons.sell_outlined,
                    label: 'Items sold',
                    value: snap.hasError
                        ? '–'
                        : snap.hasData
                            ? '${snap.data!.where((i) => i.isSold).length}'
                            : '…',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events_outlined,
                  label: 'Auctions won',
                  value: bids.error != null
                      ? '–'
                      : bids.loading
                          ? '…'
                          : '${bids.won.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.savings_outlined),
                  title: const Text('Earnings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const EarningsScreen())),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Member since'),
                  trailing: Text(user?.createdAt == null
                      ? '–'
                      : formatDateTime(user!.createdAt).split(',').first),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.logout, color: AppColors.danger),
                  title: const Text('Log out',
                      style: TextStyle(color: AppColors.danger)),
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Log out?'),
                        content: const Text(
                            'You will need to sign in again to bid or sell.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Log out')),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      await context.read<AuthState>().logOut();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.secondary),
            const SizedBox(height: 8),
            Text(value, style: text.headlineMedium),
            Text(label, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}
