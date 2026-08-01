import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/dev/basis_controls.dart';
import 'package:breakdex/dev/preview_gallery_service.dart';
import 'package:breakdex/dev/preview_harness.dart';
import 'package:breakdex/dev/primitives_catalogue.dart';
import 'package:breakdex/features/add/add_screen.dart';
import 'package:breakdex/features/battle/battle_screen.dart';
import 'package:breakdex/features/breakdex/breakdex_screen.dart';
import 'package:breakdex/features/combo_detail/combo_detail_screen.dart';
import 'package:breakdex/features/combos/combos_screen.dart';
import 'package:breakdex/features/flow/flow_screen.dart';
import 'package:breakdex/features/lab/lab_detail_screen.dart';
import 'package:breakdex/features/lab/lab_screen.dart';
import 'package:breakdex/features/move_category/move_category_screen.dart';
import 'package:breakdex/features/move_detail/move_detail_screen.dart';
import 'package:breakdex/features/move_list/move_list_screen.dart';
import 'package:breakdex/features/settings/settings_screen.dart';
import 'package:breakdex/features/stats/stats_screen.dart';

final class DevPreviewGallery extends ConsumerWidget {
  const DevPreviewGallery({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final themeMode = ref.watch(previewGalleryThemeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final theme = isDark ? AppTheme.dark() : AppTheme.light();

    return Theme(
      data: theme,
      child: DevBasisScope(
        child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _GalleryTitle(
                isDark: isDark,
                onBrightnessChanged: (final v) =>
                    ref.read(previewGalleryThemeProvider.notifier).state = v
                    ? ThemeMode.dark
                    : ThemeMode.light,
              ),
              DevBasisControls(),
              _SectionLabel(label: 'Home'),
              _PreviewCard(label: 'BreakdexScreen', child: BreakdexScreen()),
              _PreviewCard(
                label: 'MoveCategoryScreen',
                child: MoveCategoryScreen(),
              ),
              _PreviewCard(label: 'MoveListScreen', child: MoveListScreen()),
              _PreviewCard(
                label: 'MoveDetailScreen',
                child: MoveDetailScreen(moveId: PreviewSeed.moveId),
              ),
              SizedBox(height: AppSpacing.lg),
              _SectionLabel(label: 'Combos & Flow'),
              _PreviewCard(label: 'CombosScreen', child: CombosScreen()),
              _PreviewCard(
                label: 'ComboDetailScreen',
                child: ComboDetailScreen(comboId: PreviewSeed.comboId),
              ),
              _PreviewCard(label: 'FlowScreen', child: FlowScreen()),
              SizedBox(height: AppSpacing.lg),
              _SectionLabel(label: 'Review & Stats'),
              _PreviewCard(label: 'StatsScreen', child: StatsScreen()),
              _PreviewCard(label: 'LabScreen', child: LabScreen()),
              _PreviewCard(
                label: 'LabDetailScreen',
                child: LabDetailScreen(labId: PreviewSeed.labId),
              ),
              SizedBox(height: AppSpacing.lg),
              _SectionLabel(label: 'Other'),
              _PreviewCard(label: 'AddScreen', child: AddScreen()),
              _PreviewCard(label: 'BattleScreen', child: BattleScreen()),
              _PreviewCard(label: 'SettingsScreen', child: SettingsScreen()),
              SizedBox(height: AppSpacing.lg),
              _SectionLabel(label: 'Primitives'),
              DevPrimitivesCatalogue(),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

/// The gallery's own label, in the content — not a header band.
///
/// Every card below renders a *framed* screen, so the gallery is the wall the
/// pictures hang on: a band here would be a second frame over the framed. That
/// is `preview_harness.dart`'s ruling, and it binds the same way — a frameless
/// surface may own a `Scaffold` and may never own an `AppBar`.
class _GalleryTitle extends StatelessWidget {
  const _GalleryTitle({
    required this.isDark,
    required this.onBrightnessChanged,
  });

  final bool isDark;
  final ValueChanged<bool> onBrightnessChanged;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text('Preview Gallery', style: theme.textTheme.titleLarge),
          ),
          Text(isDark ? 'Dark' : 'Light', style: theme.textTheme.labelMedium),
          Switch(value: isDark, onChanged: onBrightnessChanged),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
        left: AppSpacing.xxs,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xxs,
              bottom: AppSpacing.xxs,
            ),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              height: 420,
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: AbsorbPointer(absorbing: true, child: child),
            ),
          ),
        ],
      ),
    );
  }
}
