import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/design/color_catalogue.dart';
import 'package:breakdex/core/design/color_packs.dart';
import 'package:breakdex/core/design/color_roles.dart';
import 'package:breakdex/core/design/contrast.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/shared/widgets/color_setting_tile.dart';

/// Full-screen colour-pack management panel.
///
/// Route: `/settings-panel/color-packs`, built with [settingsSectionPage].
class ColorPacksScreen extends ConsumerWidget {
  const ColorPacksScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final currentPack = ref.watch(colorPackProvider);
    final palette = ref.watch(accessiblePaletteProvider);
    final overrides = ref.watch(colorRoleOverridesProvider);
    final isOverriding = palette != AccessiblePalette.standard;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenEdge),
          children: [
            _BackHeader(title: l10n.setColorPacksRouteTitle),
            const SizedBox(height: AppSpacing.lg),
            if (isOverriding) _AccessibleOverrideBanner(palette: palette.displayName),
            Text(
              l10n.setColorPacksSubtitle,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _CurrentPackPreview(currentPack: currentPack),
            const SizedBox(height: AppSpacing.xl),
            for (final collection in colorCatalogue.collections) ...[
              _CollectionSection(collection: collection, selected: currentPack),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (overrides.isNotEmpty)
              _OverridesSection(
                overrides: overrides,
                onResetAll: () =>
                    ref.read(colorRoleOverridesProvider.notifier).clearAll(),
              ),
          ],
        ),
      ),
    );
  }
}

class _BackHeader extends StatelessWidget {
  const _BackHeader({required this.title});

  final String title;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      identifier: 'color-packs-back',
      label: 'Back',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.pop(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              AppIconView(AppIcon.back, color: colorScheme.secondary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessibleOverrideBanner extends StatelessWidget {
  const _AccessibleOverrideBanner({required this.palette});

  final String palette;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          AppIconView(AppIcon.info, size: 18, color: colorScheme.tertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              AppLocalizations.of(context).setColorPacksAccessibleOverride,
              style: AppTypography.caption.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentPackPreview extends ConsumerWidget {
  const _CurrentPackPreview({required this.currentPack});

  final ColorPackId currentPack;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final semantic = AppSemanticTheme.of(context);
    final swatches = [
      colorScheme.surface,
      colorScheme.surfaceContainerHighest,
      colorScheme.primary,
      colorScheme.onPrimary,
      semantic.stateNew,
      semantic.stateLearning,
      semantic.stateMastery,
      semantic.actionAgain,
      semantic.actionHard,
      semantic.actionGood,
      semantic.actionEasy,
    ];
    final name = switch (currentPack) {
      ColorPackId.classic => l10n.setColorPacksDefaultName,
      ColorPackId.mono => l10n.setColorPacksMonoName,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.setColorPacksSelectPack,
          style: AppTypography.caption.copyWith(
            color: colorScheme.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          name,
          style: AppTypography.titleMedium.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final color in swatches)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.18),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CollectionSection extends StatelessWidget {
  const _CollectionSection({required this.collection, required this.selected});

  final ColorCollection collection;
  final ColorPackId selected;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final packs = collection.packs;
    if (packs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          collection.name,
          style: AppTypography.sectionHeader.copyWith(
            color: colorScheme.secondary,
          ),
        ),
        if (collection.description case final desc?) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            desc,
            style: AppTypography.caption.copyWith(color: colorScheme.secondary),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(packs.length, (final i) {
          final pack = packs[i];
          return Padding(
            padding: EdgeInsets.only(
              bottom: i < packs.length - 1 ? AppSpacing.sm : 0,
            ),
            child: _PackCard(pack: pack, isSelected: pack == selected),
          );
        }),
      ],
    );
  }
}

class _PackCard extends ConsumerWidget {
  const _PackCard({required this.pack, required this.isSelected});

  final ColorPackId pack;
  final bool isSelected;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final resolved = ResolvedColors.of(pack.pack, brightness);
    final roles = [
      AppColorRole.background,
      AppColorRole.card,
      AppColorRole.fill,
      AppColorRole.accent,
      AppColorRole.stateNew,
      AppColorRole.stateLearning,
      AppColorRole.stateMastery,
      AppColorRole.actionAgain,
      AppColorRole.actionHard,
      AppColorRole.actionGood,
      AppColorRole.actionEasy,
    ];

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.25)
          : colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => ref.read(colorPackProvider.notifier).set(pack),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.18),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _packName(l10n, pack),
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xxs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        for (final role in roles)
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: resolved[role],
                              borderRadius: BorderRadius.circular(AppRadius.xxs),
                              border: Border.all(
                                color: colorScheme.outline.withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                AppIconView(AppIcon.success, color: colorScheme.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverridesSection extends StatelessWidget {
  const _OverridesSection({
    required this.overrides,
    required this.onResetAll,
  });

  final Map<AppColorRole, Color> overrides;
  final VoidCallback onResetAll;

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.setColorPacksOverrideColor,
                style: AppTypography.sectionHeader.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ),
            TextButton(
              onPressed: onResetAll,
              child: Text(l10n.setColorPacksResetOverrides),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final entry in overrides.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _OverrideTile(
              role: entry.key,
              color: entry.value,
            ),
          ),
      ],
    );
  }
}

class _OverrideTile extends ConsumerWidget {
  const _OverrideTile({required this.role, required this.color});

  final AppColorRole role;
  final Color color;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = role.kind == AppColorRoleKind.ink
        ? colorScheme.surface
        : role.kind == AppColorRoleKind.signal
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surface;
    final threshold = role.kind == AppColorRoleKind.signal ? 3.0 : 4.5;
    final ratio = contrastRatio(color, bg);
    final passes = ratio >= threshold;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: () => _showOverrideDialog(context, ref, role),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.18),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  role.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              _ContrastBadge(passes: passes, ratio: ratio),
              const SizedBox(width: AppSpacing.sm),
              AppIconView(AppIcon.edit, size: 16, color: colorScheme.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContrastBadge extends StatelessWidget {
  const _ContrastBadge({required this.passes, required this.ratio});

  final bool passes;
  final double ratio;

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: passes
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '${passes ? l10n.setColorPacksContrastPass : l10n.setColorPacksContrastFail} '
        '${l10n.setColorPacksContrastRatio(ratio.toStringAsFixed(1))}',
        style: AppTypography.caption.copyWith(
          color: passes ? Colors.green : Colors.red,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// Opens the colour editor for a per-role override.
Future<void> _showOverrideDialog(
  final BuildContext context,
  final WidgetRef ref,
  final AppColorRole role,
) async {
  final overrides = ref.read(colorRoleOverridesProvider);
  final currentColor = overrides[role] ??
      ref.read(colorPackProvider).pack.resolve(
        role,
        Theme.of(context).brightness,
      );
  final l10n = AppLocalizations.of(context);

  final selected = await showColorEditorDialog(
    context,
    initialColor: currentColor,
    title: l10n.setColorPacksOverrideTitle(role.name),
    subtitle: l10n.setColorPacksOverrideSubtitle,
  );

  if (selected != null) {
    await ref.read(colorRoleOverridesProvider.notifier).set(role, selected);
  }
}

String _packName(final AppLocalizations l10n, final ColorPackId pack) {
  return switch (pack) {
    ColorPackId.classic => l10n.setColorPacksDefaultName,
    ColorPackId.mono => l10n.setColorPacksMonoName,
  };
}
