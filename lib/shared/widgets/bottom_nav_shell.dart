import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/design/theme.dart';
import '../../core/services/media_playback_coordinator.dart';
import '../../core/models/app_mode.dart';
import '../../core/services/settings_service.dart';
import 'sync_progress_bar.dart';

class BottomNavShell extends ConsumerWidget {
  const BottomNavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sync tab index so screens can react to visibility
    ref.read(currentTabIndexProvider.notifier).state =
        navigationShell.currentIndex;

    // Watch sync trigger to keep auto-sync alive
    ref.watch(syncTriggerProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      // Stack the nav bar on top of content so the blur peeks through
      extendBody: true,
      body: Column(
        children: [
          const SyncProgressBar(),
          Expanded(child: navigationShell),
        ],
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
              currentIndex: navigationShell.currentIndex,
              onTap: (index) {
                MediaPlaybackCoordinator.shared.pauseAll();
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              // Transparent so the frosted container shows through
              backgroundColor: Colors.transparent,
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: Semantics(
                    identifier: 'breakdex-tab',
                    child: const Icon(Icons.grid_view_rounded),
                  ),
                  label: 'Breakdex',
                ),
                BottomNavigationBarItem(
                  icon: Semantics(
                    identifier: 'add-tab',
                    child: const Icon(Icons.add_circle_outline),
                  ),
                  label: 'Add',
                ),
                BottomNavigationBarItem(
                  icon: Semantics(
                    identifier: 'review-tab',
                    child: Consumer(
                      builder: (context, ref, _) {
                        final appMode = ref.watch(appModeProvider);
                        return Icon(
                          appMode == AppMode.anki
                              ? Icons.style_outlined
                              : Icons.celebration_outlined,
                        );
                      },
                    ),
                  ),
                  label: 'Review',
                ),
                BottomNavigationBarItem(
                  icon: Semantics(
                    identifier: 'settings-tab',
                    child: const Icon(Icons.settings_outlined),
                  ),
                  label: 'Settings',
                ),
                // ARCHIVED: Progress, Lab, Flow tabs — restore when ready
                // BottomNavigationBarItem(
                //   icon: Semantics(
                //     identifier: 'progress-tab',
                //     label: 'Progress, work in progress',
                //     child: const WipTabIcon(icon: Icons.insights_rounded),
                //   ),
                //   label: 'Progress',
                // ),
                // BottomNavigationBarItem(
                //   icon: Semantics(
                //     identifier: 'lab-tab',
                //     label: 'Lab, work in progress',
                //     child: const WipTabIcon(icon: Icons.science_outlined),
                //   ),
                //   label: 'Lab',
                // ),
                // BottomNavigationBarItem(
                //   icon: Semantics(
                //     identifier: 'flow-tab',
                //     label: 'Flow, work in progress',
                //     child: const WipTabIcon(icon: Icons.auto_awesome_outlined),
                //   ),
                //   label: 'Flow',
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
