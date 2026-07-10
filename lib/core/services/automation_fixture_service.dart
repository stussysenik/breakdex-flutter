import '../platform/io.dart';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_launch_arguments/flutter_launch_arguments.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';
import '../models/learning_state.dart';
import 'app_storage_paths.dart';

class _FixtureVideoSeed {
  const _FixtureVideoSeed({
    required this.assetPath,
    required this.fileName,
  });

  final String assetPath;
  final String fileName;

  String get relativePath => 'Moves/$fileName';
}

abstract class LaunchArgumentReader {
  Future<String?> getString(final String key);
  Future<bool?> getBool(final String key);
}

class FlutterLaunchArgumentReader implements LaunchArgumentReader {
  FlutterLaunchArgumentReader({final FlutterLaunchArguments? launchArguments})
    : _launchArguments = launchArguments ?? FlutterLaunchArguments();

  final FlutterLaunchArguments _launchArguments;

  @override
  Future<String?> getString(final String key) => _launchArguments.getString(key);

  @override
  Future<bool?> getBool(final String key) => _launchArguments.getBool(key);
}

class AutomationFixtureService {
  AutomationFixtureService({final LaunchArgumentReader? launchArguments})
    : _launchArguments = launchArguments ?? FlutterLaunchArgumentReader();

  static const fixtureKey = 'breakdexFixture';
  static const _reviewFixtureVideos = {
    'fixture-move-new': _FixtureVideoSeed(
      assetPath: 'assets/fixtures-blue-beat.mp4',
      fileName: 'fixture-swipe-blue-beat.mp4',
    ),
    'fixture-move-learning': _FixtureVideoSeed(
      assetPath: 'assets/fixtures-red-beat.mp4',
      fileName: 'fixture-six-step-red-beat.mp4',
    ),
    'fixture-move-mastery': _FixtureVideoSeed(
      assetPath: 'assets/fixtures-green-beat.mp4',
      fileName: 'fixture-freeze-green-beat.mp4',
    ),
  };

  final LaunchArgumentReader _launchArguments;

  Future<void> seedIfRequested(
    final AppDatabase db, {
    final SharedPreferences? prefs,
  }) async {
    if (kReleaseMode) return;

    final fixture = await _launchArguments.getString(fixtureKey);
    if (fixture == null || fixture.isEmpty) return;

    switch (fixture) {
      case 'review' || 'stress':
        fixture == 'review'
            ? await _seedReviewFixture(db)
            : await _seedStressFixture(db);
        await prefs?.setString('review_mode', 'review');
        await prefs?.setString('review_session_source', 'stateBased');
      case 'party':
        await _seedPartyFixture(db);
      default:
        debugPrint('Ignoring unknown automation fixture: $fixture');
    }
  }

  /// Delete all user data tables in dependency order.
  static Future<void> _clearAllTables(final AppDatabase db) async {
    await db.delete(db.reviews).go();
    await db.delete(db.comboMoves).go();
    await db.delete(db.deckMoves).go();
    await db.delete(db.decks).go();
    await db.delete(db.fsrsCards).go();
    await db.delete(db.auraLinks).go();
    await db.delete(db.auraPresets).go();
    await db.delete(db.combos).go();
    await db.delete(db.moves).go();
    await db.delete(db.battleResults).go();
    await db.delete(db.syncLog).go();
  }

  Future<Map<String, _FixtureVideoSeed>> _prepareReviewFixtureVideos() async {
    try {
      final docs = await AppStoragePaths.documentsDirectory();
      final movesDir = Directory(p.join(docs.path, 'Moves'));
      await movesDir.create(recursive: true);

      for (final entry in _reviewFixtureVideos.entries) {
        final data = await rootBundle.load(entry.value.assetPath);
        final bytes = data.buffer.asUint8List();
        final file = File(p.join(movesDir.path, entry.value.fileName));
        await file.writeAsBytes(bytes, flush: true);
      }

      return _reviewFixtureVideos;
    } on Object catch (error) {
      debugPrint(
        '[AutomationFixtureService] Skipping review fixture media seed: $error',
      );
      return const {};
    }
  }

