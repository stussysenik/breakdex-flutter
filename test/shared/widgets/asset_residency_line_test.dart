import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/models/asset_residency.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/shared/widgets/asset_residency_line.dart';

Widget _host(final AssetResidency residency) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: AssetResidencyLine(residency: residency)),
);

void main() {
  testWidgets('untracked says so instead of implying safety', (
    final tester,
  ) async {
    await tester.pumpWidget(
      _host(const AssetResidency(state: AssetResidencyState.untracked)),
    );
    expect(find.textContaining('Not tracked yet'), findsOneWidget);
  });

  testWidgets('local-only names the absence, not just the presence', (
    final tester,
  ) async {
    await tester.pumpWidget(
      _host(const AssetResidency(state: AssetResidencyState.localOnly)),
    );
    expect(find.textContaining('This device only'), findsOneWidget);
  });

  testWidgets('uploaded names both places on one line', (final tester) async {
    await tester.pumpWidget(
      _host(
        const AssetResidency(
          state: AssetResidencyState.uploaded,
          cloudPlaces: [CloudPlace.gdrive],
        ),
      ),
    );
    expect(
      find.textContaining('This device · Google Drive'),
      findsOneWidget,
    );
  });

  testWidgets('pending states the direction as well as the location', (
    final tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const AssetResidency(
          state: AssetResidencyState.pending,
          cloudPlaces: [CloudPlace.gdrive],
          pendingPlaces: [CloudPlace.icloud],
        ),
      ),
    );
    // Location AND direction — 8.2: conflating them is worse than no badge.
    expect(find.textContaining('Google Drive'), findsOneWidget);
    expect(find.textContaining('sending to iCloud'), findsOneWidget);
  });

  testWidgets('failure is drawn in the error role, not the body role', (
    final tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const AssetResidency(
          state: AssetResidencyState.failed,
          failedPlaces: [CloudPlace.gdrive],
        ),
      ),
    );
    final text = tester.widget<Text>(
      find.textContaining('upload failed — Google Drive'),
    );
    final context = tester.element(find.byType(AssetResidencyLine));
    expect(text.style?.color, Theme.of(context).colorScheme.error);
  });

  testWidgets('cloud-only warns the bytes are not on this device', (
    final tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const AssetResidency(
          state: AssetResidencyState.cloudOnly,
          cloudPlaces: [CloudPlace.gdrive],
        ),
      ),
    );
    expect(
      find.textContaining('Google Drive only — not on this device'),
      findsOneWidget,
    );
  });
}
