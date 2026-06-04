import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/canonical_asset.dart';

class ProvenanceTrailWidget extends StatelessWidget {
  const ProvenanceTrailWidget({super.key, required this.trail, this.maxEntries});
  final ProvenanceTrail trail;
  final int? maxEntries;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (trail.isEmpty) {
      return Center(
        child: Text('No provenance events recorded.',
            style: AppTypography.bodySmall.copyWith(color: colorScheme.secondary)),
      );
    }
    final entries = trail.entries;
    final displayEntries =
        maxEntries != null && maxEntries! < entries.length ? entries.take(maxEntries!).toList() : entries;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('History',
          style: AppTypography.sectionHeader.copyWith(color: colorScheme.onSurface)),
      const SizedBox(height: AppSpacing.sm),
      ...List.generate(displayEntries.length,
          (final index) => _ProvenanceTile(entry: displayEntries[index], isLast: index == displayEntries.length - 1)),
    ]);
  }
}

class _ProvenanceTile extends StatelessWidget {
  const _ProvenanceTile({required this.entry, required this.isLast});
  final AssetProvenanceEntry entry;
  final bool isLast;
  static final _timeFormatter = DateFormat('MMM d, h:mm a');

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 24, child: Column(children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle)),
            if (!isLast) Container(width: 2, height: 32, color: colorScheme.outlineVariant),
          ])),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_title, style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text(_timeFormatter.format(entry.recordedAt.toLocal()),
                style: AppTypography.caption.copyWith(color: colorScheme.secondary)),
            if (entry.detail != null) ...[
              const SizedBox(height: 4),
              Text(entry.detail!, style: AppTypography.caption.copyWith(color: colorScheme.secondary),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
      ),
    ]);
  }

  String get _title => switch (entry.eventType) {
        'imported' => 'Imported',
        'verified' => 'Verified',
        'trashed' => 'Moved to trash',
        'restored' => 'Restored',
        'hard_deleted' => 'Permanently deleted',
        'cloud_copy_verified' => 'Cloud copy verified',
        'cloud_copy_failed' => 'Cloud copy failed',
        _ => entry.eventType,
      };

  Color get _dotColor => switch (entry.eventType) {
        'imported' => const Color(0xFF4CAF50),
        'verified' => const Color(0xFF2196F3),
        'trashed' => const Color(0xFFE0A030),
        'restored' => const Color(0xFF4CAF50),
        'hard_deleted' => const Color(0xFFE04040),
        'cloud_copy_verified' => const Color(0xFF9C27B0),
        'cloud_copy_failed' => const Color(0xFFE04040),
        _ => const Color(0xFF9E9E9E),
      };
}