  Future<void> _seedReviewFixture(final AppDatabase db) async {
    final now = DateTime.now().toUtc();
    final fixtureVideos = await _prepareReviewFixtureVideos();

    await db.transaction(() async {
      await _clearAllTables(db);

      await db.batch((final batch) {
        batch.insertAll(db.moves, [
          MovesCompanion.insert(
            id: 'fixture-move-new',
            name: 'Fixture Swipe',
            learningState: Value(LearningState.newState.dbValue),
            category: const Value('toprock'),
            videoPath: Value(fixtureVideos['fixture-move-new']?.relativePath),
            originalVideoName: Value(
              fixtureVideos['fixture-move-new']?.fileName,
            ),
            createdAt: Value(now.subtract(const Duration(days: 3))),
          ),
          MovesCompanion.insert(
            id: 'fixture-move-learning',
            name: 'Fixture Six-Step',
            learningState: Value(LearningState.learning.dbValue),
            category: const Value('footwork'),
            videoPath: Value(
              fixtureVideos['fixture-move-learning']?.relativePath,
            ),
            originalVideoName: Value(
              fixtureVideos['fixture-move-learning']?.fileName,
            ),
            createdAt: Value(now.subtract(const Duration(days: 2))),
          ),
          MovesCompanion.insert(
            id: 'fixture-move-mastery',
            name: 'Fixture Freeze',
            learningState: Value(LearningState.mastery.dbValue),
            category: const Value('freeze'),
            videoPath: Value(
              fixtureVideos['fixture-move-mastery']?.relativePath,
            ),
            originalVideoName: Value(
              fixtureVideos['fixture-move-mastery']?.fileName,
            ),
            createdAt: Value(now.subtract(const Duration(days: 1))),
          ),
        ]);

        batch.insert(
          db.combos,
          CombosCompanion.insert(id: 'fixture-combo-1', name: 'Fixture Combo'),
        );

        batch.insertAll(db.comboMoves, [
          ComboMovesCompanion.insert(
            id: 'fixture-combo-move-1',
            sequenceIndex: 0,
            comboId: 'fixture-combo-1',
            moveId: 'fixture-move-new',
          ),
          ComboMovesCompanion.insert(
            id: 'fixture-combo-move-2',
            sequenceIndex: 1,
            comboId: 'fixture-combo-1',
            moveId: 'fixture-move-learning',
          ),
        ]);

        batch.insert(
          db.decks,
          DecksCompanion.insert(
            id: 'fixture-deck-1',
            name: 'Fixture Deck',
            deckType: const Value('manual'),
            sessionSize: const Value(2),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        batch.insertAll(db.deckMoves, [
          DeckMovesCompanion.insert(
            deckId: 'fixture-deck-1',
            moveId: 'fixture-move-new',
          ),
          DeckMovesCompanion.insert(
            deckId: 'fixture-deck-1',
            moveId: 'fixture-move-learning',
          ),
        ]);

        batch.insertAll(db.fsrsCards, [
          FsrsCardsCompanion.insert(
            entityId: 'fixture-move-new',
            entityType: const Value('move'),
            stability: const Value(0),
            difficulty: const Value(0),
            due: Value(now.subtract(const Duration(minutes: 5))),
            reps: const Value(0),
            lapses: const Value(0),
            fsrsState: const Value(0),
          ),
          FsrsCardsCompanion.insert(
            entityId: 'fixture-move-learning',
            entityType: const Value('move'),
            stability: const Value(1.6),
            difficulty: const Value(4.2),
            due: Value(now.subtract(const Duration(minutes: 4))),
            lastReview: Value(now.subtract(const Duration(hours: 8))),
            reps: const Value(2),
            lapses: const Value(0),
            fsrsState: const Value(1),
          ),
          FsrsCardsCompanion.insert(
            entityId: 'fixture-move-mastery',
            entityType: const Value('move'),
            stability: const Value(8.4),
            difficulty: const Value(2.7),
            due: Value(now.subtract(const Duration(minutes: 3))),
            lastReview: Value(now.subtract(const Duration(days: 2))),
            reps: const Value(6),
            lapses: const Value(0),
            fsrsState: const Value(2),
          ),
          FsrsCardsCompanion.insert(
            entityId: 'fixture-combo-1',
            entityType: const Value('combo'),
            stability: const Value(1.2),
            difficulty: const Value(5.1),
            due: Value(now.subtract(const Duration(minutes: 2))),
            lastReview: Value(now.subtract(const Duration(hours: 12))),
            reps: const Value(1),
            lapses: const Value(0),
            fsrsState: const Value(1),
          ),
        ]);

        batch.insertAll(db.reviews, [
          ReviewsCompanion.insert(
            id: 'fixture-review-1',
            rating: ReviewRating.good.dbValue,
            reviewType: ReviewType.move.dbValue,
            reviewedAt: Value(now.subtract(const Duration(days: 2))),
            moveId: const Value('fixture-move-learning'),
            entityIdSnapshot: const Value('fixture-move-learning'),
            entityType: const Value('move'),
            entityDisplayName: const Value('Fixture Six-Step'),
            entityCategory: const Value('footwork'),
            fsrsPreState: const Value(0),
            fsrsPostState: const Value(1),
          ),
          ReviewsCompanion.insert(
            id: 'fixture-review-2',
            rating: ReviewRating.easy.dbValue,
            reviewType: ReviewType.move.dbValue,
            reviewedAt: Value(now.subtract(const Duration(days: 1))),
            moveId: const Value('fixture-move-mastery'),
            entityIdSnapshot: const Value('fixture-move-mastery'),
            entityType: const Value('move'),
            entityDisplayName: const Value('Fixture Freeze'),
            entityCategory: const Value('freeze'),
            fsrsPreState: const Value(1),
            fsrsPostState: const Value(2),
          ),
          ReviewsCompanion.insert(
            id: 'fixture-review-3',
            rating: ReviewRating.hard.dbValue,
            reviewType: ReviewType.combo.dbValue,
            reviewedAt: Value(now.subtract(const Duration(hours: 18))),
            comboId: const Value('fixture-combo-1'),
            entityIdSnapshot: const Value('fixture-combo-1'),
            entityType: const Value('combo'),
            entityDisplayName: const Value('Fixture Combo'),
            entityCategory: const Value('combo'),
            fsrsPreState: const Value(0),
            fsrsPostState: const Value(1),
          ),
        ]);
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Stress fixture: bulk data for Maestro chaos testing.
  //
  // Seeds 100 moves, 30 combos (2-8 steps each), 10 decks, 130 FSRS cards,
  // and 500 reviews. Uses a seeded RNG (seed=42) for deterministic output.
  // ---------------------------------------------------------------------------

  static const _categories = [
    'Power Moves',
    'Footwork',
    'Freezes',
    'Toprock',
    'default',
  ];

  static String _padIdx(final int i) => (i + 1).toString().padLeft(3, '0');
  static String _moveId(final int i) => 'stress-move-${_padIdx(i)}';

  static const _ratingWeights = [
    ReviewRating.good,  ReviewRating.good,  ReviewRating.good,  // 60%
    ReviewRating.good,  ReviewRating.good,  ReviewRating.good,
    ReviewRating.again, ReviewRating.again,                     // 20%
    ReviewRating.hard,                                          // 10%
    ReviewRating.easy,                                          // 10%
  ];

  Future<void> _seedStressFixture(final AppDatabase db) async {
    final now = DateTime.now().toUtc();
    final rng = Random(42);

    await db.transaction(() async {
      await _clearAllTables(db);

      final moves = _stressMoves(now, rng);
      final combos = _stressCombos(now);
      final comboMoves = _stressComboMoves(moves);
      final decks = _stressDecks(now);
      final deckMoves = _stressDeckMoves(moves);
      final fsrsCards = _stressFsrsCards(now, rng, moves.length, combos.length);
      final reviews = _stressReviews(now, rng, moves.length, combos.length);
      final auraLinks = _stressAuraLinks();

      await db.batch((final batch) {
        batch.insertAll(db.moves, moves);
        batch.insertAll(db.combos, combos);
        batch.insertAll(db.comboMoves, comboMoves);
        batch.insertAll(db.decks, decks);
        batch.insertAll(db.deckMoves, deckMoves);
        batch.insertAll(db.fsrsCards, fsrsCards);
        batch.insertAll(db.reviews, reviews);
        batch.insertAll(db.auraLinks, auraLinks);
      });
    });
  }

  /// 100 moves: 40 new (0-39), 35 learning (40-74), 25 mastery (75-99).
  static List<MovesCompanion> _stressMoves(final DateTime now, final Random rng) {
    LearningState stateFor(final int i) {
      if (i < 40) return LearningState.newState;
      if (i < 75) return LearningState.learning;
      return LearningState.mastery;
    }

    return List.generate(100, (final i) => MovesCompanion.insert(
          id: _moveId(i),
          name: 'Stress Move ${_padIdx(i)}',
          learningState: Value(stateFor(i).dbValue),
          category: Value(_categories[i % _categories.length]),
          createdAt: Value(now.subtract(Duration(days: 90 - i))),
        ));
  }

  /// 30 combos.
  static List<CombosCompanion> _stressCombos(final DateTime now) =>
      List.generate(30, (final i) => CombosCompanion.insert(
            id: 'stress-combo-${i + 1}',
            name: 'Stress Combo ${i + 1}',
          ));

  /// 2-8 steps per combo, drawn from the first 100 moves.
  static List<ComboMovesCompanion> _stressComboMoves(
      final List<MovesCompanion> moves) {
    final result = <ComboMovesCompanion>[];
    for (var c = 0; c < 30; c++) {
      final stepCount = c % 7 + 2; // 2–8
      for (var s = 0; s < stepCount; s++) {
        final moveIdx = (c * 7 + s) % moves.length;
        result.add(ComboMovesCompanion.insert(
          id: 'stress-cm-${c + 1}-$s',
          sequenceIndex: s,
          comboId: 'stress-combo-${c + 1}',
          moveId: _moveId(moveIdx),
        ));
      }
    }
    return result;
  }

  /// 10 decks.
  static List<DecksCompanion> _stressDecks(final DateTime now) =>
      List.generate(10, (final i) => DecksCompanion.insert(
            id: 'stress-deck-${i + 1}',
            name: 'Stress Deck ${i + 1}',
            deckType: const Value('manual'),
            sessionSize: Value(5 + i),
            createdAt: Value(now),
            updatedAt: Value(now),
          ));

  /// 5-15 moves per deck, capped at 15.
  static List<DeckMovesCompanion> _stressDeckMoves(
      final List<MovesCompanion> moves) {
    final result = <DeckMovesCompanion>[];
    for (var d = 0; d < 10; d++) {
      final count = (5 + d * 2).clamp(5, 15);
      for (var m = 0; m < count; m++) {
        final moveIdx = (d * 10 + m) % moves.length;
        result.add(DeckMovesCompanion.insert(
          deckId: 'stress-deck-${d + 1}',
          moveId: _moveId(moveIdx),
        ));
      }
    }
    return result;
  }

  /// FSRS card for every move (100) and every combo (30) = 130 cards.
  static List<FsrsCardsCompanion> _stressFsrsCards(
      final DateTime now, final Random rng, final int moveCount, final int comboCount) {
    final cards = <FsrsCardsCompanion>[];

    for (var i = 0; i < moveCount; i++) {
      final (state, stab, diff, reps, lapses, dueOff, lastOff) =
          _fsrsParams(i, rng);
      cards.add(FsrsCardsCompanion.insert(
        entityId: _moveId(i),
        entityType: const Value('move'),
        fsrsState: Value(state),
        stability: Value(stab),
        difficulty: Value(diff),
        reps: Value(reps),
        lapses: Value(lapses),
        due: Value(now.subtract(dueOff)),
        lastReview: lastOff != null ? Value(now.subtract(lastOff)) : const Value.absent(),
      ));
    }

    for (var i = 0; i < comboCount; i++) {
      // Reuse learning-bucket params (index 40-74 range maps to fsrsState=1).
      final (state, stab, diff, reps, lapses, dueOff, lastOff) =
          _fsrsParams(40 + (i % 35), rng);
      cards.add(FsrsCardsCompanion.insert(
        entityId: 'stress-combo-${i + 1}',
        entityType: const Value('combo'),
        fsrsState: Value(state),
        stability: Value(stab),
        difficulty: Value(diff),
        reps: Value(reps),
        lapses: Value(lapses),
        due: Value(now.subtract(dueOff)),
        lastReview: lastOff != null ? Value(now.subtract(lastOff)) : const Value.absent(),
      ));
    }

    return cards;
  }

  /// Returns (fsrsState, stability, difficulty, reps, lapses, dueOffset,
  /// lastReviewOffset?) tuned to the move's state bucket (0-39 new, 40-74
  /// learning, 75-99 mastery).
  static (int, double, double, int, int, Duration, Duration?) _fsrsParams(
      final int i, final Random rng) {
    if (i < 40) {
      return (0, 0.0, 0.0, 0, 0, Duration(minutes: 1 + rng.nextInt(10)), null);
    }
    if (i < 75) {
      return (
        1,
        0.5 + rng.nextDouble() * 4.5,
        2.0 + rng.nextDouble() * 5.0,
        1 + rng.nextInt(4),
        rng.nextInt(2),
        Duration(minutes: 1 + rng.nextInt(60)),
        Duration(hours: 4 + rng.nextInt(44)),
      );
    }
    return (
      2,
      5.0 + rng.nextDouble() * 25.0,
      1.0 + rng.nextDouble() * 3.0,
      5 + rng.nextInt(11),
      rng.nextInt(3),
      Duration(hours: 1 + rng.nextInt(168)),
      Duration(days: 1 + rng.nextInt(14)),
    );
  }

  /// 500 reviews spread over 90 days: 400 move reviews, 100 combo reviews.
  static List<ReviewsCompanion> _stressReviews(
      final DateTime now, final Random rng, final int moveCount, final int comboCount) {
    final reviews = <ReviewsCompanion>[];

    for (var i = 0; i < 400; i++) {
      final moveIdx = i % moveCount;
      final rating = _ratingWeights[rng.nextInt(_ratingWeights.length)];
      final daysAgo = rng.nextInt(90);
      reviews.add(ReviewsCompanion.insert(
        id: 'stress-review-m-$i',
        rating: rating.dbValue,
        reviewType: ReviewType.move.dbValue,
        reviewedAt: Value(now.subtract(Duration(days: daysAgo, hours: rng.nextInt(24)))),
        moveId: Value(_moveId(moveIdx)),
        entityIdSnapshot: Value(_moveId(moveIdx)),
        entityType: const Value('move'),
        entityDisplayName: Value('Stress Move ${_padIdx(moveIdx)}'),
        entityCategory: Value(_categories[moveIdx % _categories.length]),
        fsrsPreState: Value(rng.nextInt(3)),
        fsrsPostState: Value(rng.nextInt(3)),
      ));
    }

    for (var i = 0; i < 100; i++) {
      final comboIdx = i % comboCount;
      final rating = _ratingWeights[rng.nextInt(_ratingWeights.length)];
      final daysAgo = rng.nextInt(90);
      reviews.add(ReviewsCompanion.insert(
        id: 'stress-review-c-$i',
        rating: rating.dbValue,
        reviewType: ReviewType.combo.dbValue,
        reviewedAt: Value(now.subtract(Duration(days: daysAgo, hours: rng.nextInt(24)))),
        comboId: Value('stress-combo-${comboIdx + 1}'),
        entityIdSnapshot: Value('stress-combo-${comboIdx + 1}'),
        entityType: const Value('combo'),
        entityDisplayName: Value('Stress Combo ${comboIdx + 1}'),
        entityCategory: const Value('combo'),
        fsrsPreState: Value(rng.nextInt(3)),
        fsrsPostState: Value(rng.nextInt(3)),
      ));
    }

    return reviews;
  }

  // ---------------------------------------------------------------------------
  // Aura links: ~120 deterministic move-to-move transition edges.
  //
  // Three affinity tiers:
  //   natural  – intra-category chains (consecutive + skip connections)
  //   possible – cross-category bridges between logically related styles
  //   stretch  – long-range weak ties across distant categories
  //
  // Move indices cycle through _categories[i % 5]:
  //   0 → Power Moves, 1 → Footwork, 2 → Freezes, 3 → Toprock, 4 → default
  // So Power Moves = {0,5,10,15,...,95}, Footwork = {1,6,11,...,96}, etc.
  // ---------------------------------------------------------------------------

  /// Generate ~120 deterministic aura links spanning all three affinity types.
  static List<AuraLinksCompanion> _stressAuraLinks() {
    final links = <AuraLinksCompanion>[];
    final seen = <(String, String)>{};

    void add(final int from, final int to, final String affinity) {
      final key = (_moveId(from), _moveId(to));
      if (seen.contains(key)) return;
      seen.add(key);
      links.add(AuraLinksCompanion.insert(
        fromMoveId: _moveId(from),
        toMoveId: _moveId(to),
        affinity: affinity,
      ));
    }

    // -- Natural links (~60): intra-category chains ---------------------------
    // For each of 5 categories, connect consecutive same-category members plus
    // skip connections (stride of 10 in the global index = 2 positions within
    // the category).
    for (var cat = 0; cat < 5; cat++) {
      final members = [for (var i = cat; i < 100; i += 5) i]; // 20 per cat

      // Consecutive chains: members[j] → members[j+1]
      for (var j = 0; j < members.length - 1; j++) {
        add(members[j], members[j + 1], 'natural');
      }

      // Skip connections: members[j] → members[j+2]
      for (var j = 0; j < members.length - 2; j++) {
        add(members[j], members[j + 2], 'natural');
      }
    }

    // -- Possible links (~40): cross-category bridges -------------------------
    // Toprock → Footwork
    for (var k = 0; k < 10; k++) {
      add(3 + k * 5, 1 + k * 5, 'possible');
    }
    // Footwork → Power Moves
    for (var k = 0; k < 10; k++) {
      add(1 + k * 5, 0 + k * 5, 'possible');
    }
    // Power Moves → Freezes
    for (var k = 0; k < 10; k++) {
      add(0 + k * 5, 2 + k * 5, 'possible');
    }
    // Freezes → Toprock
    for (var k = 0; k < 10; k++) {
      add(2 + k * 5, 3 + k * 5, 'possible');
    }

    // -- Stretch links (~20): long-range weak ties ----------------------------
    // Power → default
    for (var k = 0; k < 5; k++) {
      add(k * 10, k * 10 + 4, 'stretch');
    }
    // Footwork → Freezes
    for (var k = 0; k < 5; k++) {
      add(1 + k * 10, 2 + k * 10, 'stretch');
    }
    // Toprock → default
    for (var k = 0; k < 5; k++) {
      add(3 + k * 10, 4 + k * 10, 'stretch');
    }
    // default → Power
    for (var k = 0; k < 5; k++) {
      add(4 + k * 10, 5 + k * 10, 'stretch');
    }

    return links;
  }

  /// Party fixture: 10 moves across categories for shake-to-discover testing.
  static Future<void> _seedPartyFixture(final AppDatabase db) async {
    final now = DateTime.now().toUtc();

    await db.transaction(() async {
      await _clearAllTables(db);

      await db.batch((final batch) {
        batch.insertAll(db.moves, [
          MovesCompanion.insert(
            id: 'party-move-01',
            name: 'Windmill',
            learningState: Value(LearningState.newState.dbValue),
            category: const Value('power'),
            createdAt: Value(now),
          ),
          MovesCompanion.insert(
            id: 'party-move-02',
            name: 'Headspin',
            learningState: Value(LearningState.learning.dbValue),
            category: const Value('power'),
            createdAt: Value(now),
          ),
          MovesCompanion.insert(
            id: 'party-move-03',
            name: 'Flare',
            learningState: Value(LearningState.mastery.dbValue),
            category: const Value('power'),
            createdAt: Value(now),
          ),
          MovesCompanion.insert(
            id: 'party-move-04',
            name: 'Six Step',
            learningState: Value(LearningState.newState.dbValue),
            category: const Value('footwork'),
            createdAt: Value(now),
          ),
          MovesCompanion.insert(
            id: 'party-move-05',
            name: 'CCs',
            learningState: Value(LearningState.learning.dbValue),
            category: const Value('footwork'),
            createdAt: Value(now),
          ),
          MovesCompanion.insert(
            id: 'party-move-06',
            name: 'Baby Freeze',
            learningState: Value(LearningState.mastery.dbValue),
            category: const Value('freeze'),
            createdAt: Value(now),
          ),
          MovesCompanion.insert(
            id: 'party-move-07',
            name: 'Air Chair',
            learningState: Value(LearningState.learning.dbValue),
            category: const Value('freeze'),
            createdAt: Value(now),
          ),
          MovesCompanion.insert(
            id: 'party-move-08',
            name: 'Indian Step',
            learningState: Value(LearningState.newState.dbValue),
            category: const Value('toprock'),
            createdAt: Value(now),
          ),
          MovesCompanion.insert(
            id: 'party-move-09',
            name: 'Salsa Rock',
            learningState: Value(LearningState.learning.dbValue),
            category: const Value('toprock'),
            createdAt: Value(now),
          ),
          MovesCompanion.insert(
            id: 'party-move-10',
            name: 'Elbow Airflare',
            learningState: Value(LearningState.mastery.dbValue),
            category: const Value('power'),
            createdAt: Value(now),
          ),
        ]);
      });
    });
  }
}
