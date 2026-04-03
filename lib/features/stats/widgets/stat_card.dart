import 'package:flutter/material.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/spacing.dart';

/// Compact stat card with progressive disclosure: zero-value cards dim to 40%
/// opacity so the user's eye is drawn to meaningful data first.
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value});

  final String label;
  final String value;

  bool get _isZero => value == '0' || value == '0%';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedOpacity(
      opacity: _isZero ? 0.4 : 1.0,
      duration: AppMotion.moderate01,
      curve: AppMotion.entrance,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: AppSurfaces.panel(
          context,
          radius: AppRadius.sm,
          raised: !_isZero,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: cs.secondary),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: AppMotion.moderate01,
              child: Text(
                value,
                key: ValueKey(value),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
