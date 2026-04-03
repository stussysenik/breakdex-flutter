import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/widgets/color_setting_tile.dart';

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
    final rc = ref.watch(ratingColorsProvider);

    final entries = [
      ('AGAIN', 'again', rc.again, Icons.close_rounded),
      ('HARD', 'hard', rc.hard, Icons.remove_rounded),
      ('GOOD', 'good', rc.good, Icons.check_rounded),
      ('EASY', 'easy', rc.easy, Icons.star_rounded),
    ];

    return Column(
      children: [
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ColorSettingTile(
        title: label,
        subtitle: formatColorHex(currentColor),
        color: currentColor,
        leading: Icon(icon, size: 18, color: currentColor),
        onTap: () => _showColorPicker(context, ref),
      ),
    );
  }

  Future<void> _showColorPicker(BuildContext context, WidgetRef ref) async {
    final selected = await showColorEditorDialog(
      context,
      initialColor: currentColor,
      title: '$label Color',
      subtitle: 'Choose any color for the $label rating button.',
      presets: ratingPresetColors,
    );
    if (selected == null) return;
    await ref.read(ratingColorsProvider.notifier).setColor(colorKey, selected);
  }
}
