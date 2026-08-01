// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/features/flow/providers/aura_providers.dart';
import 'package:breakdex/features/flow/widgets/aura_link_tile.dart';
import 'package:breakdex/features/flow/widgets/aura_preset_picker.dart';
import 'package:breakdex/shared/widgets/app_sheet.dart';

// ---------------------------------------------------------------------------
// AuraView — the main "Your Aura" screen/section.
// ---------------------------------------------------------------------------

/// The Bboy Aura view — a Pokemon-inspired personal move transition map.
///
/// This screen is the user's "aura fingerprint": a visual map of how their
/// moves connect. Each bboy flows differently between moves — power movers
/// might rate Windmill -> Flare as "natural" while footwork specialists
/// rate Indian Step -> CCs the same way.
///
/// **Layout from top to bottom:**
/// 1. Header with "Your Aura" title + active preset name.
/// 2. Preset picker chips (horizontal scroll).
/// 3. Move grid — all moves with outgoing connection counts.
/// 4. When a move is selected, its connections expand below (link tiles).
///
/// **Design philosophy:**
/// - Feels like a personal fingerprint, not a dry data table.
/// - Single-tap interactions everywhere — no modal confirmations.
/// - Color coding follows Pokemon type effectiveness:
///   green (natural/super effective), amber (possible/neutral),
///   red (stretch/not very effective).
class AuraView extends ConsumerStatefulWidget {
  const AuraView({super.key});

  @override
  ConsumerState<AuraView> createState() => _AuraViewState();
}

class _AuraViewState extends ConsumerState<AuraView> {
  /// The currently selected move ID for viewing/editing connections.
  String? _selectedMoveId;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activePresetAsync = ref.watch(activeAuraProvider);

    return CustomScrollView(
      slivers: [
        // -- Header: "Your Aura" title + active preset name ----------------
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenEdge,
              AppSpacing.lg,
              AppSpacing.screenEdge,
              0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Your Aura',
                  style: AppTypography.titleLarge.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Active preset name as a subtle tag.
                activePresetAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (final preset) {
                    if (preset == null) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        preset.name,
                        style: AppTypography.caption.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        // -- Preset picker chips -------------------------------------------
        const SliverToBoxAdapter(child: AuraPresetPicker()),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

        // -- Move grid with connection counts ------------------------------
        _MoveGrid(
          selectedMoveId: _selectedMoveId,
          onMoveSelected: (final moveId) {
            unawaited(HapticFeedback.selectionClick());
            setState(() {
              _selectedMoveId = _selectedMoveId == moveId ? null : moveId;
            });
          },
        ),

        // -- Connection detail panel (when a move is selected) -------------
        if (_selectedMoveId != null)
          _ConnectionPanel(
            moveId: _selectedMoveId!,
            onAddConnection: () =>
                _showAddConnectionSheet(context, _selectedMoveId!),
          ),

        // Bottom padding for nav bar clearance.
        SliverPadding(
          padding: EdgeInsets.only(
            bottom:
                kBottomNavigationBarHeight +
                MediaQuery.of(context).padding.bottom +
                AppSpacing.lg,
          ),
        ),
      ],
    );
  }

  /// Shows a bottom sheet to add a new transition link from the selected move.
  Future<void> _showAddConnectionSheet(
    final BuildContext context,
    final String fromMoveId,
  ) async {
    final result =
        await showAppSheet<({String toMoveId, String affinity})>(
          context: context,
          builder: (_) => _AddConnectionSheet(fromMoveId: fromMoveId),
        );

    if (result == null) return;

    final dao = ref.read(auraDaoProvider);
    await dao.upsertLink(fromMoveId, result.toMoveId, result.affinity);
    unawaited(HapticFeedback.mediumImpact());
  }
}

// ---------------------------------------------------------------------------
// _MoveGrid — grid of all moves showing outgoing connection count.
// ---------------------------------------------------------------------------

class _MoveGrid extends ConsumerWidget {
  const _MoveGrid({required this.selectedMoveId, required this.onMoveSelected});

  final String? selectedMoveId;
  final ValueChanged<String> onMoveSelected;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final movesAsync = ref.watch(_allMovesStreamProvider);

    return movesAsync.when(
      loading: () =>
          const SliverToBoxAdapter(child: Center(child: AppLoader())),
      error: (final e, _) => SliverToBoxAdapter(
        child: Center(child: Text('Error loading moves: $e')),
      ),
      data: (final moves) {
        if (moves.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Column(
                  children: [
                    AppIconView(
                      AppIcon.discover,
                      size: 48,
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Add moves to your Arsenal first,\nthen map your transitions here.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.3,
            ),
            delegate: SliverChildBuilderDelegate((final context, final index) {
              final move = moves[index];
              final isSelected = move.id == selectedMoveId;

              return _MoveGridTile(
                move: move,
                isSelected: isSelected,
                onTap: () => onMoveSelected(move.id),
              );
            }, childCount: moves.length),
          ),
        );
      },
    );
  }
}

/// Internal stream provider for all moves — keeps the grid reactive.
final _allMovesStreamProvider = StreamProvider<List<Move>>((final ref) {
  return ref.watch(databaseProvider).movesDao.watchAll();
});

// ---------------------------------------------------------------------------
// _MoveGridTile — single move cell in the grid.
// ---------------------------------------------------------------------------

class _MoveGridTile extends ConsumerWidget {
  const _MoveGridTile({
    required this.move,
    required this.isSelected,
    required this.onTap,
  });

