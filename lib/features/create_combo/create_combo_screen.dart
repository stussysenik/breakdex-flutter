import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/design/spacing.dart';
import '../../core/design/theme.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/providers.dart';
import '../../shared/widgets/combo_step_line.dart';
import '../../shared/widgets/primary_button.dart';
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
  bool _showBeatGrid = true;

  Set<String> get _selectedMoveIds =>
      _selectedMoves.map((move) => move.id).toSet();

  String? get _activeVideoPath => _selectedMoves
      .cast<Move?>()
      .firstWhere((move) => move?.videoPath != null, orElse: () => null)
      ?.videoPath;

  static const _bpm = 100;
  static double _countsToSeconds(int counts) => counts * (60 / _bpm);

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
      body: SafeArea(
        child: _isLoadingExisting
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.screenEdge),
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    widget.isEditing ? 'Edit Combo' : 'Create Combo',
                    style: AppTypography.titleLarge.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (_comboName != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _comboName!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  if (currentMove != null && currentMove.videoPath != null)
                    RobustVideoPlayer(
                      key: ValueKey('${currentMove.id}:$safeIndex'),
                      videoPath: currentMove.videoPath!,
                      autoPlay: true,
                    )
                  else
                    const VideoPlaceholder(),
                  const SizedBox(height: AppSpacing.lg),

                  // -- Beat Grid Toggle --
                  _buildToggleRow(context),
                  if (_showBeatGrid && _selectedMoves.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildBeatGrid(context),
                  ],
                  if (_selectedMoves.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildSummaryBar(context),
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'SEQUENCE',
                    style: AppTypography.sectionHeader.copyWith(
                      color: colorScheme.secondary,
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
                  if (currentMove != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            currentMove.name,
                            style: AppTypography.bodyMedium.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${safeIndex + 1}/${_selectedMoves.length}',
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    if (currentMove.category != 'default') ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        currentMove.category.toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: colorScheme.secondary,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  if (_selectedMoves.isNotEmpty) ...[
                    Text(
                      'ORDER',
                      style: AppTypography.sectionHeader.copyWith(
                        color: colorScheme.secondary,
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
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          decoration: AppSurfaces.panel(
                            context,
                            tone: isActive
                                ? AppSurfaceTone.emphasis
                                : AppSurfaceTone.base,
                            raised: true,
                            radius: AppRadius.md,
                            focused: isActive,
                          ),
                          child: ListTile(
                            onTap: () => setState(() => _activeIndex = index),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 2,
                            ),
                            leading: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? colorScheme.primary.withValues(
                                        alpha: 0.12,
                                      )
                                    : colorScheme.surfaceContainerHighest,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: AppTypography.caption.copyWith(
                                  color: isActive
                                      ? colorScheme.primary
                                      : colorScheme.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: Text(
                              move.name,
                              style: AppTypography.bodyMedium.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${move.count} counts${move.category != 'default' ? ' · ${move.category.toUpperCase()}' : ''}',
                              style: AppTypography.caption.copyWith(
                                color: colorScheme.secondary,
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
                                const SizedBox(width: 2),
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '${move.count}',
                                    style: AppTypography.caption.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                _CountControl(
                                  icon: Icons.add_rounded,
                                  enabled: move.count < 16,
                                  onTap: () => _adjustMoveCount(index, 1),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                IconButton(
                                  tooltip: 'Remove move',
                                  onPressed: () => _removeMoveAt(index),
                                  icon: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: colorScheme.secondary,
                                  ),
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Icon(
                                    Icons.drag_handle_rounded,
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  SecondaryButton(
                    label: 'ADD MOVE',
                    onPressed: () => _showMovePicker(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PrimaryButton(
                    label: widget.isEditing ? 'SAVE CHANGES' : 'SAVE COMBO',
                    onPressed: _selectedMoves.isEmpty
                        ? null
                        : () => _saveCombo(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildToggleRow(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showBeatGrid = !_showBeatGrid),
      child: Container(
        decoration: AppSurfaces.panel(context, radius: AppRadius.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Beat Grid Overlay',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            Container(
              width: 44, height: 26,
              decoration: BoxDecoration(
                color: _showBeatGrid
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: _showBeatGrid ? Alignment.centerRight : Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 22, height: 22,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
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
        Text(
          'BEAT GRID',
          style: AppTypography.sectionHeader.copyWith(
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: AppSurfaces.panel(context, radius: AppRadius.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    for (int i = 0; i < _selectedMoves.length; i++)
                      _buildGridBlock(context, i, total),
                  ],
                ),
              ),
              _buildCountAxis(total),
              const SizedBox(height: AppSpacing.sm),
              _buildTimeline(total),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(0),
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.secondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    _formatTime(_countsToSeconds(total)),
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.secondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridBlock(BuildContext context, int index, int total) {
    final colorScheme = Theme.of(context).colorScheme;
    final move = _selectedMoves[index];
    final isActive = index == _activeIndex;
    final colors = [
      const Color(0xFFE45D7A),
      const Color(0xFF2F6BFF),
      const Color(0xFF1F8A70),
      const Color(0xFFB7791F),
    ];
    final color = colors[index % colors.length];

    return Expanded(
      flex: move.count,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: GestureDetector(
          onTap: () => setState(() => _activeIndex = index),
          child: Container(
            decoration: BoxDecoration(
              color: isActive ? color : color.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(6),
              boxShadow: isActive
                  ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)]
                  : null,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  move.name,
                  style: AppTypography.caption.copyWith(
                    color: isActive ? Colors.white : color.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountAxis(int total) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 2, right: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 1; i <= total && i <= 16; i++)
            Text(
              '$i',
              style: AppTypography.caption.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (total > 16)
            Text(
              '...$total',
              style: AppTypography.caption.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 9,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(int total) {
    final colorScheme = Theme.of(context).colorScheme;
    int before = 0;
    for (int i = 0; i < _activeIndex; i++) {
      before += _selectedMoves[i].count;
    }
    final midpoint = before + _selectedMoves[_activeIndex].count / 2;
    final pct = total > 0 ? midpoint / total : 0.0;

    return SizedBox(
      height: 4,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          FractionallySizedBox(
            widthFactor: pct,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalSecs = _countsToSeconds(_totalCounts);

    return Container(
      decoration: AppSurfaces.panel(context, radius: AppRadius.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _summaryItem(context, _selectedMoves.length.toString(), 'MOVES', colorScheme.primary),
          _summaryItem(context, _totalCounts.toString(), 'COUNTS', const Color(0xFF2F6BFF)),
          _summaryItem(context, _formatTime(totalSecs), '@ $_bpm BPM', const Color(0xFF1F8A70)),
        ],
      ),
    );
  }

  Widget _summaryItem(
    BuildContext context, String value, String label, Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(double seconds) {
    final m = (seconds / 60).floor();
    final s = (seconds % 60).round();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _loadExistingCombo() async {
    final comboId = widget.comboId;
    if (comboId == null) return;

    setState(() => _isLoadingExisting = true);
    try {
      final combo = await ref.read(comboRepositoryProvider).getById(comboId);
      final comboMoves = await ref
          .read(comboRepositoryProvider)
          .watchComboMoves(comboId)
          .first;

      if (!mounted) return;
      setState(() {
        _comboName = combo.name;
        _selectedMoves
          ..clear()
          ..addAll(comboMoves.map((entry) => entry.move));
        _activeIndex = _selectedMoves.indexWhere(
          (move) => move.videoPath != null && move.videoPath!.isNotEmpty,
        );
        if (_activeIndex < 0) _activeIndex = 0;
        _isLoadingExisting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingExisting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load combo.')));
      Navigator.of(context).pop();
    }
  }

  void _reorderMoves(int oldIndex, int newIndex) {
    HapticFeedback.selectionClick();
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final move = _selectedMoves.removeAt(oldIndex);
      _selectedMoves.insert(newIndex, move);

      if (_selectedMoves.isEmpty) {
        _activeIndex = 0;
        return;
      }

      if (_activeIndex == oldIndex) {
        _activeIndex = newIndex;
      } else if (oldIndex < _activeIndex && newIndex >= _activeIndex) {
        _activeIndex -= 1;
      } else if (oldIndex > _activeIndex && newIndex <= _activeIndex) {
        _activeIndex += 1;
      }
    });
  }

  Future<String?> _promptForComboName() async {
    final nameController = TextEditingController(text: _comboName ?? '');
    String? errorText;

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Name Your Combo'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Combo name',
              errorText: errorText,
            ),
            onChanged: (_) {
              if (errorText != null) {
                setDialogState(() => errorText = null);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final naming = ref.read(reviewableNamingServiceProvider);
                final normalized = naming.normalize(nameController.text);
                if (normalized.isEmpty) {
                  setDialogState(() => errorText = 'Enter a combo name.');
                  return;
                }
                final exists = await naming.isNameTaken(normalized);
                if (!context.mounted) return;
                if (exists) {
                  setDialogState(
                    () => errorText = '"$normalized" already exists.',
                  );
                  await HapticFeedback.heavyImpact();
                  return;
                }
                Navigator.pop(context, normalized);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeMoveAt(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMoves.removeAt(index);
      if (_activeIndex >= _selectedMoves.length && _selectedMoves.isNotEmpty) {
        _activeIndex = _selectedMoves.length - 1;
      }
      if (_selectedMoves.isEmpty) _activeIndex = 0;
    });
  }

  void _adjustMoveCount(int index, int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      final move = _selectedMoves[index];
      final newCount = (move.count + delta).clamp(1, 16);
      _selectedMoves[index] = move.copyWith(count: newCount);
    });
  }

  Future<void> _showMovePicker() async {
    final moves = await ref.read(moveRepositoryProvider).getAll();
    final selectedIds = _selectedMoveIds;
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.screenEdge),
          children: [
            Text(
              'Pick a Move',
              style: AppTypography.titleMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (moves.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Text(
                    'No moves yet — add some first!',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              )
            else
              for (final move in moves)
                ListTile(
                  title: Text(move.name),
                  subtitle: Text(
                    selectedIds.contains(move.id)
                        ? 'Already in this combo'
                        : '${move.count} counts${move.category != 'default' ? ' · ${move.category.toUpperCase()}' : ''}',
                    style: TextStyle(
                      color: selectedIds.contains(move.id)
                          ? Theme.of(context).colorScheme.secondary
                          : null,
                    ),
                  ),
                  trailing: Icon(
                    selectedIds.contains(move.id)
                        ? Icons.check_circle
                        : Icons.circle,
                    size: 10,
                    color: selectedIds.contains(move.id)
                        ? Theme.of(context).colorScheme.primary
                        : context.stateColor(
                            LearningState.fromString(move.learningState),
                          ),
                  ),
                  enabled: !selectedIds.contains(move.id),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedMoves.add(move);
                      _activeIndex = _selectedMoves.length - 1;
                    });
                    HapticFeedback.selectionClick();
                  },
                ),
          ],
        );
      },
    );
  }

  Future<void> _saveCombo() async {
    if (widget.isEditing) {
      final didSave = await _updateCombo();
      if (didSave && mounted) {
        Navigator.of(context).pop(_comboName);
      }
      return;
    }

    final name = await _promptForComboName();
    if (name == null || name.isEmpty) return;
    _comboName = name;

    await HapticFeedback.mediumImpact();

    final comboId = const Uuid().v4();
    final db = ref.read(databaseProvider);
    final syncDao = ref.read(syncDaoProvider);
    final loggedIn = ref.read(isLoggedInProvider);

    try {
      final activeVideoPath = _activeVideoPath;
      final comboMoveEntries = List.generate(
        _selectedMoves.length,
        (index) => (
          id: const Uuid().v4(),
          sequenceIndex: index,
          moveId: _selectedMoves[index].id,
        ),
      );

      await db.transaction(() async {
        await db
            .into(db.combos)
            .insert(
              CombosCompanion.insert(
                id: comboId,
                name: name,
                activeVideoPath: Value(activeVideoPath),
              ),
            );

        for (final entry in comboMoveEntries) {
          await db
              .into(db.comboMoves)
              .insert(
                ComboMovesCompanion.insert(
                  id: entry.id,
                  sequenceIndex: entry.sequenceIndex,
                  comboId: comboId,
                  moveId: entry.moveId,
                ),
              );
        }

        await ref
            .read(fsrsCardsDaoProvider)
            .ensureCard(comboId, entityType: 'combo');

        if (loggedIn) {
          await syncDao.logChange(
            entityId: comboId,
            table: 'combos',
            action: 'create',
            hasVideo: activeVideoPath != null,
          );
          for (final entry in comboMoveEntries) {
            await syncDao.logChange(
              entityId: entry.id,
              table: 'combo_moves',
              action: 'create',
            );
          }
          await syncDao.logChange(
            entityId: comboId,
            table: 'fsrs_cards',
            action: 'create',
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$e'.contains('duplicate')
                  ? 'Combo names must stay unique and a move can only appear once per combo.'
                  : 'Failed to save combo: $e',
            ),
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.of(context).pop(name);
    }
  }

  Future<bool> _updateCombo() async {
    final comboId = widget.comboId;
    final comboName = _comboName;
    if (comboId == null || comboName == null) return false;

    final db = ref.read(databaseProvider);
    final syncDao = ref.read(syncDaoProvider);
    final loggedIn = ref.read(isLoggedInProvider);
    final activeVideoPath = _activeVideoPath;

    try {
      await db.transaction(() async {
        final combo = await (db.select(
          db.combos,
        )..where((table) => table.id.equals(comboId))).getSingle();

        if (combo.activeVideoPath != activeVideoPath) {
          await (db.update(db.combos)
                ..where((table) => table.id.equals(comboId)))
              .write(CombosCompanion(activeVideoPath: Value(activeVideoPath)));

          if (loggedIn) {
            await syncDao.logChange(
              entityId: comboId,
              table: 'combos',
              action: 'update',
              hasVideo: activeVideoPath != null,
            );
          }
        }

        final existingRows = await (db.select(
          db.comboMoves,
        )..where((table) => table.comboId.equals(comboId))).get();
        final existingByMoveId = {
          for (final row in existingRows) row.moveId: row,
        };
        final nextMoveIds = _selectedMoveIds;

        for (final row in existingRows) {
          if (!nextMoveIds.contains(row.moveId)) {
            await (db.delete(
              db.comboMoves,
            )..where((table) => table.id.equals(row.id))).go();
            if (loggedIn) {
              await syncDao.logChange(
                entityId: row.id,
                table: 'combo_moves',
                action: 'delete',
              );
            }
          }
        }

        for (int index = 0; index < _selectedMoves.length; index++) {
          final move = _selectedMoves[index];
          final existing = existingByMoveId[move.id];
          if (existing == null) {
            final id = const Uuid().v4();
            await db
                .into(db.comboMoves)
                .insert(
                  ComboMovesCompanion.insert(
                    id: id,
                    sequenceIndex: index,
                    comboId: comboId,
                    moveId: move.id,
                  ),
                );
            if (loggedIn) {
              await syncDao.logChange(
                entityId: id,
                table: 'combo_moves',
                action: 'create',
              );
            }
            continue;
          }

          if (existing.sequenceIndex != index) {
            await (db.update(db.comboMoves)
                  ..where((table) => table.id.equals(existing.id)))
                .write(ComboMovesCompanion(sequenceIndex: Value(index)));
            if (loggedIn) {
              await syncDao.logChange(
                entityId: existing.id,
                table: 'combo_moves',
                action: 'update',
              );
            }
          }
        }
      });
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$e'.contains('duplicate')
                  ? 'A move can only appear once per combo.'
                  : 'Failed to update combo: $e',
            ),
          ),
        );
      }
      return false;
    }
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
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: enabled
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled
                ? colorScheme.outline.withValues(alpha: 0.3)
                : colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
