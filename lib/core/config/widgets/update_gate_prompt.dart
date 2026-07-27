import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/config/update_gate.dart';
import 'package:breakdex/core/config/update_gate_providers.dart';

/// Root wrapper that renders the config-driven update prompt over [child].
///
/// Behaviour is a pure function of [updateGateProvider]:
///  * [UpdateGateNone] → [child] verbatim (the inert default; zero overhead).
///  * [UpdateGateSoftNag] → [child] plus a dismissible strip along the bottom.
///  * [UpdateGateHardBlock] → a blocking scrim over [child]; not dismissible.
///
/// Wire once near the app root (wrapping the navigator's child). Inert until the
/// owner publishes a `minSupportedBuild`/`latestBuild` above the running build,
/// so mounting it is behaviour-safe.
class UpdateGatePrompt extends ConsumerStatefulWidget {
  const UpdateGatePrompt({required this.child, super.key});

  /// Identifies the blocking scrim in a hard-block state (the framework mounts
  /// its own [ModalBarrier]s, so type alone is not a reliable marker).
  static const Key hardBlockBarrierKey = ValueKey('update_gate_hard_block');

  final Widget child;

  @override
  ConsumerState<UpdateGatePrompt> createState() => _UpdateGatePromptState();
}

class _UpdateGatePromptState extends ConsumerState<UpdateGatePrompt> {
  /// The soft-nag message the user dismissed this session. A different message
  /// (owner published a newer nudge) re-shows the strip.
  String? _dismissedNag;

  @override
  Widget build(final BuildContext context) {
    final gate = ref.watch(updateGateProvider);
    return switch (gate) {
      UpdateGateNone() => widget.child,
      UpdateGateSoftNag(:final message) => _withSoftNag(context, message),
      UpdateGateHardBlock(:final message) => _withHardBlock(context, message),
    };
  }

  Widget _withSoftNag(final BuildContext context, final String message) {
    if (_dismissedNag == message) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: _SoftNagStrip(
              message: message,
              onDismiss: () => setState(() => _dismissedNag = message),
            ),
          ),
        ),
      ],
    );
  }

  Widget _withHardBlock(final BuildContext context, final String message) {
    return Stack(
      children: [
        widget.child,
        // Absorb every pointer so the app underneath is fully inert.
        const ModalBarrier(
          key: UpdateGatePrompt.hardBlockBarrierKey,
          dismissible: false,
          color: Colors.black54,
        ),
        Center(child: _HardBlockCard(message: message)),
      ],
    );
  }
}

class _SoftNagStrip extends StatelessWidget {
  const _SoftNagStrip({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.secondaryContainer,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: onDismiss,
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HardBlockCard extends StatelessWidget {
  const _HardBlockCard({required this.message});

  final String message;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.system_update, size: 40, color: colorScheme.primary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Update required',
                textAlign: TextAlign.center,
                style: AppTypography.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
