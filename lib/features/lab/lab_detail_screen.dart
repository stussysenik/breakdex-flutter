// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/features/flow/providers/aura_providers.dart';
import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/shared/widgets/app_screen.dart';
import 'package:breakdex/shared/widgets/notes_section.dart';
import 'package:breakdex/features/lab/providers/lab_providers.dart';
import 'package:breakdex/features/lab/widgets/lab_timeline.dart';
import 'package:breakdex/features/lab/widgets/linked_moves_section.dart';
import 'package:breakdex/features/lab/widgets/milestone_list.dart';
import 'package:breakdex/features/lab/widgets/set_builder.dart';
import 'package:breakdex/shared/widgets/app_sheet.dart';
import 'package:breakdex/shared/widgets/app_dialog.dart';

/// Full detail screen for a single lab (project or set).
///
/// Layout adapts based on lab type:
/// - **Set**: shows the horizontal Set Builder sequencer for move ordering,
///   plus milestones and notes.
/// - **Project**: shows a vertical timeline of entries/milestones, linked
///   moves, milestones list, and notes.
///
/// The header region includes:
/// - Editable lab name (tap to rename)
/// - Tappable status pill that cycles: idea -> attempting -> landed -> clean
/// - Lab type icon (science beaker for project, playlist for set)
/// - Relative creation time ("Created 78 days ago")
///
/// FAB at the bottom provides quick actions: add milestone, add entry
/// (project only), and link move.
class LabDetailScreen extends ConsumerStatefulWidget {
  const LabDetailScreen({super.key, required this.labId});

  final String labId;

  @override
  ConsumerState<LabDetailScreen> createState() => _LabDetailScreenState();
}

class _LabDetailScreenState extends ConsumerState<LabDetailScreen> {
  /// Status cycle order for the tappable status pill.
  static const _statusCycle = ['idea', 'attempting', 'landed', 'clean'];

  // ---------------------------------------------------------------------------
  // Status cycling
  // ---------------------------------------------------------------------------

