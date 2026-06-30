import 'package:breakdex/dev/preview_harness.dart';
import 'package:breakdex/features/move_list/move_list_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('preview harness renders a data-driven screen with seed data',
      (final tester) async {
    await tester.pumpWidget(PreviewHarness.wrapLight(MoveListScreen()));
    // Let the in-memory DB seed and the reactive streams emit.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    // A seeded move name should appear once the stream resolves.
    expect(find.textContaining('Six Step'), findsWidgets);

    // Tear the screen down so its animation/coordinator timers are cancelled
    // (real app screens spawn timers; the preview tool tolerates them, the
    // test binding's leak check does not).
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
