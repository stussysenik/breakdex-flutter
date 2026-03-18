import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/providers.dart';
import '../settings_screen.dart' show colorSwatchGrid;

/// Curated accent color palette for global UI personalization.
const accentPresetColors = [
  Color(0xFF2362A2), // Default blue
  Color(0xFF6929C4), // Violet
  Color(0xFF8A3FFC), // Purple
  Color(0xFFDA1E28), // Red
  Color(0xFFFF6F00), // Amber
  Color(0xFF198038), // Green
  Color(0xFF08BDBA), // Teal
  Color(0xFF33B1FF), // Sky blue
  Color(0xFFE040FB), // Magenta
  Color(0xFFFF7EB6), // Pink
  Color(0xFFD4A017), // Gold
  Color(0xFFA2AAB4), // Neutral
];

class AccentColorSection extends ConsumerWidget {
  const AccentColorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = ref.watch(accentColorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Accent Color',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(accentColorProvider.notifier).reset();
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
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '#${accent.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        colorSwatchGrid(
          colors: accentPresetColors,
          selected: accent,
          size: 36,
          onSelected: (c) {
            HapticFeedback.mediumImpact();
            ref.read(accentColorProvider.notifier).set(c);
          },
        ),
      ],
    );
  }
}
