import 'package:breakdex/shared/widgets/action_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('action tile preserves long labels without losing tap behavior', (
    final tester,
  ) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            child: ActionTile(
              icon: Icons.edit,
              label:
                  'Rename this move so the label is long enough to challenge the row layout',
              onTap: () => tapCount++,
            ),
          ),
        ),
      ),
    );

    final label = tester.widget<Text>(
      find.text(
        'Rename this move so the label is long enough to challenge the row layout',
      ),
    );
    expect(label.maxLines, 2);
    expect(label.overflow, TextOverflow.ellipsis);

    await tester.tap(find.byType(ActionTile));
    await tester.pump();

    expect(tapCount, 1);
  });
}
