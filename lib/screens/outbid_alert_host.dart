import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/my_bids_state.dart';
import '../theme/app_theme.dart';
import '../widgets/item_card.dart';
import '../widgets/primary_button.dart';
import 'item_detail_screen.dart';

/// Screen 11: shows the outbid alert on top of whatever screen is open.
/// Sits above the app's screens and listens to [MyBidsState].
class OutbidAlertHost extends StatefulWidget {
  const OutbidAlertHost({super.key, required this.child});

  final Widget child;

  @override
  State<OutbidAlertHost> createState() => _OutbidAlertHostState();
}

class _OutbidAlertHostState extends State<OutbidAlertHost> {
  late final MyBidsState _state;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    _state = context.read<MyBidsState>()..addListener(_check);
  }

  @override
  void dispose() {
    _state.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (_showing || _state.pendingAlert == null) return;
    // Never open a dialog from inside a notify; wait for the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
  }

  Future<void> _show() async {
    final entry = _state.pendingAlert;
    if (!mounted || _showing || entry == null) return;
    _showing = true;
    final view = await showDialog<bool>(
      context: context,
      builder: (_) => _OutbidDialog(entry: entry),
    );
    _state.dismissAlert();
    _showing = false;
    if (view == true && mounted) {
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ItemDetailScreen(itemId: entry.item.id)));
    }
    _check(); // another alert may have queued up meanwhile
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _OutbidDialog extends StatelessWidget {
  const _OutbidDialog({required this.entry});

  final MyBidEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final item = entry.item;
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.trending_up, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text('You\'ve been outbid',
                textAlign: TextAlign.center, style: text.titleLarge),
            const SizedBox(height: 8),
            Text(item.title,
                textAlign: TextAlign.center, style: text.titleMedium),
            const SizedBox(height: 12),
            Text(
              'Someone bid ${ItemCard.formatRwf(item.highestBid)}. '
              'Your top bid was ${ItemCard.formatRwf(entry.myTopBid)}.',
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Bid again',
              icon: Icons.gavel_rounded,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }
}
