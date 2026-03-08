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

  Set<String> get _selectedMoveIds =>
      _selectedMoves.map((move) => move.id).toSet();

  String? get _activeVideoPath => _selectedMoves
      .cast<Move?>()
      .firstWhere((move) => move?.videoPath != null, orElse: () => null)
      ?.videoPath;

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
                            subtitle: move.category == 'default'
                                ? null
                                : Text(
                                    move.category.toUpperCase(),
                                    style: AppTypography.caption.copyWith(
                                      color: colorScheme.secondary,
                                      letterSpacing: 1,
                                    ),
                                  ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                  HapticFeedback.heavyImpact();
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

  Future<void> _showMovePicker() async {
    final moves = await ref.read(moveRepositoryProvider).getAll();
    final selectedIds = _selectedMoveIds;
    if (!mounted) return;

    showModalBottomSheet(
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
                  subtitle: selectedIds.contains(move.id)
                      ? const Text('Already in this combo')
                      : null,
                  trailing: Icon(
                    selectedIds.contains(move.id)
                        ? Icons.check_circle
                        : Icons.circle,
                    size: 10,
                    color: selectedIds.contains(move.id)
                        ? Theme.of(context).colorScheme.primary
                        : LearningState.fromString(move.learningState).color,
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

    HapticFeedback.mediumImpact();

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
