import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/dev/basis_controls.dart';

/// 5.3's claim is one sentence: moving a control changes the basis every widget
/// below it lays out against. Each test drives a real `Slider` gesture and reads
/// the answer back through `AppLayout.of(context)` — the same call a screen
/// makes — so nothing here passes on the provider alone.
void main() {
  late AppLayoutTheme observed;

  Future<void> pumpControls(final WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: DevBasisScope(
              child: Builder(
                builder: (final context) {
                  observed = AppLayout.of(context);
                  return const SingleChildScrollView(child: DevBasisControls());
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Drags [key]'s thumb clear past the track end, so the value lands on the
  /// bound rather than on an offset the test would have to compute.
  Future<void> dragToEnd(
    final WidgetTester tester,
    final Key key, {
    required final bool toMax,
  }) async {
    await tester.drag(find.byKey(key), Offset(toMax ? 800 : -800, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('each slider moves its own field and leaves the rest', (
    final tester,
  ) async {
    for (final field in basisFields) {
      await pumpControls(tester);
      final before = observed;

      await dragToEnd(tester, field.sliderKey, toMax: true);

      expect(
        field.read(observed),
        field.max,
        reason: '${field.name} did not reach its bound',
      );
      for (final other in basisFields.where((final f) => f.name != field.name)) {
        expect(
          other.read(observed),
          other.read(before),
          reason: '${field.name} moved ${other.name} with it',
        );
      }
    }
  });

  testWidgets('sliders start on the shipped constants', (final tester) async {
    await pumpControls(tester);

    expect(observed, const AppLayoutTheme());
  });

  testWidgets('reset restores the shipped basis', (final tester) async {
    await pumpControls(tester);
    await dragToEnd(tester, basisFields.first.sliderKey, toMax: true);
    expect(observed, isNot(const AppLayoutTheme()));

    await tester.tap(find.byKey(DevBasisControls.resetKey));
    await tester.pumpAndSettle();

    expect(observed, const AppLayoutTheme());
  });

  testWidgets('the scope wins over the theme without losing its extensions', (
    final tester,
  ) async {
    late ThemeData themed;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          previewBasisProvider.overrideWith(
            (final _) => const AppLayoutTheme(gutter: 99),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: DevBasisScope(
            child: Builder(
              builder: (final context) {
                themed = Theme.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    // A basis override must not cost the colour packs or the semantic signals:
    // every extension the app theme carries survives, plus the one we add.
    expect(
      themed.extensions.keys.toSet(),
      containsAll(AppTheme.light().extensions.keys),
    );
    // `AppTheme` already registers the default basis, so the scope's job is to
    // *replace* it, not to add one. Non-null would have proved nothing.
    expect(themed.extension<AppLayoutTheme>()?.gutter, 99);
  });
}
