import 'package:breakdex/core/utils/share_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sharePositionOrigin returns the source widget bounds', (
    final tester,
  ) async {
    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox(key: key, width: 120, height: 48)),
        ),
      ),
    );

    final context = tester.element(find.byKey(key));
    final origin = sharePositionOrigin(context);

    expect(origin.width, 120);
    expect(origin.height, 48);
    expect(origin.left, isNonNegative);
    expect(origin.top, isNonNegative);
  });
}
