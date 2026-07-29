import 'package:flutter/material.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/design/icons.dart';

/// The labelled back affordance used by pushed detail routes.
///
/// Detail routes sit outside the stacked-viewport frame (`AppScreen`) on
/// purpose — they have a back affordance and no nav band — so they still build
/// an `AppBar`. What they must not do is hand-roll this control: three screens
/// each grew their own chevron-plus-word `Row`, one of them patched the slot
/// width to a bare `104` after the fact, and the `Moves` header shipped a
/// RenderFlex "OVERFLOWED BY 2" (`SCR-20260728-mafz`).
///
/// The cause is that `AppBar` gives `leading` a fixed 56pt slot, which fits a
/// bare icon and not an icon plus a word — and every point of text scaling
/// makes it worse. So this control declares the slot it needs ([slotWidth]) and
/// lets its label ellipsize inside it, which makes overflow impossible at any
/// text scale rather than merely unlikely at one.
class BackLeading extends StatelessWidget {
  const BackLeading({
    super.key,
    required this.identifier,
    this.label = 'Back',
    this.onTap,
  });

  /// Semantics identifier the Maestro flows select on.
  final String identifier;

  /// Word shown beside the chevron. Defaults to `Back`; detail routes that
  /// return to a named surface pass that name instead.
  final String label;

  /// Defaults to `Navigator.maybePop`.
  final VoidCallback? onTap;

  /// Width the `AppBar` must give this control via `leadingWidth`.
  ///
  /// Chevron (20) + the widest label we ship at `bodyMedium` + the leading
  /// gutter. Passing it is not optional: at the default 56 the control is
  /// exactly the two logical pixels too wide that the screenshot recorded.
  static const double slotWidth = 104;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      identifier: identifier,
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap ?? () => Navigator.maybePop(context),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconView(AppIcon.back, color: colorScheme.secondary, size: 20),
              Flexible(
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
