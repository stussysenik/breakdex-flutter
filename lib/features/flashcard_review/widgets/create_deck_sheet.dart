import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/providers.dart';
import '../../../core/services/categories_service.dart';
import '../../../core/services/deck_service.dart';

/// Bottom sheet for creating a new smart or manual deck.
///
/// Smart deck: user picks categories, FSRS states, due-only toggle.
/// Manual deck: user picks specific moves from a list.
class CreateDeckSheet extends ConsumerStatefulWidget {
  const CreateDeckSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const CreateDeckSheet(),
    );
  }

  @override
  ConsumerState<CreateDeckSheet> createState() => _CreateDeckSheetState();
}

class _CreateDeckSheetState extends ConsumerState<CreateDeckSheet> {
  final _nameController = TextEditingController();
  bool _isSmart = true;
  final _selectedCategories = <String>{};
  final _selectedStates = <int>{};
  bool _dueOnly = false;
  int? _sessionSize;

  // Manual deck state
  final _selectedMoveIds = <String>{};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenEdge,
        AppSpacing.lg,
        AppSpacing.screenEdge,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Deck',
                style: AppTypography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                )),
            const SizedBox(height: AppSpacing.md),

            // Name
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Deck name'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Deck type toggle
            Row(
              children: [
                Expanded(
                  child: _TypeChip(
                    label: 'Smart',
                    icon: Icons.auto_awesome,
                    isSelected: _isSmart,
                    onTap: () => setState(() => _isSmart = true),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _TypeChip(
                    label: 'Manual',
                    icon: Icons.playlist_add_check,
                    isSelected: !_isSmart,
                    onTap: () => setState(() => _isSmart = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            if (_isSmart) ...[
              // Category filter
              Text('Categories',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final cat in categories)
                    _FilterChip(
                      label: cat.name,
                      dotColor: cat.color,
                      isSelected: _selectedCategories.contains(cat.name),
                      onTap: () => setState(() {
                        if (_selectedCategories.contains(cat.name)) {
                          _selectedCategories.remove(cat.name);
                        } else {
                          _selectedCategories.add(cat.name);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // FSRS state filter
              Text('Card States',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _FilterChip(
                    label: 'New',
                    dotColor: AppColors.stateNew,
                    isSelected: _selectedStates.contains(0),
                    onTap: () => _toggleState(0),
                  ),
                  _FilterChip(
                    label: 'Learning',
                    dotColor: AppColors.stateLearning,
                    isSelected: _selectedStates.contains(1),
                    onTap: () => _toggleState(1),
                  ),
                  _FilterChip(
                    label: 'Review',
                    dotColor: AppColors.stateMastery,
                    isSelected: _selectedStates.contains(2),
                    onTap: () => _toggleState(2),
                  ),
                  _FilterChip(
                    label: 'Relearning',
                    dotColor: AppColors.actionHard,
                    isSelected: _selectedStates.contains(3),
                    onTap: () => _toggleState(3),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Due only toggle
              Row(
                children: [
                  Switch.adaptive(
                    value: _dueOnly,
                    onChanged: (v) => setState(() => _dueOnly = v),
                    activeTrackColor: AppColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Due only',
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurface,
                      )),
                ],
              ),
            ] else ...[
              // Manual deck: move selection
              Text('Select Moves',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: AppSpacing.sm),
              _ManualMoveSelector(
                selectedIds: _selectedMoveIds,
                onToggle: (id) => setState(() {
                  if (_selectedMoveIds.contains(id)) {
                    _selectedMoveIds.remove(id);
                  } else {
                    _selectedMoveIds.add(id);
                  }
                }),
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            // Session size
            Text('Session Size',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final size in [5, 10, 15, null])
                  _FilterChip(
                    label: size?.toString() ?? 'All',
                    isSelected: _sessionSize == size,
                    onTap: () => setState(() => _sessionSize = size),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Create button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _canCreate ? _create : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.accent.withValues(alpha: 0.3),
                ),
                child: const Text('Create Deck'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canCreate {
    if (_nameController.text.trim().isEmpty) return false;
    if (!_isSmart && _selectedMoveIds.isEmpty) return false;
    return true;
  }

  void _toggleState(int state) {
    setState(() {
      if (_selectedStates.contains(state)) {
        _selectedStates.remove(state);
      } else {
        _selectedStates.add(state);
      }
    });
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final id = const Uuid().v4();
    final dao = ref.read(decksDaoProvider);

    if (_isSmart) {
      final filter = DeckFilter(
        categories: _selectedCategories.toList(),
        fsrsStates: _selectedStates.toList(),
        dueOnly: _dueOnly,
      );
      await dao.insertDeck(DecksCompanion.insert(
        id: id,
        name: name,
        deckType: const Value('smart'),
        filterCriteria: Value(filter.toJson()),
        sessionSize: Value(_sessionSize),
      ));
    } else {
      await dao.insertDeck(DecksCompanion.insert(
        id: id,
        name: name,
        deckType: const Value('manual'),
        sessionSize: Value(_sessionSize),
      ));
      // Add selected moves
      for (final moveId in _selectedMoveIds) {
        await dao.addMoveToDeck(id, moveId);
      }
    }

    HapticFeedback.mediumImpact();
    if (mounted) Navigator.pop(context);
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected ? Colors.white : colorScheme.secondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.dotColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color? dotColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Move selector for manual decks — shows a scrollable list of all moves
/// with checkboxes.
class _ManualMoveSelector extends ConsumerWidget {
  const _ManualMoveSelector({
    required this.selectedIds,
    required this.onToggle,
  });

  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movesAsync = ref.watch(moveRepositoryProvider).watchAll();
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<Move>>(
      stream: movesAsync,
      builder: (context, snapshot) {
        final moves = snapshot.data ?? [];
        if (moves.isEmpty) {
          return Text('No moves available',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
              ));
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: moves.length,
            itemBuilder: (context, index) {
              final move = moves[index];
              final isSelected = selectedIds.contains(move.id);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isSelected
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: isSelected ? AppColors.accent : colorScheme.secondary,
                  size: 22,
                ),
                title: Text(
                  move.name,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                onTap: () => onToggle(move.id),
              );
            },
          ),
        );
      },
    );
  }
}
