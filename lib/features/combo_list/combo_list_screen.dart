import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/providers.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/settings_gear_button.dart';

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
        actions: const [SettingsGearButton(), SizedBox(width: AppSpacing.sm)],
      ),
      body: combosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => data.isEmpty
            ? _ComboEmptyState(colorScheme: colorScheme)
            : _ComboTableView(combos: data, colorScheme: colorScheme),
      ),
      floatingActionButton: combos.isNotEmpty
          ? Semantics(
              label: 'Create new combo',
              button: true,
              child: FloatingActionButton(
                onPressed: () async {
                  final comboName = await context.push<String>('/create-combo');
                  if (comboName != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Combo "$comboName" created')),
                    );
                  }
                },
                backgroundColor: colorScheme.primary,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            )
          : null,
    );
  }
}

final _combosProvider = StreamProvider<List<(Combo, int)>>((ref) {
  return ref.watch(comboRepositoryProvider).watchAllWithMoveCounts();
});

// -- Table View ---------------------------------------------------------------

class _ComboTableView extends StatelessWidget {
  const _ComboTableView({required this.combos, required this.colorScheme});

  final List<(Combo, int)> combos;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table header
        Container(
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.sm,
            AppSpacing.screenEdge,
            0,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Name',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  'Moves',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Table body
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdge,
              vertical: 0,
            ),
            itemCount: combos.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: colorScheme.outline.withValues(alpha: 0.08),
            ),
            itemBuilder: (context, index) {
              final (combo, moveCount) = combos[index];
              return _ComboTableRow(
                combo: combo,
                moveCount: moveCount,
                colorScheme: colorScheme,
                onTap: () => context.push('/breakdex/combo/${combo.id}'),
              );
            },
          ),
        ),
        // Bottom padding
        SizedBox(height: 80 + MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}

class _ComboTableRow extends StatelessWidget {
  const _ComboTableRow({
    required this.combo,
    required this.moveCount,
    required this.colorScheme,
    required this.onTap,
  });

  final Combo combo;
  final int moveCount;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                combo.name,
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(
                '$moveCount',
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.secondary.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// -- Empty State --------------------------------------------------------------

class _ComboEmptyState extends StatelessWidget {
  const _ComboEmptyState({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenEdge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dotted lines connecting placeholder move cards
            _DottedComboVisual(colorScheme: colorScheme),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No combos yet',
              style: AppTypography.titleSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Chain moves together into sequences.\nCreate your first combo to get started.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
              SizedBox(
                    width: 220,
                    child: FilledButton.icon(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        final comboName = await context.push<String>(
                          '/create-combo',
                        );
                        if (comboName != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Combo "$comboName" created')),
                          );
                        }
                      },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Create your first combo'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DottedComboVisual extends StatelessWidget {
  const _DottedComboVisual({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: CustomPaint(
        size: const Size(double.infinity, 160),
        painter: _DottedLinePainter(color: colorScheme.outline.withValues(alpha: 0.3)),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PlaceholderMoveCard(index: 0),
              SizedBox(width: 24),
              _PlaceholderMoveCard(index: 1),
              SizedBox(width: 24),
              _PlaceholderMoveCard(index: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderMoveCard extends StatelessWidget {
  const _PlaceholderMoveCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icons = [Icons.sports_martial_arts, Icons.directions_run, Icons.self_improvement];
    return Container(
      width: 64,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
        color: colorScheme.surface,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icons[index % icons.length],
            size: 20,
            color: colorScheme.secondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 24,
            height: 3,
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dashWidth = 5.0;
    final dashSpace = 5.0;
    final startX = size.width / 2 - 100;
    final endX = size.width / 2 + 100;
    final y = size.height / 2;

    double currentX = startX;
    while (currentX < endX) {
      final end = min(currentX + dashWidth, endX);
      canvas.drawLine(Offset(currentX, y), Offset(end, y), paint);
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter oldDelegate) => false;
}
