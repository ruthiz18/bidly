import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../repositories/bid_repository.dart';
import '../state/auction_state.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/item_card.dart';
import '../widgets/primary_button.dart';
import 'bid_error_screen.dart';

/// Bid input + Place Bid button (screen 8) and the confirmation sheet
/// (screen 9). Rejections go to [BidErrorScreen] (screen 10).
class BidSection extends StatefulWidget {
  const BidSection({super.key, required this.item});

  final Item item;

  @override
  State<BidSection> createState() => _BidSectionState();
}

class _BidSectionState extends State<BidSection> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _fieldError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onPlaceBid() async {
    final item = widget.item;
    final amount = int.tryParse(_controller.text.trim());
    if (amount == null) {
      setState(() => _fieldError = 'Enter your bid amount');
      return;
    }
    if (amount < item.minimumBid) {
      setState(() => _fieldError =
          'Bid at least ${ItemCard.formatRwf(item.minimumBid)}');
      return;
    }
    setState(() => _fieldError = null);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
      ),
      builder: (_) => _ConfirmSheet(item: item, amount: amount),
    );
    if (confirmed != true || !mounted) return;
    await _submit(amount);
  }

  Future<void> _onBuyNow() async {
    final item = widget.item;
    final price = item.buyNowPrice;
    if (price == null) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
      ),
      builder: (_) => _ConfirmSheet(item: item, amount: price, buyNow: true),
    );
    if (confirmed != true || !mounted) return;
    await _submit(price, buyNow: true);
  }

  Future<void> _submit(int amount, {bool buyNow = false}) async {
    final auth = context.read<AuthState>();
    final state = context.read<AuctionState>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final uid = auth.uid;
    if (uid == null) return;

    setState(() => _busy = true);
    try {
      final name = auth.user?.name ?? 'Bidder';
      if (buyNow) {
        await state.buyNow(
            itemId: widget.item.id, buyerId: uid, buyerName: name);
      } else {
        await state.placeBid(
          itemId: widget.item.id,
          bidderId: uid,
          bidderName: name,
          amount: amount,
        );
      }
      if (!mounted) return;
      _controller.clear();
      messenger.showSnackBar(SnackBar(
          content: Text(buyNow
              ? 'You bought it for ${ItemCard.formatRwf(amount)}!'
              : 'Bid of ${ItemCard.formatRwf(amount)} placed. You lead!')));
    } on BidRejectedException catch (e) {
      if (!mounted) return;
      final retry = await navigator.push<bool>(MaterialPageRoute(
        builder: (_) => BidErrorScreen(
          itemId: widget.item.id,
          rejection: e,
          attemptedAmount: amount,
        ),
      ));
      if (!mounted) return;
      // "Bid again": prefill with the new minimum.
      _controller.text =
          retry == true ? widget.item.minimumBid.toString() : '';
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
          content: Text('Could not place your bid. Check your connection.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final text = Theme.of(context).textTheme;
    final uid = context.watch<AuthState>().uid;

    // Requirement 5: closed is computed from endTime/boughtNow, no job needed.
    if (item.isClosed) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('YOUR BID', style: text.labelSmall),
              const SizedBox(height: 8),
              const TextField(
                enabled: false,
                decoration: InputDecoration(hintText: 'Bidding closed'),
              ),
              const SizedBox(height: 16),
              const PrimaryButton(label: 'Bidding closed', onPressed: null),
            ],
          ),
        ),
      );
    }

    if (uid == item.sellerId) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('This is your listing. Sellers cannot bid.',
              style: text.bodyMedium),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('YOUR BID', style: text.labelSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) {
                if (_fieldError != null) setState(() => _fieldError = null);
              },
              decoration: InputDecoration(
                // Show the floor up front so users rarely hit the error.
                hintText: 'Min ${ItemCard.formatRwf(item.minimumBid)}',
                suffixText: 'RWF',
                errorText: _fieldError,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Place Bid',
              icon: Icons.gavel_rounded,
              loading: _busy,
              onPressed: _onPlaceBid,
            ),
            if (item.hasBuyNow && item.highestBid < item.buyNowPrice!) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy ? null : _onBuyNow,
                child: Text('Buy Now for ${ItemCard.formatRwf(item.buyNowPrice!)}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Screen 9: confirm before the bid is sent.
class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet(
      {required this.item, required this.amount, this.buyNow = false});

  final Item item;
  final int amount;
  final bool buyNow;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(buyNow ? 'Confirm Buy Now' : 'Confirm your bid',
                style: text.titleLarge),
            const SizedBox(height: 16),
            Text(item.title, style: text.titleMedium),
            const SizedBox(height: 8),
            Text(buyNow ? 'You pay' : 'Your bid', style: text.labelSmall),
            Text(ItemCard.formatRwf(amount), style: text.headlineMedium),
            const SizedBox(height: 4),
            Text('Current highest: ${ItemCard.formatRwf(item.highestBid)}',
                style: text.bodyMedium),
            const SizedBox(height: 4),
            Text(
                buyNow
                    ? 'This ends the auction immediately.'
                    : 'A bid cannot be withdrawn once placed.',
                style: text.bodyMedium),
            const SizedBox(height: 20),
            PrimaryButton(
              label: buyNow ? 'Confirm Buy Now' : 'Confirm Bid',
              onPressed: () => Navigator.of(context).pop(true),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
