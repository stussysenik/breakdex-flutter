import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/providers.dart';
import '../../shared/widgets/celebration_overlay.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/secondary_button.dart';
import '../../shared/widgets/timeline_node.dart';
import '../../shared/widgets/video_player_widget.dart' show RobustVideoPlayer, VideoPlaceholder;

class CreateComboScreen extends ConsumerStatefulWidget {
  const CreateComboScreen({super.key});

  @override
  ConsumerState<CreateComboScreen> createState() => _CreateComboScreenState();
}

class _CreateComboScreenState extends ConsumerState<CreateComboScreen> {
  final List<Move> _selectedMoves = [];
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentMove =
        _selectedMoves.isNotEmpty ? _selectedMoves[_activeIndex] : null;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenEdge),
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Create Combo',
              style: AppTypography.titleLarge.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Video preview
            if (currentMove?.videoPath != null)
              RobustVideoPlayer(videoPath: currentMove!.videoPath!)
            else
              const VideoPlaceholder(),
            const SizedBox(height: AppSpacing.lg),

            // Sequence section
            Text(
              'SEQUENCE',
              style: AppTypography.sectionHeader.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Timeline
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < _selectedMoves.length; i++)
                    GestureDetector(
                      onLongPress: () => _removeMoveAt(i),
                      child: TimelineNode(
                        index: i + 1,
                        style: i == _activeIndex
                            ? TimelineNodeStyle.active
                            : TimelineNodeStyle.inactive,
                        showLeadingLine: i > 0,
                        showTrailingLine: true,
                        onTap: () => setState(() => _activeIndex = i),
                      ),
                    ),
                  TimelineNode(
                    index: 0,
                    style: TimelineNodeStyle.add,
                    showLeadingLine: _selectedMoves.isNotEmpty,
                    showTrailingLine: false,
                    onTap: () => _showMovePicker(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Current move label + remove
            if (currentMove != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      currentMove.name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: _removeActiveMove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.xl),

            // Buttons
            SecondaryButton(
              label: 'ADD MOVE',
              onPressed: () => _showMovePicker(),
            ),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: 'SAVE COMBO',
              onPressed:
                  _selectedMoves.isEmpty ? null : () => _saveCombo(),
            ),
          ],
        ),
      ),
    );
  }

  void _removeActiveMove() {
    if (_selectedMoves.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMoves.removeAt(_activeIndex);
      if (_activeIndex >= _selectedMoves.length && _selectedMoves.isNotEmpty) {
        _activeIndex = _selectedMoves.length - 1;
      }
      if (_selectedMoves.isEmpty) _activeIndex = 0;
    });
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
                  trailing: Icon(
                    Icons.circle,
                    size: 10,
                    color: LearningState.fromString(move.learningState).color,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedMoves.add(move);
                      _activeIndex = _selectedMoves.length - 1;
                    });
                  },
                ),
          ],
        );
      },
    );
  }

  Future<void> _saveCombo() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name Your Combo'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Combo name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    HapticFeedback.mediumImpact();

    final comboId = const Uuid().v4();
    final comboRepo = ref.read(comboRepositoryProvider);

    await comboRepo.insert(CombosCompanion.insert(
      id: comboId,
      name: name,
    ));

    for (int i = 0; i < _selectedMoves.length; i++) {
      await comboRepo.addMove(ComboMovesCompanion.insert(
        id: const Uuid().v4(),
        sequenceIndex: i,
        comboId: comboId,
        moveId: _selectedMoves[i].id,
      ));
    }

    if (mounted) {
      setState(() {
        _selectedMoves.clear();
        _activeIndex = 0;
      });
      CelebrationOverlay.show(context, title: name);
    }
  }
}
