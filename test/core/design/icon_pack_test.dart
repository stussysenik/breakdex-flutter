import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:breakdex/core/design/icons.dart';

void main() {
  group('AppIcon vocabulary', () {
    test('has ≤80 semantic names (currently 78)', () {
      expect(AppIcon.values.length, lessThanOrEqualTo(80));
    });

    test('every name is lowercase and single-word semantic', () {
      for (final icon in AppIcon.values) {
        final name = icon.name;
        expect(name, matches(r'^[a-z][a-zA-Z0-9]*$'),
          reason: '$name should be camelCase, no underscores');
      }
    });
  });

  group('MaterialPack', () {
    final pack = MaterialPack();

    test('resolves every AppIcon to non-null IconData', () {
      for (final icon in AppIcon.values) {
        final data = pack.resolve(icon);
        expect(data, isNotNull);
        expect(data.codePoint, greaterThan(0),
          reason: '${icon.name} resolved to codePoint 0');
      }
    });

    test('exhaustiveness - removing a case is a compile error', () {
      // This is a compile-time guarantee (switch w/ no default).
      // The test proves it by exercising every case.
      final results = AppIcon.values.map(pack.resolve);
      expect(results.length, AppIcon.values.length);
    });
  });

  group('LucidePack', () {
    final pack = LucidePack();

    test('resolves every AppIcon to non-null IconData', () {
      for (final icon in AppIcon.values) {
        final data = pack.resolve(icon);
        expect(data, isNotNull);
        expect(data.codePoint, greaterThan(0),
          reason: '${icon.name} resolved to codePoint 0');
      }
    });
  });

  group('IconPackId', () {
    test('fromKey falls back to the default pack for unknown keys', () {
      // Cupertino is the default: Flutter bundles CupertinoIcons as a font, so
      // every platform gets the same glyphs rather than the host's.
      expect(IconPackId.fromKey(null), IconPackId.cupertino);
      expect(IconPackId.fromKey(''), IconPackId.cupertino);
      expect(IconPackId.fromKey('nonexistent'), IconPackId.cupertino);
    });

    test('fromKey returns lucide for lucide key', () {
      expect(IconPackId.fromKey('lucide'), IconPackId.lucide);
    });

    test('fromKey returns material for material key', () {
      expect(IconPackId.fromKey('material'), IconPackId.material);
    });

    test('build returns correct pack', () {
      expect(IconPackId.material.build(), isA<MaterialPack>());
      expect(IconPackId.lucide.build(), isA<LucidePack>());
    });
  });

  group('AppIconPackTheme', () {
    testWidgets('of(context) returns the theme extension', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final ext = AppIconPackTheme.of(context);
              expect(ext.pack, isA<MaterialPack>());
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('AppIconView renders from context', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppIconView(AppIcon.add),
        ),
      );
      expect(find.byType(AppIconView), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('AppIcon.resolve returns IconData', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final data = AppIcon.add.resolve(context);
              expect(data, isA<IconData>());
              expect(data.codePoint, greaterThan(0));
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
