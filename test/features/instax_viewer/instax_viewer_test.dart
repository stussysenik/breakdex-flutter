import 'package:breakdex/core/design/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:breakdex/features/instax_viewer/instax_viewer_screen.dart';

void main() {
  group('InstaxMode', () {
    test('has three modes', () {
      expect(InstaxMode.values.length, 3);
    });

    test('next cycles through modes', () {
      expect(InstaxMode.carousel.next, InstaxMode.feed);
      expect(InstaxMode.feed.next, InstaxMode.tinder);
      expect(InstaxMode.tinder.next, InstaxMode.carousel);
    });

    test('label returns display text', () {
      expect(InstaxMode.carousel.label, 'Carousel');
      expect(InstaxMode.feed.label, 'Feed');
      expect(InstaxMode.tinder.label, 'Tinder');
    });

    test('icon maps to correct icon', () {
      expect(InstaxMode.carousel.icon, AppIcon.shuffle);
      expect(InstaxMode.feed.icon, AppIcon.glance);
      expect(InstaxMode.tinder.icon, AppIcon.study);
    });
  });

  group('InstaxVideoViewer', () {
    testWidgets('shows empty state with no moves', (final tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: InstaxVideoViewer(moves: [], category: 'Power'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('No moves yet'), findsOneWidget);
      expect(find.text('Tap + to add your first Power move'), findsOneWidget);
    });
  });
}
