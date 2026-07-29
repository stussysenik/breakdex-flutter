// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

part of '../move_list_screen.dart';

// -- Study View (rich cards) --------------------------------------------------
//
// The richest of the three view modes: one full-width card per item with inline
// playback, counts, category, and a notes preview. Fed by the SAME filtered
// list as Glance and Scan — one datasource, three presentations (design.md).

const double _studyMediaHeight = 180;

class _MoveStudySliver extends StatelessWidget {
  const _MoveStudySliver({required this.moves});

  final List<Move> moves;

  @override
  Widget build(final BuildContext context) {
    return _sliverStaggeredList(
      itemCount: moves.length,
      builder: (final index) =>
          _MoveStudyCard(move: moves[index], index: index),
    );
  }
}

class _MoveStudyCard extends StatelessWidget {
  const _MoveStudyCard({required this.move, this.index = 0});

  final Move move;
  final int index;

  @override
  Widget build(final BuildContext context) {
    final state = LearningState.fromString(move.learningState);
    final videoPath = move.resolvedVideoPath;
    final hasVideo = videoPath != null && videoPath.isNotEmpty;

    return _StudyCardShell(
      index: index,
      semanticLabel: move.name,
      onTap: () => context.go('/moves/move/${move.id}'),
      media: hasVideo
          ? _StudyMedia(videoPath: videoPath)
          : _StudyMediaMissing(recoverable: move.contentHash != null),
      title: move.name,
      trailing: StatePill(state: state),
      meta: [
        if (move.category != 'default') _CategoryLabel(category: move.category),
        _BeatCountLabel(count: move.count),
      ],
      notes: move.notes,
    );
  }
}

class _ComboStudySliver extends StatelessWidget {
  const _ComboStudySliver({required this.combos});

  // Study cards do not render the date line (out of 3.2's scope); the triple
  // is carried so the combo slivers share one payload shape.
  final List<(Combo, int, DateTime)> combos;

  @override
  Widget build(final BuildContext context) {
    return _sliverStaggeredList(
      itemCount: combos.length,
      builder: (final index) {
        final (combo, moveCount, _) = combos[index];
        return _ComboStudyCard(
          combo: combo,
          moveCount: moveCount,
          index: index,
        );
      },
    );
  }
}

class _ComboStudyCard extends StatelessWidget {
  const _ComboStudyCard({
    required this.combo,
    required this.moveCount,
    this.index = 0,
  });

  final Combo combo;
  final int moveCount;
  final int index;

  @override
  Widget build(final BuildContext context) {
    final previewPath = combo.resolvedActiveVideoPath;
    final hasVideo = previewPath != null && previewPath.isNotEmpty;

    return _StudyCardShell(
      index: index,
      semanticLabel: combo.name,
      onTap: () => context.go('/moves/combo/${combo.id}'),
      media: hasVideo
          ? _StudyMedia(videoPath: previewPath)
          : _ComboPreviewFallback(stepCount: moveCount, stepNames: const []),
      title: combo.name,
      trailing: _ComboStatusChip(status: combo.status),
      meta: [
        if (moveCount > 0) _MoveCountDots(count: moveCount),
        Text(
          '$moveCount move${moveCount == 1 ? '' : 's'}',
          style: AppTypography.caption.copyWith(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
      notes: combo.notes,
    );
  }
}

/// Shared shell for both Study cards: media header, title + trailing badge,
/// a wrap of metadata anchors, and an optional 2-line notes preview.
class _StudyCardShell extends StatelessWidget {
  const _StudyCardShell({
    required this.onTap,
    required this.media,
    required this.title,
    required this.trailing,
    required this.meta,
    required this.semanticLabel,
    this.notes,
    this.index = 0,
  });

  final VoidCallback onTap;
  final Widget media;
  final String title;
  final Widget trailing;
  final List<Widget> meta;
  final String semanticLabel;
  final String? notes;
  final int index;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final trimmedNotes = notes?.trim();
    final hasNotes = trimmedNotes != null && trimmedNotes.isNotEmpty;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Pressable(
        onTap: onTap,
        scaleEnd: 0.98,
        child:
            RepaintBoundary(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    clipBehavior: Clip.antiAlias,
                    decoration: AppSurfaces.panel(
                      context,
                      radius: AppRadius.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: _studyMediaHeight,
                          width: double.infinity,
                          child: media,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.titleSmall.copyWith(
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  trailing,
                                ],
                              ),
                              if (meta.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.md,
                                  runSpacing: AppSpacing.xs,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: meta,
                                ),
                              ],
                              if (hasNotes) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  trimmedNotes,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(
                  duration: AppMotion.moderate01,
                  delay: Duration(milliseconds: index.clamp(0, 15) * 40),
                )
                .slideY(
                  begin: 0.03,
                  duration: AppMotion.moderate02,
                  delay: Duration(milliseconds: index.clamp(0, 15) * 40),
                  curve: AppMotion.entrance,
                ),
      ),
    );
  }
}

/// Inline, tap-to-play player for a Study card. Deliberately NOT autoplaying —
/// a scrolling list of autoplaying videos would thrash decoders; the card shows
/// a first frame and plays on tap.
class _StudyMedia extends StatelessWidget {
  const _StudyMedia({required this.videoPath});

  final String videoPath;

  @override
  Widget build(final BuildContext context) {
    return RobustVideoPlayer(
      videoPath: videoPath,
      height: _studyMediaHeight,
      minimal: true,
      looping: true,
      muted: true,
    );
  }
}

/// Placeholder for a move whose local video is absent. Mirrors the grid-cell
/// language: a cloud glyph when the byte is recoverable from the backend, a
/// muted camera-off glyph when it is genuinely missing.
class _StudyMediaMissing extends StatelessWidget {
  const _StudyMediaMissing({required this.recoverable});

  final bool recoverable;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconView(
            recoverable ? AppIcon.download : AppIcon.videoOff,
            size: 40,
            color: recoverable
                ? AppColors.accent.withValues(alpha: 0.6)
                : colorScheme.secondary,
          ),
          if (!recoverable) ...[
            const SizedBox(height: 4),
            Text(
              'Missing',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small anchor showing a move's pre-planned beat count (the atom-model `count`).
class _BeatCountLabel extends StatelessWidget {
  const _BeatCountLabel({required this.count});

  final int count;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconView(AppIcon.graph, size: 12, color: colorScheme.secondary),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          '$count beat${count == 1 ? '' : 's'}',
          style: AppTypography.caption.copyWith(color: colorScheme.secondary),
        ),
      ],
    );
  }
}

/// Combo lifecycle status ('idea' → 'attempting' → 'landed' → 'clean'), shown
/// as the Study card's trailing badge — the combo analog of a move's StatePill.
class _ComboStatusChip extends StatelessWidget {
  const _ComboStatusChip({required this.status});

  final String status;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = status.isEmpty
        ? 'idea'
        : '${status[0].toUpperCase()}${status.substring(1)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: colorScheme.onSurface),
      ),
    );
  }
}
