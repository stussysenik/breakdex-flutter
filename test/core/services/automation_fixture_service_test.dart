import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/services/automation_fixture_service.dart';

import '../../helpers/test_database.dart';

class _FakeLaunchArguments implements LaunchArgumentReader {
  _FakeLaunchArguments(this.values);

  final Map<String, Object?> values;

  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;

  @override
  Future<String?> getString(String key) async => values[key] as String?;
}

void main() {
  test('review fixture seeds reviewable content for maestro flows', () async {
    final db = createTestDatabase();
    addTearDown(db.close);

    final service = AutomationFixtureService(
      launchArguments: _FakeLaunchArguments({
        AutomationFixtureService.fixtureKey: 'review',
        AutomationFixtureService.maestroKey: true,
      }),
    );

    await service.seedIfRequested(db);

    final moves = await db.movesDao.getAll();
    final combos = await db.combosDao.getAll();
    final decks = await db.decksDao.getAll();
    final cards = await db.fsrsCardsDao.getAll();
    final reviewCount = await db.reviewsDao.countAll();

    expect(
      moves.map((move) => move.name),
      containsAll(['Fixture Swipe', 'Fixture Six-Step', 'Fixture Freeze']),
    );
    expect(combos.single.name, 'Fixture Combo');
    expect(decks.single.name, 'Fixture Deck');
    expect(cards, hasLength(4));
    expect(reviewCount, 3);
  });
}
