import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_launch_arguments/flutter_launch_arguments.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';
import '../models/learning_state.dart';

abstract class LaunchArgumentReader {
  Future<String?> getString(String key);
  Future<bool?> getBool(String key);
}

class FlutterLaunchArgumentReader implements LaunchArgumentReader {
  FlutterLaunchArgumentReader({FlutterLaunchArguments? launchArguments})
    : _launchArguments = launchArguments ?? FlutterLaunchArguments();

  final FlutterLaunchArguments _launchArguments;

  @override
  Future<String?> getString(String key) => _launchArguments.getString(key);

  @override
  Future<bool?> getBool(String key) => _launchArguments.getBool(key);
}

class AutomationFixtureService {
  AutomationFixtureService({LaunchArgumentReader? launchArguments})
    : _launchArguments = launchArguments ?? FlutterLaunchArgumentReader();

  static const fixtureKey = 'breakdexFixture';
  static const maestroKey = 'maestro';

  final LaunchArgumentReader _launchArguments;

  Future<void> seedIfRequested(
    AppDatabase db, {
    SharedPreferences? prefs,
  }) async {
    if (kReleaseMode) return;

    final fixture = await _launchArguments.getString(fixtureKey);
    final isMaestro = await _launchArguments.getBool(maestroKey) ?? false;

    if (fixture == null || fixture.isEmpty) {
      if (!isMaestro) return;
      return;
    }

    switch (fixture) {
      case 'review':
        await _seedReviewFixture(db);
        await prefs?.setString('review_mode', 'review');
        await prefs?.setString('review_session_source', 'stateBased');
      default:
        debugPrint('Ignoring unknown automation fixture: $fixture');
    }
  }

  Future<void> _seedReviewFixture(AppDatabase db) async {
    final now = DateTime.now().toUtc();

    await db.transaction(() async {
      await db.delete(db.reviews).go();
      await db.delete(db.comboMoves).go();
      await db.delete(db.deckMoves).go();
      await db.delete(db.decks).go();
      await db.delete(db.fsrsCards).go();
      await db.delete(db.combos).go();
      await db.delete(db.moves).go();
      await db.delete(db.battleResults).go();
      await db.delete(db.syncLog).go();

      await db.batch((batch) {
        batch.insertAll(db.moves, [
          MovesCompanion.insert(
            id: 'fixture-move-new',
            name: 'Fixture Swipe',
            learningState: Value(LearningState.newState.dbValue),
            category: const Value('toprock'),
            createdAt: Value(now.subtract(const Duration(days: 3))),
          ),
          MovesCompanion.insert(
            id: 'fixture-move-learning',
            name: 'Fixture Six-Step',
            learningState: Value(LearningState.learning.dbValue),
            category: const Value('footwork'),
            createdAt: Value(now.subtract(const Duration(days: 2))),
          ),
          MovesCompanion.insert(
            id: 'fixture-move-mastery',
            name: 'Fixture Freeze',
            learningState: Value(LearningState.mastery.dbValue),
            category: const Value('freeze'),
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
}
