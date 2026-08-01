import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/design/color_packs.dart';
import 'package:breakdex/core/design/color_roles.dart';
import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/dev/primitives_catalogue.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/shared/widgets/app_row.dart';

/// The catalogue's promise is completeness: everything the vocabulary can say
/// is rendered once. A name added to `AppIcon`, a role added to
/// `AppColorRole`, or a pack added to either enum lands here or fails.
void main() {
  Future<void> pumpCatalogue(final WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(child: DevPrimitivesCatalogue()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders every icon name in every pack', (final tester) async {
    await pumpCatalogue(tester);

    for (final icon in AppIcon.values) {
      for (final pack in IconPackId.values) {
        expect(
          find.byKey(DevPrimitivesCatalogue.iconCellKey(icon, pack)),
          findsOneWidget,
          reason: '${icon.name} missing from the ${pack.key} column',
        );
      }
    }
  });

  testWidgets('every pack resolves each name to its own glyph', (
    final tester,
  ) async {
    await pumpCatalogue(tester);

    // Not just present — actually resolved through the pack in force for that
    // column. A table that rendered three copies of the default pack would
    // satisfy the count above and prove nothing.
    for (final pack in IconPackId.values) {
      final widget = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(
            DevPrimitivesCatalogue.iconCellKey(AppIcon.library, pack),
          ),
          matching: find.byType(Icon),
        ),
      );
      expect(widget.icon, pack.build().resolve(AppIcon.library));
    }
  });

  testWidgets('renders every colour role from every pack', (
    final tester,
  ) async {
    await pumpCatalogue(tester);

    for (final role in AppColorRole.values) {
      for (final pack in ColorPackId.values) {
        expect(
          find.byKey(DevPrimitivesCatalogue.roleSwatchKey(role, pack)),
          findsOneWidget,
          reason: '${role.name} missing from the ${pack.key} column',
        );
      }
    }
  });

  testWidgets('renders the row atom in each of its states', (
    final tester,
  ) async {
    await pumpCatalogue(tester);

    for (final key in const [
      'row-readout',
      'row-value',
      'row-tappable',
      'row-leading',
      'row-switch',
      'row-disabled',
      'row-choice-list',
    ]) {
      expect(find.byKey(ValueKey<String>(key)), findsOneWidget, reason: key);
    }
  });

  testWidgets('both motion families are present and replayable', (
    final tester,
  ) async {
    await pumpCatalogue(tester);

    expect(find.byKey(const ValueKey('motion-fluid')), findsOneWidget);
    final morph = find.byKey(const ValueKey('motion-morph'));

    // The catalogue is taller than any test viewport, so the replay row is laid
    // out but off screen — a tap without this scrolls nothing and hits nothing.
    final replay = find.byKey(const ValueKey('motion-replay'));
    await tester.ensureVisible(replay);
    await tester.pumpAndSettle();
    final before = tester.getSize(morph);

    await tester.tap(replay);
    await tester.pumpAndSettle();

    expect(tester.getSize(morph), isNot(before));
  });

  testWidgets('the frame sample is a real AppScreen', (final tester) async {
    await pumpCatalogue(tester);

    expect(find.widgetWithText(AppRow, 'A row is one line of type'), findsOne);
  });
}
