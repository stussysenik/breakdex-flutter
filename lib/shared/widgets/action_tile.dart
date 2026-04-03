import 'package:flutter/material.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/theme.dart';
import '../../core/design/typography.dart';

/// Reusable row tile with icon, label, chevron — used across settings, detail screens, etc.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = destructive ? AppColors.actionAgain : colorScheme.onSurface;
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.32),
            ),
            boxShadow: AppShadows.soft(Theme.of(context).brightness),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(color: color),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right, color: colorScheme.secondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
