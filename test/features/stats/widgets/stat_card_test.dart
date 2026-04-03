import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/features/stats/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('stat card presents the subject label above the value', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: StatCard(label: 'Recall Quality', value: '87%'),
        ),
      ),
    );

    final labelTop = tester.getTopLeft(find.text('Recall Quality')).dy;
    final valueTop = tester.getTopLeft(find.text('87%')).dy;

    expect(labelTop, lessThan(valueTop));
  });
}