  final Move move;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final linksAsync = ref.watch(auraLinksFromProvider(move.id));
    final linkCount = linksAsync.valueOrNull?.length ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.moderate01,
        curve: AppMotion.productive,
        decoration: AppSurfaces.panel(
          context,
          tone: isSelected ? AppSurfaceTone.emphasis : AppSurfaceTone.base,
          focused: isSelected,
          radius: AppRadius.sm,
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Move name — truncated for grid layout.
            Text(
              move.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            // Connection count badge.
            if (linkCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  '$linkCount',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              )
            else
              Text(
                '\u2014',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary.withValues(alpha: 0.4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ConnectionPanel — expanded connection list for the selected move.
// ---------------------------------------------------------------------------

class _ConnectionPanel extends ConsumerWidget {
  const _ConnectionPanel({required this.moveId, required this.onAddConnection});

  final String moveId;
  final VoidCallback onAddConnection;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final linksAsync = ref.watch(auraLinksFromProvider(moveId));
    final allMovesAsync = ref.watch(_allMovesStreamProvider);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenEdge,
          AppSpacing.lg,
          AppSpacing.screenEdge,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with "Add" button.
            Row(
              children: [
                Text(
                  'TRANSITIONS',
                  style: AppTypography.sectionHeader.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onAddConnection,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIconView(
                          AppIcon.add,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Link list.
            linksAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: AppLoader()),
              ),
              error: (final e, _) => Text('Error: $e'),
              data: (final links) {
                if (links.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: Center(
                      child: Text(
                        'No transitions rated yet.\nTap "Add" to connect moves.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  );
                }

                final moveMap = _buildMoveMap(allMovesAsync);

                return Column(
                  children: [
                    for (int i = 0; i < links.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i < links.length - 1 ? AppSpacing.sm : 0,
                        ),
                        child:
                            AuraLinkTile(
                                  fromMoveName:
                                      moveMap[links[i].fromMoveId] ?? 'Unknown',
                                  toMoveName:
                                      moveMap[links[i].toMoveId] ?? 'Unknown',
                                  affinity: AuraAffinity.fromString(
                                    links[i].affinity,
                                  ),
                                  notes: links[i].notes,
                                  onAffinityChanged: (final newAffinity) {
                                    ref
                                        .read(auraDaoProvider)
                                        .upsertLink(
                                          links[i].fromMoveId,
                                          links[i].toMoveId,
                                          newAffinity.name,
                                          notes: links[i].notes,
                                        );
                                  },
                                  onDelete: () {
                                    ref
                                        .read(auraDaoProvider)
                                        .deleteLink(
                                          links[i].fromMoveId,
                                          links[i].toMoveId,
                                        );
                                    unawaited(HapticFeedback.lightImpact());
                                  },
                                )
                                .animate()
                                .fadeIn(
                                  duration: AppMotion.moderate01,
                                  delay: Duration(milliseconds: i * 40),
                                )
                                .slideY(
                                  begin: 0.1,
                                  end: 0,
                                  duration: AppMotion.moderate02,
                                  delay: Duration(milliseconds: i * 40),
                                  curve: AppMotion.entrance,
                                ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build a quick lookup map of moveId -> moveName from the moves stream.
  Map<String, String> _buildMoveMap(final AsyncValue<List<Move>> movesAsync) {
    final moves = movesAsync.valueOrNull ?? [];
    return {for (final m in moves) m.id: m.name};
  }
}

// ---------------------------------------------------------------------------
// _AddConnectionSheet — bottom sheet to create a new aura link.
// ---------------------------------------------------------------------------

/// Modal bottom sheet for selecting a target move and initial affinity
/// when creating a new transition link.
///
/// Shows a searchable list of all moves (excluding the source move) with
/// affinity buttons. The user taps a move, selects an affinity, and the
/// link is created immediately — fast, no multi-step wizard.
class _AddConnectionSheet extends ConsumerStatefulWidget {
  const _AddConnectionSheet({required this.fromMoveId});

  final String fromMoveId;

  @override
  ConsumerState<_AddConnectionSheet> createState() =>
      _AddConnectionSheetState();
}

class _AddConnectionSheetState extends ConsumerState<_AddConnectionSheet> {
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
    final movesAsync = ref.watch(_allMovesStreamProvider);
    final existingLinksAsync = ref.watch(
      auraLinksFromProvider(widget.fromMoveId),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
                'Add Transition',
                style: AppTypography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Search field
              Semantics(
                label: 'Search moves',
                textField: true,
                child: TextField(
                  controller: _searchController,
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
                    // Exclude the source move and already-linked moves.
                    final existingIds = (existingLinksAsync.valueOrNull ?? [])
                        .map((final l) => l.toMoveId)
                        .toSet();

                    final filtered = moves
                        .where(
                          (final m) =>
                              m.id != widget.fromMoveId &&
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
                        return _MoveConnectionRow(
                          moveName: move.name,
                          onSelect: (final affinity) {
                            Navigator.pop(context, (
                              toMoveId: move.id,
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

/// A single row in the add-connection sheet: move name + 3 affinity buttons.
class _MoveConnectionRow extends StatelessWidget {
  const _MoveConnectionRow({required this.moveName, required this.onSelect});

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
          // Move name
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

          // Affinity quick-select buttons
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
                      affinity.label[0], // N / P / S
                      style: AppTypography.caption.copyWith(
                        color: affinity.color(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
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
