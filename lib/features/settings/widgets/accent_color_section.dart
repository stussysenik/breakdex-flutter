import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/providers.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/shared/widgets/color_setting_tile.dart';

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
  Widget build(final BuildContext context, final WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    final l10n = AppLocalizations.of(context);

    return ColorSettingTile(
      title: l10n.setAccentColorLabel,
      subtitle: formatColorHex(accent),
      color: accent,
      onTap: () async {
        final selected = await showColorEditorDialog(
          context,
          initialColor: accent,
          title: l10n.setAccentColorLabel,
          subtitle: l10n.setAccentEditorSubtitle,
          presets: accentPresetColors,
        );
        if (selected != null) {
          await ref.read(accentColorProvider.notifier).set(selected);
        }
      },
    );
  }
}