  /// Advance the lab's status to the next stage in the cycle. Wraps around
  /// from 'clean' back to 'idea' so the user can reset if needed.
  Future<void> _cycleStatus(final Lab lab) async {
    final currentIndex = _statusCycle.indexOf(lab.status);
    final nextIndex = (currentIndex + 1) % _statusCycle.length;
    final nextStatus = _statusCycle[nextIndex];

    await ref
        .read(labsDaoProvider)
        .updateLab(
          LabsCompanion(
            id: drift.Value(lab.id),
            status: drift.Value(nextStatus),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
    unawaited(HapticFeedback.selectionClick());
  }

  // ---------------------------------------------------------------------------
  // Rename
  // ---------------------------------------------------------------------------

  Future<void> _rename(final Lab lab) async {
    final controller = TextEditingController(text: lab.name);
    final newName = await showAppDialog<String>(
      context: context,
      builder: (final ctx) {
        return AlertDialog(
          title: const Text('Rename Lab'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Lab name'),
            textInputAction: TextInputAction.done,
            onSubmitted: (final value) => Navigator.pop(ctx, value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty || newName == lab.name) return;

    await ref
        .read(labsDaoProvider)
        .updateLab(
          LabsCompanion(
            id: drift.Value(lab.id),
            name: drift.Value(newName),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
    unawaited(HapticFeedback.lightImpact());
  }

  // ---------------------------------------------------------------------------
  // Move picker bottom sheet
  // ---------------------------------------------------------------------------

  /// Shows a bottom sheet with a searchable list of all moves. When the user
  /// selects one, it's linked to the current lab. Already-linked moves are
  /// shown as disabled (greyed out) to prevent duplicates.
  Future<void> _showMovePicker() async {
    final labMoves = ref.read(labMovesProvider(widget.labId)).valueOrNull ?? [];
    final linkedMoveIds = labMoves.map((final e) => e.move.id).toSet();
    final lastMoveId = labMoves.isNotEmpty ? labMoves.last.move.id : null;

    if (!mounted) return;

    final selectedMoveId = await showAppSheet<String>(
      context: context,
      builder: (_) => _MovePickerSheet(
        linkedMoveIds: linkedMoveIds,
        lastMoveId: lastMoveId,
      ),
    );

    if (selectedMoveId == null || !mounted) return;

    await ref
        .read(labsDaoProvider)
        .addMoveToLab(widget.labId, selectedMoveId, labMoves.length);
    unawaited(HapticFeedback.mediumImpact());
  }

  // ---------------------------------------------------------------------------
  // Delete lab
  // ---------------------------------------------------------------------------

  Future<void> _deleteLab(final Lab lab) async {
    final confirm = await showAppDialog<bool>(
      context: context,
      builder: (final ctx) => AlertDialog(
        title: const Text('Delete Lab?'),
        content: Text(
          'Permanently delete "${lab.name}" and all its milestones, entries, and move links?',
        ),
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
    if (confirm != true || !mounted) return;

    await ref.read(labsDaoProvider).deleteLab(lab.id);
    unawaited(HapticFeedback.mediumImpact());
    if (mounted) context.pop();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(final BuildContext context) {
    final labAsync = ref.watch(labDetailProvider(widget.labId));
    final colorScheme = Theme.of(context).colorScheme;

    final lab = labAsync.valueOrNull;

    // `fill`, not the scrolling default: half the sections below are
    // deliberately full-bleed (the set sequencer scrolls edge to edge), so a
    // frame that applied the gutter to every child would inset them all.
    return AppScreen.fill(
      title: lab?.name ?? '',
      backIdentifier: 'lab-back',
      actions: lab == null
          ? const <Widget>[]
          : [
              PopupMenuButton<String>(
                icon: AppIconView(AppIcon.more, color: colorScheme.secondary),
                onSelected: (final value) {
                  switch (value) {
                    case 'rename':
                      _rename(lab);
                    case 'delete':
                      _deleteLab(lab);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete Lab',
                      style: TextStyle(
                        color: AppSemanticTheme.of(context).actionAgain,
                      ),
                    ),
                  ),
                ],
              ),
            ],
      child: labAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (final e, _) => Center(
          child: Text(
            'Error loading lab: $e',
            style: AppTypography.bodySmall.copyWith(
              color: AppSemanticTheme.of(context).actionAgain,
            ),
          ),
        ),
        data: (final lab) {
          if (lab == null) {
            return Center(
              child: Text(
                'Lab not found',
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            );
          }

          final isSet = lab.labType == 'set';

          return ListView(
            padding: EdgeInsets.only(bottom: AppScreen.bottomInsetOf(context)),
            children: [
              // The back affordance, the name, and the more-menu all moved
              // into the header band the frame owns. What is left is the
              // lab's substance.

              // -- Status pill (tappable) + metadata row --------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdge,
                ),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Tappable status pill
                    GestureDetector(
                      onTap: () => _cycleStatus(lab),
                      child: _LabStatusPill(status: lab.status),
                    ),
                    // Lab type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isSet ? 'Set' : 'Project',
                        style: AppTypography.caption.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // -- Created time ago -----------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdge,
                ),
                child: Text(
                  'Created ${_daysAgo(lab.createdAt)}',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // -- Type-specific content ------------------------------------
              if (isSet) ...[
                // Set Builder — horizontal move sequencer
                SetBuilder(labId: widget.labId, onAddMove: _showMovePicker),
                const SizedBox(height: AppSpacing.lg),
              ] else ...[
                // Project: Timeline view
                LabTimeline(labId: widget.labId),
                const SizedBox(height: AppSpacing.lg),

                // Project: Linked moves
                LinkedMovesSection(
                  labId: widget.labId,
                  onAddMove: _showMovePicker,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // -- Milestones (both types) ----------------------------------
              MilestoneList(labId: widget.labId),
              const SizedBox(height: AppSpacing.lg),

              // -- Notes (both types) ---------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdge,
                ),
                child: NotesSection(
                  notes: lab.notes,
                  onChanged: (final text) {
                    ref
                        .read(labsDaoProvider)
                        .updateLab(
                          LabsCompanion(
                            id: drift.Value(lab.id),
                            notes: drift.Value(text.isEmpty ? null : text),
                            updatedAt: drift.Value(DateTime.now()),
                          ),
                        );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // -- Danger zone / actions ------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdge,
                ),
                child: Divider(color: colorScheme.outline),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdge,
                ),
                child: Text(
                  'ACTIONS',
                  style: AppTypography.sectionHeader.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdge,
                ),
                child: _ActionRow(
                  icon: AppIcon.link.resolve(context),
                  label: 'Link Move',
                  onTap: _showMovePicker,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdge,
                ),
                child: _ActionRow(
                  icon: AppIcon.delete.resolve(context),
                  label: 'Delete Lab',
                  destructive: true,
                  onTap: () => _deleteLab(lab),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Returns a human-readable "X days ago" string from a creation date.
  String _daysAgo(final DateTime created) {
    final diff = DateTime.now().difference(created);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return '1 day ago';
    return '${diff.inDays} days ago';
  }
}

// =============================================================================
// Lab Status Pill — reusable, color-coded pill for the 4-stage progression
// =============================================================================

class _LabStatusPill extends StatelessWidget {
  const _LabStatusPill({required this.status});

  final String status;

  @override
  Widget build(final BuildContext context) {
    final (label, color) = _statusMeta(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 4),
          AppIconView(
            AppIcon.move,
            size: 12,
            color: color.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  static (String, Color) _statusMeta(
    final BuildContext context,
    final String status,
  ) => switch (status) {
    'idea' => ('Idea', const Color(0xFFA7B1C2)),
    'attempting' => ('Attempting', AppSemanticTheme.of(context).stateLearning),
    'landed' => ('Landed', AppSemanticTheme.of(context).stateMastery),
    'clean' => ('Clean', const Color(0xFF0D9F9A)),
    _ => ('Idea', const Color(0xFFA7B1C2)),
  };
}

// =============================================================================
// Move Picker Bottom Sheet — searchable list of all moves
// =============================================================================

class _MovePickerSheet extends ConsumerStatefulWidget {
  const _MovePickerSheet({required this.linkedMoveIds, this.lastMoveId});

  final Set<String> linkedMoveIds;
  final String? lastMoveId;

  @override
  ConsumerState<_MovePickerSheet> createState() => _MovePickerSheetState();
}

class _MovePickerSheetState extends ConsumerState<_MovePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final suggestedAsync = widget.lastMoveId != null
        ? ref.watch(naturalNextMovesProvider(widget.lastMoveId!))
        : null;
    final suggestedMoves = suggestedAsync?.valueOrNull ?? [];
    final suggestedIds = suggestedMoves.map((final m) => m.id).toSet();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (final context, final scrollController) {
        return Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdge,
              ),
              child: Text(
                'Add Move',
                style: AppTypography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdge,
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search moves...',
                  prefixIcon: AppIconView(AppIcon.search),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Move list
            Expanded(
              child: FutureBuilder<List<Move>>(
                future: ref.read(moveRepositoryProvider).getAll(),
                builder: (final context, final snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: AppLoader());
                  }

                  final allMoves = snapshot.data!;
                  final filtered = _query.isEmpty
                      ? allMoves
                      : allMoves
                            .where(
                              (final m) =>
                                  m.name.toLowerCase().contains(_query),
                            )
                            .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'No moves found',
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                    );
                  }

                  final items = _buildMoveItems(
                    filtered,
                    linkedMoveIds: widget.linkedMoveIds,
                    suggestedIds: suggestedIds,
                    colorScheme: colorScheme,
                  );

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenEdge,
                    ),
                    itemCount: items.length,
                    itemBuilder: (final context, final index) => items[index],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildMoveItems(
    final List<Move> moves, {
    required final Set<String> linkedMoveIds,
    required final Set<String> suggestedIds,
    required final ColorScheme colorScheme,
  }) {
    final suggested = <Move>[];
    final remaining = <Move>[];
    for (final move in moves) {
      if (suggestedIds.contains(move.id)) {
        suggested.add(move);
      } else {
        remaining.add(move);
      }
    }

    final items = <Widget>[];
    if (suggested.isNotEmpty && _query.isEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              AppIconView(
                AppIcon.discover,
                size: 14,
                color: AppSemanticTheme.of(context).stateMastery,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Suggested — flows naturally from previous move',
                style: AppTypography.caption.copyWith(
                  color: AppSemanticTheme.of(context).stateMastery,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
      for (final move in suggested) {
        items.add(
          _buildMoveTile(
            move,
            isLinked: linkedMoveIds.contains(move.id),
            isSuggested: true,
            colorScheme: colorScheme,
          ),
        );
      }
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Divider(color: colorScheme.outline.withValues(alpha: 0.15)),
        ),
      );
    }
    for (final move in remaining) {
      items.add(
        _buildMoveTile(
          move,
          isLinked: linkedMoveIds.contains(move.id),
          isSuggested: false,
          colorScheme: colorScheme,
        ),
      );
    }
    return items;
  }

  Widget _buildMoveTile(
    final Move move, {
    required final bool isLinked,
    required final bool isSuggested,
    required final ColorScheme colorScheme,
  }) {
    final accent = isSuggested
        ? AppSemanticTheme.of(context).stateMastery
        : Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isLinked
              ? colorScheme.surfaceContainerHighest
              : accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Center(
          child: Text(
            move.name.isNotEmpty ? move.name[0].toUpperCase() : '?',
            style: AppTypography.bodySmall.copyWith(
              color: isLinked ? colorScheme.secondary : accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      title: Text(
        move.name,
        style: AppTypography.bodySmall.copyWith(
          color: isLinked
              ? colorScheme.secondary.withValues(alpha: 0.5)
              : isSuggested
              ? accent
              : colorScheme.onSurface,
          fontWeight: isSuggested ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        move.category,
        style: AppTypography.caption.copyWith(color: colorScheme.secondary),
      ),
      trailing: isLinked
          ? AppIconView(
              AppIcon.check,
              color: AppSemanticTheme.of(context).stateMastery,
              size: 20,
            )
          : null,
      enabled: !isLinked,
      onTap: isLinked
          ? null
          : () {
              HapticFeedback.selectionClick();
              Navigator.pop(context, move.id);
            },
    );
  }
}

// =============================================================================
// Action Row — simple row with icon, label, chevron
// =============================================================================

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = destructive
        ? AppSemanticTheme.of(context).actionAgain
        : colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.32),
          ),
          boxShadow: AppShadows.soft(Theme.of(context).brightness),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTypography.bodyMedium.copyWith(color: color)),
            const Spacer(),
            AppIconView(
              AppIcon.forward,
              color: colorScheme.secondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
