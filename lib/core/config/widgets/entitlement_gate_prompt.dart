import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/spacing.dart';
import '../../design/typography.dart';
import '../entitlement.dart';
import '../entitlement_providers.dart';

/// Root wrapper that renders the invite-code gate over [child] for released
/// builds that require an entitlement.
///
/// Behaviour is a pure function of [entitlementGateProvider]:
///  * [EntitlementGranted] → [child] verbatim (the inert default; zero overhead).
///  * [EntitlementRequired] → a blocking invite-code entry over [child].
///
/// Wire once near the app root, alongside `UpdateGatePrompt`. Inert at the
/// compiled defaults (`kEntitlementGateEnabled` is false), and even when enabled
/// it never blocks the owner, dev builds, grandfathered existing users, or an
/// already-entitled user — so mounting it is behaviour-safe.
class EntitlementGatePrompt extends ConsumerWidget {
  const EntitlementGatePrompt({required this.child, super.key});

  /// Identifies the blocking barrier in the required state.
  static const Key barrierKey = ValueKey('entitlement_gate_barrier');

  final Widget child;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final gate = ref.watch(entitlementGateProvider);
    return switch (gate) {
      EntitlementGranted() => child,
      EntitlementRequired() => Stack(
          children: [
            child,
            const ModalBarrier(
              key: barrierKey,
              dismissible: false,
              color: Colors.black54,
            ),
            const Center(child: _InviteEntryCard()),
          ],
        ),
    };
  }
}

class _InviteEntryCard extends ConsumerStatefulWidget {
  const _InviteEntryCard();

  @override
  ConsumerState<_InviteEntryCard> createState() => _InviteEntryCardState();
}

class _InviteEntryCardState extends ConsumerState<_InviteEntryCard> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.isEmpty || _submitting) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final response = await ref.read(entitlementServiceProvider).redeem(code);
    if (!mounted) {
      return;
    }
    if (response.isGrant) {
      // Re-read the entitlement → the gate re-evaluates to granted and lets the
      // app through. No navigation needed; the overlay simply lifts.
      ref.invalidate(entitlementProvider);
      return;
    }
    setState(() {
      _submitting = false;
      _error = _messageFor(response.outcome);
    });
  }

  String _messageFor(final RedeemOutcome outcome) => switch (outcome) {
        RedeemOutcome.invalidCode => "That code isn't valid. Check it and retry.",
        RedeemOutcome.expired => 'That code has expired.',
        RedeemOutcome.exhausted => 'That code has been fully used.',
        RedeemOutcome.error => "Couldn't reach the server. Try again.",
        RedeemOutcome.granted ||
        RedeemOutcome.alreadyEntitled =>
          '', // never shown — a grant lifts the gate
      };

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.key_outlined, size: 40, color: colorScheme.primary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Enter your invite code',
                textAlign: TextAlign.center,
                style: AppTypography.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Breakdex is invite-only for now. Enter the code you were sent to '
                'unlock your library.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                enabled: !_submitting,
                onSubmitted: (final _) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Invite code',
                  border: const OutlineInputBorder(),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Redeem'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
