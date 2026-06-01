import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:breakdex/core/app_metadata.dart';
import 'package:breakdex/core/database/database.dart';

/// Factory functions for generating test data — both JSON export format
/// and direct DB insertions. Keeps test files focused on assertions.

// ---------------------------------------------------------------------------
// JSON builders — produce maps matching the current export schema.
// ---------------------------------------------------------------------------

/// Builds a valid export JSON string from optional entity lists.
String makeExportJson({
  final int schemaVersion = AppMetadata.exportSchemaVersion,
  final List<Map<String, dynamic>>? moves,
  final List<Map<String, dynamic>>? reviews,
  final List<Map<String, dynamic>>? combos,
  final List<Map<String, dynamic>>? comboMoves,
  final List<Map<String, dynamic>>? battleResults,
  final List<Map<String, dynamic>>? fsrsCards,
  final List<Map<String, dynamic>>? decks,
  final List<Map<String, dynamic>>? deckMoves,
  final List<Map<String, dynamic>>? categories,
}) {
  return jsonEncode({
    'schemaVersion': schemaVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'appVersion': AppMetadata.releaseVersion,
    'moves': ?moves,
    'reviews': ?reviews,
    'combos': ?combos,
    'comboMoves': ?comboMoves,
    'battleResults': ?battleResults,
    'fsrsCards': ?fsrsCards,
    'decks': ?decks,
    'deckMoves': ?deckMoves,
    'categories': ?categories,
  });
}

/// A single move in export JSON format.
Map<String, dynamic> makeJsonMove({
  final String id = 'move-1',
  final String name = 'Windmill',
  final String category = 'power',
  final String learningState = 'NEW',
  final String? videoFilename,
  final String? originalVideoName,
  final DateTime? createdAt,
}) {
  return {
    'id': id,
    'name': name,
    'category': category,
    'learningState': learningState,
    'videoFilename': ?videoFilename,
    'originalVideoName': ?originalVideoName,
    'createdAt': (createdAt ?? DateTime(2024, 1, 15)).toIso8601String(),
  };
}

/// A single review in export JSON format.
Map<String, dynamic> makeJsonReview({
  final String id = 'review-1',
  final String rating = 'GOOD',
  final String reviewType = 'STANDARD',
  final String? moveId = 'move-1',
  final String? comboId,
  final String? entityIdSnapshot,
  final String? entityType,
  final String? entityDisplayName,
  final String? entityCategory,
  final DateTime? reviewedAt,
  final int? fsrsPreState,
  final int? fsrsPostState,
}) {
  return {
    'id': id,
    'rating': rating,
    'reviewType': reviewType,
    'moveId': moveId,
    'comboId': comboId,
    'entityIdSnapshot': ?entityIdSnapshot,
    'entityType': ?entityType,
    'entityName': ?entityDisplayName,
    'entityCategory': ?entityCategory,
    'reviewedAt': (reviewedAt ?? DateTime(2024, 1, 16)).toIso8601String(),
    'fsrsPreState': ?fsrsPreState,
    'fsrsPostState': ?fsrsPostState,
  };
}

/// A single combo in export JSON format.
Map<String, dynamic> makeJsonCombo({
  final String id = 'combo-1',
  final String name = 'Power Combo',
  final String? activeVideoFilename,
}) {
  return {'id': id, 'name': name, 'activeVideoFilename': ?activeVideoFilename};
}

/// A single comboMove in export JSON format.
Map<String, dynamic> makeJsonComboMove({
  final String id = 'cm-1',
  final int sequenceIndex = 0,
  final String comboId = 'combo-1',
  final String moveId = 'move-1',
}) {
  return {
    'id': id,
    'sequenceIndex': sequenceIndex,
    'comboId': comboId,
    'moveId': moveId,
  };
}

