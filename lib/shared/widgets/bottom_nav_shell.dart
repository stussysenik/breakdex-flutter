import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/design/theme.dart';
import 'sync_progress_bar.dart';

class BottomNavShell extends ConsumerWidget {
  const BottomNavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              onTap: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              // Transparent so the frosted container shows through
              backgroundColor: Colors.transparent,
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: Semantics(
                    identifier: 'moves-tab',
                    child: const Icon(Icons.grid_view_rounded),
                  ),
                  label: 'Moves',
                ),
                BottomNavigationBarItem(
                  icon: Semantics(
                    identifier: 'drill-tab',
                    child: const Icon(Icons.style_outlined),
                  ),
                  label: 'Drill',
                ),
                BottomNavigationBarItem(
                  icon: Semantics(
                    identifier: 'progress-tab',
                    child: const Icon(Icons.insights_rounded),
                  ),
                  label: 'Progress',
                ),
                BottomNavigationBarItem(
                  icon: Semantics(
                    identifier: 'lab-tab',
                    child: const Icon(Icons.science_outlined),
                  ),
                  label: 'Lab',
                ),
                BottomNavigationBarItem(
                  icon: Semantics(
                    identifier: 'flow-tab',
                    child: const Icon(Icons.auto_awesome_outlined),
                  ),
                  label: 'Flow',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
