import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/navigation/app_route_observer.dart';
import 'package:breakdex/core/navigation/settings_section_page.dart';
import 'package:breakdex/features/move_detail/move_detail_screen.dart';
import 'package:breakdex/features/flashcard_review/flashcard_review_screen.dart';
import 'package:breakdex/features/create_combo/create_combo_screen.dart';
import 'package:breakdex/features/combo_detail/combo_detail_screen.dart';
import 'package:breakdex/features/settings/settings_screen.dart';
import 'package:breakdex/features/settings/recently_deleted_screen.dart';
import 'package:breakdex/features/settings/canonical_trash_screen.dart';
import 'package:breakdex/features/battle/battle_screen.dart';
import 'package:breakdex/features/video_editor/video_editor_screen.dart';
import 'package:breakdex/features/move_analysis/move_analysis_screen.dart';
import 'package:breakdex/features/breakdex/breakdex_screen.dart';
import 'package:breakdex/features/move_category/move_category_screen.dart';
import 'package:breakdex/features/combos/combos_screen.dart';
import 'package:breakdex/features/add/add_screen.dart';
import 'package:breakdex/features/party/party_screen.dart';
import 'package:breakdex/features/party/bloc/party_bloc.dart';
import 'package:breakdex/features/stats/stats_screen.dart';
import 'package:breakdex/features/auth/appwrite_login_screen.dart';
import 'package:breakdex/features/settings/free_space_screen.dart';
import 'package:breakdex/features/settings/sync_providers_screen.dart';
import 'package:breakdex/features/settings/sync_status_screen.dart';
import 'package:breakdex/features/settings/help/asset_sync_help_screen.dart';
import 'package:breakdex/features/settings/system_status_screen.dart';
import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/shared/widgets/bottom_nav_shell.dart';
import 'package:breakdex/shared/widgets/quick_video_viewer.dart';
import 'package:breakdex/core/models/app_mode.dart';
import 'package:breakdex/core/services/settings_service.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/breakdex',
  observers: [appRouteObserver],
  errorBuilder: (final context, final state) => const _RedirectToHome(),
  redirect: (final context, final state) {
    if (state.matchedLocation == '/') {
      return '/breakdex';
    }
    return null;
  },
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (final context, final state, final navigationShell) =>
          BottomNavShell(navigationShell: navigationShell),
      branches: [
        // Breakdex — moves library home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/breakdex',
              builder: (final context, final state) => const BreakdexScreen(),
              routes: [
                GoRoute(
                  path: 'moves',
                  builder: (final context, final state) => const MoveCategoryScreen(),
                  routes: [
                    GoRoute(
                      path: ':category',
                      builder: (final context, final state) =>
                          MoveCategoryDetailScreen(
                            categoryName: state.pathParameters['category']!,
                          ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'combos',
                  builder: (final context, final state) => const CombosScreen(),
                ),
                GoRoute(
                  path: 'move/:id',
                  builder: (final context, final state) =>
                      MoveDetailScreen(moveId: state.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'combo/:id',
                  builder: (final context, final state) =>
                      ComboDetailScreen(comboId: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        // Add — create moves
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/add', builder: (final context, final state) => const AddScreen()),
          ],
        ),
        // Review — flashcard drill or party shake, controlled via AppMode
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/review',
              builder: (final context, final state) => const _ReviewRouter(),
            ),
          ],
        ),
        // Stats — progress and learning metrics
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/stats',
              builder: (final context, final state) => const StatsScreen(),
            ),
          ],
        ),
        // Settings — global app settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (final context, final state) => const SettingsScreen.tab(),
            ),
          ],
        ),
      ],
    ),
    // Modal routes (no bottom nav) — full-page screens pushed over shell
    GoRoute(
      path: '/create-combo',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (final context, final state) => const CreateComboScreen(),
    ),
    GoRoute(
      path: '/edit-combo/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (final context, final state) =>
          CreateComboScreen(comboId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/battle',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (final context, final state) => const BattleScreen(),
    ),
    GoRoute(
      path: '/video-editor',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (final context, final state) {
        // The editor drives the iOS-only AVFoundation export/playback seams.
        // `/video-editor` is an addressable URL on web, so guard the route
        // itself — a deep-link degrades visibly instead of crashing (1.3).
        if (kIsWeb) return const _EditorUnavailableOnWeb();
        final extras = state.extra as Map<String, dynamic>?;
        return VideoEditorScreen(
          videoPath: extras?['videoPath'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/move-analysis',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (final context, final state) {
        final extras = state.extra as Map<String, dynamic>?;
        return MoveAnalysisScreen(
          moveId: extras?['moveId'] as String?,
          videoPath: extras?['videoPath'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      // The Appwrite Google sign-in surface (wave task 3.3). Optional entry:
      // reached from Settings → Sync, never a login wall. On success the session
      // stream drives `isLoggedInProvider`, so we just pop back to where the user
      // opened it from (falling back to home if this is the only route).
      path: '/auth',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (final context, final state) => AppwriteLoginScreen(
        onSignedIn: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
    ),
    GoRoute(
      path: '/settings-panel',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (final context, final state) => settingsSectionPage(
        key: state.pageKey,
        child: const SettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/settings-panel/sync-providers',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (final context, final state) => settingsSectionPage(
        key: state.pageKey,
        child: const SyncProvidersScreen(),
      ),
    ),
    GoRoute(
      path: '/settings-panel/sync-status',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (final context, final state) => settingsSectionPage(
        key: state.pageKey,
        child: const SyncStatusScreen(),
      ),
    ),
    GoRoute(
      path: '/settings-panel/free-space',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (final context, final state) => settingsSectionPage(
        key: state.pageKey,
        child: const FreeSpaceScreen(),
      ),
    ),
    GoRoute(
      path: '/settings-panel/recently-deleted',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (final context, final state) => settingsSectionPage(
        key: state.pageKey,
        child: const RecentlyDeletedScreen(),
      ),
    ),
    GoRoute(
      path: '/settings-panel/canonical-trash',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (final context, final state) => settingsSectionPage(
        key: state.pageKey,
        child: const CanonicalTrashScreen(),
      ),
    ),
    GoRoute(
      path: '/settings-panel/system-status',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (final context, final state) => settingsSectionPage(
        key: state.pageKey,
        child: const SystemStatusScreen(),
      ),
    ),
    GoRoute(
      path: '/settings-panel/sync-help',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (final context, final state) => settingsSectionPage(
        key: state.pageKey,
        child: const AssetSyncHelpScreen(),
      ),
    ),
    GoRoute(
      path: '/video-viewer',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (final context, final state) {
        final extras = state.extra as Map<String, dynamic>?;
        return QuickVideoViewer(
          videoPath: extras?['videoPath'] as String? ?? '',
          title: extras?['title'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/moves',
      redirect: (final context, final state) => '/breakdex/moves',
    ),
    GoRoute(
      path: '/moves/move/:id',
      redirect: (final context, final state) => '/breakdex/move/${state.pathParameters['id']}',
    ),
    GoRoute(
      path: '/moves/combo/:id',
      redirect: (final context, final state) => '/breakdex/combo/${state.pathParameters['id']}',
    ),
    GoRoute(
      path: '/arsenal',
      redirect: (final context, final state) => '/breakdex',
    ),
  ],
);

class _RedirectToHome extends StatefulWidget {
  const _RedirectToHome();

  @override
  State<_RedirectToHome> createState() => _RedirectToHomeState();
}

class _RedirectToHomeState extends State<_RedirectToHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/breakdex');
      }
    });
  }

  @override
  Widget build(final BuildContext context) {
    return const Scaffold(
      body: Center(
        child: AppLoader(),
      ),
    );
  }
}

/// Shown when `/video-editor` is reached on web (e.g. a deep-link). The editor
/// depends on iOS-only AVFoundation, so it degrades to a plain explanation
/// instead of building a screen that would crash on the native seam (1.3).
class _EditorUnavailableOnWeb extends StatelessWidget {
  const _EditorUnavailableOnWeb();

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.movie_creation_outlined, size: 48, color: colorScheme.secondary),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Video editing isn’t available on web',
                style: AppTypography.titleMedium.copyWith(color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Trim, crop, and speed edits run on the mobile app. Web plays '
                'videos but can’t edit them.',
                style: AppTypography.bodySmall.copyWith(color: colorScheme.secondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewRouter extends ConsumerWidget {
  const _ReviewRouter();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final appMode = ref.watch(appModeProvider);
    return switch (appMode) {
      AppMode.anki => const FlashcardReviewScreen(),
      AppMode.party => BlocProvider(
          create: (final context) => PartyBloc(),
          child: const PartyScreen(),
        ),
    };
  }
}
