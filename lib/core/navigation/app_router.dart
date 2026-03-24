import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/move_list/move_list_screen.dart';
import '../../features/move_detail/move_detail_screen.dart';
import '../../features/flashcard_review/flashcard_review_screen.dart';
import '../../features/create_combo/create_combo_screen.dart';
import '../../features/combo_detail/combo_detail_screen.dart';
import '../../features/lab/lab_screen.dart';
import '../../features/lab/lab_detail_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/flow/flow_screen.dart';
import '../../features/stats/stats_screen.dart';
import '../../features/battle/battle_screen.dart';
import '../../features/video_editor/video_editor_screen.dart';
import '../../features/move_analysis/move_analysis_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/settings/free_space_screen.dart';
import '../../features/settings/sync_providers_screen.dart';
import '../../features/settings/sync_status_screen.dart';
import '../../features/settings/help/asset_sync_help_screen.dart';
import '../../shared/widgets/bottom_nav_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/moves',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          BottomNavShell(navigationShell: navigationShell),
      branches: [
        // Moves (Move List)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/moves',
              builder: (context, state) => MoveListScreen(),
              routes: [
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
        // Drill
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/drill',
              builder: (context, state) => const FlashcardReviewScreen(),
            ),
          ],
        ),
        // Progress
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/progress',
              builder: (context, state) => const StatsScreen(),
            ),
          ],
        ),
        // Lab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/lab',
              builder: (context, state) => const LabScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => LabDetailScreen(
                    labId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Flow (move transition map)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/flow',
              builder: (context, state) => const FlowScreen(),
              routes: [
                GoRoute(
                  path: 'move/:id',
                  builder: (context, state) =>
                      MoveDetailScreen(moveId: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    // Modal routes (no bottom nav)
    GoRoute(
      path: '/create-combo',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreateComboScreen(),
    ),
    GoRoute(
      path: '/edit-combo/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          CreateComboScreen(comboId: state.pathParameters['id']!),
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
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/sync-providers',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SyncProvidersScreen(),
    ),
    GoRoute(
      path: '/settings/sync-status',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SyncStatusScreen(),
    ),
    GoRoute(
      path: '/settings/free-space',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FreeSpaceScreen(),
    ),
    GoRoute(
      path: '/settings/sync-help',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AssetSyncHelpScreen(),
    ),
  ],
);
