import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum TagKind { neutral, live, winning, outbid, sold }

/// Small pill label: LIVE, WINNING, OUTBID, SOLD...
class StatusTag extends StatelessWidget {
  const StatusTag(this.label, {super.key, this.kind = TagKind.neutral});

  final String label;
  final TagKind kind;

  (Color bg, Color fg) get _colors => switch (kind) {
        TagKind.live => (AppColors.danger, Colors.white),
        TagKind.winning => (AppColors.success, Colors.white),
        TagKind.outbid => (AppColors.danger.withValues(alpha: 0.12), AppColors.danger),
        TagKind.sold => (AppColors.primary, Colors.white),
        TagKind.neutral => (AppColors.accentSoft, AppColors.secondary),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
