import 'package:flutter/material.dart';

import '../../core/design/spacing.dart';
import '../../core/design/theme.dart';
import '../../core/design/typography.dart';

class AppSegmentedControlItem<T> {
  const AppSegmentedControlItem({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;

  /// Optional — omit when three or more segments would truncate labels.
  final IconData? icon;
}

class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<AppSegmentedControlItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(final BuildContext context) {
    return Container(
      decoration: AppSurfaces.panel(context, radius: AppRadius.md),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _AppSegmentedControlButton<T>(
                item: items[index],
                selected: items[index].value == selectedValue,
                onTap: () => onChanged(items[index].value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppSegmentedControlButton<T> extends StatelessWidget {
  const _AppSegmentedControlButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppSegmentedControlItem<T> item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: AnimatedContainer(
          duration: AppMotion.moderate01,
          curve: AppMotion.productive,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 18,
                  color:
                      selected ? colorScheme.onPrimary : colorScheme.secondary,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  item.label,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: AppTypography.bodyMedium.copyWith(
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
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
