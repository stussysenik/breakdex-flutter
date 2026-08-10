import 'package:flutter/material.dart';

import 'package:breakdex/core/design/color_packs.dart';
import 'package:breakdex/core/design/color_roles.dart';
import 'package:breakdex/core/design/depth.dart';
import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/shared/widgets/app_screen.dart';

/// A live, token-pure reference for the whole design system.
///
/// Every sample resolves from the runtime constants — a token value drifting
/// from its rendered preview is immediately visible. The variant rail flips
/// brightness × accessibility palette and the color region re-renders in place,
/// so the whole system is sign-off-able in one sitting.
///
/// Resolution mirrors `AppTheme._build`: `pack → brightness → accessibility
/// overlay`, the overlay last and winning on signal roles. The default
/// [ColorPackId.classic] pack is used throughout — this page demonstrates the
/// system, it does not let you retheme it.
class DesignSystemShowcaseScreen extends StatefulWidget {
  const DesignSystemShowcaseScreen({super.key});

  @override
  State<DesignSystemShowcaseScreen> createState() =>
      _DesignSystemShowcaseScreenState();
}

class _DesignSystemShowcaseScreenState
    extends State<DesignSystemShowcaseScreen> {
  Brightness _brightness = Brightness.light;
  AccessiblePalette _palette = AccessiblePalette.standard;

  /// Axis 1 + 2 + 3, mirroring `AppTheme._build`. The classic pack at the
  /// chosen brightness, then the accessibility overlay replacing signal roles.
  Color _resolve(AppColorRole role) {
    final colors = ResolvedColors.of(ColorPackId.classic.pack, _brightness);
    if (_palette == AccessiblePalette.standard ||
        role.kind != AppColorRoleKind.signal) {
      return colors[role];
    }
    final semantic = switch (_palette) {
      AccessiblePalette.deuteranopia => AppSemanticTheme.deuteranopia,
      AccessiblePalette.monochrome =>
        AppSemanticTheme.ink(colors[AppColorRole.text]),
      AccessiblePalette.standard => null,
    };
    return switch (role) {
      AppColorRole.stateNew => semantic!.stateNew,
      AppColorRole.stateLearning => semantic!.stateLearning,
      AppColorRole.stateMastery => semantic!.stateMastery,
      AppColorRole.actionAgain => semantic!.actionAgain,
      AppColorRole.actionHard => semantic!.actionHard,
      AppColorRole.actionGood => semantic!.actionGood,
      AppColorRole.actionEasy => semantic!.actionEasy,
      AppColorRole.error => semantic!.actionAgain,
      _ => colors[role],
    };
  }

  @override
  Widget build(final BuildContext context) {
    return AppScreen(
      title: 'Design System',
      pinned: _VariantRail(
        brightness: _brightness,
        palette: _palette,
        onBrightness: (final b) => setState(() => _brightness = b),
        onPalette: (final p) => setState(() => _palette = p),
      ),
      children: [
        _ColorRegion(resolve: _resolve, brightness: _brightness),
        const _TypographyRegion(),
        const _SpacingRadiusRegion(),
        _DepthShadowsRegion(brightness: _brightness),
        const _LayoutRegion(),
        const _MotionRegion(),
        // Reserve the nav-band inset so the last region clears band 4.
        const SizedBox(height: AppLayout.scrollBottomInset),
      ],
    );
  }
}

/// The one control on the page: brightness × palette. Pinned directly under
/// the header band (Face Law rule 2 — one primary control), it stays put while
/// the color region scrolls and re-renders beneath it.
class _VariantRail extends StatelessWidget {
  const _VariantRail({
    required this.brightness,
    required this.palette,
    required this.onBrightness,
    required this.onPalette,
  });

  final Brightness brightness;
  final AccessiblePalette palette;
  final ValueChanged<Brightness> onBrightness;
  final ValueChanged<AccessiblePalette> onPalette;

  @override
  Widget build(final BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Segmented<Brightness>(
          options: const [
            (Brightness.light, 'Light'),
            (Brightness.dark, 'Dark'),
          ],
          selected: brightness,
          onChanged: onBrightness,
          ink: ink,
          surface: surface,
        ),
        const SizedBox(height: AppSpacing.sm),
        _Segmented<AccessiblePalette>(
          options: const [
            (AccessiblePalette.standard, 'Standard'),
            (AccessiblePalette.deuteranopia, 'Deuteranopia'),
            (AccessiblePalette.monochrome, 'Monochrome'),
          ],
          selected: palette,
          onChanged: onPalette,
          ink: ink,
          surface: surface,
        ),
      ],
    );
  }
}

