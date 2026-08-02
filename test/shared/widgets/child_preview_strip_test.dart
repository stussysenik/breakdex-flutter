import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/shared/widgets/child_preview_strip.dart';
import 'package:breakdex/shared/widgets/video_thumbnail_image.dart';

/// Task 8.3 — what the strip claims about a parent, independent of whether any
/// frame ever decodes. The thumbnails themselves are owner-verified on a real
/// screen; the arithmetic is not.
/// The thumbnail loader arms a 5s file-access timeout on mount. These tests
/// assert the strip's arithmetic, not its decoding, so the load is let finish
/// rather than left pending into teardown.
Future<void> drainThumbnailLoads(final WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(seconds: 3));
  }
}

void main() {
  Future<void> pumpStrip(
    final WidgetTester tester, {
    required final List<String> videoPaths,
    required final int totalCount,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChildPreviewStrip(
          videoPaths: videoPaths,
          totalCount: totalCount,
        ),
      ),
    ),
  );

  testWidgets('an unfilmed parent renders nothing at all', (
    final tester,
  ) async {
    await pumpStrip(tester, videoPaths: const [], totalCount: 9);

    expect(find.byType(VideoThumbnailImage), findsNothing);
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('shows at most four faces and counts the rest', (
    final tester,
  ) async {
    await pumpStrip(
      tester,
      videoPaths: const ['a.mp4', 'b.mp4', 'c.mp4', 'd.mp4', 'e.mp4'],
      totalCount: 9,
    );

    expect(find.byType(VideoThumbnailImage), findsNWidgets(4));
    // +5, not +1: the overflow answers how much is inside the parent, not how
    // many paths were handed to the strip.
    expect(find.text('+5'), findsOneWidget);
    await drainThumbnailLoads(tester);
  });

  testWidgets('a parent that fits says no more', (final tester) async {
    await pumpStrip(
      tester,
      videoPaths: const ['a.mp4', 'b.mp4'],
      totalCount: 2,
    );

    expect(find.byType(VideoThumbnailImage), findsNWidgets(2));
    expect(find.textContaining('+'), findsNothing);
    await drainThumbnailLoads(tester);
  });
}
