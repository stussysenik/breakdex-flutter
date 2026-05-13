import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_route_observer.dart';
import '../../features/move_detail/move_detail_screen.dart';
import '../../features/flashcard_review/flashcard_review_screen.dart';
import '../../features/create_combo/create_combo_screen.dart';
import '../../features/combo_detail/combo_detail_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/recently_deleted_screen.dart';
import '../../features/settings/canonical_trash_screen.dart';
import '../../features/battle/battle_screen.dart';
import '../../features/video_editor/video_editor_screen.dart';
import '../../features/move_analysis/move_analysis_screen.dart';
import '../../features/breakdex/breakdex_screen.dart';
import '../../features/move_category/move_category_screen.dart';
import '../../features/combo_list/combo_list_screen.dart';
import '../../features/add/add_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/settings/free_space_screen.dart';
import '../../features/settings/sync_providers_screen.dart';
import '../../features/settings/sync_status_screen.dart';
import '../../features/settings/help/asset_sync_help_screen.dart';
import '../../shared/widgets/bottom_nav_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/breakdex',
  observers: [appRouteObserver],
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          BottomNavShell(navigationShell: navigationShell),
      branches: [
        // Breakdex — moves library home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/breakdex',
              builder: (context, state) => const BreakdexScreen(),
              routes: [
                GoRoute(
                  path: 'moves',
                  builder: (context, state) => const MoveCategoryScreen(),
                  routes: [
                    GoRoute(
                      path: ':category',
                      builder: (context, state) =>
                          MoveCategoryDetailScreen(
                            categoryName: state.pathParameters['category']!,
                          ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'combos',
                  builder: (context, state) => const ComboListScreen(),
                ),
                GoRoute(
                  path: 'move/:id',
                  builder: (context, state) =>
                      MoveDetailScreen(moveId: state.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'combo/:id',
                  builder: (context, state) =>
                      ComboDetailScreen(comboId: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        // Add — create moves
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/add', builder: (context, state) => const AddScreen()),
          ],
        ),
        // Drill — flashcard review
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/drill',
              builder: (context, state) => const FlashcardReviewScreen(),
            ),
          ],
        ),
        // Settings — global app settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen.tab(),
            ),
          ],
        ),
      ],
    ),
    // Modal routes (no bottom nav) — full-page screens pushed over shell
    GoRoute(
      path: '/create-combo',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreateComboScreen(),
    ),
    GoRoute(
      path: '/edit-combo/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          CreateComboScreen(comboId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/battle',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BattleScreen(),
    ),
    GoRoute(
      path: '/video-editor',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>?;
        return VideoEditorScreen(
          videoPath: extras?['videoPath'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/move-analysis',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>?;
        return MoveAnalysisScreen(
          moveId: extras?['moveId'] as String?,
          videoPath: extras?['videoPath'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/auth',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/settings-panel',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings-panel/sync-providers',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SyncProvidersScreen(),
    ),
    GoRoute(
      path: '/settings-panel/sync-status',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SyncStatusScreen(),
    ),
    GoRoute(
      path: '/settings-panel/free-space',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FreeSpaceScreen(),
    ),
    GoRoute(
      path: '/settings-panel/recently-deleted',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RecentlyDeletedScreen(),
    ),
    GoRoute(
      path: '/settings-panel/canonical-trash',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CanonicalTrashScreen(),
    ),
    GoRoute(
      path: '/settings-panel/sync-help',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AssetSyncHelpScreen(),
    ),
  ],
);