/// A compact single-select segmented control built from tokens.
class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.ink,
    required this.surface,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final Color ink;
  final Color surface;

  @override
  Widget build(final BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, label) in options) ...[
              _Segment<T>(
                label: label,
                selected: value == selected,
                ink: ink,
                onTap: () => onChanged(value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.ink,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast02,
        curve: AppMotion.fluid,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? ink : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected ? Theme.of(context).colorScheme.surface : ink,
          ),
        ),
      ),
    );
  }
}

/// Region 1 — Color. Every role as an inline `[name | hex | swatch]` triple;
/// signals also read as pills against their own swatch.
class _ColorRegion extends StatelessWidget {
  const _ColorRegion({required this.resolve, required this.brightness});

  final Color Function(AppColorRole) resolve;
  final Brightness brightness;

  static String _hex(final Color c) {
    int ch(final double v) => (v * 255).round().clamp(0, 255);
    String h(final double v) => ch(v).toRadixString(16).padLeft(2, '0');
    return '#${h(c.r)}${h(c.g)}${h(c.b)}'.toUpperCase();
  }

  @override
  Widget build(final BuildContext context) {
    final surfaces = [
      AppColorRole.background,
      AppColorRole.card,
      AppColorRole.fill,
      AppColorRole.separator,
    ];
    final inks = [
      AppColorRole.text,
      AppColorRole.secondaryText,
      AppColorRole.accent,
      AppColorRole.onAccent,
    ];
    final signals = [
      AppColorRole.error,
      AppColorRole.stateNew,
      AppColorRole.stateLearning,
      AppColorRole.stateMastery,
      AppColorRole.actionAgain,
      AppColorRole.actionHard,
      AppColorRole.actionGood,
      AppColorRole.actionEasy,
    ];

    return AppSection(
      first: true,
      title: 'Color · ${_hex(resolve(AppColorRole.background))} ground · '
          '${brightness.name}',
      children: [
        _RoleTripleRow(
          roles: surfaces,
          resolve: resolve,
          hexOf: _hex,
        ),
        const SizedBox(height: AppSpacing.lg),
        _RoleTripleRow(
          roles: inks,
          resolve: resolve,
          hexOf: _hex,
        ),
        const SizedBox(height: AppSpacing.lg),
        _SignalPills(
          roles: signals,
          resolve: resolve,
          hexOf: _hex,
        ),
      ],
    );
  }
}

/// Inline `[name | hex | swatch]` tiles for a list of roles, wrapped to a
/// dense grid keyed to the block grid.
class _RoleTripleRow extends StatelessWidget {
  const _RoleTripleRow({
    required this.roles,
    required this.resolve,
    required this.hexOf,
  });

  final List<AppColorRole> roles;
  final Color Function(AppColorRole) resolve;
  final String Function(Color) hexOf;

  @override
  Widget build(final BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final role in roles)
          _TokenTriple(
            name: role.name,
            value: hexOf(resolve(role)),
            preview: _Swatch(color: resolve(role)),
          ),
      ],
    );
  }
}

/// Signal roles read as pills: a swatch with their own name inked on top, so
/// the contrast pairing (e.g. `onAccent` over `accent`) is itself on display.
class _SignalPills extends StatelessWidget {
  const _SignalPills({
    required this.roles,
    required this.resolve,
    required this.hexOf,
  });

  final List<AppColorRole> roles;
  final Color Function(AppColorRole) resolve;
  final String Function(Color) hexOf;

  @override
  Widget build(final BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final role in roles)
          _SignalPill(
            role: role,
            color: resolve(role),
            hex: hexOf(resolve(role)),
          ),
      ],
    );
  }
}

class _SignalPill extends StatelessWidget {
  const _SignalPill({
    required this.role,
    required this.color,
    required this.hex,
  });

  final AppColorRole role;
  final Color color;
  final String hex;

