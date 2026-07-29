// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/utils/diagnostics.dart';
import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/features/flow/providers/aura_providers.dart';
import 'package:breakdex/features/flow/widgets/aura_link_tile.dart'
    show AuraAffinity;
import 'package:breakdex/core/design/icons.dart';

// ---------------------------------------------------------------------------
// MoveAuraSection — compact aura flow display for the Move Detail screen.
// ---------------------------------------------------------------------------

/// Shows incoming and outgoing aura links for a given move as colored pills.
///
/// **"Flows into"** = outgoing links (this move -> target move).
/// **"Flows from"** = incoming links (source move -> this move).
///
/// Each pill is colored using the Pokemon-inspired affinity scheme:
/// - Green (natural) — the transition flows effortlessly.
/// - Amber (possible) — workable but requires setup.
/// - Red (stretch) — forcing this transition is risky.
///
/// Tapping a pill navigates to that connected move's detail screen.
/// A small "+" button at the end of each row opens a quick picker
/// to add a new connection.
///
/// Designed to sit inside the move detail [ListView] without dominating
/// the screen — compact header, horizontal [Wrap] layout, subtle empty state.
class MoveAuraSection extends ConsumerWidget {
  const MoveAuraSection({super.key, required this.moveId});

  final String moveId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final outgoingAsync = ref.watch(auraLinksFromProvider(moveId));
    final incomingAsync = ref.watch(auraLinksToProvider(moveId));
    final colorScheme = Theme.of(context).colorScheme;

