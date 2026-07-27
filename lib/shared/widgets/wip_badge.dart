import 'package:flutter/material.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';

class WipBadge extends StatelessWidget {
  const WipBadge({super.key, this.label = 'WIP', this.compact = false});

  final String label;
  final bool compact;

  static const _badgeColor = Color(0xFFD97706);

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: _badgeColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: _badgeColor.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: colorScheme.brightness == Brightness.dark
              ? const Color(0xFFFFC57A)
              : _badgeColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class WipTabIcon extends StatelessWidget {
  const WipTabIcon({super.key, required this.icon});

  final IconData icon;

  static const _badgeColor = Color(0xFFD97706);

  @override
  Widget build(final BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -10,
          top: -6,
          child: ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: const BoxDecoration(
                color: _badgeColor,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
              child: Text(
                'WIP',
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
