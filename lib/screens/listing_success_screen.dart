import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/item_card.dart';
import '../widgets/primary_button.dart';
import 'sale_detail_screen.dart';

/// Screen 15: shown after a listing is published.
class ListingSuccessScreen extends StatelessWidget {
  const ListingSuccessScreen({
    super.key,
    required this.itemId,
    required this.title,
    required this.startingPrice,
    required this.endTime,
    this.imageUrl,
  });

  final String itemId;
  final String title;
  final int startingPrice;
  final DateTime endTime;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: ConfettiBurst(height: 300)),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Icon(Icons.check_circle,
                      size: 80, color: AppColors.success),
                  const SizedBox(height: 16),
                  Text('Your item is live!',
                      textAlign: TextAlign.center,
                      style: text.headlineMedium),
                  const SizedBox(height: 8),
                  Text('Bidders can now see it and start bidding.',
                      textAlign: TextAlign.center, style: text.bodyMedium),
                  const SizedBox(height: 24),
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: imageUrl == null
                              ? Container(
                                  color: AppColors.field,
                                  child: const Icon(Icons.image_outlined,
                                      color: AppColors.tertiary))
                              : Image.network(imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                      color: AppColors.field,
                                      child: const Icon(
                                          Icons.broken_image_outlined,
                                          color: AppColors.tertiary))),
                        ),
                      ),
                      title: Text(title,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle:
                          Text('Starting at ${ItemCard.formatRwf(startingPrice)}'),
                    ),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: 'View my listing',
                    icon: Icons.arrow_forward,
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => SaleDetailScreen(itemId: itemId)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to auctions'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
