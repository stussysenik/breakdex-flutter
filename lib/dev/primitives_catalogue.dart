import 'package:flutter/material.dart';

import 'package:breakdex/core/design/color_packs.dart';
import 'package:breakdex/core/design/color_roles.dart';
import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/shared/widgets/app_row.dart';
import 'package:breakdex/shared/widgets/app_screen.dart';

/// Every design primitive rendered once, in every state it can hold.
///
/// The screen cards above this in the gallery prove the *compositions* work.
/// This proves the *vocabulary* does: a row in each of its states, all three
/// icon packs resolving the same name side by side, every colour role from
/// every pack, and one instance of each motion family. Anything the app can
/// say is visible here, so a change to the basis (5.1) can be judged against
/// the whole vocabulary at once rather than one screen at a time.
///
/// A [Column], not a [ListView], on purpose: everything must be built whether
/// or not it is on screen, so a widget test measures the whole catalogue in one
/// pump and the completeness assertions are real.
class DevPrimitivesCatalogue extends StatelessWidget {
  const DevPrimitivesCatalogue({super.key});

  /// Key for the cell resolving [icon] under [pack].
  ///
  /// Public because completeness is asserted, not eyeballed: the test walks
  /// `AppIcon.values × IconPackId.values` and demands each cell, so adding a
  /// name to the vocabulary without rendering it here fails the gate.
  static ValueKey<String> iconCellKey(
    final AppIcon icon,
    final IconPackId pack,
  ) => ValueKey<String>('icon-${icon.name}-${pack.key}');

  /// Key for the swatch resolving [role] under [pack]. Same contract as
  /// [iconCellKey], over `AppColorRole.values × ColorPackId.values`.
  static ValueKey<String> roleSwatchKey(
    final AppColorRole role,
    final ColorPackId pack,
  ) => ValueKey<String>('role-${role.name}-${pack.key}');

  @override
  Widget build(final BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Block(title: 'Frame', child: _FrameSample()),
      _Block(title: 'Rows', child: _RowStates()),
      _Block(title: 'Icon packs', child: _IconPackTable()),
      _Block(title: 'Colour roles', child: _ColorRoleTable()),
      _Block(title: 'Motion families', child: MotionFamilies()),
    ],
  );
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              title.toUpperCase(),
              style: AppTypography.sectionHeader.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// The four bands, with nothing in them but rows — the frame without a feature.
class _FrameSample extends StatelessWidget {
  const _FrameSample();

