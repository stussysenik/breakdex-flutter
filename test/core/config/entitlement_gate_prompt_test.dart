import 'package:breakdex/core/config/entitlement.dart';
import 'package:breakdex/core/config/entitlement_providers.dart';
import 'package:breakdex/core/config/widgets/entitlement_gate_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(final EntitlementGate gate) => ProviderScope(
      overrides: [entitlementGateProvider.overrideWithValue(gate)],
      child: const MaterialApp(
        home: EntitlementGatePrompt(
          child: Scaffold(body: Center(child: Text('APP CONTENT'))),
        ),
      ),
    );

void main() {
  testWidgets('granted renders the child with no gate chrome', (
    final tester,
  ) async {
    await tester.pumpWidget(_harness(const EntitlementGranted()));
    expect(find.text('APP CONTENT'), findsOneWidget);
    expect(find.byKey(EntitlementGatePrompt.barrierKey), findsNothing);
    expect(find.text('Enter your invite code'), findsNothing);
  });

  testWidgets('required shows a blocking invite entry over the app', (
    final tester,
  ) async {
    await tester.pumpWidget(_harness(const EntitlementRequired()));
    expect(find.text('Enter your invite code'), findsOneWidget);
    expect(find.text('Redeem'), findsOneWidget);
    final barrier = tester.widget<ModalBarrier>(
      find.byKey(EntitlementGatePrompt.barrierKey),
    );
    expect(barrier.dismissible, isFalse); // no way past the gate but redeeming
  });
}
