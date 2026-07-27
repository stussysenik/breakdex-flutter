import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/services/entity_names_service.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';

class BreakdexScreen extends ConsumerWidget {
  const BreakdexScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;
    final entityNames = ref.watch(entityNamesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).appTitle),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              identifier: 'moves-tile',
              child: _HeroNavTile(
                label: entityNames.movePlural,
                onTap: () => context.go('/breakdex/moves'),
                color: textColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Semantics(
              identifier: 'combos-tile',
              child: _HeroNavTile(
                label: entityNames.comboPlural,
                onTap: () => context.go('/breakdex/combos'),
                color: textColor,
              ),
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
    required this.onTap,
    required this.color,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(final BuildContext context) {
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
        ],
      ),
    );
  }
}