    // Resolve both streams — show nothing while loading.
    final outgoing = outgoingAsync.valueOrNull ?? [];
    final incoming = incomingAsync.valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header — uppercase caption with auto_awesome icon.
        Row(
          children: [
            AppIconView(
              AppIcon.discover,
              size: 14,
              color: colorScheme.secondary,
            ),
            const SizedBox(width: 6),
            Text(
              'AURA',
              style: AppTypography.sectionHeader.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        if (outgoing.isEmpty && incoming.isEmpty)
          _EmptyAuraState(moveId: moveId)
        else ...[
          // "Flows into" — outgoing links
          if (outgoing.isNotEmpty || incoming.isNotEmpty)
            _AuraFlowRow(
              label: 'Flows into',
              links: outgoing,
              moveId: moveId,
              direction: _FlowDirection.outgoing,
            ),
          if (outgoing.isNotEmpty && incoming.isNotEmpty)
            const SizedBox(height: AppSpacing.sm),
          if (incoming.isNotEmpty)
            _AuraFlowRow(
              label: 'Flows from',
              links: incoming,
              moveId: moveId,
              direction: _FlowDirection.incoming,
            ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Flow direction — determines which end of the link to display.
// ---------------------------------------------------------------------------

enum _FlowDirection { outgoing, incoming }

// ---------------------------------------------------------------------------
// _AuraFlowRow — a labeled row of colored pills for one direction.
// ---------------------------------------------------------------------------

class _AuraFlowRow extends ConsumerWidget {
  const _AuraFlowRow({
    required this.label,
    required this.links,
    required this.moveId,
    required this.direction,
  });

  final String label;
  final List<AuraLink> links;
  final String moveId;
  final _FlowDirection direction;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // Collect the connected move IDs so we can resolve names.
    final connectedIds = links
        .map(
          (final l) => switch (direction) {
            _FlowDirection.outgoing => l.toMoveId,
            _FlowDirection.incoming => l.fromMoveId,
          },
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-label
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: colorScheme.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Pills in a Wrap layout
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < links.length; i++)
              _AuraPill(
                link: links[i],
                connectedMoveId: connectedIds[i],
                direction: direction,
              ),
            // "+" add connection button
            _AddConnectionButton(moveId: moveId, direction: direction),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _AuraPill — a single colored chip showing the connected move's name.
// ---------------------------------------------------------------------------

/// Resolves the connected move's name reactively and renders a tappable pill.
///
/// The pill color is determined by the link's affinity:
/// - Green for natural, amber for possible, red for stretch.
/// Tapping navigates to the connected move's detail screen so the user
/// can explore the transition chain.
class _AuraPill extends ConsumerWidget {
  const _AuraPill({
    required this.link,
    required this.connectedMoveId,
    required this.direction,
  });

  final AuraLink link;
  final String connectedMoveId;
  final _FlowDirection direction;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final affinity = AuraAffinity.fromString(link.affinity);
    final affinityColor = affinity.color(context);

    // Watch the connected move reactively — name updates propagate instantly.
    final moveStream = ref
        .watch(moveRepositoryProvider)
        .watchById(connectedMoveId);

    return StreamBuilder<Move>(
      stream: moveStream,
      builder: (final context, final snapshot) {
        final moveName = snapshot.data?.name ?? '...';

        return GestureDetector(
          onTap: () {
            unawaited(HapticFeedback.selectionClick());
            context.push('/moves/move/$connectedMoveId');
          },
          onLongPress: () => _showAffinitySheet(context, ref, moveName),
          child: Semantics(
            label: '$moveName (${affinity.label}). Long press to delete.',
            button: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: affinityColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: affinityColor.withValues(alpha: 0.24),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Small affinity dot
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: affinityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  // Move name
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      moveName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: affinityColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAffinitySheet(
    final BuildContext context,
    final WidgetRef ref,
    final String moveName,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final currentAffinity = AuraAffinity.fromString(link.affinity);

    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (final ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenEdge,
                  AppSpacing.lg,
                  AppSpacing.screenEdge,
                  AppSpacing.md,
                ),
                child: Text(
                  'Connection to "$moveName"',
                  style: AppTypography.titleSmall,
                ),
              ),
              for (final affinity in AuraAffinity.values)
                ListTile(
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: affinity.color(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(affinity.label, style: AppTypography.bodyMedium),
                  trailing: currentAffinity == affinity
                      ? AppIconView(
                          AppIcon.check,
                          color: colorScheme.primary,
                          size: 20,
                        )
                      : null,
                  onTap: () => Navigator.pop(ctx, affinity.name),
                ),
              const Divider(),
              ListTile(
                leading: const AppIconView(
                  AppIcon.delete,
                  color: Colors.red,
                  size: 20,
                ),
                title: Text(
                  'Remove Connection',
                  style: AppTypography.bodyMedium.copyWith(color: Colors.red),
                ),
                onTap: () => Navigator.pop(ctx, '__delete__'),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null) return;
    final dao = ref.read(auraDaoProvider);

    if (result == '__delete__') {
      DiagnosticsLog.info(
        'AuraPill',
        'Deleting aura link ${link.fromMoveId}→${link.toMoveId} (was ${link.affinity})',
      );
      await dao.deleteLink(link.fromMoveId, link.toMoveId);
      DiagnosticsLog.info('AuraPill', 'Aura link deleted OK');
      unawaited(HapticFeedback.mediumImpact());
    } else {
      DiagnosticsLog.info(
        'AuraPill',
        'Changing aura link ${link.fromMoveId}→${link.toMoveId} from ${link.affinity} to $result',
      );
      await dao.upsertLink(link.fromMoveId, link.toMoveId, result);
      DiagnosticsLog.info('AuraPill', 'Aura affinity updated OK');
      unawaited(HapticFeedback.selectionClick());
    }
  }
}

// ---------------------------------------------------------------------------
// _AddConnectionButton — small "+" pill to add a new aura link.
// ---------------------------------------------------------------------------

class _AddConnectionButton extends ConsumerWidget {
  const _AddConnectionButton({required this.moveId, required this.direction});

  final String moveId;
  final _FlowDirection direction;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _showAddConnectionSheet(context, ref),
      child: Semantics(
        label: 'Add connection',
        button: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: AppIconView(
            AppIcon.add,
            size: 14,
            color: colorScheme.secondary.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddConnectionSheet(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
    final result =
        await showModalBottomSheet<({String targetMoveId, String affinity})>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _QuickAddSheet(moveId: moveId, direction: direction),
        );

    if (result == null) return;

    final dao = ref.read(auraDaoProvider);
    // Direction determines which end of the link this move occupies.
    switch (direction) {
      case _FlowDirection.outgoing:
        await dao.upsertLink(moveId, result.targetMoveId, result.affinity);
      case _FlowDirection.incoming:
        await dao.upsertLink(result.targetMoveId, moveId, result.affinity);
    }
    unawaited(HapticFeedback.mediumImpact());
  }
}

// ---------------------------------------------------------------------------
// _QuickAddSheet — searchable bottom sheet for adding an aura connection.
// ---------------------------------------------------------------------------

/// A streamlined version of the aura add-connection sheet, reusing the same
/// search + affinity-button pattern from `aura_view.dart` but scoped to the
/// move detail context. Filters out the current move and already-linked moves.
class _QuickAddSheet extends ConsumerStatefulWidget {
  const _QuickAddSheet({required this.moveId, required this.direction});

  final String moveId;
  final _FlowDirection direction;

  @override
  ConsumerState<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<_QuickAddSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
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
    final movesAsync = ref.watch(_allMovesForPickerProvider);

    // Determine which direction's existing links to exclude.
    final existingLinksAsync = switch (widget.direction) {
      _FlowDirection.outgoing => ref.watch(
        auraLinksFromProvider(widget.moveId),
      ),
      _FlowDirection.incoming => ref.watch(auraLinksToProvider(widget.moveId)),
    };

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (final context, final scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.lg,
            AppSpacing.screenEdge,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                widget.direction == _FlowDirection.outgoing
                    ? 'Add Outgoing Transition'
                    : 'Add Incoming Transition',
                style: AppTypography.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.direction == _FlowDirection.outgoing
                    ? 'Which moves does this flow into?'
                    : 'Which moves flow into this one?',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Search field
              Semantics(
                label: 'Search moves',
                textField: true,
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search moves...',
                    prefixIcon: AppIconView(AppIcon.search),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Move list
              Expanded(
                child: movesAsync.when(
                  loading: () => const Center(child: AppLoader()),
                  error: (final e, _) => Center(child: Text('Error: $e')),
                  data: (final moves) {
                    // Build set of already-linked IDs to exclude.
                    final existingIds = (existingLinksAsync.valueOrNull ?? [])
                        .map(
                          (final l) => switch (widget.direction) {
                            _FlowDirection.outgoing => l.toMoveId,
                            _FlowDirection.incoming => l.fromMoveId,
                          },
                        )
                        .toSet();

                    final filtered = moves
                        .where(
                          (final m) =>
                              m.id != widget.moveId &&
                              !existingIds.contains(m.id) &&
                              (_searchQuery.isEmpty ||
                                  m.name.toLowerCase().contains(_searchQuery)),
                        )
                        .toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'No matching moves.'
                              : 'All moves are already connected.',
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (final context, final index) {
                        final move = filtered[index];
                        return _QuickMoveRow(
                          moveName: move.name,
                          onSelect: (final affinity) {
                            Navigator.pop(context, (
                              targetMoveId: move.id,
                              affinity: affinity.name,
                            ));
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _QuickMoveRow — move name + 3 affinity quick-select buttons.
// ---------------------------------------------------------------------------

class _QuickMoveRow extends StatelessWidget {
  const _QuickMoveRow({required this.moveName, required this.onSelect});

  final String moveName;
  final ValueChanged<AuraAffinity> onSelect;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: AppSurfaces.panel(context, radius: AppRadius.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              moveName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Three affinity quick-select buttons: Natural / Possible / Stretch
          for (final affinity in AuraAffinity.values)
            Padding(
              padding: EdgeInsets.only(
                left: affinity == AuraAffinity.natural ? 0 : 8,
              ),
              child: GestureDetector(
                onTap: () => onSelect(affinity),
                child: Semantics(
                  label: 'Rate as ${affinity.label}',
                  button: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: affinity.color(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      affinity.label.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: affinity.color(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _EmptyAuraState — subtle empty state when no links exist.
// ---------------------------------------------------------------------------

class _EmptyAuraState extends ConsumerWidget {
  const _EmptyAuraState({required this.moveId});

  final String moveId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _showAddConnectionSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconView(
              AppIcon.add,
              size: 16,
              color: colorScheme.secondary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            Text(
              'Tap to rate transitions',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddConnectionSheet(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
    final result =
        await showModalBottomSheet<({String targetMoveId, String affinity})>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _QuickAddSheet(
            moveId: moveId,
            direction: _FlowDirection.outgoing,
          ),
        );

    if (result == null) return;

    final dao = ref.read(auraDaoProvider);
    await dao.upsertLink(moveId, result.targetMoveId, result.affinity);
    unawaited(HapticFeedback.mediumImpact());
  }
}

// ---------------------------------------------------------------------------
// Internal providers
// ---------------------------------------------------------------------------

/// Stream of all moves for the picker sheet. Kept private to this file
/// to avoid polluting the global provider namespace.
final _allMovesForPickerProvider = StreamProvider<List<Move>>((final ref) {
  return ref.watch(databaseProvider).movesDao.watchAll();
});
