import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/providers.dart';
import '../../core/services/settings_service.dart';
import '../../core/sync/icloud_setup_service.dart';

/// First-launch card prompting iCloud backup with one-tap enable.
///
/// Shows only when:
/// 1. Onboarding hasn't been dismissed yet
/// 2. iCloud is available on this device
///
/// After the user taps Enable or Skip, the card disappears permanently.
class SyncOnboardingCard extends ConsumerWidget {
  const SyncOnboardingCard({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final shown = ref.watch(syncOnboardingShownProvider);
    if (shown) return const SizedBox.shrink();

    final iCloudAvailable = ref.watch(iCloudAvailableProvider);
    return iCloudAvailable.when(
      data: (final available) =>
          available ? _OnboardingCardContent() : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _OnboardingCardContent extends ConsumerStatefulWidget {
  @override
  ConsumerState<_OnboardingCardContent> createState() =>
      _OnboardingCardContentState();
}

class _OnboardingCardContentState
    extends ConsumerState<_OnboardingCardContent> {
  bool _enabling = false;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenEdge,
        vertical: AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_outlined, color: AppColors.accent, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Back up your videos to iCloud?',
                    style: AppTypography.titleSmall.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your training videos will be automatically backed up.',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _enabling ? null : _enableICloud,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                    ),
                    child: _enabling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Enable iCloud'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                TextButton(
                  onPressed: _enabling ? null : _dismiss,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enableICloud() async {
    setState(() => _enabling = true);
    HapticFeedback.mediumImpact();

    final result = await ref.read(iCloudSetupProvider).enable();
    if (!mounted) return;

    setState(() => _enabling = false);
    _dismiss();

    if (result == ICloudSetupResult.notAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enable iCloud Drive in iOS Settings > [your name] > iCloud',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _dismiss() {
    ref.read(syncOnboardingShownProvider.notifier).state = true;
    ref.read(sharedPreferencesProvider).setBool('sync_onboarding_shown', true);
  }
}