  @override
  Widget build(final BuildContext context) => SizedBox(
    height: 360,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: const AppScreen(
          title: 'Frame',
          children: [
            AppSection(
              first: true,
              title: 'Section',
              children: [
                AppRow(label: 'A row is one line of type'),
                AppRow(label: 'With a value', value: '24pt'),
              ],
            ),
            AppSection(
              title: 'Second section',
              children: [AppRow(label: 'Section gap above')],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Every state [AppRow] can hold, in the order a reader meets them.
class _RowStates extends StatefulWidget {
  const _RowStates();

  @override
  State<_RowStates> createState() => _RowStatesState();
}

class _RowStatesState extends State<_RowStates> {
  bool _switched = true;
  String _choice = 'Morph';

  @override
  Widget build(final BuildContext context) => AppSection(
    first: true,
    children: [
      const AppRow(key: ValueKey('row-readout'), label: 'Readout — no tap'),
      const AppRow(
        key: ValueKey('row-value'),
        label: 'With value',
        value: 'Classic',
      ),
      AppRow(
        key: const ValueKey('row-tappable'),
        label: 'Tappable — chevron',
        onTap: () {},
      ),
      AppRow(
        key: const ValueKey('row-leading'),
        label: 'With leading glyph',
        leading: const AppIconView(AppIcon.library),
        onTap: () {},
      ),
      AppRow(
        key: const ValueKey('row-switch'),
        label: 'With a control',
        trailing: Switch(
          value: _switched,
          onChanged: (final v) => setState(() => _switched = v),
        ),
      ),
      const AppRow(
        key: ValueKey('row-disabled'),
        label: 'Disabled — keeps its line',
        value: 'Unavailable',
        enabled: false,
      ),
      AppChoiceList<String>(
        key: const ValueKey('row-choice-list'),
        values: const ['Fluid', 'Morph'],
        selected: _choice,
        labelOf: (final v) => v,
        onChanged: (final v) => setState(() => _choice = v),
      ),
    ],
  );
}

/// One row per [AppIcon], one column per pack, so the same name can be read
/// across all three vocabularies at a glance.
class _IconPackTable extends StatelessWidget {
  const _IconPackTable();

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              const Spacer(),
              for (final pack in IconPackId.values)
                SizedBox(
                  width: 44,
                  child: Text(
                    pack.key,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (final icon in AppIcon.values)
          SizedBox(
            height: AppLayout.of(context).rowHeight,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    icon.name,
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                for (final pack in IconPackId.values)
                  SizedBox(
                    width: 44,
                    child: _withIconPack(
                      context,
                      pack,
                      AppIconView(
                        icon,
                        key: DevPrimitivesCatalogue.iconCellKey(icon, pack),
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// Rebinds the active [IconPack] for one subtree.
  ///
  /// `copyWith(extensions:)` replaces the whole extension map rather than
  /// merging into it, so the current values are passed through and the override
  /// appended last — dropping them would take the colour and layout bases with
  /// the icon pack.
  Widget _withIconPack(
    final BuildContext context,
    final IconPackId pack,
    final Widget child,
  ) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        extensions: <ThemeExtension<Object?>>[
          ...theme.extensions.values,
          AppIconPackTheme(pack.build()),
        ],
      ),
      child: child,
    );
  }
}

/// One row per [AppColorRole], one swatch per pack, at the brightness in force.
class _ColorRoleTable extends StatelessWidget {
  const _ColorRoleTable();

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final role in AppColorRole.values)
          SizedBox(
            height: AppLayout.of(context).rowHeight,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${role.name} · ${role.kind.name}',
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                for (final pack in ColorPackId.values)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: Container(
                      key: DevPrimitivesCatalogue.roleSwatchKey(role, pack),
                      width: 44,
                      height: 20,
                      decoration: BoxDecoration(
                        color: pack.pack.resolve(role, brightness),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One instance of each locked motion family, replayed by tapping.
///
/// Fluid is opacity and translation on a productive curve; Morph is one
/// persistent shape changing size and radius on the gentle spring. Both read
/// their duration and curve from `AppMotion` — a literal here would be the same
/// review violation it is anywhere else.
class MotionFamilies extends StatefulWidget {
  const MotionFamilies({super.key});

  @override
  State<MotionFamilies> createState() => _MotionFamiliesState();
}

class _MotionFamiliesState extends State<MotionFamilies> {
  bool _out = false;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 96,
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: AnimatedSlide(
                    key: const ValueKey('motion-fluid'),
                    offset: _out ? const Offset(0, -0.4) : Offset.zero,
                    duration: AppMotion.moderate02,
                    curve: AppMotion.fluid,
                    child: AnimatedOpacity(
                      opacity: _out ? 0.2 : 1,
                      duration: AppMotion.moderate02,
                      curve: AppMotion.fluid,
                      child: _Swatch(
                        color: colorScheme.primary,
                        label: 'Fluid',
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: AnimatedContainer(
                    key: const ValueKey('motion-morph'),
                    width: _out ? 120 : 72,
                    height: _out ? 40 : 72,
                    duration: AppMotion.moderate02,
                    curve: AppMotion.morph,
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(_out ? 20 : 6),
                    ),
                    alignment: Alignment.center,
                    child: Text('Morph', style: AppTypography.labelSmall),
                  ),
                ),
              ),
            ],
          ),
        ),
        AppRow(
          key: const ValueKey('motion-replay'),
          label: 'Replay both families',
          onTap: () => setState(() => _out = !_out),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(final BuildContext context) => Container(
    width: 72,
    height: 72,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Text(
      label,
      style: AppTypography.labelSmall.copyWith(
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    ),
  );
}
