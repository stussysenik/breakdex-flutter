// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/providers.dart';
import '../../core/sync/asset_sync_detail.dart';
import '../../core/sync/asset_sync_engine.dart';
import '../../core/sync/integrity_verifier.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/app_loader.dart';

/// Sync status dashboard showing overall progress, active transfers,
/// and monthly data usage.
class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final syncProgress = ref.watch(assetSyncProgressProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final networkPolicy = ref.watch(networkPolicyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sync Status',
          style: AppTypography.titleSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenEdge),
        children: [
          // Overall status card
          _StatusCard(
            syncProgress: syncProgress.valueOrNull ?? SyncProgress.idle,
            pendingCount: ref.watch(underprotectedCountProvider).valueOrNull,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Per-asset detail — what the engine is actually doing, per video.
          _SectionHeader(
            title: AppLocalizations.of(context).setSyncVideosHeader,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: AppSpacing.sm),
          _AssetDetailList(
            details: ref.watch(assetSyncDetailsProvider).valueOrNull,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Network settings
          _SectionHeader(title: 'Network', colorScheme: colorScheme),
          const SizedBox(height: AppSpacing.sm),
          _SettingsTile(
            title: 'Sync on Mobile Data',
            subtitle: networkPolicy.syncOnMobileData
                ? 'Enabled (${networkPolicy.mobileDataCapMb} MB cap)'
                : 'WiFi only',
            trailing: Switch.adaptive(
              value: networkPolicy.syncOnMobileData,
              activeThumbColor: AppColors.accent,
              onChanged: (final value) async {
                await networkPolicy.setSyncOnMobileData(enabled: value);
              },
            ),
            colorScheme: colorScheme,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Data usage
          _DataUsageCard(
            usedBytes: networkPolicy.mobileUsedBytesThisMonth(),
            capBytes: networkPolicy.mobileDataCapMb * 1024 * 1024,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Quick actions
          _SectionHeader(title: 'Actions', colorScheme: colorScheme),
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            icon: Icons.sync,
            title: 'Sync Now',
            subtitle: 'Upload pending videos to cloud',
            onTap: () {
              // Trigger immediate sync
              ref.read(backgroundSyncManagerProvider).triggerImmediate(
                    syncCallback: () => ref
                        .read(assetSyncEngineProvider)
                        .runSyncCycle(
                          ref
                              .read(connectivityServiceProvider)
                              .currentType,
                        ),
                  );
            },
            colorScheme: colorScheme,
          ),
          _ActionTile(
            icon: Icons.verified_outlined,
            title: 'Verify Integrity',
            subtitle: 'Re-hash every local file and list any mismatches',
            onTap: () => _runIntegrityCheck(context, ref),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

/// Run a full, read-only integrity scan and present the results. Healing
/// (re-download) is never automatic here — it's an explicit, warned action
/// inside the results sheet, so a stale-hash local edit is never silently
/// clobbered by a cloud copy.
Future<void> _runIntegrityCheck(
  final BuildContext context,
  final WidgetRef ref,
) async {
  final verifier = ref.read(integrityVerifierProvider);

  // Blocking spinner — a full re-hash of every local video can take a while.
  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (final _) => const Center(child: AppLoader()),
  ));

  IntegrityReport report;
  try {
    report = await verifier.verify(checkAll: true, heal: false);
  } finally {
    if (context.mounted) Navigator.of(context).pop(); // dismiss spinner
  }

  if (!context.mounted) return;

  if (report.allGood) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All ${report.filesChecked} local files verified OK'),
      ),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (final sheetContext) =>
        _IntegrityResultSheet(report: report, verifier: verifier),
  );
}

/// Last path segment, for a readable file label.
String _basename(final String? path) {
  if (path == null || path.isEmpty) return '(no local file)';
  final segments = path.split('/');
  return segments.isEmpty ? path : segments.last;
}

String _shortHash(final String? hash) =>
    hash == null ? '—' : (hash.length <= 12 ? hash : hash.substring(0, 12));

class _IntegrityResultSheet extends StatelessWidget {
  final IntegrityReport report;
  final IntegrityVerifier verifier;

  const _IntegrityResultSheet({required this.report, required this.verifier});

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mismatches = report.mismatchedHashes;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenEdge,
          0,
          AppSpacing.screenEdge,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Integrity Report',
              style: AppTypography.titleSmall.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${report.filesChecked} checked · ${report.filesOk} OK · '
              '${report.filesMismatched} mismatched · '
              '${report.filesMissing} missing',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: report.issues.length,
                separatorBuilder: (final _, final _) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (final _, final i) =>
                    _IssueRow(issue: report.issues[i], colorScheme: colorScheme),
              ),
            ),
            if (mismatches.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.cloud_download_outlined, size: 18),
                  label: Text('Re-download ${mismatches.length} flagged'),
                  onPressed: () => _confirmHeal(context, mismatches),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmHeal(
    final BuildContext context,
    final List<String> hashes,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (final dialogContext) => AlertDialog(
        title: const Text('Re-download flagged files?'),
        content: Text(
          'This marks ${hashes.length} local ${hashes.length == 1 ? 'copy' : 'copies'} '
          'as failed so a clean copy is pulled from cloud on the next sync.\n\n'
          'If you edited any of these files locally without re-importing, that '
          'edit will be replaced by the cloud version.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Re-download'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final healed = await verifier.healMismatches(hashes);
    if (!context.mounted) return;
    Navigator.of(context).pop(); // close the result sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$healed flagged for re-download on next sync'),
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  final IntegrityIssue issue;
  final ColorScheme colorScheme;

  const _IssueRow({required this.issue, required this.colorScheme});

  @override
  Widget build(final BuildContext context) {
    final (icon, tint) = switch (issue.kind) {
      IntegrityIssueKind.mismatch => (Icons.warning_amber_rounded, AppColors.actionAgain),
      IntegrityIssueKind.missing => (Icons.link_off, AppColors.actionHard),
      IntegrityIssueKind.unreadable => (Icons.error_outline, AppColors.actionAgain),
    };

    final detail = switch (issue.kind) {
      IntegrityIssueKind.mismatch =>
        'expected ${_shortHash(issue.contentHash)} · got ${_shortHash(issue.actualHash)}',
      IntegrityIssueKind.missing => 'manifest ${_shortHash(issue.contentHash)} · no file on disk',
      IntegrityIssueKind.unreadable => issue.error ?? 'unreadable',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tint, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _basename(issue.localPath),
                  style: AppTypography.bodySmall.merge(
                    const TextStyle(fontWeight: FontWeight.w600),
                  ).copyWith(color: colorScheme.onSurface),
                ),
                Text(
                  detail,
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final SyncProgress syncProgress;

  /// Live Drift count of assets still lacking a verified cloud copy; null
  /// while the first read is in flight.
  final int? pendingCount;
  final ColorScheme colorScheme;

  const _StatusCard({
    required this.syncProgress,
    required this.pendingCount,
    required this.colorScheme,
  });

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIdle = syncProgress.state == SyncEngineState.idle;
    // Honest header (D1): an idle engine says nothing about protection — the
    // persistent count decides. "All synced" only renders once the store
    // proves zero pending; a silent stream shows "Checking…", never a default.
    final allSynced = isIdle && pendingCount == 0;
    final headerLabel = !isIdle
        ? syncProgress.statusLabel
        : switch (pendingCount) {
            null => l10n.setSyncChecking,
            0 => l10n.setSyncAllSynced,
            final count => l10n.setSyncPendingCount(count),
          };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: allSynced
              ? AppColors.stateMastery.withValues(alpha: 0.3)
              : AppColors.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allSynced ? Icons.cloud_done_outlined : Icons.sync,
                color: allSynced ? AppColors.stateMastery : AppColors.accent,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                headerLabel,
                style: AppTypography.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          if (!isIdle) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xxs),
              child: LinearProgressIndicator(
                value: syncProgress.fraction,
                backgroundColor:
                    colorScheme.onSurface.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${syncProgress.syncedAssets}/${syncProgress.totalAssets} synced',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Per-asset backup state, worst-first. Read-only: it reports what the
/// manifest, the copies, and the operation queue already say, and never
/// infers a state none of them support.
class _AssetDetailList extends StatelessWidget {
  /// Null while the first Drift read is in flight — rendered as "Checking…",
  /// never as an empty library.
  final List<AssetSyncDetail>? details;
  final ColorScheme colorScheme;

  const _AssetDetailList({required this.details, required this.colorScheme});

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = details;
    if (rows == null) {
      return _AssetDetailNote(
        text: l10n.setSyncChecking,
        colorScheme: colorScheme,
      );
    }
    if (rows.isEmpty) {
      return _AssetDetailNote(
        text: l10n.setSyncNoVideosTracked,
        colorScheme: colorScheme,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AssetTallyRow(
          tally: AssetSyncTally.from(rows),
          colorScheme: colorScheme,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final detail in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _AssetDetailRow(detail: detail, colorScheme: colorScheme),
          ),
      ],
    );
  }
}

class _AssetDetailNote extends StatelessWidget {
  final String text;
  final ColorScheme colorScheme;

  const _AssetDetailNote({required this.text, required this.colorScheme});

  @override
  Widget build(final BuildContext context) => Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      );
}

/// The three-way split the header can't carry: what is moving, what is
/// waiting, and what is broken. Buckets come from [AssetSyncTally], so they
/// partition the same rows listed below — a video can never appear in two.
class _AssetTallyRow extends StatelessWidget {
  final AssetSyncTally tally;
  final ColorScheme colorScheme;

  const _AssetTallyRow({required this.tally, required this.colorScheme});

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Empty buckets are omitted rather than shown as "0" — a zero is noise
    // that reads as a problem the user has to parse.
    final chips = <(int, String, Color)>[
      (tally.uploading, l10n.setSyncTallyUploading(tally.uploading),
          AppColors.accent),
      (tally.waiting, l10n.setSyncTallyWaiting(tally.waiting),
          AppColors.actionHard),
      (tally.retrying, l10n.setSyncTallyRetrying(tally.retrying),
          AppColors.actionHard),
      (tally.unbackupable, l10n.setSyncTallyStuck(tally.unbackupable),
          AppColors.actionAgain),
      (tally.backedUp, l10n.setSyncTallyBackedUp(tally.backedUp),
          AppColors.stateMastery),
    ];

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final (count, label, tint) in chips)
          if (count > 0)
            Container(
              key: Key('assetTally_$label'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                label,
                style: AppTypography.caption.copyWith(color: tint),
              ),
            ),
      ],
    );
  }
}

