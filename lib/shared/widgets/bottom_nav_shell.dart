import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/services/hydrate_on_login_providers.dart';
import 'package:breakdex/core/services/legacy_identity_providers.dart';
import 'package:breakdex/core/services/media_playback_coordinator.dart';
import 'package:breakdex/core/models/app_mode.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/core/utils/diagnostics.dart';
import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/shared/widgets/nav_band_scope.dart';
import 'package:breakdex/shared/widgets/shake_detector.dart';
import 'package:breakdex/shared/widgets/sync_progress_bar.dart';

class BottomNavShell extends ConsumerWidget {
  const BottomNavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final showStats = ref.watch(showStatsTabProvider);
    final l10n = AppLocalizations.of(context);

    // Only update tab index in post-frame — avoids side effects during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        final current = ref.read(currentTabIndexProvider);
        if (current != navigationShell.currentIndex) {
          DiagnosticsLog.debug(
            'BottomNavShell',
            'Syncing tab index: current=$current, next=${navigationShell.currentIndex}',
          );
          ref.read(currentTabIndexProvider.notifier).state =
              navigationShell.currentIndex;
        }
      }
    });

    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      extendBody: true,
      body: ShakeDetector(
        onShake: () {
          if (navigationShell.currentIndex == 2) {
            DiagnosticsLog.debug(
              'BottomNavShell',
              'shake ignored — already on review tab',
            );
            return;
          }
          DiagnosticsLog.info(
            'BottomNavShell',
            'shake triggered — navigating to review',
          );
          navigationShell.goBranch(2);
        },
        child: Column(
          children: [
            // Only the progress bar and sync logic need to watch the trigger
            Consumer(
              builder: (final context, final ref, _) {
                ref.watch(syncTriggerProvider);
                // D3 legacy-identity claim on first Appwrite login (task 3.4);
                // no-op until a session exists, idempotent thereafter.
                ref.watch(legacyIdentityClaimTriggerProvider);
                // Auto-hydrate local Drift from the backend on first login so a
                // fresh device (esp. a just-signed-in web client) sees the
                // user's library immediately; once per user, never throws.
                ref.watch(hydrateOnLoginTriggerProvider);
                return const SyncProgressBar();
              },
            ),
            // Everything inside the branch navigator has band 4 drawn over it
            // (`extendBody: true`). Screens and sheets read this to reserve the
            // inset; a root-navigator route never sees it and reserves none.
            Expanded(child: NavBandScope(child: navigationShell)),
          ],
        ),
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              // Semi-transparent surface — content bleeds through the blur
              color: colorScheme.surface.withValues(alpha: 0.85),
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              boxShadow: AppShadows.layered(brightness),
            ),
            child: BottomNavigationBar(
              currentIndex: _calculateRealIndex(
                navigationShell.currentIndex,
                showStats,
              ),
              onTap: (final index) {
                MediaPlaybackCoordinator.shared.pauseAll();
                final branchIndex = _calculateBranchIndex(index, showStats);
                DiagnosticsLog.info(
                  'BottomNavShell',
                  'Tab tapped: visual_index=$index, showStats=$showStats -> branch_index=$branchIndex',
                );
                navigationShell.goBranch(
                  branchIndex,
                  initialLocation: branchIndex == navigationShell.currentIndex,
                );
              },
              // Transparent so the frosted container shows through
              backgroundColor: Colors.transparent,
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: Semantics(
                    identifier: 'breakdex-tab',
                    child: const AppIconView(AppIcon.library),
                  ),
                  label: l10n.navBreakdex,
                ),
                BottomNavigationBarItem(
                  icon: Semantics(
                    identifier: 'add-tab',
                    child: const AppIconView(AppIcon.add),
                  ),
                  label: l10n.navAdd,
                ),
                BottomNavigationBarItem(
                  icon: Semantics(
                    identifier: 'review-tab',
                    child: Consumer(
                      builder: (final context, final ref, _) {
                        final appMode = ref.watch(appModeProvider);
                        return AppIconView(
                          appMode == AppMode.anki
                              ? AppIcon.dojo
                              : AppIcon.celebration,
                        );
                      },
                    ),
                  ),
                  label: l10n.navReview,
                ),
                if (showStats)
                  BottomNavigationBarItem(
                    icon: Semantics(
                      identifier: 'stats-tab',
                      child: const AppIconView(AppIcon.insight),
                    ),
                    label: l10n.navStats,
                  ),
                BottomNavigationBarItem(
                  icon: Semantics(
                    identifier: 'settings-tab',
                    child: const AppIconView(AppIcon.settings),
                  ),
                  label: l10n.navSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _calculateRealIndex(final int branchIndex, final bool showStats) {
    if (showStats) return branchIndex;
    // If stats is hidden, branch 4 (Settings) becomes visual index 3
    if (branchIndex == 4) return 3;
    return branchIndex;
  }

  int _calculateBranchIndex(final int visualIndex, final bool showStats) {
    if (showStats) return visualIndex;
    // If stats is hidden, visual index 3 maps to branch 4 (Settings)
    if (visualIndex == 3) return 4;
    return visualIndex;
  }
}
