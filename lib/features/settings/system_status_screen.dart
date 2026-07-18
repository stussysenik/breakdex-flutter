import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/boot_coordinator.dart';
import '../../core/services/video_path_resolver.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../shared/widgets/app_loader.dart';

class SystemStatusScreen extends ConsumerWidget {
  const SystemStatusScreen({super.key});

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
            style: AppTypography.sectionHeader.copyWith(color: colorScheme.secondary),
          ),
          const SizedBox(height: AppSpacing.md),
          _GatesList(boot: boot),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'STORAGE HYGIENE',
            style: AppTypography.sectionHeader.copyWith(color: colorScheme.secondary),
          ),
          const SizedBox(height: AppSpacing.md),
          const _HygieneCounters(),
          const SizedBox(height: AppSpacing.xl),

          Text(
            'DIAGNOSTIC LOG',
            style: AppTypography.sectionHeader.copyWith(color: colorScheme.secondary),
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
        color: isHealthy ? Colors.green.withValues(alpha: 0.1) : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isHealthy ? Colors.green.withValues(alpha: 0.3) : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.check_circle_outline : Icons.pending_outlined,
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
              Icon(
                isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: isDone ? Colors.green : Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                _gateLabel(gate),
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                  color: isDone ? null : Theme.of(context).colorScheme.secondary,
                ),
              ),
              const Spacer(),
              if (isDone)
                const Icon(Icons.done_all, size: 14, color: Colors.green)
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

class _DiagnosticFeed extends ConsumerWidget {
  const _DiagnosticFeed();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // In a real implementation, DiagnosticsLog would expose a stream of events.
    // For now, we show a simplified "Live Log" look.
    final colorScheme = Theme.of(context).colorScheme;

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
          Text(
            'SYSTEM LOG',
            style: AppTypography.caption.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              reverse: true,
              children: const [
                _LogEntry(time: 'T+1.2s', tag: 'BOOT', msg: 'Core subsystems online'),
                _LogEntry(time: 'T+0.8s', tag: 'SQL', msg: 'Database connection pooled'),
                _LogEntry(time: 'T+0.4s', tag: 'FB', msg: 'Firebase initialized'),
                _LogEntry(time: 'T+0.0s', tag: 'SYS', msg: 'Main entry triggered'),
              ],
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
            TextSpan(text: '$time ', style: const TextStyle(color: Colors.blueGrey)),
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
