import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(final Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('renders exactly two dots on one track', (final tester) async {
    await tester.pumpWidget(host(const AppLoader()));
    // Two crossing dots — no more, no fewer.
    expect(find.byType(Positioned), findsNWidgets(2));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('exposes the loading semantics label', (final tester) async {
    await tester.pumpWidget(host(const AppLoader(semanticLabel: 'Retrying')));
    expect(find.bySemanticsLabel('Retrying'), findsOneWidget);
  });

  testWidgets('animates without throwing and disposes cleanly',
      (final tester) async {
    await tester.pumpWidget(host(const AppLoader()));
    // Advance across a full cross-and-return; a leaked/undisposed controller
    // would fault when the element is torn down below.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpWidget(host(const SizedBox.shrink()));
    expect(tester.takeException(), isNull);
  });
}
