import 'package:flutter/material.dart';

import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';

/// A single line in a content band — the atom every text-first surface is
/// built from.
///
/// Bands 1, 2 and 4 are held identical by `AppScreen`. This type does the same
/// job one level down: it makes the *inside* of band 3 identical too, so a row
/// on Settings, on Add, and on a detail screen are the same object with
/// different words. That sameness is the point — a reader who learns one screen
/// has learned all of them, and every choice the app offers is presented at the
/// same weight, in the same place, at the same height.
///
/// Deliberately flat: no fill, no card, no elevation. A filled container makes a
/// row look like a *thing* rather than a *choice*, and once one screen has cards
/// and another has lines the parity is gone. Grouping is expressed by
/// [AppSection] above, never by decorating rows.
class AppRow extends StatelessWidget {
  const AppRow({
    super.key,
    required this.label,
    this.value,
    this.onTap,
    this.identifier,
    this.leading,
    this.trailing,
    this.enabled = true,
  });

  /// The row's words. This is the affordance — not an icon, not a colour.
  final String label;

  /// Optional trailing text: the row's current setting or count. Rendered
  /// secondary, because it is state, and [label] is the choice.
  final String? value;

  /// Tapping navigates or acts. A row with no [onTap] is a readout, and renders
  /// without the forward chevron so the two are never confused.
  final VoidCallback? onTap;

  /// Stable handle for E2E drivers. Labels are entity-name-configurable, so
  /// text is not a selector rows can offer.
  final String? identifier;

  /// Optional leading glyph. Optional on purpose: the text carries the meaning,
  /// and an icon that is merely decorative widens every row for nothing.
  final Widget? leading;

  /// Replaces the default trailing affordance (chevron / [value]) — for rows
  /// whose trailing element is itself a control, e.g. a switch.
  final Widget? trailing;

  /// A disabled row still occupies its line and keeps its place in the list,
  /// so the shape of the screen does not change with state.
  final bool enabled;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTappable = enabled && onTap != null;
    final labelColor = enabled
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.38);

    final row = Row(
      children: [
        if (leading != null) ...[
          IconTheme.merge(
            data: IconThemeData(size: 20, color: labelColor),
            child: leading!,
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Text(
            label,
            style: AppTypography.titleSmall.copyWith(color: labelColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ..._trailing(context, colorScheme, isTappable),
      ],
    );

    final line = Container(
      constraints: BoxConstraints(minHeight: AppLayout.of(context).rowHeight),
      alignment: Alignment.centerLeft,
      child: row,
    );

    final semantic = Semantics(
      identifier: identifier ?? '',
      button: isTappable,
      enabled: enabled,
      child: line,
    );

    if (!isTappable) return semantic;

    return InkWell(
      onTap: onTap,
      // Bleeds into the gutter so the ink covers the full line the eye reads,
      // not just the text column inside it.
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: semantic,
    );
  }

  List<Widget> _trailing(
    final BuildContext context,
    final ColorScheme colorScheme,
    final bool isTappable,
  ) {
    final trailing = this.trailing;
    if (trailing != null) {
      return [const SizedBox(width: AppSpacing.md), trailing];
    }

    final value = this.value;
    return [
      if (value != null) ...[
        const SizedBox(width: AppSpacing.md),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
      if (isTappable) ...[
        const SizedBox(width: AppSpacing.sm),
        AppIconView(AppIcon.forward, size: 20, color: colorScheme.outline),
      ],
    ];
  }
}

/// A single-select rendered as lines, not as pills.
///
/// Every option is an [AppRow], so an option here weighs exactly what a
/// navigation row weighs elsewhere; the chosen one is marked with a check on
/// its own line. A filled pill would make the selected option a different
/// *kind* of object from its siblings — the eye then compares shapes instead of
/// comparing the options, which is the one thing a picker must not do. It also
/// stops the ragged multi-run `Wrap` that put five fonts on three lines in an
/// order nobody chose.
class AppChoiceList<T> extends StatelessWidget {
  const AppChoiceList({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final value in values)
          AppRow(
            label: labelOf(value),
            onTap: () => onChanged(value),
            trailing: value == selected
                ? AppIconView(
                    AppIcon.check,
                    size: 20,
                    color: colorScheme.primary,
                  )
                : const SizedBox(width: 20),
          ),
      ],
    );
  }
}
