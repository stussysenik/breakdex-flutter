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
  TestWidgetsFlutterBinding.ensureInitialized();

  test('review fixture seeds reviewable content for maestro flows', () async {
    final db = createTestDatabase();
    addTearDown(db.close);

    final service = AutomationFixtureService(
      launchArguments: _FakeLaunchArguments({
        AutomationFixtureService.fixtureKey: 'review',
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

  test('stress fixture seeds aura links with all affinity types', () async {
    final db = createTestDatabase();
    addTearDown(db.close);

    final service = AutomationFixtureService(
      launchArguments: _FakeLaunchArguments({
        AutomationFixtureService.fixtureKey: 'stress',
      }),
    );

    await service.seedIfRequested(db);

    // Fetch all aura links via a raw select on the table.
    final allLinks =
        await db.select(db.auraLinks).get();

    // Should have at least 100 links total.
    expect(allLinks.length, greaterThanOrEqualTo(100));

    // All three affinity types must be present.
    final affinities = allLinks.map((l) => l.affinity).toSet();
    expect(affinities, containsAll(['natural', 'possible', 'stretch']));

    // No duplicate (fromMoveId, toMoveId) pairs — enforced by PK, but verify
    // the generator itself doesn't attempt duplicates.
    final pairSet = allLinks
        .map((l) => '${l.fromMoveId}|${l.toMoveId}')
        .toSet();
    expect(pairSet.length, allLinks.length);
  });
}
