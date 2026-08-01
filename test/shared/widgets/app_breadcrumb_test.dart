import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/shared/widgets/app_breadcrumb.dart';

void main() {
  group('breadcrumbsFor', () {
    test('builds one crumb per segment, each addressing its own prefix', () {
      expect(breadcrumbsFor('/breakdex/moves'), [
        const AppCrumb(label: 'breakdex', location: '/breakdex'),
        const AppCrumb(label: 'moves', location: '/breakdex/moves'),
      ]);
    });

    test('root has no crumbs', () {
      expect(breadcrumbsFor('/'), isEmpty);
    });

    test('drops query and fragment — a crumb addresses a page, not a state', () {
      expect(
        breadcrumbsFor('/breakdex/combos?sort=recent#top').last.location,
        '/breakdex/combos',
      );
    });
  });

  group('crumbLabel', () {
    test('slugifies a decoded segment', () {
      expect(crumbLabel('Power%20Moves'), 'power-moves');
      expect(crumbLabel('Go_Downs'), 'go-downs');
    });

    test('elides an opaque id rather than printing it whole', () {
      final label = crumbLabel('3f8c1d2e-9b4a-4c77-8e21-5a6b7c8d9e0f');
      expect(label.length, lessThan(16));
      expect(label, contains('…'));
      expect(label.startsWith('3f8c1d'), isTrue);
    });

    test('leaves a short readable segment alone', () {
      expect(crumbLabel('settings'), 'settings');
    });
  });
}
