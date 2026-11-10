import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'countdown_text.dart';
import 'status_tag.dart';

/// Auction card used on Home, Search, My Bids and My Sales.
/// Takes plain values (not a model) so it can be built before models exist.
class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.title,
    required this.currentBid,
    required this.endTime,
    this.imageUrl,
    this.bidCount,
    this.tag,
    this.onTap,
    this.action,
  });

  final String title;
  final int currentBid;
  final DateTime endTime;
  final String? imageUrl;
  final int? bidCount;
  final StatusTag? tag;
  final VoidCallback? onTap;

  /// Optional widget at the bottom right, e.g. a "View & Bid" button.
  final Widget? action;

  static String formatRwf(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '$buf RWF';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: imageUrl == null
                      ? Container(
                          color: AppColors.field,
                          child: const Icon(Icons.image_outlined,
                              size: 40, color: AppColors.tertiary),
                        )
                      : Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.field,
                            child: const Icon(Icons.broken_image_outlined,
                                color: AppColors.tertiary),
                          ),
                        ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Row(children: [
                    if (tag != null) ...[tag!, const SizedBox(width: 6)],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: CountdownText(
                        endTime: endTime,
                        style: text.labelSmall?.copyWith(color: Colors.white),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Current bid', style: text.bodySmall),
                            Text(formatRwf(currentBid), style: text.titleLarge),
                            if (bidCount != null)
                              Text('$bidCount bids', style: text.bodySmall),
                          ],
                        ),
                      ),
                      ?action,
                    ],
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
