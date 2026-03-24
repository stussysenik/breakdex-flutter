import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';

/// Gear icon button for accessing Settings from any screen's header.
///
/// Shows a badge with pending sync count when the user is logged in.
/// Replaces the old Settings bottom nav tab — settings is maintenance,
/// not a daily destination.
class SettingsGearButton extends ConsumerWidget {
  const SettingsGearButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount =
        ref.watch(pendingChangesCountProvider).valueOrNull ?? 0;
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => context.push('/settings'),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surface.withValues(alpha: 0.6),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Badge(
          isLabelVisible: isLoggedIn && pendingCount > 0,
          label: Text(
            pendingCount > 99 ? '99+' : '$pendingCount',
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
          backgroundColor: colorScheme.primary,
          child: Icon(
            Icons.settings_outlined,
            size: 20,
            color: colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}
