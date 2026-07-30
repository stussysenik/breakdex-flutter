import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/utils/time_format.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/features/lab/providers/lab_providers.dart';
import 'package:breakdex/core/design/icons.dart';

/// Vertical timeline showing lab entries and milestones interleaved
/// chronologically for 'project'-type labs.
///
/// Visual language:
/// - Left vertical border line with colored dots at each event
/// - Blue dots for regular entries
/// - Purple dots for pending milestones
/// - Green dots for completed milestones
///
/// The "Add entry" input floats at the top of the timeline, making it
/// fast to log progress without opening a separate screen.
class LabTimeline extends ConsumerStatefulWidget {
  const LabTimeline({super.key, required this.labId});

  final String labId;

  @override
  ConsumerState<LabTimeline> createState() => _LabTimelineState();
}

class _LabTimelineState extends ConsumerState<LabTimeline> {
  final _entryController = TextEditingController();

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _addEntry() async {
    final content = _entryController.text.trim();
    if (content.isEmpty) return;

    final dao = ref.read(labEntriesDaoProvider);
    await dao.insertEntry(
      LabEntriesCompanion.insert(
        id: const Uuid().v4(),
        content: content,
        labId: drift.Value(widget.labId),
      ),
    );

    _entryController.clear();
    if (mounted) {
      FocusScope.of(context).unfocus();
      unawaited(HapticFeedback.lightImpact());
    }
  }

  @override
  Widget build(final BuildContext context) {
    final entriesAsync = ref.watch(labEntriesByLabProvider(widget.labId));
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
            'TIMELINE',
            style: AppTypography.sectionHeader.copyWith(
              color: colorScheme.secondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Add entry input
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _entryController,
                  decoration: const InputDecoration(
                    hintText: 'Log progress...',
                    prefixIcon: AppIconView(AppIcon.edit),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _addEntry(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                onPressed: _addEntry,
                icon: const AppIconView(
                  AppIcon.add,
                  color: Colors.white,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  minimumSize: const Size(40, 40),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Timeline body — merge entries + milestones chronologically
        entriesAsync.when(
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
          data: (final entries) {
            final milestones = milestonesAsync.valueOrNull ?? [];
            final items = _mergeChronologically(entries, milestones);

            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdge,
                ),
                child: Text(
                  'No activity yet. Start logging your progress above.',
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
                  for (var i = 0; i < items.length; i++)
                    _TimelineRow(item: items[i], isLast: i == items.length - 1),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Merge lab entries and milestones into a single chronologically-sorted
  /// list (newest first) wrapped in a sealed union type.
  List<_TimelineItem> _mergeChronologically(
    final List<LabEntry> entries,
    final List<Milestone> milestones,
  ) {
    final items = <_TimelineItem>[
      for (final e in entries)
        _TimelineItem.entry(
          content: e.content,
          hasVideo: e.videoPath != null,
          timestamp: e.createdAt,
        ),
      for (final m in milestones)
        _TimelineItem.milestone(
          title: m.title,
          completed: m.completedAt != null,
          timestamp: m.completedAt ?? m.createdAt,
        ),
    ];
    // Sort newest first
    items.sort((final a, final b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }
}

// -- Timeline Item sealed class -----------------------------------------------

enum _TimelineItemType { entry, milestone }

class _TimelineItem {
  final _TimelineItemType type;
  final String text;
  final DateTime timestamp;
  final bool hasVideo;
  final bool completed;

  const _TimelineItem._({
    required this.type,
    required this.text,
    required this.timestamp,
    this.hasVideo = false,
    this.completed = false,
  });

  factory _TimelineItem.entry({
    required final String content,
    required final bool hasVideo,
    required final DateTime timestamp,
  }) => _TimelineItem._(
    type: _TimelineItemType.entry,
    text: content,
    timestamp: timestamp,
    hasVideo: hasVideo,
  );

  factory _TimelineItem.milestone({
    required final String title,
    required final bool completed,
    required final DateTime timestamp,
  }) => _TimelineItem._(
    type: _TimelineItemType.milestone,
    text: title,
    timestamp: timestamp,
    completed: completed,
  );

  /// Dot color: blue for entries, purple for pending milestones, green for
  /// completed milestones.
  Color dotColor(final BuildContext context) => switch (type) {
    _TimelineItemType.entry => Theme.of(context).colorScheme.primary,
    _TimelineItemType.milestone =>
      completed ? AppSemanticTheme.of(context).stateMastery : const Color(0xFF8B5CF6),
  };
}

// -- Timeline Row -------------------------------------------------------------

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.isLast});

  final _TimelineItem item;
  final bool isLast;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left rail: dot + line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.dotColor(context),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main text
                  Text(
                    item.text,
                    style: AppTypography.bodySmall.copyWith(
                      color:
                          item.type == _TimelineItemType.milestone &&
                              item.completed
                          ? colorScheme.secondary.withValues(alpha: 0.6)
                          : colorScheme.onSurface,
                      fontWeight: item.type == _TimelineItemType.milestone
                          ? FontWeight.w600
                          : FontWeight.w400,
                      decoration: item.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),

                  // Video indicator
                  if (item.hasVideo) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIconView(
                          AppIcon.video,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Video attached',
                          style: AppTypography.caption.copyWith(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Milestone badge
                  if (item.type == _TimelineItemType.milestone) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: item.dotColor(context).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.completed ? 'Milestone completed' : 'Milestone',
                        style: AppTypography.caption.copyWith(
                          color: item.dotColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  // Timestamp
                  const SizedBox(height: 4),
                  Text(
                    relativeTime(item.timestamp),
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.secondary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
