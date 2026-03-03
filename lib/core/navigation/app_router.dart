import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/move_list/move_list_screen.dart';
import '../../features/move_detail/move_detail_screen.dart';
import '../../features/flashcard_review/flashcard_review_screen.dart';
import '../../features/create_combo/create_combo_screen.dart';
import '../../features/combo_detail/combo_detail_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/video_editor/video_editor_screen.dart';
import '../../shared/widgets/bottom_nav_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/arsenal',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          BottomNavShell(navigationShell: navigationShell),
      branches: [
        // Arsenal (Move List)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/arsenal',
              builder: (context, state) => const MoveListScreen(),
              routes: [
                GoRoute(
                  path: 'move/:id',
                  builder: (context, state) => MoveDetailScreen(
                    moveId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: 'combo/:id',
                  builder: (context, state) => ComboDetailScreen(
                    comboId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Create
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/create',
              builder: (context, state) => const CreateComboScreen(),
            ),
          ],
        ),
        // Review
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/review',
              builder: (context, state) => const FlashcardReviewScreen(),
            ),
          ],
        ),
        // Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    // Modal routes (no bottom nav)
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
  ],
);
