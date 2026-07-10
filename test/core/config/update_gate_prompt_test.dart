import 'package:breakdex/core/config/update_gate.dart';
import 'package:breakdex/core/config/update_gate_providers.dart';
import 'package:breakdex/core/config/widgets/update_gate_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(final UpdateGate gate) => ProviderScope(
  overrides: [updateGateProvider.overrideWithValue(gate)],
  child: const MaterialApp(
    home: UpdateGatePrompt(
      child: Scaffold(body: Center(child: Text('APP CONTENT'))),
    ),
  ),
);

void main() {
  testWidgets('none renders the child with no prompt chrome', (final tester) async {
    await tester.pumpWidget(_harness(const UpdateGateNone()));
    expect(find.text('APP CONTENT'), findsOneWidget);
    expect(find.text('Dismiss'), findsNothing);
    expect(find.byKey(UpdateGatePrompt.hardBlockBarrierKey), findsNothing);
  });

  testWidgets('soft nag shows the message over the app and is dismissible', (
    final tester,
  ) async {
    await tester.pumpWidget(
      _harness(const UpdateGateSoftNag(message: 'A new version is available.')),
    );
    expect(find.text('APP CONTENT'), findsOneWidget); // app still visible
    expect(find.text('A new version is available.'), findsOneWidget);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();

    expect(find.text('A new version is available.'), findsNothing);
    expect(find.text('APP CONTENT'), findsOneWidget);
  });

  testWidgets('hard block shows a blocking scrim with no dismiss affordance', (
    final tester,
  ) async {
    await tester.pumpWidget(
      _harness(const UpdateGateHardBlock(message: 'Please reinstall from the invite link.')),
    );
    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('Please reinstall from the invite link.'), findsOneWidget);
    // Blocking barrier present; nothing lets the user dismiss it.
    final barrier = tester.widget<ModalBarrier>(
      find.byKey(UpdateGatePrompt.hardBlockBarrierKey),
    );
    expect(barrier.dismissible, isFalse);
    expect(find.text('Dismiss'), findsNothing);
  });
}
