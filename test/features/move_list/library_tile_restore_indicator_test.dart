import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/daos/combos_dao.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/library_sort.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/appwrite_auth_providers.dart';
import 'package:breakdex/core/services/appwrite_auth_service.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/move_list/move_list_screen.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';

/// Task 5.3 — the tile's cloud affordance must track *protection*, not
/// bookkeeping. A move with no local video renders one of two things:
/// a download affordance when a verified cloud copy exists, or the plain
/// "gone" state when it does not. Before 5.3 both cases showed the download
/// icon, because the condition was `contentHash != null` — true for every
/// tracked asset, including ones that had never finished an upload.
void main() {
  late SharedPreferences prefs;

  // No videoPath: this is the placeholder branch, the only place the tile
  // makes a cloud claim.
  final move = Move(
    id: 'move-1',
    name: 'Six Step',
    category: 'default',
    learningState: 'learning',
    count: 0,
    createdAt: DateTime.now(),
    contentHash: 'hash-1',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpGrid(
    final WidgetTester tester, {
    required final Set<String> restorable,
  }) async {
    await prefs.setString('library_sort', LibrarySort.recentlyAdded.name);
    await prefs.setString('arsenal_view_mode', ViewMode.glance.name);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentAppwriteUserProvider.overrideWith(
            (final ref) => const Stream<AuthUser?>.empty(),
          ),
          libraryMovesProvider.overrideWithValue(AsyncValue.data([move])),
          libraryCombosProvider.overrideWithValue(
            const AsyncValue.data(<LibraryRow>[]),
          ),
          restorableAssetHashesProvider.overrideWith(
            (final ref) => Stream.value(restorable),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MoveListScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('offers a restore affordance when a cloud copy is verified', (
    final tester,
  ) async {
    await pumpGrid(tester, restorable: {'hash-1'});

    expect(find.byIcon(Icons.cloud_download_outlined), findsOneWidget);
    expect(find.text('Missing'), findsNothing);
  });

  testWidgets('tracked but unprotected does not promise a download', (
    final tester,
  ) async {
    // The asset has a contentHash — the old condition would have shown the
    // download icon here, for bytes that exist nowhere but this phone.
    await pumpGrid(tester, restorable: const {});

    expect(find.byIcon(Icons.cloud_download_outlined), findsNothing);
    expect(find.text('Missing'), findsOneWidget);
  });
}
