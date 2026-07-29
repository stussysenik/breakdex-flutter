import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';

/// Gear icon button for accessing Settings from any screen's header.
///
/// Shows a badge with pending sync count when the user is logged in.
/// Replaces the old Settings bottom nav tab — settings is maintenance,
/// not a daily destination.
class SettingsGearButton extends ConsumerWidget {
  const SettingsGearButton({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final pendingCount =
        ref.watch(pendingChangesCountProvider).valueOrNull ?? 0;
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      identifier: 'settings-gear',
      label: l10n.navSettings,
      button: true,
      child: GestureDetector(
        onTap: () => context.push('/settings-panel'),
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
            child: AppIconView(
              AppIcon.settings,
              size: 20,
              color: colorScheme.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
