import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('review fill color provider', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    });

    tearDown(() => container.dispose());

    test('defaults to null (no custom fill) when unset', () {
      expect(container.read(reviewFillColorProvider), isNull);
    });

    test('persists an arbitrary ARGB fill and survives a restart', () async {
      const color = Color(0xCCEE3355);
      await container.read(reviewFillColorProvider.notifier).set(color);

      expect(container.read(reviewFillColorProvider), color);
      expect(prefs.getInt('review_fill_color'), color.toARGB32());

      // A fresh container reading the same prefs = the restart case.
      final restarted = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restarted.dispose);
      expect(restarted.read(reviewFillColorProvider), color);
    });

    test('reset clears the stored value back to default', () async {
      await container
          .read(reviewFillColorProvider.notifier)
          .set(const Color(0xFF12303A));
      await container.read(reviewFillColorProvider.notifier).reset();

      expect(container.read(reviewFillColorProvider), isNull);
      expect(prefs.getInt('review_fill_color'), isNull);
    });
  });
}