/// A single battle result in export JSON format.
Map<String, dynamic> makeJsonBattleResult({
  final String id = 'battle-1',
  final int score = 100,
  final int movesReviewed = 10,
  final int goodCount = 5,
  final int hardCount = 3,
  final int againCount = 2,
  final int longestStreak = 3,
  final String difficulty = 'MEDIUM',
  final DateTime? playedAt,
}) {
  return {
    'id': id,
    'score': score,
    'movesReviewed': movesReviewed,
    'goodCount': goodCount,
    'hardCount': hardCount,
    'againCount': againCount,
    'longestStreak': longestStreak,
    'difficulty': difficulty,
    'playedAt': (playedAt ?? DateTime(2024, 1, 17)).toIso8601String(),
  };
}

/// A single FSRS card in export JSON format (v6 polymorphic).
Map<String, dynamic> makeJsonFsrsCard({
  final String entityId = 'move-1',
  final String entityType = 'move',
  final double stability = 4.5,
  final double difficulty = 5.2,
  final DateTime? due,
  final DateTime? lastReview,
  final int reps = 3,
  final int lapses = 0,
  final int fsrsState = 2,
}) {
  return {
    'entityId': entityId,
    'entityType': entityType,
    'stability': stability,
    'difficulty': difficulty,
    'due': (due ?? DateTime(2024, 2, 1)).toIso8601String(),
    if (lastReview != null) 'lastReview': lastReview.toIso8601String(),
    'reps': reps,
    'lapses': lapses,
    'fsrsState': fsrsState,
  };
}

/// A single deck in export JSON format.
Map<String, dynamic> makeJsonDeck({
  final String id = 'deck-1',
  final String name = 'Power Moves',
  final String deckType = 'manual',
  final String? filterCriteria,
  final int? sessionSize,
  final DateTime? createdAt,
  final DateTime? updatedAt,
}) {
  return {
    'id': id,
    'name': name,
    'deckType': deckType,
    'filterCriteria': ?filterCriteria,
    'sessionSize': ?sessionSize,
    'createdAt': (createdAt ?? DateTime(2024, 1, 10)).toIso8601String(),
    'updatedAt': (updatedAt ?? DateTime(2024, 1, 10)).toIso8601String(),
  };
}

/// A single deckMove in export JSON format.
Map<String, dynamic> makeJsonDeckMove({
  final String deckId = 'deck-1',
  final String moveId = 'move-1',
}) {
  return {'deckId': deckId, 'moveId': moveId};
}

/// A single category in export JSON format.
Map<String, dynamic> makeJsonCategory({
  final String name = 'power',
  final int colorValue = 0xFFFF0000,
}) {
  return {'name': name, 'colorValue': colorValue};
}

// ---------------------------------------------------------------------------
// DB seed helpers — insert directly into the in-memory database
// ---------------------------------------------------------------------------

/// Seed a move into the database. Returns the ID.
Future<String> seedMove(
  final AppDatabase db, {
  final String id = 'move-1',
  final String name = 'Windmill',
  final String category = 'power',
  final String? videoPath,
  final String? originalVideoName,
}) async {
  await db
      .into(db.moves)
      .insert(
        MovesCompanion.insert(
          id: id,
          name: name,
          category: Value(category),
          videoPath: Value(videoPath),
          originalVideoName: Value(originalVideoName),
        ),
      );
  return id;
}

/// Seed a review into the database.
Future<void> seedReview(
  final AppDatabase db, {
  final String id = 'review-1',
  final String rating = 'GOOD',
  final String reviewType = 'STANDARD',
  final String? moveId = 'move-1',
  final String? comboId,
  final String? entityIdSnapshot,
  final String? entityType,
  final String? entityDisplayName,
  final String? entityCategory,
  final DateTime? reviewedAt,
  final int? fsrsPreState,
  final int? fsrsPostState,
}) async {
  await db
      .into(db.reviews)
      .insert(
        ReviewsCompanion.insert(
          id: id,
          rating: rating,
          reviewType: reviewType,
          moveId: Value(moveId),
          comboId: Value(comboId),
          entityIdSnapshot: Value(entityIdSnapshot),
          entityType: Value(entityType),
          entityDisplayName: Value(entityDisplayName),
          entityCategory: Value(entityCategory),
          reviewedAt: Value(reviewedAt ?? DateTime.now()),
          fsrsPreState: Value(fsrsPreState),
          fsrsPostState: Value(fsrsPostState),
        ),
      );
}

