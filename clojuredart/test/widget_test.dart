// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cljd_clojuredart/main.dart';

void main() {
  testWidgets('Breakdex shell renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(app() as Widget);
    await tester.pumpAndSettle();

    expect(find.text('Breakdex'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Flow'), findsOneWidget);
  });
}
