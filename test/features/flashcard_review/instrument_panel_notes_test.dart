import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/models/review_card_display_settings.dart';
import 'package:breakdex/features/flashcard_review/widgets/instrument_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _longNote =
    'Keep the chair leg locked and drive from the shoulder — the first two '
    'rotations set the whole flare, so if the hips drop early the exit stalls.';

// showState:false keeps the panel free of StatePill (a ConsumerWidget) so the
// notes reveal can be tested without a ProviderScope — notes don't depend on it.
Widget _host({final String? notes}) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: InstrumentPanel(
        title: 'Flare',
        state: LearningState.learning,
        displaySettings: ReviewCardDisplaySettings.defaults.copyWith(
          showState: false,
        ),
        notes: notes,
      ),
    ),
  ),
);

void main() {
  testWidgets('long notes render collapsed behind an expand affordance', (
    final tester,
  ) async {
    await tester.pumpWidget(_host(notes: _longNote));

    // Collapsed: one line, an expand-more control, no collapse control.
    expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);
    expect(find.byIcon(Icons.expand_less_rounded), findsNothing);
    final collapsed = tester.widget<Text>(find.text(_longNote));
    expect(collapsed.maxLines, 1);
  });

  testWidgets('tapping the notes expands them to full text', (
    final tester,
  ) async {
    await tester.pumpWidget(_host(notes: _longNote));

    await tester.tap(find.text(_longNote));
    await tester.pump();

    expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);
    final expanded = tester.widget<Text>(find.text(_longNote));
    expect(expanded.maxLines, isNull); // unbounded — full note visible
  });

  testWidgets('empty notes render no notes affordance', (final tester) async {
    await tester.pumpWidget(_host(notes: '   '));

    expect(find.byIcon(Icons.expand_more_rounded), findsNothing);
    expect(find.byIcon(Icons.notes_rounded), findsNothing);
  });
}
