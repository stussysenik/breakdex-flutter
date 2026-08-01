import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';

/// The basis the gallery is currently rendering against.
///
/// Defaults to the shipped constants, so a gallery nobody has touched shows the
/// real frame.
final previewBasisProvider = StateProvider<AppLayoutTheme>(
  (_) => const AppLayoutTheme(),
);

/// One overridable dimension of [AppLayoutTheme], with the range a slider may
/// move it through.
///
/// The list, not the widget, is the source of truth: [DevBasisControls] builds
/// a slider per entry and the test drives the same entries, so a field that
/// gains a control gains its proof in the same edit.
@immutable
final class BasisField {
  const BasisField({
    required this.name,
    required this.min,
    required this.max,
    required this.read,
    required this.apply,
  });

  /// Label shown next to the slider, and the identity in [sliderKey].
  final String name;

  /// Lowest value the slider can reach. Never 0 — a basis of nothing is not a
  /// layout to judge, it is a collapsed one.
  final double min;

  /// Highest value the slider can reach.
  final double max;

  /// Reads this field out of a basis.
  final double Function(AppLayoutTheme basis) read;

  /// Returns [basis] with this field set to [value].
  final AppLayoutTheme Function(AppLayoutTheme basis, double value) apply;

  /// Key for this field's slider, so a test can drive it by name.
  ValueKey<String> get sliderKey => ValueKey<String>('basis-slider-$name');
}

/// Every field [AppLayoutTheme] can override, in the order they are read: the
/// horizontal measure first, then the two grids, then the two band heights.
final List<BasisField> basisFields = <BasisField>[
  BasisField(
    name: 'gutter',
    min: 8,
    max: 48,
    read: (final b) => b.gutter,
    apply: (final b, final v) => b.copyWith(gutter: v),
  ),
  BasisField(
    name: 'baseline',
    min: 2,
    max: 8,
    read: (final b) => b.baseline,
    apply: (final b, final v) => b.copyWith(baseline: v),
  ),
  BasisField(
    name: 'blockGrid',
    min: 4,
    max: 16,
    read: (final b) => b.blockGrid,
    apply: (final b, final v) => b.copyWith(blockGrid: v),
  ),
  BasisField(
    name: 'rowHeight',
    min: 40,
    max: 96,
    read: (final b) => b.rowHeight,
    apply: (final b, final v) => b.copyWith(rowHeight: v),
  ),
  BasisField(
    name: 'headerHeight',
    min: 48,
    max: 120,
    read: (final b) => b.headerHeight,
    apply: (final b, final v) => b.copyWith(headerHeight: v),
  ),
];

/// Puts [previewBasisProvider] into the ambient `Theme` for [child].
///
/// This is the seam 5.1 exists for: the basis is an extension on the theme, so
/// re-flowing everything under it is a `setState`-sized event and not a hot
/// restart. Every other extension already on the theme is carried through —
/// colour packs and semantics must survive a change of grid.
class DevBasisScope extends ConsumerWidget {
  const DevBasisScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final basis = ref.watch(previewBasisProvider);
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        extensions: [...theme.extensions.values, basis],
      ),
      child: child,
    );
  }
}

/// A slider per basis field, plus a reset back to the shipped constants.
///
/// Lives above the gallery's cards so the thing being adjusted and the thing
/// re-flowing are on screen together.
class DevBasisControls extends ConsumerWidget {
  const DevBasisControls({super.key});

  /// Key for the control that restores the shipped basis.
  static const resetKey = ValueKey<String>('basis-reset');

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final basis = ref.watch(previewBasisProvider);
    final theme = Theme.of(context);
    final isDefault = basis == const AppLayoutTheme();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'BASIS',
                  style: AppTypography.sectionHeader.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              TextButton(
                key: resetKey,
                onPressed: isDefault
                    ? null
                    : () => ref.read(previewBasisProvider.notifier).state =
                          const AppLayoutTheme(),
                child: const Text('Reset'),
              ),
            ],
          ),
          for (final field in basisFields)
            _BasisSlider(
              field: field,
              value: field.read(basis),
              onChanged: (final v) =>
                  ref.read(previewBasisProvider.notifier).state = field.apply(
                    basis,
                    v,
                  ),
            ),
        ],
      ),
    );
  }
}

class _BasisSlider extends StatelessWidget {
  const _BasisSlider({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final BasisField field;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(field.name, style: theme.textTheme.labelMedium),
        ),
        Expanded(
          child: Slider(
            key: field.sliderKey,
            value: value.clamp(field.min, field.max),
            min: field.min,
            max: field.max,
            // One stop per point: the basis is measured in whole points, and a
            // fractional gutter is a value no screen could ever be built to.
            divisions: (field.max - field.min).round(),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value.toStringAsFixed(0),
            textAlign: TextAlign.end,
            style: theme.textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}
