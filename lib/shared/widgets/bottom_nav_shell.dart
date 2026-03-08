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
    final pendingCount =
        ref.watch(pendingChangesCountProvider).valueOrNull ?? 0;
    final isLoggedIn = ref.watch(isLoggedInProvider);

    // Watch sync trigger to keep auto-sync alive
    ref.watch(syncTriggerProvider);

    return Scaffold(
      body: Column(
        children: [
          const SyncProgressBar(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: 0.5,
            ),
          ),
          boxShadow: AppShadows.raised(Theme.of(context).brightness),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.grid_view_rounded),
              label: 'Arsenal',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.style_outlined),
              label: 'Review',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.insights_rounded),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: isLoggedIn && pendingCount > 0,
                label: Text(
                  pendingCount > 99 ? '99+' : '$pendingCount',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.settings_outlined),
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
