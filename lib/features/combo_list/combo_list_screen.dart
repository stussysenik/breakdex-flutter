import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/providers.dart';
import '../../shared/widgets/pressable.dart';

class ComboListScreen extends ConsumerWidget {
  const ComboListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combosAsync = ref.watch(_combosProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final combos = combosAsync.valueOrNull ?? const <(Combo, int)>[];

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'combos-back',
          label: 'Back',
          button: true,
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left, color: colorScheme.secondary, size: 20),
                  Text('Back', style: AppTypography.bodyMedium.copyWith(color: colorScheme.secondary)),
                ],
              ),
            ),
          ),
        ),
        title: const Text('Combos'),
      ),
      body: combos.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_outlined, size: 48, color: colorScheme.secondary.withValues(alpha: 0.4)),
                  const SizedBox(height: AppSpacing.md),
                  Text('No combos yet', style: AppTypography.bodyMedium.copyWith(color: colorScheme.secondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Create one to get started', style: AppTypography.bodySmall.copyWith(color: colorScheme.secondary.withValues(alpha: 0.6))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenEdge),
              itemCount: combos.length,
              itemBuilder: (context, index) {
                final (combo, moveCount) = combos[index];
                return _ComboRow(
                  combo: combo,
                  moveCount: moveCount,
                  onTap: () => context.push('/breakdex/combo/${combo.id}'),
                );
              },
            ),
    );
  }
}

final _combosProvider = StreamProvider<List<(Combo, int)>>((ref) {
  return ref.watch(comboRepositoryProvider).watchAllWithMoveCounts();
});

class _ComboRow extends StatelessWidget {
  const _ComboRow({required this.combo, required this.moveCount, required this.onTap});

  final Combo combo;
  final int moveCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(combo.name, style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '$moveCount move${moveCount == 1 ? '' : 's'}',
                      style: AppTypography.caption.copyWith(color: colorScheme.secondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colorScheme.secondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