class _AssetDetailRow extends StatelessWidget {
  final AssetSyncDetail detail;
  final ColorScheme colorScheme;

  const _AssetDetailRow({required this.detail, required this.colorScheme});

  @override
  Widget build(final BuildContext context) {
    final (icon, tint) = switch (detail.status) {
      AssetSyncStatus.backedUp => (
          Icons.cloud_done_outlined,
          AppColors.stateMastery,
        ),
      AssetSyncStatus.uploading => (Icons.cloud_upload_outlined, AppColors.accent),
      AssetSyncStatus.queued => (Icons.schedule, AppColors.accent),
      AssetSyncStatus.failed => (
          Icons.error_outline,
          AppColors.actionAgain,
        ),
      AssetSyncStatus.pending => (
          Icons.cloud_off_outlined,
          AppColors.actionHard,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tint, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall
                      .merge(const TextStyle(fontWeight: FontWeight.w600))
                      .copyWith(color: colorScheme.onSurface),
                ),
                Text(
                  _detailLine(AppLocalizations.of(context), detail),
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (detail.status == AssetSyncStatus.uploading) ...[
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xxs),
                    child: LinearProgressIndicator(
                      key: Key('assetProgress_${detail.contentHash}'),
                      // Null while no bytes have moved — an indeterminate bar
                      // is honest about "started, nothing reported yet".
                      value: detail.fraction,
                      backgroundColor:
                          colorScheme.onSurface.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                      minHeight: 3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The one line under the name that answers "what is happening to this file".
///
/// A non-terminal failure says "retrying" because the next sweep queues a
/// fresh operation. A terminal verdict says "won't retry" — honest since 4.4:
/// `queueUpload` consults the verdict, so the sweep really skips the asset
/// until a restore or re-import re-homes its bytes and revokes it.
String _detailLine(
  final AppLocalizations l10n,
  final AssetSyncDetail detail,
) =>
    switch (detail.status) {
      AssetSyncStatus.backedUp => [
          for (final copy in detail.copies)
            if (copy.provider != 'local' && copy.status == 'verified')
              copy.provider,
        ].join(' · '),
      AssetSyncStatus.uploading => switch (detail.fraction) {
          // No bytes reported yet — say "starting" rather than compute a 0%
          // that reads as stalled.
          null => l10n.setSyncDetailStarting(_mb(detail.fileSizeBytes)),
          final fraction => l10n.setSyncDetailUploading(
              _mb(detail.transferredBytes),
              _mb(detail.fileSizeBytes),
              (fraction * 100).round(),
            ),
        },
      AssetSyncStatus.queued =>
        l10n.setSyncDetailQueued(_mb(detail.fileSizeBytes)),
      AssetSyncStatus.failed => switch ((detail.isTerminal, detail.errorMessage)) {
          (true, final String error) => l10n.setSyncDetailStuck(error),
          (true, _) => l10n.setSyncDetailStuckUnknown,
          (false, final String error) => l10n.setSyncDetailRetrying(error),
          (false, _) => l10n.setSyncDetailRetryingUnknown,
        },
      AssetSyncStatus.pending =>
        l10n.setSyncDetailPending(_mb(detail.fileSizeBytes)),
    };

String _mb(final int bytes) =>
    '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

class _SectionHeader extends StatelessWidget {
  final String title;
  final ColorScheme colorScheme;

  const _SectionHeader({required this.title, required this.colorScheme});

  @override
  Widget build(final BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.caption.copyWith(
        color: colorScheme.onSurface.withValues(alpha: 0.5),
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final ColorScheme colorScheme;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.colorScheme,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.merge(const TextStyle(fontWeight: FontWeight.w600)).copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _DataUsageCard extends StatelessWidget {
  final int usedBytes;
  final int capBytes;
  final ColorScheme colorScheme;

  const _DataUsageCard({
    required this.usedBytes,
    required this.capBytes,
    required this.colorScheme,
  });

  @override
  Widget build(final BuildContext context) {
    final usedMb = usedBytes / (1024 * 1024);
    final capMb = capBytes / (1024 * 1024);
    final fraction = capBytes > 0 ? (usedBytes / capBytes).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mobile Data This Month',
            style: AppTypography.bodySmall.merge(const TextStyle(fontWeight: FontWeight.w600)).copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xxs),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor:
                  colorScheme.onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                fraction > 0.9 ? AppColors.actionAgain : AppColors.accent,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${usedMb.toStringAsFixed(1)} MB / ${capMb.toStringAsFixed(0)} MB',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall.merge(const TextStyle(fontWeight: FontWeight.w600)).copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
