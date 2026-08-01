// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/features/lab/providers/lab_providers.dart';
import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/shared/widgets/app_dialog.dart';

/// Vertical list of milestones for a lab, with inline creation.
///
/// Each milestone row has:
/// - A checkbox that toggles completedAt (null <-> now)
/// - Title text (strikethrough + muted color when completed)
/// - Completion date shown beneath completed milestones
/// - Long press to delete
///
/// At the bottom, an inline TextField lets the user add a new milestone
/// without leaving the screen. Watches [labMilestonesProvider] for
/// reactive updates.
class MilestoneList extends ConsumerStatefulWidget {
  const MilestoneList({super.key, required this.labId});

  final String labId;

  @override
  ConsumerState<MilestoneList> createState() => _MilestoneListState();
}

class _MilestoneListState extends ConsumerState<MilestoneList> {
  final _addController = TextEditingController();
  final _addFocusNode = FocusNode();
  bool _showAddField = false;

  @override
  void dispose() {
    _addController.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addMilestone() async {
    final title = _addController.text.trim();
    if (title.isEmpty) return;

    final dao = ref.read(milestonesDaoProvider);
    await dao.insertMilestone(
      MilestonesCompanion.insert(
        id: const Uuid().v4(),
        labId: widget.labId,
        title: title,
      ),
    );

    _addController.clear();
    unawaited(HapticFeedback.lightImpact());
  }

  Future<void> _toggleMilestone(final Milestone milestone) async {
    final dao = ref.read(milestonesDaoProvider);
    if (milestone.completedAt != null) {
      await dao.uncomplete(milestone.id);
    } else {
      await dao.complete(milestone.id);
    }
    unawaited(HapticFeedback.selectionClick());
  }

  Future<void> _deleteMilestone(final Milestone milestone) async {
    final confirm = await showAppDialog<bool>(
      context: context,
      builder: (final ctx) => AlertDialog(
        title: const Text('Delete Milestone?'),
        content: Text('Remove "${milestone.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: AppSemanticTheme.of(context).actionAgain),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await ref.read(milestonesDaoProvider).deleteMilestone(milestone.id);
    unawaited(HapticFeedback.mediumImpact());
  }

  @override
  Widget build(final BuildContext context) {
    final milestonesAsync = ref.watch(labMilestonesProvider(widget.labId));
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
          ),
          child: Text(
            'MILESTONES',
            style: AppTypography.sectionHeader.copyWith(
              color: colorScheme.secondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Milestone rows
        milestonesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: AppLoader()),
          ),
          error: (final e, _) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdge,
            ),
            child: Text(
              'Error: $e',
              style: AppTypography.caption.copyWith(
                color: AppSemanticTheme.of(context).actionAgain,
              ),
            ),
          ),
          data: (final milestones) {
            if (milestones.isEmpty && !_showAddField) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdge,
                ),
                child: Text(
                  'No milestones yet',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.secondary.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdge,
              ),
              child: Column(
                children: [
                  for (final milestone in milestones)
                    _MilestoneRow(
                      milestone: milestone,
                      onToggle: () => _toggleMilestone(milestone),
                      onDelete: () => _deleteMilestone(milestone),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),

        // Add milestone inline
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
          ),
          child: _showAddField
              ? Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addController,
                        focusNode: _addFocusNode,
                        decoration: const InputDecoration(
                          hintText: 'Milestone title...',
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addMilestone(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      onPressed: () {
                        _addMilestone();
                        setState(() => _showAddField = false);
                      },
                      icon: AppIconView(
                        AppIcon.check,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _addController.clear();
                        setState(() => _showAddField = false);
                      },
                      icon: AppIconView(
                        AppIcon.close,
                        color: colorScheme.secondary,
                        size: 20,
                      ),
                    ),
                  ],
                )
              : GestureDetector(
                  onTap: () {
                    setState(() => _showAddField = true);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _addFocusNode.requestFocus();
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: Row(
                    children: [
                      AppIconView(
                        AppIcon.add,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Add milestone',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

// -- Milestone Row ------------------------------------------------------------

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.milestone,
    required this.onToggle,
    required this.onDelete,
  });

  final Milestone milestone;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isComplete = milestone.completedAt != null;

    return GestureDetector(
      onLongPress: onDelete,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: isComplete
                      ? AppSemanticTheme.of(context).stateMastery.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isComplete
                        ? AppSemanticTheme.of(context).stateMastery
                        : colorScheme.outline.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: isComplete
                    ? AppIconView(
                        AppIcon.check,
                        size: 14,
                        color: AppSemanticTheme.of(context).stateMastery,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            // Title + optional completion date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.title,
                    style: AppTypography.bodySmall.copyWith(
                      color: isComplete
                          ? colorScheme.secondary.withValues(alpha: 0.6)
                          : colorScheme.onSurface,
                      decoration: isComplete
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: colorScheme.secondary.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                  if (isComplete) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Completed ${DateFormat('MMM d').format(milestone.completedAt!)}',
                      style: AppTypography.caption.copyWith(
                        color: AppSemanticTheme.of(context).stateMastery.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  if (milestone.notes != null &&
                      milestone.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      milestone.notes!,
                      style: AppTypography.caption.copyWith(
                        color: colorScheme.secondary.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