  @override
  Widget build(final BuildContext context) {
    final onColor = ThemeData.estimateBrightnessForColor(color) ==
            Brightness.dark
        ? Colors.white
        : Colors.black;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role.name,
              style: AppTypography.labelLarge.copyWith(color: onColor),
            ),
            Text(
              hex,
              style: AppTypography.labelSmall.copyWith(
                color: onColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Region 2 — Typography. The full scale as `[style | size/weight | sample]`
/// rows, followed by the alternate font families.
class _TypographyRegion extends StatelessWidget {
  const _TypographyRegion();

  @override
  Widget build(final BuildContext context) {
    final scale = <(String, TextStyle)>[
      ('titleLarge', AppTypography.titleLarge),
      ('titleMedium', AppTypography.titleMedium),
      ('titleSmall', AppTypography.titleSmall),
      ('bodyLarge', AppTypography.bodyLarge),
      ('bodyMedium', AppTypography.bodyMedium),
      ('bodySmall', AppTypography.bodySmall),
      ('caption', AppTypography.caption),
      ('sectionHeader', AppTypography.sectionHeader),
      ('labelLarge', AppTypography.labelLarge),
      ('labelSmall', AppTypography.labelSmall),
    ];
    return AppSection(
      title: 'Typography',
      children: [
        for (final (name, style) in scale)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(name, style: AppTypography.caption),
                ),
                SizedBox(
                  width: 96,
                  child: Text(
                    '${style.fontSize?.toInt()}·'
                    '${(style.fontWeight?.value ?? 400)}',
                    style: AppTypography.caption,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Breakdex',
                    style: style.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        for (final family in AppFontFamily.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    family.displayName,
                    style: AppTypography.caption,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Breakdex moves in sets',
                    style: TextStyle(
                      fontFamily: _fontFamilyName(family),
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Resolved font family name, matching `AppTypography._resolvedFontFamily`.
String? _fontFamilyName(final AppFontFamily family) => switch (family) {
      AppFontFamily.inter => 'Inter',
      AppFontFamily.spaceMono ||
      AppFontFamily.jetBrainsMono => 'monospace',
      _ => null,
    };

/// Region 3 — Spacing + Radius. `[name | value | visualized]` rows: spacing as
/// a ruled gap of that width, radius as a tile with that corner.
class _SpacingRadiusRegion extends StatelessWidget {
  const _SpacingRadiusRegion();

  @override
  Widget build(final BuildContext context) {
    final spacing = <(String, double)>[
      ('xxs', AppSpacing.xxs),
      ('xs', AppSpacing.xs),
      ('sm', AppSpacing.sm),
      ('md', AppSpacing.md),
      ('lg', AppSpacing.lg),
      ('xl', AppSpacing.xl),
      ('xxl', AppSpacing.xxl),
      ('xxxl', AppSpacing.xxxl),
    ];
    final radius = <(String, double)>[
      ('xxs', AppRadius.xxs),
      ('xs', AppRadius.xs),
      ('sm', AppRadius.sm),
      ('md', AppRadius.md),
      ('lg', AppRadius.lg),
      ('xl', AppRadius.xl),
      ('pill', AppRadius.pill),
    ];
    final ink = Theme.of(context).colorScheme.onSurfaceVariant;
    return AppSection(
      title: 'Spacing · Radius',
      children: [
        for (final (name, value) in spacing)
          _MetricRow(
            name: name,
            value: '${value.toInt()}pt',
            preview: SizedBox(
              width: value.clamp(0, 200),
              height: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.xxs),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (name, value) in radius)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(value),
                        border: Border.all(color: ink),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '$name · ${value.toInt()}',
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// Region 4 — Depth + Shadows. Each `AppDepth` level as a raised card carrying
/// its own shadow, so the depth ramp reads at a glance.
class _DepthShadowsRegion extends StatelessWidget {
  const _DepthShadowsRegion({required this.brightness});

  final Brightness brightness;

  @override
  Widget build(final BuildContext context) {
    final levels = <(String, DepthLevel)>[
      ('sunken', AppDepth.sunken),
      ('flat', AppDepth.flat),
      ('elevated', AppDepth.elevated),
      ('floating', AppDepth.floating),
      ('overlay', AppDepth.overlay),
    ];
    return AppSection(
      title: 'Depth · Shadows',
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final (name, level) in levels)
              SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: level.shadowOpacity),
                            offset: level.shadowOffset,
                            blurRadius: level.shadowBlur,
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: 64,
                        width: double.infinity,
                        child: Center(
                          child: Text(
                            name,
                            style: AppTypography.labelLarge,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'blur ${level.shadowBlur.toInt()} · '
                      'z ${level.scale.toStringAsFixed(2)}',
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Region 5 — Layout. The four-band frame diagram plus the `AppLayout`
/// constants as a labeled table.
class _LayoutRegion extends StatelessWidget {
  const _LayoutRegion();

  @override
  Widget build(final BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final constants = <(String, double)>[
      ('headerHeight', AppLayout.headerHeight),
      ('backSlot', AppLayout.backSlot),
      ('contentTopGap', AppLayout.contentTopGap),
      ('navBandHeight', AppLayout.navBandHeight),
      ('gutter', AppLayout.gutter),
      ('maxContentWidth', AppLayout.maxContentWidth),
      ('maxWideWidth', AppLayout.maxWideWidth),
      ('dialogMaxWidth', AppLayout.dialogMaxWidth),
      ('sectionGap', AppLayout.sectionGap),
      ('itemGap', AppLayout.itemGap),
      ('rowHeight', AppLayout.rowHeight),
      ('blockGrid', AppLayout.blockGrid),
    ];
    return AppSection(
      title: 'Layout',
      children: [
        // The four-band frame diagram.
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Column(
              children: [
                _Band(
                  label: '1 · safe area',
                  height: 20,
                  color: ink.withValues(alpha: 0.04),
                ),
                _Band(
                  label: '2 · header · ${AppLayout.headerHeight.toInt()}pt',
                  height: AppLayout.headerHeight,
                  color: ink.withValues(alpha: 0.08),
                ),
                _Band(
                  label: '3 · content (scrolls)',
                  height: 96,
                  color: ink.withValues(alpha: 0.04),
                ),
                _Band(
                  label: '4 · nav · ${AppLayout.navBandHeight.toInt()}pt',
                  height: AppLayout.navBandHeight,
                  color: ink.withValues(alpha: 0.08),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final (name, value) in constants)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: 160,
                  child: Text(name, style: AppTypography.caption),
                ),
                Text(
                  value % 1 == 0 ? '${value.toInt()}pt' : '$value',
                  style: AppTypography.caption.copyWith(color: ink),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({
    required this.label,
    required this.height,
    required this.color,
  });

  final String label;
  final double height;
  final Color color;

  @override
  Widget build(final BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: color,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Text(label, style: AppTypography.labelSmall),
    );
  }
}

/// Region 6 — Motion. Fluid + Morph families, durations + curves, and a
/// replayable animated sample driven by the Fluid curve on the compositor.
class _MotionRegion extends StatefulWidget {
  const _MotionRegion();

  @override
  State<_MotionRegion> createState() => _MotionRegionState();
}

class _MotionRegionState extends State<_MotionRegion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.moderate02,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _replay() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(final BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final durations = <(String, Duration)>[
      ('fast01', AppMotion.fast01),
      ('fast02', AppMotion.fast02),
      ('moderate01', AppMotion.moderate01),
      ('moderate02', AppMotion.moderate02),
      ('slow01', AppMotion.slow01),
    ];
    return AppSection(
      title: 'Motion',
      children: [
        Row(
          children: [
            Text('Fluid', style: AppTypography.labelLarge),
            const SizedBox(width: AppSpacing.xs),
            Text('opacity · translation', style: AppTypography.caption),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (name, dur) in durations)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    '$name · ${dur.inMilliseconds}ms',
                    style: AppTypography.labelSmall,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text('Morph', style: AppTypography.labelLarge),
            const SizedBox(width: AppSpacing.xs),
            Text('shape · layout continuity', style: AppTypography.caption),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Replayable sample: a dot translating on the Fluid curve, transform
        // only — compositor-bound, never layout.
        Row(
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (final context, final _) {
                final t = AppMotion.fluid.transform(_controller.value);
                return Row(
                  children: [
                    Transform.translate(
                      offset: Offset(t * 120, 0),
                      child: Opacity(
                        opacity: t,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxl),
                  ],
                );
              },
            ),
            GestureDetector(
              onTap: _replay,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    'Replay',
                    style: AppTypography.caption.copyWith(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --- Shared region widgets ---------------------------------------------------

/// An inline `[name | value | preview]` triple — the page's dominant motif.
class _TokenTriple extends StatelessWidget {
  const _TokenTriple({
    required this.name,
    required this.value,
    required this.preview,
  });

  final String name;
  final String value;
  final Widget preview;

  @override
  Widget build(final BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          child: Text(name, style: AppTypography.caption.copyWith(color: ink)),
        ),
        SizedBox(
          width: 80,
          child: Text(value, style: AppTypography.labelSmall),
        ),
        preview,
      ],
    );
  }
}

/// A solid color swatch with a thin outline, for color triples.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.xxs),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }
}

/// A `[name | value | preview]` row used by the spacing region.
class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.name,
    required this.value,
    required this.preview,
  });

  final String name;
  final String value;
  final Widget preview;

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(name, style: AppTypography.caption),
          ),
          SizedBox(
            width: 64,
            child: Text(value, style: AppTypography.labelSmall),
          ),
          Expanded(child: preview),
        ],
      ),
    );
  }
}