/// Seed a combo into the database.
Future<void> seedCombo(
  final AppDatabase db, {
  final String id = 'combo-1',
  final String name = 'Power Combo',
}) async {
  await db.into(db.combos).insert(CombosCompanion.insert(id: id, name: name));
}

/// Seed a battle result into the database.
Future<void> seedBattleResult(
  final AppDatabase db, {
  final String id = 'battle-1',
  final int score = 100,
  final int movesReviewed = 10,
  final String difficulty = 'MEDIUM',
}) async {
  await db
      .into(db.battleResults)
      .insert(
        BattleResultsCompanion.insert(
          id: id,
          score: score,
          movesReviewed: movesReviewed,
          goodCount: 5,
          hardCount: 3,
          againCount: 2,
          longestStreak: 3,
          difficulty: difficulty,
        ),
      );
}

/// Seed an FSRS card into the database.
Future<void> seedFsrsCard(
  final AppDatabase db, {
  final String entityId = 'move-1',
  final String entityType = 'move',
  final double stability = 4.5,
  final double difficulty = 5.2,
  final DateTime? due,
  final int fsrsState = 2,
}) async {
  await db.fsrsCardsDao.upsert(
    FsrsCardsCompanion(
      entityId: Value(entityId),
      entityType: Value(entityType),
      stability: Value(stability),
      difficulty: Value(difficulty),
      due: Value(due ?? DateTime.now().toUtc()),
      fsrsState: Value(fsrsState),
    ),
  );
}

/// Seed a deck into the database.
Future<void> seedDeck(
  final AppDatabase db, {
  final String id = 'deck-1',
  final String name = 'Power Moves',
  final String deckType = 'manual',
}) async {
  await db
      .into(db.decks)
      .insert(
        DecksCompanion.insert(id: id, name: name, deckType: Value(deckType)),
      );
}

/// Seed a deckMove into the database.
Future<void> seedDeckMove(
  final AppDatabase db, {
  final String deckId = 'deck-1',
  final String moveId = 'move-1',
}) async {
  await db
      .into(db.deckMoves)
      .insert(DeckMovesCompanion.insert(deckId: deckId, moveId: moveId));
}

/// Builds a full export JSON with all entity types populated.
/// Useful for round-trip and comprehensive import tests.
String makeFullExportJson() {
  return makeExportJson(
    moves: [
      makeJsonMove(id: 'move-1', name: 'Windmill', category: 'power'),
      makeJsonMove(id: 'move-2', name: 'Headspin', category: 'power'),
    ],
    reviews: [
      makeJsonReview(
        id: 'review-1',
        moveId: 'move-1',
        rating: 'GOOD',
        fsrsPreState: 1,
        fsrsPostState: 2,
      ),
      makeJsonReview(id: 'review-2', moveId: 'move-2', rating: 'EASY'),
    ],
    combos: [makeJsonCombo(id: 'combo-1', name: 'Power Combo')],
    comboMoves: [
      makeJsonComboMove(id: 'cm-1', comboId: 'combo-1', moveId: 'move-1'),
    ],
    battleResults: [makeJsonBattleResult(id: 'battle-1')],
    fsrsCards: [
      makeJsonFsrsCard(entityId: 'move-1', entityType: 'move'),
      makeJsonFsrsCard(entityId: 'combo-1', entityType: 'combo'),
    ],
    decks: [makeJsonDeck(id: 'deck-1', name: 'Power Moves')],
    deckMoves: [makeJsonDeckMove(deckId: 'deck-1', moveId: 'move-1')],
    categories: [
      makeJsonCategory(name: 'power', colorValue: 0xFFFF0000),
      makeJsonCategory(name: 'freeze', colorValue: 0xFF0000FF),
    ],
  );
}
