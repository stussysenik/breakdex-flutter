import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/providers.dart';
import '../settings_screen.dart' show colorSwatchGrid;

/// Preset palette for rating color customization.
const ratingPresetColors = [
  Color(0xFFDA1E28), // Red
  Color(0xFFFF6F00), // Amber
  Color(0xFF8E6A00), // Gold
  Color(0xFFE040FB), // Purple
  Color(0xFF198038), // Green
  Color(0xFF08BDBA), // Teal
  Color(0xFF2362A2), // Blue
  Color(0xFF6929C4), // Violet
];

class RatingColorsSection extends ConsumerWidget {
  const RatingColorsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final rc = ref.watch(ratingColorsProvider);

    final entries = [
      ('AGAIN', 'again', rc.again, Icons.close_rounded),
      ('HARD', 'hard', rc.hard, Icons.remove_rounded),
      ('GOOD', 'good', rc.good, Icons.check_rounded),
      ('EASY', 'easy', rc.easy, Icons.star_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Rating Buttons',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(ratingColorsProvider.notifier).resetAll();
              },
              child: Text(
                'Reset',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (final (label, key, color, icon) in entries)
          RatingColorRow(
            label: label,
            colorKey: key,
            currentColor: color,
            icon: icon,
          ),
      ],
    );
  }
}

class RatingColorRow extends ConsumerWidget {
  const RatingColorRow({
    super.key,
    required this.label,
    required this.colorKey,
    required this.currentColor,
    required this.icon,
  });

  final String label;
  final String colorKey;
  final Color currentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () => _showColorPicker(context, ref),
        child: Row(
          children: [
            Icon(icon, size: 18, color: currentColor),
            const SizedBox(width: 10),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              '#${currentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$label Color'),
        content: colorSwatchGrid(
          colors: ratingPresetColors,
          selected: currentColor,
          size: 40,
          onSelected: (c) {
            HapticFeedback.mediumImpact();
            ref.read(ratingColorsProvider.notifier).setColor(colorKey, c);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
