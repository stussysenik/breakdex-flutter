import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/core/sync/asset_sync_detail.dart';
import 'package:breakdex/core/sync/asset_sync_engine.dart';
import 'package:breakdex/features/settings/sync_status_screen.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pure-override harness: every stream the screen watches is stubbed, so no
/// live Drift query streams exist (their close timers flake widget tests).
/// The query itself is covered by `test/core/sync/asset_sync_detail_test.dart`.
Future<void> _pumpScreen(
  final WidgetTester tester, {
  required final List<AssetSyncDetail>? details,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        assetSyncProgressProvider.overrideWith(
          (final ref) => const Stream<SyncProgress>.empty(),
        ),
        underprotectedCountProvider.overrideWith((final ref) => Stream.value(0)),
        assetSyncDetailsProvider.overrideWith(
          (final ref) => details == null
              ? const Stream<List<AssetSyncDetail>>.empty()
              : Stream.value(details),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SyncStatusScreen(),
      ),
    ),
  );
  // Not pumpAndSettle: an indeterminate progress bar animates forever, so
  // settling would time out on exactly the case worth testing.
  await tester.pump();
  await tester.pump();
}

AssetSyncDetail _detail({
  required final String label,
  required final AssetSyncStatus status,
  final int fileSizeBytes = 10 * 1024 * 1024,
  final int transferredBytes = 0,
  final String? errorMessage,
  final bool isTerminal = false,
  final List<AssetCopyState> copies = const [],
}) =>
    AssetSyncDetail(
      contentHash: label,
      label: label,
      fileSizeBytes: fileSizeBytes,
      status: status,
      transferredBytes: transferredBytes,
      errorMessage: errorMessage,
      isTerminal: isTerminal,
      copies: copies,
    );

void main() {
  testWidgets('a silent stream says Checking, never an empty library',
      (final tester) async {
    await _pumpScreen(tester, details: null);

    expect(find.text('Checking…'), findsOneWidget);
    expect(find.text('No videos are being tracked yet.'), findsNothing);
  });

  testWidgets('an empty list says so plainly', (final tester) async {
    await _pumpScreen(tester, details: const []);

    expect(find.text('No videos are being tracked yet.'), findsOneWidget);
  });

  testWidgets('an uploading asset shows its bytes and a progress bar',
      (final tester) async {
    await _pumpScreen(tester, details: [
      _detail(
        label: 'flare.mp4',
        status: AssetSyncStatus.uploading,
        fileSizeBytes: 10 * 1024 * 1024,
        transferredBytes: 5 * 1024 * 1024,
      ),
    ]);

    expect(find.text('flare.mp4'), findsOneWidget);
    expect(find.text('5.0 MB of 10.0 MB · 50%'), findsOneWidget);

    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('assetProgress_flare.mp4')),
    );
    expect(bar.value, closeTo(0.5, 0.001));
  });

  testWidgets('an upload with no bytes yet shows an indeterminate bar',
      (final tester) async {
    await _pumpScreen(tester, details: [
      _detail(label: 'windmill.mp4', status: AssetSyncStatus.uploading),
    ]);

    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('assetProgress_windmill.mp4')),
    );
    expect(bar.value, isNull);
  });

  testWidgets('an upload with no bytes yet says "Starting", not 0%',
      (final tester) async {
    await _pumpScreen(tester, details: [
      _detail(label: 'windmill.mp4', status: AssetSyncStatus.uploading),
    ]);

    expect(find.text('Starting · 10.0 MB'), findsOneWidget);
    expect(find.textContaining('0%'), findsNothing);
  });

  testWidgets('a failure shows its error and whether it will retry',
      (final tester) async {
    await _pumpScreen(tester, details: [
      _detail(
        label: 'headspin.mp4',
        status: AssetSyncStatus.failed,
        errorMessage: 'file not found',
      ),
      _detail(
        label: 'airflare.mp4',
        status: AssetSyncStatus.failed,
        errorMessage: 'file not found',
        isTerminal: true,
      ),
    ]);

    expect(find.text('Retrying after: file not found'), findsOneWidget);
    // "Won't retry" is reserved for the terminal verdict, where it is a kept
    // promise since 4.4 (queueUpload consults the verdict). A non-terminal
    // failure is re-swept, so it must never claim a stop (task 4.10).
    expect(find.text("Won't retry — file not found"), findsOneWidget);
    expect(find.textContaining("Won't retry"), findsOneWidget);
  });

  testWidgets('a failure with no recorded error still says what happened',
      (final tester) async {
    await _pumpScreen(tester, details: [
      _detail(label: 'headspin.mp4', status: AssetSyncStatus.failed),
      _detail(
        label: 'airflare.mp4',
        status: AssetSyncStatus.failed,
        isTerminal: true,
      ),
    ]);

    expect(find.text('Retrying after a failed upload'), findsOneWidget);
    expect(
      find.text("Won't retry — the video file is nowhere on this device"),
      findsOneWidget,
    );
  });

  testWidgets('a backed-up asset names the providers holding it',
      (final tester) async {
    await _pumpScreen(tester, details: [
      _detail(
        label: 'flare.mp4',
        status: AssetSyncStatus.backedUp,
        copies: const [
          AssetCopyState(provider: 'gdrive', status: 'verified'),
          AssetCopyState(provider: 'local', status: 'verified'),
        ],
      ),
    ]);

    // The local copy is not cloud protection, so it is not listed as one.
    expect(find.text('gdrive'), findsOneWidget);
  });

  testWidgets('a pending asset is named as not backed up', (final tester) async {
    await _pumpScreen(tester, details: [
      _detail(label: 'flare.mp4', status: AssetSyncStatus.pending),
    ]);

    expect(find.text('Not backed up · 10.0 MB'), findsOneWidget);
  });

  testWidgets('the tally splits what is moving from what is waiting from '
      'what is broken', (final tester) async {
    await _pumpScreen(tester, details: [
      _detail(label: 'a.mp4', status: AssetSyncStatus.uploading),
      _detail(label: 'b.mp4', status: AssetSyncStatus.queued),
      _detail(label: 'c.mp4', status: AssetSyncStatus.pending),
      _detail(label: 'd.mp4', status: AssetSyncStatus.failed),
      _detail(
        label: 'e.mp4',
        status: AssetSyncStatus.failed,
        isTerminal: true,
      ),
      _detail(label: 'f.mp4', status: AssetSyncStatus.backedUp),
    ]);

    expect(find.text('1 uploading'), findsOneWidget);
    expect(find.text('2 waiting'), findsOneWidget);
    expect(find.text('1 retrying'), findsOneWidget);
    expect(find.text("1 can't be backed up"), findsOneWidget);
    expect(find.text('1 backed up'), findsOneWidget);
  });

  testWidgets('empty buckets are omitted rather than shown as zero',
      (final tester) async {
    await _pumpScreen(tester, details: [
      _detail(label: 'a.mp4', status: AssetSyncStatus.backedUp),
    ]);

    expect(find.text('1 backed up'), findsOneWidget);
    for (final zero in const [
      '0 uploading',
      '0 waiting',
      '0 retrying',
      "0 can't be backed up",
    ]) {
      expect(find.text(zero), findsNothing);
    }
  });
}
