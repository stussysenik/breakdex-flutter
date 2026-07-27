import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:breakdex/core/design/colors.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';

/// The combo journey vocabulary — shared with labs.
const comboStatuses = ['idea', 'attempting', 'landed', 'clean'];

/// Visual treatment per status. Text carries the meaning; color only
/// reinforces (existing learning-state palette, no new vocabulary).
({Color color, bool filled, bool dashed}) statusStyle(final String status) {
  return switch (status) {
    'attempting' => (color: AppColors.stateLearning, filled: false, dashed: false),
    'landed' => (color: AppColors.stateMastery, filled: false, dashed: false),
    'clean' => (color: AppColors.stateMastery, filled: true, dashed: false),
    _ => (color: Colors.transparent, filled: false, dashed: true), // idea
  };
}

/// Tappable status chip: current word + ▾. Tapping reveals the four words
/// inline; selecting one calls [onChanged].
class StatusTag extends StatefulWidget {
  const StatusTag({
    super.key,
    required this.status,
    required this.onChanged,
  });

  final String status;
  final ValueChanged<String> onChanged;

  @override
  State<StatusTag> createState() => _StatusTagState();
}

class _StatusTagState extends State<StatusTag> {
  bool _expanded = false;

  @override
  Widget build(final BuildContext context) {
    if (!_expanded) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _StatusChip(
          status: widget.status,
          selected: true,
          trailing: ' ▾',
          onTap: () => setState(() => _expanded = true),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final status in comboStatuses)
          _StatusChip(
            status: status,
            selected: status == widget.status,
            onTap: () {
              setState(() => _expanded = false);
              if (status != widget.status) {
                unawaited(HapticFeedback.selectionClick());
                widget.onChanged(status);
              }
            },
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.selected,
    required this.onTap,
    this.trailing = '',
  });

  final String status;
  final bool selected;
  final VoidCallback onTap;
  final String trailing;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = statusStyle(status);
    final borderColor =
        style.dashed ? colorScheme.outline : style.color;
    final textColor = style.filled
        ? Colors.white
        : (style.dashed ? colorScheme.secondary : style.color);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // ≥48dp hit area via min constraints; visual chip stays compact.
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: style.filled ? style.color : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? borderColor : borderColor.withValues(alpha: 0.6),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            '${status.toUpperCase()}$trailing',
            style: AppTypography.labelLarge.copyWith(
              color: textColor,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
