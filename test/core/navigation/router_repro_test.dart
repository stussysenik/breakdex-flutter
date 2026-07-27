import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:breakdex/core/navigation/app_router.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/appwrite_auth_service.dart';
import 'package:breakdex/core/services/appwrite_auth_providers.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = createTestDatabase();
  });

  testWidgets('router redirects legacy paths', (final tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (final details) {
      if (details.exception is FlutterError &&
          details.exception.toString().contains('overflowed')) {
        return;
      }
      originalOnError?.call(details);
    };
    addTearDown(() {
      FlutterError.onError = originalOnError;
    });

    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentAppwriteUserProvider.overrideWith((final ref) => Stream<AuthUser?>.value(null)),
        ],
        child: MaterialApp.router(
          routerConfig: appRouter,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    appRouter.go('/moves');
    await tester.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.path, equals('/breakdex/moves'));

    appRouter.go('/arsenal');
    await tester.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.path, equals('/breakdex'));

    await db.close();
    await tester.pump(const Duration(milliseconds: 500));
  });
}
