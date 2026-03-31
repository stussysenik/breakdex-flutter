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
  int schemaVersion = AppMetadata.exportSchemaVersion,
  List<Map<String, dynamic>>? moves,
  List<Map<String, dynamic>>? reviews,
  List<Map<String, dynamic>>? combos,
  List<Map<String, dynamic>>? comboMoves,
  List<Map<String, dynamic>>? battleResults,
  List<Map<String, dynamic>>? fsrsCards,
  List<Map<String, dynamic>>? decks,
  List<Map<String, dynamic>>? deckMoves,
  List<Map<String, dynamic>>? categories,
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
  String id = 'move-1',
  String name = 'Windmill',
  String category = 'power',
  String learningState = 'NEW',
  String? videoFilename,
  String? originalVideoName,
  DateTime? createdAt,
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
  String id = 'review-1',
  String rating = 'GOOD',
  String reviewType = 'STANDARD',
  String? moveId = 'move-1',
  String? comboId,
  String? entityIdSnapshot,
  String? entityType,
  String? entityDisplayName,
  String? entityCategory,
  DateTime? reviewedAt,
  int? fsrsPreState,
  int? fsrsPostState,
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
  String id = 'combo-1',
  String name = 'Power Combo',
  String? activeVideoFilename,
}) {
  return {'id': id, 'name': name, 'activeVideoFilename': ?activeVideoFilename};
}

/// A single comboMove in export JSON format.
Map<String, dynamic> makeJsonComboMove({
  String id = 'cm-1',
  int sequenceIndex = 0,
  String comboId = 'combo-1',
  String moveId = 'move-1',
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
  String id = 'battle-1',
  int score = 100,
  int movesReviewed = 10,
  int goodCount = 5,
  int hardCount = 3,
  int againCount = 2,
  int longestStreak = 3,
  String difficulty = 'MEDIUM',
  DateTime? playedAt,
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
  String entityId = 'move-1',
  String entityType = 'move',
  double stability = 4.5,
  double difficulty = 5.2,
  DateTime? due,
  DateTime? lastReview,
  int reps = 3,
  int lapses = 0,
  int fsrsState = 2,
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
  String id = 'deck-1',
  String name = 'Power Moves',
  String deckType = 'manual',
  String? filterCriteria,
  int? sessionSize,
  DateTime? createdAt,
  DateTime? updatedAt,
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
  String deckId = 'deck-1',
  String moveId = 'move-1',
}) {
  return {'deckId': deckId, 'moveId': moveId};
}

/// A single category in export JSON format.
Map<String, dynamic> makeJsonCategory({
  String name = 'power',
  int colorValue = 0xFFFF0000,
}) {
  return {'name': name, 'colorValue': colorValue};
}

// ---------------------------------------------------------------------------
// DB seed helpers — insert directly into the in-memory database
// ---------------------------------------------------------------------------

/// Seed a move into the database. Returns the ID.
Future<String> seedMove(
  AppDatabase db, {
  String id = 'move-1',
  String name = 'Windmill',
  String category = 'power',
  String? videoPath,
  String? originalVideoName,
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
  AppDatabase db, {
  String id = 'review-1',
  String rating = 'GOOD',
  String reviewType = 'STANDARD',
  String? moveId = 'move-1',
  String? comboId,
  String? entityIdSnapshot,
  String? entityType,
  String? entityDisplayName,
  String? entityCategory,
  DateTime? reviewedAt,
  int? fsrsPreState,
  int? fsrsPostState,
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
  AppDatabase db, {
  String id = 'combo-1',
  String name = 'Power Combo',
}) async {
  await db.into(db.combos).insert(CombosCompanion.insert(id: id, name: name));
}

/// Seed a battle result into the database.
Future<void> seedBattleResult(
  AppDatabase db, {
  String id = 'battle-1',
  int score = 100,
  int movesReviewed = 10,
  String difficulty = 'MEDIUM',
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
  AppDatabase db, {
  String entityId = 'move-1',
  String entityType = 'move',
  double stability = 4.5,
  double difficulty = 5.2,
  DateTime? due,
  int fsrsState = 2,
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
  AppDatabase db, {
  String id = 'deck-1',
  String name = 'Power Moves',
  String deckType = 'manual',
}) async {
  await db
      .into(db.decks)
      .insert(
        DecksCompanion.insert(id: id, name: name, deckType: Value(deckType)),
      );
}

/// Seed a deckMove into the database.
Future<void> seedDeckMove(
  AppDatabase db, {
  String deckId = 'deck-1',
  String moveId = 'move-1',
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
