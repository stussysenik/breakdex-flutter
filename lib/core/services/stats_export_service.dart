import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';
import '../../features/stats/providers/stats_providers.dart';

/// Result of a JSON export operation.
class ExportResult {
  final String json;
  final int moveCount;
  final int reviewCount;
  final int comboCount;
  final int battleResultCount;

  const ExportResult({
    required this.json,
    required this.moveCount,
    required this.reviewCount,
    required this.comboCount,
    required this.battleResultCount,
  });

  int get totalRecords =>
      moveCount + reviewCount + comboCount + battleResultCount;
}

/// Result of validating an import JSON.
class ImportValidation {
  final bool valid;
  final int schemaVersion;
  final String? error;
  final int moveCount;
  final int reviewCount;
  final int comboCount;
  final int battleResultCount;
  final int categoryCount;

  const ImportValidation({
    required this.valid,
    this.schemaVersion = 0,
    this.error,
    this.moveCount = 0,
    this.reviewCount = 0,
    this.comboCount = 0,
    this.battleResultCount = 0,
    this.categoryCount = 0,
  });
}

enum ImportMode { replaceAll, merge }

/// Result of an import operation.
class ImportResult {
  final int movesImported;
  final int reviewsImported;
  final int combosImported;
  final int comboMovesImported;
  final int battleResultsImported;
  final int categoriesImported;
  final List<String> movesWithMissingVideos;

  const ImportResult({
    this.movesImported = 0,
    this.reviewsImported = 0,
    this.combosImported = 0,
    this.comboMovesImported = 0,
    this.battleResultsImported = 0,
    this.categoriesImported = 0,
    this.movesWithMissingVideos = const [],
  });

  int get totalImported =>
      movesImported +
      reviewsImported +
      combosImported +
      comboMovesImported +
      battleResultsImported;
}

class StatsExportService {
  /// Generates a shareable text summary of stats.
  static String generateTextSummary(StatsBundle stats) {
    final total = stats.totalReviews;
    final dist = stats.ratingDistribution;
    final again = dist['AGAIN'] ?? 0;
    final hard = dist['HARD'] ?? 0;
    final good = dist['GOOD'] ?? 0;

    String pct(int count) =>
        total > 0 ? '${(count / total * 100).round()}%' : '0%';

    final topMoves = stats.topMoveEntries.take(5).map((e) {
      final move = stats.allMoves.where((m) => m.id == e.key).firstOrNull;
      final name = move?.name ?? e.key;
      return '  $name — ${e.value} reviews';
    }).join('\n');

    final timestamp = DateTime.now().toIso8601String().split('T').first;

    return '''Breakdex Stats — $timestamp

Reviews: $total total | ${stats.reviewsThisWeek} this week | ${stats.reviewsThisMonth} this month
Streak: ${stats.currentStreak} day${stats.currentStreak == 1 ? '' : 's'}

Rating Breakdown:
  AGAIN: $again (${pct(again)})
  HARD:  $hard (${pct(hard)})
  GOOD:  $good (${pct(good)})

${topMoves.isNotEmpty ? 'Most Practiced:\n$topMoves' : 'No moves practiced yet.'}''';
  }

