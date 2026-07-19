import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/models/move_detail_caption.dart';
import 'package:breakdex/features/move_detail/widgets/move_detail_caption_line.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';

/// The caption slot as the detail screen actually renders it.
///
/// No provider scope and no Drift: the widget is dumb by construction, so the
/// documented live-stream flake class cannot apply here.
void main() {
  Future<void> pump(
    final WidgetTester tester,
    final MoveDetailCaptionSpec spec, {
    final DateTime? now,
  }) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MoveDetailCaptionLine(spec: spec, now: now),
      ),
    ),
  );

  testWidgets('a date renders through the shared library wording', (
    final tester,
  ) async {
    final now = DateTime(2026, 7, 19, 12);
    await pump(tester, MoveDetailCaptionSpec.date(DateTime(2026, 7, 16, 12)), now: now);

    // "Added 3 days ago" — the same phrasing the library rows use, which is the
    // point of routing through LibraryDateLabel rather than formatting here.
    expect(find.textContaining('Added'), findsOneWidget);
    expect(find.textContaining('3 days ago'), findsOneWidget);
  });

  testWidgets('a filename renders monospace and does not wrap', (
    final tester,
  ) async {
    await pump(tester, const MoveDetailCaptionSpec.text('IMG_4471.mov'));

    final text = tester.widget<Text>(find.text('IMG_4471.mov'));
    expect(text.style?.fontFamily, 'monospace');
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('none renders no text at all', (final tester) async {
    await pump(tester, const MoveDetailCaptionSpec.none());

    expect(find.byType(Text), findsNothing);
  });
}
