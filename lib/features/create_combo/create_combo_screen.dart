import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/database/daos/combos_dao.dart';
import '../../core/design/spacing.dart';
import '../../core/design/theme.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/models/reviewable_item.dart';
import '../../core/providers.dart';
import '../../shared/widgets/combo_step_line.dart';
import '../../shared/widgets/secondary_button.dart';
import '../../shared/widgets/video_player_widget.dart'
    show RobustVideoPlayer, VideoPlaceholder;

class CreateComboScreen extends ConsumerStatefulWidget {
  const CreateComboScreen({super.key, this.comboId});

  final String? comboId;

  bool get isEditing => comboId != null;

  @override
  ConsumerState<CreateComboScreen> createState() => _CreateComboScreenState();
}

class _CreateComboScreenState extends ConsumerState<CreateComboScreen> {
  final List<Move> _selectedMoves = [];
  int _activeIndex = 0;
  String? _comboName;
  bool _isLoadingExisting = false;

  Set<String> get _selectedMoveIds =>
      _selectedMoves.map((move) => move.id).toSet();

  int get _totalCounts =>
      _selectedMoves.fold(0, (sum, m) => sum + m.count);

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadExistingCombo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final safeIndex = _selectedMoves.isEmpty
        ? 0
        : _activeIndex.clamp(0, _selectedMoves.length - 1);
    final currentMove = _selectedMoves.isNotEmpty
        ? _selectedMoves[safeIndex]
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Combo' : 'Create Combo'),
        actions: [
          if (_selectedMoves.isNotEmpty)
            TextButton(
              onPressed: () => _saveCombo(),
              child: Text('SAVE', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingExisting
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
                children: [
                  const SizedBox(height: AppSpacing.md),
                  if (currentMove != null && currentMove.videoPath != null)
                    RobustVideoPlayer(
                      key: ValueKey('${currentMove.id}:$safeIndex:${currentMove.contentHash}'),
                      videoPath: currentMove.resolvedVideoPath!,
                      autoPlay: true,
                    )
                  else
                    const VideoPlaceholder(),
                  const SizedBox(height: AppSpacing.lg),

                  // -- Beat Grid --
                  if (_selectedMoves.isNotEmpty) ...[
                    _buildBeatGrid(context),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  Text(
                    'SEQUENCE',
                    style: AppTypography.labelLarge.copyWith(
                      color: colorScheme.secondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ComboStepLine(
                    stepCount: _selectedMoves.length,
                    activeIndex: safeIndex,
                    onStepSelected: (index) =>
                        setState(() => _activeIndex = index),
                    onAddStep: _showMovePicker,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'ORDER',
                    style: AppTypography.labelLarge.copyWith(
                      color: colorScheme.secondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: _selectedMoves.length,
                    onReorder: _reorderMoves,
                    itemBuilder: (context, index) {
                      final move = _selectedMoves[index];
                      final isActive = index == safeIndex;
                      return Container(
                        key: ValueKey(move.id),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: ListTile(
                          onTap: () => setState(() => _activeIndex = index),
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: Text(
                            '${index + 1}',
                            style: AppTypography.titleMedium.copyWith(
                              color: isActive ? colorScheme.primary : colorScheme.outline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          title: Text(
                            move.name,
                            style: AppTypography.bodyMedium.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${move.count} BEATS${move.category != 'default' ? ' · ${move.category.toUpperCase()}' : ''}',
                            style: AppTypography.caption.copyWith(
                              color: colorScheme.secondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _CountControl(
                                icon: Icons.remove_rounded,
                                enabled: move.count > 1,
                                onTap: () => _adjustMoveCount(index, -1),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                '${move.count}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              _CountControl(
                                icon: Icons.add_rounded,
                                enabled: move.count < 16,
                                onTap: () => _adjustMoveCount(index, 1),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              ReorderableDragStartListener(
                                index: index,
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  color: colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SecondaryButton(
                    label: 'ADD MOVE',
                    onPressed: () => _showMovePicker(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
      ),
    );
  }

  Widget _buildBeatGrid(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = _totalCounts;
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BEAT GRID',
              style: AppTypography.labelLarge.copyWith(
                color: colorScheme.secondary,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              '$total BEATS',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 40,
          child: Row(
            children: [
              for (int i = 0; i < _selectedMoves.length; i++)
                _buildGridBlock(context, i, total),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildTimeline(total),
      ],
    );
  }

  Widget _buildGridBlock(BuildContext context, int index, int total) {
    final move = _selectedMoves[index];
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = index == _activeIndex;

    return Expanded(
      flex: move.count,
      child: GestureDetector(
        onTap: () => setState(() => _activeIndex = index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
            border: isActive
                ? null
                : Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          alignment: Alignment.center,
          child: Text(
            '${move.count}',
            style: AppTypography.caption.copyWith(
              color: isActive ? Colors.white : colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(int total) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Stack(
        children: [
          // We could add a playhead here if needed
        ],
      ),
    );
  }

  Future<void> _loadExistingCombo() async {
    setState(() => _isLoadingExisting = true);
    try {
      final combo = await ref.read(comboRepositoryProvider).getById(widget.comboId!);
      final movesWithDetail = await ref.read(comboRepositoryProvider).watchComboMoves(widget.comboId!).first;
      
      if (mounted) {
        setState(() {
          _comboName = combo.name;
          _selectedMoves.addAll(movesWithDetail.map((m) => m.move));
          _isLoadingExisting = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingExisting = false);
    }
  }

  void _showMovePicker() async {
    final result = await showModalBottomSheet<List<Move>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MovePickerSheet(
        alreadySelectedIds: _selectedMoveIds,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedMoves.addAll(result);
        _activeIndex = _selectedMoves.length - 1;
      });
    }
  }

  void _reorderMoves(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final move = _selectedMoves.removeAt(oldIndex);
      _selectedMoves.insert(newIndex, move);
      _activeIndex = newIndex;
    });
  }

  void _adjustMoveCount(int index, int delta) {
    setState(() {
      final move = _selectedMoves[index];
      final newCount = (move.count + delta).clamp(1, 16);
      _selectedMoves[index] = move.copyWith(count: newCount);
    });
  }

  Future<void> _saveCombo() async {
    final name = _comboName ?? await _promptForName();
    if (name == null || name.isEmpty) return;

    final comboId = widget.comboId ?? const Uuid().v4();
    final companion = CombosCompanion(
      id: Value(comboId),
      name: Value(name),
    );

    if (widget.isEditing) {
      await ref.read(comboRepositoryProvider).update(companion);
    } else {
      await ref.read(comboRepositoryProvider).insert(companion);
      unawaited(
        ref.read(fsrsCardsDaoProvider).ensureCard(comboId, entityType: 'combo'),
      );
    }

    if (mounted) context.pop();
  }

  Future<String?> _promptForName() async {
    final controller = TextEditingController(text: _comboName);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Combo Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Morning Flow'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('SAVE')),
        ],
      ),
    );
  }
}

class _CountControl extends StatelessWidget {
  const _CountControl({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? colorScheme.outline : colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? colorScheme.onSurface : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

class _MovePickerSheet extends ConsumerStatefulWidget {
  const _MovePickerSheet({required this.alreadySelectedIds});
  final Set<String> alreadySelectedIds;

  @override
  ConsumerState<_MovePickerSheet> createState() => _MovePickerSheetState();
}

class _MovePickerSheetState extends ConsumerState<_MovePickerSheet> {
  final List<Move> _selected = [];

  @override
  Widget build(BuildContext context) {
    final movesAsync = ref.watch(allMovesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pick Moves', style: AppTypography.titleSmall),
                  TextButton(
                    onPressed: _selected.isEmpty ? null : () => Navigator.pop(context, _selected),
                    child: const Text('ADD'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: movesAsync.when(
                data: (moves) {
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: moves.length,
                    itemBuilder: (context, index) {
                      final move = moves[index];
                      final isPicked = _selected.any((m) => m.id == move.id);
                      final isAlreadyInCombo = widget.alreadySelectedIds.contains(move.id);

                      return ListTile(
                        onTap: isAlreadyInCombo ? null : () {
                          setState(() {
                            if (isPicked) {
                              _selected.removeWhere((m) => m.id == move.id);
                            } else {
                              _selected.add(move);
                            }
                          });
                        },
                        leading: isPicked 
                          ? Icon(Icons.check_circle, color: colorScheme.primary)
                          : Icon(Icons.circle_outlined, color: colorScheme.outline),
                        title: Text(move.name, style: TextStyle(
                          color: isAlreadyInCombo ? colorScheme.outline : colorScheme.onSurface,
                        )),
                        subtitle: Text(move.category),
                        trailing: isAlreadyInCombo ? const Text('In Combo', style: TextStyle(fontSize: 10)) : null,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        );
      },
    );
  }
}

final allMovesProvider = StreamProvider<List<Move>>((ref) {
  return ref.watch(moveRepositoryProvider).watchAll();
});