  /// Generates a full JSON export of all data (schema v2).
  static Future<ExportResult> generateJsonExport(
    AppDatabase db,
    SharedPreferences prefs,
  ) async {
    final moves = await db.movesDao.getAll();
    final reviews = await db.reviewsDao.watchAll().first;
    final battleResults = await db.select(db.battleResults).get();
    final combos = await db.combosDao.getAll();
    final comboMoves = await db.select(db.comboMoves).get();

    // Categories from SharedPreferences
    List<Map<String, dynamic>> categoriesJson = [];
    final catJson = prefs.getString('categories');
    if (catJson != null) {
      try {
        final list = jsonDecode(catJson) as List;
        categoriesJson = list.cast<Map<String, dynamic>>();
      } catch (_) {}
    }

    final data = {
      'schemaVersion': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'appVersion': '0.4.0',
      'categories': categoriesJson,
      'moves': moves
          .map((m) => {
                'id': m.id,
                'name': m.name,
                'category': m.category,
                'learningState': m.learningState,
                'videoFilename': m.videoPath != null
                    ? p.basename(m.videoPath!)
                    : null,
                'createdAt': m.createdAt.toIso8601String(),
              })
          .toList(),
      'combos': combos
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'activeVideoFilename': c.activeVideoPath != null
                    ? p.basename(c.activeVideoPath!)
                    : null,
              })
          .toList(),
      'comboMoves': comboMoves
          .map((cm) => {
                'id': cm.id,
                'sequenceIndex': cm.sequenceIndex,
                'comboId': cm.comboId,
                'moveId': cm.moveId,
              })
          .toList(),
      'reviews': reviews
          .map((r) => {
                'id': r.id,
                'rating': r.rating,
                'reviewType': r.reviewType,
                'moveId': r.moveId,
                'reviewedAt': r.reviewedAt.toIso8601String(),
              })
          .toList(),
      'battleResults': battleResults
          .map((b) => {
                'id': b.id,
                'score': b.score,
                'movesReviewed': b.movesReviewed,
                'goodCount': b.goodCount,
                'hardCount': b.hardCount,
                'againCount': b.againCount,
                'longestStreak': b.longestStreak,
                'difficulty': b.difficulty,
                'playedAt': b.playedAt.toIso8601String(),
              })
          .toList(),
    };

    final json = const JsonEncoder.withIndent('  ').convert(data);
    return ExportResult(
      json: json,
      moveCount: moves.length,
      reviewCount: reviews.length,
      comboCount: combos.length,
      battleResultCount: battleResults.length,
    );
  }

  /// Date-stamped filename for exports.
  static String get exportFilename {
    final date = DateTime.now().toIso8601String().split('T').first;
    return 'breakdex_export_$date.json';
  }

  /// Validates import JSON and returns summary counts.
  static ImportValidation validateImportJson(String json) {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final version = data['schemaVersion'] as int? ?? 1;

      if (version > 2) {
        return const ImportValidation(
          valid: false,
          error:
              'This backup was created by a newer version of Breakdex. Please update the app.',
        );
      }

      final moves = data['moves'] as List? ?? [];
      final reviews = data['reviews'] as List? ?? [];
      final combos = data['combos'] as List? ?? [];
      final battleResults = data['battleResults'] as List? ?? [];
      final categories = data['categories'] as List? ?? [];

      // Validate required fields on moves
      for (final m in moves) {
        final map = m as Map<String, dynamic>;
        if (map['id'] == null || map['name'] == null) {
          return const ImportValidation(
            valid: false,
            error: 'Invalid move data: missing id or name.',
          );
        }
      }

      return ImportValidation(
        valid: true,
        schemaVersion: version,
        moveCount: moves.length,
        reviewCount: reviews.length,
        comboCount: combos.length,
        battleResultCount: battleResults.length,
        categoryCount: categories.length,
      );
    } catch (e) {
      return ImportValidation(valid: false, error: 'Invalid JSON: $e');
    }
  }

  /// Imports data from JSON.
  static Future<ImportResult> importFromJson(
    AppDatabase db,
    SharedPreferences prefs,
    String json,
    ImportMode mode,
  ) async {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final version = data['schemaVersion'] as int? ?? 1;

    final movesJson = data['moves'] as List? ?? [];
    final reviewsJson = data['reviews'] as List? ?? [];
    final combosJson = data['combos'] as List? ?? [];
    final comboMovesJson = data['comboMoves'] as List? ?? [];
    final battleResultsJson = data['battleResults'] as List? ?? [];
    final categoriesJson = data['categories'] as List? ?? [];

    int movesImported = 0;
    int reviewsImported = 0;
    int combosImported = 0;
    int comboMovesImported = 0;
    int battleResultsImported = 0;
    int categoriesImported = 0;
    final missingVideos = <String>[];

    await db.transaction(() async {
      if (mode == ImportMode.replaceAll) {
        await db.delete(db.reviews).go();
        await db.delete(db.comboMoves).go();
        await db.delete(db.combos).go();
        await db.delete(db.battleResults).go();
        await db.delete(db.moves).go();
      }

      // Import moves
      final existingMoveIds = mode == ImportMode.merge
          ? (await db.movesDao.getAll()).map((m) => m.id).toSet()
          : <String>{};

      for (final m in movesJson) {
        final map = m as Map<String, dynamic>;
        final id = map['id'] as String;
        if (mode == ImportMode.merge && existingMoveIds.contains(id)) continue;

        final hasVideo = map['videoFilename'] != null ||
            (version == 1 && map['videoPath'] != null);
        if (hasVideo) missingVideos.add(map['name'] as String);

        await db.into(db.moves).insert(MovesCompanion.insert(
              id: id,
              name: map['name'] as String,
              learningState:
                  Value(map['learningState'] as String? ?? 'NEW'),
              category: Value(map['category'] as String? ?? 'default'),
              videoPath: const Value(null), // Videos not included in export
              createdAt: Value(
                map['createdAt'] != null
                    ? DateTime.parse(map['createdAt'] as String)
                    : DateTime.now(),
              ),
            ));
        movesImported++;
      }

      // Import combos
      final existingComboIds = mode == ImportMode.merge
          ? (await db.combosDao.getAll()).map((c) => c.id).toSet()
          : <String>{};

      for (final c in combosJson) {
        final map = c as Map<String, dynamic>;
        final id = map['id'] as String;
        if (mode == ImportMode.merge && existingComboIds.contains(id)) continue;

        await db.into(db.combos).insert(CombosCompanion.insert(
              id: id,
              name: map['name'] as String,
              activeVideoPath: const Value(null),
            ));
        combosImported++;
      }

      // Import comboMoves
      if (comboMovesJson.isNotEmpty) {
        final existingCmIds = mode == ImportMode.merge
            ? (await db.select(db.comboMoves).get()).map((cm) => cm.id).toSet()
            : <String>{};

        for (final cm in comboMovesJson) {
          final map = cm as Map<String, dynamic>;
          final id = map['id'] as String;
          if (mode == ImportMode.merge && existingCmIds.contains(id)) continue;

          await db.into(db.comboMoves).insert(ComboMovesCompanion.insert(
                id: id,
                sequenceIndex: map['sequenceIndex'] as int,
                comboId: map['comboId'] as String,
                moveId: map['moveId'] as String,
              ));
          comboMovesImported++;
        }
      }

      // Import reviews
      final existingReviewIds = mode == ImportMode.merge
          ? (await db.reviewsDao.watchAll().first).map((r) => r.id).toSet()
          : <String>{};

      for (final r in reviewsJson) {
        final map = r as Map<String, dynamic>;
        final id = map['id'] as String;
        if (mode == ImportMode.merge && existingReviewIds.contains(id)) {
          continue;
        }

        await db.into(db.reviews).insert(ReviewsCompanion.insert(
              id: id,
              rating: map['rating'] as String,
              reviewType: map['reviewType'] as String,
              moveId: Value(map['moveId'] as String?),
              reviewedAt: Value(
                map['reviewedAt'] != null
                    ? DateTime.parse(map['reviewedAt'] as String)
                    : DateTime.now(),
              ),
            ));
        reviewsImported++;
      }

      // Import battle results
      final existingBrIds = mode == ImportMode.merge
          ? (await db.select(db.battleResults).get()).map((b) => b.id).toSet()
          : <String>{};

      for (final b in battleResultsJson) {
        final map = b as Map<String, dynamic>;
        final id = map['id'] as String;
        if (mode == ImportMode.merge && existingBrIds.contains(id)) continue;

        await db.into(db.battleResults).insert(BattleResultsCompanion.insert(
              id: id,
              score: map['score'] as int,
              movesReviewed: map['movesReviewed'] as int,
              goodCount: map['goodCount'] as int? ?? 0,
              hardCount: map['hardCount'] as int? ?? 0,
              againCount: map['againCount'] as int? ?? 0,
              longestStreak: map['longestStreak'] as int? ?? 0,
              difficulty: map['difficulty'] as String,
              playedAt: Value(
                map['playedAt'] != null
                    ? DateTime.parse(map['playedAt'] as String)
                    : DateTime.now(),
              ),
            ));
        battleResultsImported++;
      }
    });

    // Import categories to SharedPreferences
    if (categoriesJson.isNotEmpty) {
      final cats = categoriesJson
          .map((c) => c as Map<String, dynamic>)
          .where((c) => c['name'] != null && c['colorValue'] != null)
          .toList();
      if (cats.isNotEmpty) {
        await prefs.setString('categories', jsonEncode(cats));
        categoriesImported = cats.length;
      }
    }

    return ImportResult(
      movesImported: movesImported,
      reviewsImported: reviewsImported,
      combosImported: combosImported,
      comboMovesImported: comboMovesImported,
      battleResultsImported: battleResultsImported,
      categoriesImported: categoriesImported,
      movesWithMissingVideos: missingVideos,
    );
  }
}
