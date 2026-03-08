import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/stats/providers/stats_providers.dart';

import '../../helpers/test_data.dart';
import '../../helpers/test_database.dart';

void main() {
  group('stats providers', () {
    late AppDatabase db;
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      db = createTestDatabase();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('deleted cards remain visible in day detail via immutable snapshots', () async {
      final reviewTime = DateTime(2026, 3, 8, 11, 45);

      await seedMove(db, id: 'move-1', name: 'Windmill', category: 'power');
      await seedReview(
        db,
        id: 'review-1',
        moveId: 'move-1',
        reviewedAt: reviewTime,
        entityIdSnapshot: 'move-1',
        entityType: 'move',
        entityDisplayName: 'Windmill',
        entityCategory: 'power',
      );

      await db.movesDao.deleteMove('move-1');

      final reviews = await db.reviewsDao.getAllOrdered();
      expect(reviews.single.entityIdSnapshot, 'move-1');
      expect(reviews.single.entityDisplayName, 'Windmill');

      final detail = await container.read(
        dayDetailProvider(DateTime(2026, 3, 8)).future,
      );
      expect(detail, hasLength(1));
      expect(detail.single.moveName, 'Windmill');
      expect(detail.single.isDeleted, isTrue);
    });
  });
}
