import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/appwrite_auth_service.dart';
import 'package:breakdex/core/services/appwrite_auth_providers.dart';
import 'package:breakdex/core/sync/asset_sync_engine.dart';
import 'package:breakdex/core/sync/cloud_provider.dart';
import 'package:breakdex/core/sync/providers/gdrive_provider.dart';
import 'package:breakdex/features/settings/widgets/cloud_sync_section.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure-override harness: every stream the section watches is stubbed, so no
/// live Drift query streams exist (their close timers flake widget tests) —
/// the DB-backed email caching itself is covered by
/// `gdrive_setup_service_test.dart`.
Future<void> pumpSection(
  final WidgetTester tester, {
  required final bool isWeb,
  final String? accountEmail,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cloudProvidersProvider.overrideWith(
          (final ref) => Stream.value(<CloudProvider>[GDriveProvider()]),
        ),
        underprotectedCountProvider.overrideWith(
          (final ref) => Stream.value(0),
        ),
        gdriveAccountEmailProvider.overrideWith(
          (final ref) async => accountEmail,
        ),
        currentAppwriteUserProvider.overrideWith(
          (final ref) => Stream<AuthUser?>.value(null),
        ),
        assetSyncProgressProvider.overrideWith(
          (final ref) => const Stream<SyncProgress>.empty(),
        ),
        iCloudAvailableProvider.overrideWith((final ref) async => false),
        isWebPlatformProvider.overrideWithValue(isWeb),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: CloudSyncSection()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'connected Drive row names the account that holds the backup (2.1)',
      (final tester) async {
    await pumpSection(tester, isWeb: false, accountEmail: 'dancer@gmail.com');

    expect(find.text('Connected · dancer@gmail.com'), findsOneWidget);
  });

  testWidgets(
      'on web the Drive row is unavailable with a reason and no tap (2.2)',
      (final tester) async {
    await pumpSection(tester, isWeb: true, accountEmail: 'dancer@gmail.com');

    expect(find.text('Backup runs from your phone'), findsOneWidget);

    final driveRow = tester.widget<SyncProviderRow>(
      find.ancestor(
        of: find.text('Backup runs from your phone'),
        matching: find.byType(SyncProviderRow),
      ),
    );
    expect(driveRow.status, ProviderStatus.unavailable);
    expect(driveRow.onTap, isNull,
        reason: 'no sign-in attempt may be offered on web');
  });
}
