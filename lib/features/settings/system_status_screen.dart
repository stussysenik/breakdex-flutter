import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:breakdex/core/utils/diagnostics.dart';
import 'package:breakdex/core/services/boot_coordinator.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/shared/widgets/app_loader.dart';

class SystemStatusScreen extends ConsumerWidget {
  const SystemStatusScreen({super.key});

  /// The log panel alone. The screen around it watches boot and storage
  /// providers that need the whole app graph; the feed is a claim about
  /// [DiagnosticsLog] only, so tests pump it directly.
  @visibleForTesting
  static const Widget debugFeed = _DiagnosticFeed();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final boot = ref.watch(bootCoordinatorProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Status'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenEdge),
        children: [
          _StatusHeader(boot: boot),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'BOOT GATES',
            style: AppTypography.sectionHeader.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _GatesList(boot: boot),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'STORAGE HYGIENE',
            style: AppTypography.sectionHeader.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _HygieneCounters(),
          const SizedBox(height: AppSpacing.xl),

          Text(
            'DIAGNOSTIC LOG',
            style: AppTypography.sectionHeader.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _DiagnosticFeed(),
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.boot});
  final BootState boot;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isHealthy = boot.isComplete;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isHealthy
            ? Colors.green.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isHealthy
              ? Colors.green.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          AppIconView(
            isHealthy ? AppIcon.success : AppIcon.empty,
            color: isHealthy ? Colors.green : colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHealthy ? 'All Systems Go' : 'Initializing...',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isHealthy ? Colors.green : colorScheme.onSurface,
                  ),
                ),
                Text(
                  boot.isComplete
                      ? 'Started in ${DateTime.now().difference(boot.startTime).inMilliseconds}ms'
                      : 'Clearing startup gates (${boot.completedGates.length}/${BootGate.values.length})',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GatesList extends StatelessWidget {
  const _GatesList({required this.boot});
  final BootState boot;

  @override
  Widget build(final BuildContext context) {
    return Column(
      children: BootGate.values.map((final gate) {
        final isDone = boot.completedGates.contains(gate);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              AppIconView(
                isDone ? AppIcon.success : AppIcon.empty,
                size: 18,
                color: isDone
                    ? Colors.green
                    : Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                _gateLabel(gate),
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                  color: isDone
                      ? null
                      : Theme.of(context).colorScheme.secondary,
                ),
              ),
              const Spacer(),
              if (isDone)
                AppIconView(AppIcon.success, size: 14, color: Colors.green)
              else if (boot.currentTask?.contains(_gateLabel(gate)) ?? false)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: AppLoader(size: 6),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _gateLabel(final BootGate gate) {
    return switch (gate) {
      BootGate.firebase => 'Cloud Infrastructure',
      BootGate.preferences => 'User Preferences',
      BootGate.videoResolver => 'Path Resolver',
      BootGate.storageGate => 'Storage Validator',
      BootGate.database => 'Primary Database',
      BootGate.recovery => 'Recovery Check',
      BootGate.migrations => 'Data Migrations',
      BootGate.healing => 'Path Healing',
      BootGate.legacyMigration => 'Legacy Assets',
    };
  }
}

/// The real diagnostic feed, backed by [DiagnosticsLog]'s retained buffer.
///
/// This panel previously rendered four hardcoded lines behind a comment saying
/// a real implementation would read `DiagnosticsLog` — so the one screen an
/// owner opens to answer "what did the app just do?" answered with fiction.
/// It now reads the buffer, and `Copy` exports it redacted so the answer can
/// leave the device and land in a bug report.
class _DiagnosticFeed extends StatefulWidget {
  const _DiagnosticFeed();

  @override
  State<_DiagnosticFeed> createState() => _DiagnosticFeedState();
}

class _DiagnosticFeedState extends State<_DiagnosticFeed> {
  /// The buffer is a plain static list, not a stream — polling while this one
  /// screen is visible is cheaper and simpler than making every log call
  /// notify a listener that is almost never mounted.
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
      const Duration(seconds: 1),
      (final _) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: DiagnosticsLog.export()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diagnostics copied — secrets redacted')),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Newest first: a failure is explained by the tail, and `reverse: true`
    // pins the list to that end.
    final records = DiagnosticsLog.recent().reversed.toList(growable: false);

    return Container(
      height: 300,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'SYSTEM LOG · ${records.length}',
                  style: AppTypography.caption.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('copy-diagnostics'),
                onPressed: records.isEmpty ? null : _copy,
                child: const Text('Copy'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: records.isEmpty
                ? Text(
                    'Nothing retained yet.',
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.secondary,
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: records.length,
                    itemBuilder: (final _, final i) {
                      // `reverse: true` walks the list from its end, so index 0
                      // must be the oldest of the newest-first list.
                      final r = records[records.length - 1 - i];
                      return _LogEntry(
                        time: TimeOfDay.fromDateTime(r.at).format(context),
                        tag: r.subsystem.toUpperCase(),
                        msg: redactSecrets(r.message),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  const _LogEntry({required this.time, required this.tag, required this.msg});
  final String time;
  final String tag;
  final String msg;

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$time ',
              style: const TextStyle(color: Colors.blueGrey),
            ),
            TextSpan(
              text: '[$tag] ',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(text: msg),
          ],
        ),
        style: AppTypography.caption.copyWith(
          fontFamily: 'monospace',
          fontSize: 10,
        ),
      ),
    );
  }
}

class _HygieneCounters extends StatelessWidget {
  const _HygieneCounters();

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _CounterRow(
            label: 'Stale folders removed',
            value: '${VideoPathHealer.staleFoldersRemoved}',
            colorScheme: colorScheme,
          ),
          _CounterRow(
            label: 'Orphans quarantined',
            value: '${VideoPathHealer.orphansQuarantined}',
            colorScheme: colorScheme,
          ),
          _CounterRow(
            label: 'Paths healed',
            value: '${VideoPathHealer.pathsHealed}',
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
