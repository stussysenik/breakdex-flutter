import 'package:breakdex/dev/preview_harness.dart';
import 'package:breakdex/features/move_list/move_list_screen.dart';
import 'package:breakdex/features/move_list/widgets/library_date_line_format.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('preview harness renders a data-driven screen with seed data',
      (final tester) async {
    await tester.pumpWidget(wrapLight(MoveListScreen()));
    // Let the in-memory DB seed and the reactive streams emit.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    // The library's default view is ViewMode.glance — the visual-first grid,
    // which deliberately renders no move-name text. So asserting on 'Six Step'
    // was stale from the redesign, not a harness failure. Every grid cell does
    // render a LibraryDateLabel derived from the seeded rows, so that is the
    // data-driven signal: cells present means the seeded DB reached the widgets.
    expect(find.byType(LibraryDateLabel), findsWidgets);

    // Tear the screen down so its animation/coordinator timers are cancelled
    // (real app screens spawn timers; the preview tool tolerates them, the
    // test binding's leak check does not).
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
