import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/widgets/color_setting_tile.dart';

/// A few card-fill starting points; the editor still allows any ARGB value.
const _reviewFillPresets = [
  Color(0xFFFFFFFF), // Classic white (default)
  Color(0xFFF5EFE0), // Warm paper
  Color(0xFFE8F0F2), // Cool mist
  Color(0xFF1C1C1E), // Charcoal
  Color(0xFF12303A), // Deep teal
  Color(0xFF2A1A2E), // Plum
];

const _defaultReviewFill = Color(0xFFFFFFFF);

/// Settings control for the review card's frame fill. Reuses the shared
/// arbitrary color editor (`showColorEditorDialog`) — the same one accent and
/// rating colors use — rather than duplicating a picker. Applies live.
class ReviewFillColorSection extends ConsumerWidget {
  const ReviewFillColorSection({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final fill = ref.watch(reviewFillColorProvider);
    final effective = fill ?? _defaultReviewFill;

    return ColorSettingTile(
      title: 'Review Card Fill',
      subtitle: fill == null ? 'Default (white)' : formatColorHex(fill),
      color: effective,
      onTap: () async {
        final selected = await showColorEditorDialog(
          context,
          initialColor: effective,
          title: 'Review Card Fill',
          subtitle: 'Tint the review card frame. Applies to your next card.',
          presets: _reviewFillPresets,
        );
        if (selected != null) {
          await ref.read(reviewFillColorProvider.notifier).set(selected);
        }
      },
    );
  }
}
