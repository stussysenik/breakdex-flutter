import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/reviewable_item.dart';
import '../../core/providers.dart';
import '../../core/utils/diagnostics.dart';
import '../../shared/widgets/beat_grid.dart';
import '../../shared/widgets/combo_step_line.dart';
import '../combos/plan_combo_flow.dart';
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

enum _ScreenState { editing, saving, saved }

class _CreateComboScreenState extends ConsumerState<CreateComboScreen> {
  final List<Move> _selectedMoves = [];
  int _activeIndex = 0;
  String? _comboName;
  bool _isLoadingExisting = false;
  _ScreenState _screenState = _ScreenState.editing;

  Set<String> get _selectedMoveIds =>
      _selectedMoves.map((final move) => move.id).toSet();

  @override
  void initState() {
    super.initState();
    DiagnosticsLog.info('CreateCombo', 'initState isEditing=${widget.isEditing} comboId=${widget.comboId ?? "null"}');
    if (widget.isEditing) {
      _loadExistingCombo();
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final safeIndex = _selectedMoves.isEmpty
        ? 0
        : _activeIndex.clamp(0, _selectedMoves.length - 1);
    final currentMove = _selectedMoves.isNotEmpty
        ? _selectedMoves[safeIndex]
        : null;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: _renameCombo,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _comboName ?? (widget.isEditing ? 'Edit Combo' : 'Create Combo'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit, size: 14, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6)),
                ],
              ),
            ),
            actions: [
              if (_selectedMoves.isNotEmpty && _screenState != _ScreenState.saving)
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

                  // -- Beat Grid (renders its own moves/beats summary) --
                  if (_selectedMoves.isNotEmpty) ...[
                    BeatGrid(
                      items: [
                        for (int i = 0; i < _selectedMoves.length; i++)
                          BeatGridItem(
                            label: _selectedMoves[i].name,
                            count: _selectedMoves[i].count,
                            isActive: i == safeIndex,
                            onTap: () => setState(() => _activeIndex = i),
                          ),
                      ],
                    ),
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
                    onStepSelected: (final index) =>
                        setState(() => _activeIndex = index),
                    onAddStep: _showMovePicker,
                    beatCounts: _selectedMoves.map((final m) => m.count).toList(),
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
                    itemBuilder: (final context, final index) {
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
        ),
        if (_screenState == _ScreenState.saving)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: AppSpacing.md),
                    Text('Saving combo...', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
      ],
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
          _selectedMoves.addAll(movesWithDetail.map((final m) => m.move));
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
      builder: (final context) => _MovePickerSheet(
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

  void _reorderMoves(final int oldIndex, final int newIndex) {
    setState(() {
      int effectiveNewIndex = newIndex;
      if (effectiveNewIndex > oldIndex) effectiveNewIndex -= 1;
      final move = _selectedMoves.removeAt(oldIndex);
      _selectedMoves.insert(effectiveNewIndex, move);
      _activeIndex = effectiveNewIndex;
    });
  }

  void _adjustMoveCount(final int index, final int delta) {
    setState(() {
      final move = _selectedMoves[index];
      final newCount = (move.count + delta).clamp(1, 16);
      _selectedMoves[index] = move.copyWith(count: newCount);
    });
  }

  Future<void> _saveCombo() async {
    if (_screenState == _ScreenState.saving) return;
    setState(() => _screenState = _ScreenState.saving);
    final name = _comboName ?? await _promptForName();
    if (name == null || name.isEmpty) {
      if (mounted) setState(() => _screenState = _ScreenState.editing);
      return;
    }

    final comboId = widget.comboId ?? const Uuid().v4();
    final log = StageLogger.begin('_saveCombo', subsystem: 'CreateCombo', context: {
      'comboId': comboId,
      'name': name,
      'moveCount': _selectedMoves.length,
      'isEditing': widget.isEditing,
    });

    try {
      final companion = CombosCompanion(
        id: Value(comboId),
        name: Value(name),
      );

      if (widget.isEditing) {
        await ref.read(comboRepositoryProvider).update(companion);
        log.stage('comboUpdated');
        final db = ref.read(databaseProvider);
        await db.combosDao.deleteAllMovesForCombo(comboId);
        log.stage('oldMovesCleared');
      } else {
        await ref.read(comboRepositoryProvider).insert(companion);
        log.stage('comboInserted');
        unawaited(
          ref.read(fsrsCardsDaoProvider).ensureCard(comboId, entityType: 'combo'),
        );
      }

      for (var i = 0; i < _selectedMoves.length; i++) {
        final move = _selectedMoves[i];
        await ref.read(comboRepositoryProvider).addMove(
              ComboMovesCompanion(
                id: Value(const Uuid().v4()),
                sequenceIndex: Value(i),
                comboId: Value(comboId),
                moveId: Value(move.id),
                count: Value(move.count),
              ),
            );
      }
      log.stage('movesPersisted', {'count': _selectedMoves.length});
      log.complete();

      if (mounted) {
        setState(() => _screenState = _ScreenState.saved);
        _comboName = name;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Combo updated successfully' : 'Combo created successfully'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (widget.isEditing) {
          unawaited(Future<void>.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) setState(() => _screenState = _ScreenState.editing);
          }));
        } else {
          // New combo is born as an idea — offer to put it on the calendar
          // while this screen (and its ref) is still alive, then leave.
          await _offerPlanIt(comboId);
          if (mounted) context.pop();
        }
      }
    } catch (e, stack) {
      log.fail(e, stack);
      if (mounted) {
        setState(() => _screenState = _ScreenState.editing);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save combo: $e')),
        );
      }
    }
  }

  /// Post-create affordance: "Plan it?" — accepting opens the date picker
  /// and persists a plan for the freshly created combo.
  Future<void> _offerPlanIt(final String comboId) async {
    final wantsPlan = await showModalBottomSheet<bool>(
      context: context,
      builder: (final sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenEdge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Plan it?',
                  style: AppTypography.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Put this combo on a practice day.',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: const Text('Not now'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: const Text('Pick a day'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (wantsPlan != true || !mounted) return;
    await planComboFlow(context, ref, comboId: comboId);
  }

  void _renameCombo() async {
    final name = await _promptForName();
    if (name != null && name.isNotEmpty && mounted) {
      setState(() => _comboName = name);
    }
  }

  Future<String?> _promptForName() async {
    final controller = TextEditingController(text: _comboName);
    return showDialog<String>(
      context: context,
      builder: (final context) => AlertDialog(
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
  Widget build(final BuildContext context) {
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
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final movesAsync = ref.watch(allMovesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (final context, final scrollController) {
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
                    child: Text(
                      _selected.isEmpty ? 'ADD' : 'ADD ${_selected.length}',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search moves…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor:
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: movesAsync.when(
                data: (final allMoves) {
                  final moves = _query.isEmpty
                      ? allMoves
                      : allMoves
                          .where((final m) =>
                              m.name.toLowerCase().contains(_query) ||
                              m.category.toLowerCase().contains(_query))
                          .toList();
                  if (moves.isEmpty) {
                    return Center(
                      child: Text(
                        'No moves match "$_query"',
                        style: AppTypography.bodySmall
                            .copyWith(color: colorScheme.secondary),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: moves.length,
                    itemBuilder: (final context, final index) {
                      final move = moves[index];
                      final isPicked = _selected.any((final m) => m.id == move.id);
                      final isAlreadyInCombo = widget.alreadySelectedIds.contains(move.id);

                      return ListTile(
                        onTap: isAlreadyInCombo ? null : () {
                          setState(() {
                            if (isPicked) {
                              _selected.removeWhere((final m) => m.id == move.id);
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
                error: (final e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        );
      },
    );
  }
}

final allMovesProvider = StreamProvider<List<Move>>((final ref) {
  return ref.watch(moveRepositoryProvider).watchAll();
});
