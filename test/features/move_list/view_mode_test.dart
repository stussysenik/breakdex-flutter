import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/features/move_list/move_list_screen.dart';

void main() {
  test('view modes are declared in the fixed cycle order glance → scan → study', () {
    // The toggle presents ViewMode.values in order; this IS the cycle contract.
    expect(ViewMode.values, [ViewMode.glance, ViewMode.scan, ViewMode.study]);
  });

  group('persisted value resolution', () {
    test('legacy grid migrates to Glance and is flagged for re-persist', () {
      expect(viewModeFromStored('grid'), ViewMode.glance);
      expect(isLegacyViewModeValue('grid'), isTrue);
    });

    test('legacy list migrates to Scan and is flagged for re-persist', () {
      expect(viewModeFromStored('list'), ViewMode.scan);
      expect(isLegacyViewModeValue('list'), isTrue);
    });

    test('new names pass through and are never re-persisted', () {
      expect(viewModeFromStored('glance'), ViewMode.glance);
      expect(viewModeFromStored('scan'), ViewMode.scan);
      expect(viewModeFromStored('study'), ViewMode.study);
      for (final mode in ViewMode.values) {
        expect(isLegacyViewModeValue(mode.name), isFalse);
      }
    });

    test('unknown or absent values default to Glance', () {
      expect(viewModeFromStored(null), ViewMode.glance);
      expect(viewModeFromStored('bogus'), ViewMode.glance);
      expect(isLegacyViewModeValue(null), isFalse);
    });

    test('every mode round-trips through its persisted name (survives restart)', () {
      // set() persists `mode.name`; the next launch reads it back via
      // viewModeFromStored — proving persistence across restart at the logic level.
      for (final mode in ViewMode.values) {
        expect(viewModeFromStored(mode.name), mode);
      }
    });
  });
}
