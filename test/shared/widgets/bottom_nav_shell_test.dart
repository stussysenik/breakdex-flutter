import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:breakdex/shared/widgets/bottom_nav_shell.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';

void main() {
  testWidgets('BottomNavShell does not throw Riverpod modification error on build', (final tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final router = GoRouter(
      initialLocation: '/a',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (final context, final state, final navigationShell) {
            return ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                syncTriggerProvider.overrideWith((final ref) {}),
              ],
              child: BottomNavShell(navigationShell: navigationShell),
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/a',
                  builder: (final context, final state) => const Scaffold(body: Text('Tab A')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/b',
                  builder: (final context, final state) => const Scaffold(body: Text('Tab B')),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );

    expect(find.byType(BottomNavShell), findsOneWidget);
  });
}
