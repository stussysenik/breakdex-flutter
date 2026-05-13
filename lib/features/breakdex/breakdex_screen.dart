import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/app_mode.dart';
import '../../core/services/settings_service.dart';
import '../../shared/widgets/settings_gear_button.dart';

class BreakdexScreen extends ConsumerWidget {
  const BreakdexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(appModeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Breakdex'),
        actions: const [SettingsGearButton(), SizedBox(width: AppSpacing.sm)],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeroNavTile(
              label: 'Moves',
              subtitle: appMode == AppMode.party
                  ? 'Shake to browse'
                  : 'Browse by category',
              onTap: () => context.go('/breakdex/moves'),
              color: textColor,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _HeroNavTile(
              label: 'Combos',
              subtitle: 'Build sequences',
              onTap: () => context.go('/breakdex/combos'),
              color: textColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroNavTile extends StatelessWidget {
  const _HeroNavTile({
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 42,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: color.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
