import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../app_metadata.dart';
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
  final int fsrsCardsImported;
  final int decksImported;
  final int deckMovesImported;
  final int categoriesImported;
  final List<String> movesWithMissingVideos;

  const ImportResult({
    this.movesImported = 0,
    this.reviewsImported = 0,
    this.combosImported = 0,
    this.comboMovesImported = 0,
    this.battleResultsImported = 0,
    this.fsrsCardsImported = 0,
    this.decksImported = 0,
    this.deckMovesImported = 0,
    this.categoriesImported = 0,
    this.movesWithMissingVideos = const [],
  });

  int get totalImported =>
      movesImported +
      reviewsImported +
      combosImported +
      comboMovesImported +
      battleResultsImported +
      fsrsCardsImported +
      decksImported +
      deckMovesImported;
}

class StatsExportService {
  /// Generates a shareable text summary of stats.
  static String generateTextSummary(final StatsBundle stats) {
    final dist = stats.ratingDistribution;
    final again = dist['AGAIN'] ?? 0;
    final hard = dist['HARD'] ?? 0;
    final good = dist['GOOD'] ?? 0;
    final easy = dist['EASY'] ?? 0;
    final total = again + hard + good + easy;

    String pct(final int count) =>
        total > 0 ? '${(count / total * 100).round()}%' : '0%';

    final topMoves = stats.topMoveEntries
        .take(5)
        .map((final e) {
          final move = stats.allMoves.where((final m) => m.id == e.key).firstOrNull;
          final name = move?.name ?? e.key;
          return '  $name — ${e.value} reviews';
        })
        .join('\n');

    final retPct = (stats.overallRetention * 100).round();
    final due = stats.dueSummary;
    final timestamp = DateTime.now().toIso8601String().split('T').first;

    return '''Breakdex Stats — $timestamp

Moves: ${stats.allMoves.length} | Retention: $retPct%
Streak: ${stats.currentStreak} day${stats.currentStreak == 1 ? '' : 's'}
Due: ${due.newDue} new | ${due.learningDue} learning | ${due.reviewDue} review | ${due.dueTomorrow} tomorrow

Rating Breakdown:
  AGAIN: $again (${pct(again)})
  HARD:  $hard (${pct(hard)})
  GOOD:  $good (${pct(good)})
  EASY:  $easy (${pct(easy)})

${topMoves.isNotEmpty ? 'Most Practiced:\n$topMoves' : 'No moves practiced yet.'}''';
  }

  /// Generates a full JSON export of all data (schema v9).
  ///
  /// v9 changes from v8:
  /// - combos include status and createdAt (combo journey)
  /// - adds comboNoteEntries (journal: kind, videoPath, videoHash)
  /// - adds comboPlans (practice planner)
  ///
  /// v6 changes from v5:
  /// - fsrsCards uses entityId/entityType instead of moveId (polymorphic)
  /// - reviews includes comboId field
  static Future<ExportResult> generateJsonExport(
    final AppDatabase db,
    final SharedPreferences prefs,
  ) async {
    final moves = await db.movesDao.getAllIncludingArchived();
    final reviews = await db.reviewsDao.watchAll().first;
    final battleResults = await db.select(db.battleResults).get();
    final combos = await db.combosDao.getAll();
    final comboMoves = await db.select(db.comboMoves).get();
    final comboNoteEntries = await db.select(db.comboNoteEntries).get();
    final comboPlans = await db.comboPlansDao.getAll();
    final fsrsCards = await db.fsrsCardsDao.getAll();
    final decks = await db.decksDao.getAll();
    final deckMoves = await db.select(db.deckMoves).get();

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
      'schemaVersion': AppMetadata.exportSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'appVersion': AppMetadata.releaseVersion,
      'categories': categoriesJson,
      'moves': moves
          .map(
            (final m) => {
              'id': m.id,
              'name': m.name,
              'category': m.category,
              'learningState': m.learningState,
              'videoFilename': m.videoPath != null
                  ? p.basename(m.videoPath!)
                  : null,
              'originalVideoName': m.originalVideoName,
              'archivedAt': m.archivedAt?.toIso8601String(),
              'archiveReason': m.archiveReason,
              'notes': m.notes,
              'createdAt': m.createdAt.toIso8601String(),
            },
          )
          .toList(),
      'combos': combos
          .map(
            (final c) => {
              'id': c.id,
              'name': c.name,
              'notes': c.notes,
              'activeVideoFilename': c.activeVideoPath != null
                  ? p.basename(c.activeVideoPath!)
                  : null,
              'status': c.status,
              'createdAt': c.createdAt.toIso8601String(),
            },
          )
          .toList(),
      'comboMoves': comboMoves
          .map(
            (final cm) => {
              'id': cm.id,
              'sequenceIndex': cm.sequenceIndex,
              'comboId': cm.comboId,
              'moveId': cm.moveId,
            },
          )
          .toList(),
      // v9: append-only combo journal (videos exported by reference only)
      'comboNoteEntries': comboNoteEntries
          .map(
            (final e) => {
              'id': e.id,
              'comboId': e.comboId,
              'body': e.body,
              'kind': e.kind,
              'videoPath': e.videoPath,
              'videoHash': e.videoHash,
              'createdAt': e.createdAt.toIso8601String(),
            },
          )
          .toList(),
      // v9: practice plans
      'comboPlans': comboPlans
          .map(
            (final pl) => {
              'id': pl.id,
              'comboId': pl.comboId,
              'planDate': pl.planDate.toIso8601String(),
              'position': pl.position,
              'createdAt': pl.createdAt.toIso8601String(),
              'completedAt': pl.completedAt?.toIso8601String(),
            },
          )
          .toList(),
      'reviews': reviews
          .map(
            (final r) => {
              'id': r.id,
              'rating': r.rating,
              'reviewType': r.reviewType,
              'moveId': r.moveId,
              'comboId': r.comboId,
              'entityIdSnapshot': r.entityIdSnapshot,
              'entityType': r.entityType,
              'entityName': r.entityDisplayName,
              'entityCategory': r.entityCategory,
              'reviewedAt': r.reviewedAt.toIso8601String(),
              'fsrsPreState': r.fsrsPreState,
              'fsrsPostState': r.fsrsPostState,
            },
          )
          .toList(),
      'battleResults': battleResults
          .map(
            (final b) => {
              'id': b.id,
              'score': b.score,
              'movesReviewed': b.movesReviewed,
              'goodCount': b.goodCount,
              'hardCount': b.hardCount,
              'againCount': b.againCount,
              'longestStreak': b.longestStreak,
              'difficulty': b.difficulty,
              'playedAt': b.playedAt.toIso8601String(),
            },
          )
          .toList(),
      // v6: entityId + entityType instead of moveId
      'fsrsCards': fsrsCards
          .map(
            (final fc) => {
              'entityId': fc.entityId,
              'entityType': fc.entityType,
              'stability': fc.stability,
              'difficulty': fc.difficulty,
              'due': fc.due.toIso8601String(),
              'lastReview': fc.lastReview?.toIso8601String(),
              'reps': fc.reps,
              'lapses': fc.lapses,
              'fsrsState': fc.fsrsState,
            },
          )
          .toList(),
      'decks': decks
          .map(
            (final d) => {
              'id': d.id,
              'name': d.name,
              'deckType': d.deckType,
              'filterCriteria': d.filterCriteria,
              'sessionSize': d.sessionSize,
              'createdAt': d.createdAt.toIso8601String(),
              'updatedAt': d.updatedAt.toIso8601String(),
            },
          )
          .toList(),
      'deckMoves': deckMoves
          .map((final dm) => {'deckId': dm.deckId, 'moveId': dm.moveId})
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
  static ImportValidation validateImportJson(final String json) {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final version = data['schemaVersion'] as int? ?? 1;

      if (version > AppMetadata.exportSchemaVersion) {
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

  /// Imports data from JSON. Handles both old (v1–v5) and new (v6) formats.
  static Future<ImportResult> importFromJson(
    final AppDatabase db,
    final SharedPreferences prefs,
    final String json,
    final ImportMode mode,
  ) async {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final version = data['schemaVersion'] as int? ?? 1;

    final movesJson = data['moves'] as List? ?? [];
    final reviewsJson = data['reviews'] as List? ?? [];
    final combosJson = data['combos'] as List? ?? [];
    final comboMovesJson = data['comboMoves'] as List? ?? [];
    // v9 fields — absent in older exports, imported with defaults
    final comboNoteEntriesJson = data['comboNoteEntries'] as List? ?? [];
    final comboPlansJson = data['comboPlans'] as List? ?? [];
    final battleResultsJson = data['battleResults'] as List? ?? [];
    final categoriesJson = data['categories'] as List? ?? [];
    final fsrsCardsJson = data['fsrsCards'] as List? ?? [];
    final decksJson = data['decks'] as List? ?? [];
    final deckMovesJson = data['deckMoves'] as List? ?? [];

    int movesImported = 0;
    int reviewsImported = 0;
    int combosImported = 0;
    int comboMovesImported = 0;
    int battleResultsImported = 0;
    int fsrsCardsImported = 0;
    int decksImported = 0;
    int deckMovesImported = 0;
    int categoriesImported = 0;
    final missingVideos = <String>[];

    await db.transaction(() async {
      // Import moves — replaceAll overwrites existing by ID instead of bulk-deleting
      final existingMoveIds = (await db.movesDao.getAllIncludingArchived())
            .map((final m) => m.id)
            .toSet();

      for (final m in movesJson) {
        final map = m as Map<String, dynamic>;
        final id = map['id'] as String;
        if (mode == ImportMode.merge && existingMoveIds.contains(id)) continue;
        if (mode == ImportMode.replaceAll && existingMoveIds.contains(id)) {
          await db.update(db.moves).replace(
            MovesCompanion.insert(
              id: id,
              name: map['name'] as String,
              learningState: Value(map['learningState'] as String? ?? 'NEW'),
              category: Value(map['category'] as String? ?? 'default'),
              videoPath: const Value(null),
              originalVideoName: Value(map['originalVideoName'] as String?),
              archivedAt: Value(
                map['archivedAt'] != null
                    ? DateTime.parse(map['archivedAt'] as String)
                    : null,
              ),
              archiveReason: Value(map['archiveReason'] as String?),
              notes: Value(map['notes'] as String?),
              createdAt: Value(
                map['createdAt'] != null
                    ? DateTime.parse(map['createdAt'] as String)
                    : DateTime.now(),
              ),
            ),
          );
          movesImported++;
          final hasVideo =
              map['videoFilename'] != null ||
              (version == 1 && map['videoPath'] != null);
          if (hasVideo) missingVideos.add(map['name'] as String);
          continue;
        }

        final hasVideo =
            map['videoFilename'] != null ||
            (version == 1 && map['videoPath'] != null);
        if (hasVideo) missingVideos.add(map['name'] as String);

        await db
            .into(db.moves)
            .insert(
              MovesCompanion.insert(
                id: id,
                name: map['name'] as String,
                learningState: Value(map['learningState'] as String? ?? 'NEW'),
                category: Value(map['category'] as String? ?? 'default'),
                videoPath: const Value(null),
                originalVideoName: Value(map['originalVideoName'] as String?),
                archivedAt: Value(
                  map['archivedAt'] != null
                      ? DateTime.parse(map['archivedAt'] as String)
                      : null,
                ),
                archiveReason: Value(map['archiveReason'] as String?),
                notes: Value(map['notes'] as String?),
                createdAt: Value(
                  map['createdAt'] != null
                      ? DateTime.parse(map['createdAt'] as String)
                      : DateTime.now(),
                ),
              ),
            );
        movesImported++;
      }

      // Import combos
      final existingComboIds = mode == ImportMode.merge
          ? (await db.combosDao.getAll()).map((final c) => c.id).toSet()
          : <String>{};

      for (final c in combosJson) {
        final map = c as Map<String, dynamic>;
        final id = map['id'] as String;
        if (mode == ImportMode.merge && existingComboIds.contains(id)) continue;

        await db
            .into(db.combos)
            .insert(
              CombosCompanion.insert(
                id: id,
                name: map['name'] as String,
                notes: Value(map['notes'] as String?),
                activeVideoPath: const Value(null),
                // pre-v9 exports lack these → defaults
                status: Value(map['status'] as String? ?? 'idea'),
                createdAt: map['createdAt'] != null
                    ? Value(DateTime.parse(map['createdAt'] as String))
                    : const Value.absent(),
              ),
            );
        combosImported++;
      }

      // Import combo journal entries (v9+; absent in older exports)
      if (comboNoteEntriesJson.isNotEmpty) {
        final existingEntryIds = mode == ImportMode.merge
            ? (await db.select(db.comboNoteEntries).get())
                  .map((final e) => e.id)
                  .toSet()
            : <String>{};

        for (final e in comboNoteEntriesJson) {
          final map = e as Map<String, dynamic>;
          final id = map['id'] as String;
          if (mode == ImportMode.merge && existingEntryIds.contains(id)) {
            continue;
          }

          await db
              .into(db.comboNoteEntries)
              .insert(
                ComboNoteEntriesCompanion.insert(
                  id: id,
                  comboId: map['comboId'] as String,
                  body: map['body'] as String? ?? '',
                  kind: Value(map['kind'] as String? ?? 'jot'),
                  videoPath: Value(map['videoPath'] as String?),
                  videoHash: Value(map['videoHash'] as String?),
                  createdAt: map['createdAt'] != null
                      ? Value(DateTime.parse(map['createdAt'] as String))
                      : const Value.absent(),
                ),
              );
        }
      }

      // Import combo plans (v9+; absent in older exports)
      if (comboPlansJson.isNotEmpty) {
        final existingPlanIds = mode == ImportMode.merge
            ? (await db.comboPlansDao.getAll()).map((final pl) => pl.id).toSet()
            : <String>{};

        for (final plJson in comboPlansJson) {
          final map = plJson as Map<String, dynamic>;
          final id = map['id'] as String;
          if (mode == ImportMode.merge && existingPlanIds.contains(id)) {
            continue;
          }

          await db
              .into(db.comboPlans)
              .insert(
                ComboPlansCompanion.insert(
                  id: id,
                  comboId: map['comboId'] as String,
                  planDate: DateTime.parse(map['planDate'] as String),
                  position: Value(map['position'] as int? ?? 0),
                  createdAt: map['createdAt'] != null
                      ? Value(DateTime.parse(map['createdAt'] as String))
                      : const Value.absent(),
                  completedAt: Value(
                    map['completedAt'] != null
                        ? DateTime.parse(map['completedAt'] as String)
                        : null,
                  ),
                ),
              );
        }
      }

      // Import comboMoves
      if (comboMovesJson.isNotEmpty) {
        final existingCmIds = mode == ImportMode.merge
            ? (await db.select(db.comboMoves).get()).map((final cm) => cm.id).toSet()
            : <String>{};

        for (final cm in comboMovesJson) {
          final map = cm as Map<String, dynamic>;
          final id = map['id'] as String;
          if (mode == ImportMode.merge && existingCmIds.contains(id)) continue;

          await db
              .into(db.comboMoves)
              .insert(
                ComboMovesCompanion.insert(
                  id: id,
                  sequenceIndex: map['sequenceIndex'] as int,
                  comboId: map['comboId'] as String,
                  moveId: map['moveId'] as String,
                ),
              );
          comboMovesImported++;
        }
      }

      // Import reviews
      final existingReviewIds = mode == ImportMode.merge
          ? (await db.reviewsDao.watchAll().first).map((final r) => r.id).toSet()
          : <String>{};

      for (final r in reviewsJson) {
        final map = r as Map<String, dynamic>;
        final id = map['id'] as String;
        if (mode == ImportMode.merge && existingReviewIds.contains(id)) {
          continue;
        }

        await db
            .into(db.reviews)
            .insert(
              ReviewsCompanion.insert(
                id: id,
                rating: map['rating'] as String,
                reviewType: map['reviewType'] as String,
                moveId: Value(map['moveId'] as String?),
                comboId: Value(map['comboId'] as String?),
                entityIdSnapshot: Value(map['entityIdSnapshot'] as String?),
                entityType: Value(map['entityType'] as String?),
                entityDisplayName: Value(map['entityName'] as String?),
                entityCategory: Value(map['entityCategory'] as String?),
                reviewedAt: Value(
                  map['reviewedAt'] != null
                      ? DateTime.parse(map['reviewedAt'] as String)
                      : DateTime.now(),
                ),
                fsrsPreState: Value(map['fsrsPreState'] as int?),
                fsrsPostState: Value(map['fsrsPostState'] as int?),
              ),
            );
        reviewsImported++;
      }

      // Import battle results
      final existingBrIds = mode == ImportMode.merge
          ? (await db.select(db.battleResults).get()).map((final b) => b.id).toSet()
          : <String>{};

      for (final b in battleResultsJson) {
        final map = b as Map<String, dynamic>;
        final id = map['id'] as String;
        if (mode == ImportMode.merge && existingBrIds.contains(id)) continue;

        await db
            .into(db.battleResults)
            .insert(
              BattleResultsCompanion.insert(
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
              ),
            );
        battleResultsImported++;
      }

      // Import FSRS cards — handle both old (moveId) and new (entityId) formats
      if (fsrsCardsJson.isNotEmpty) {
        for (final fc in fsrsCardsJson) {
          final map = fc as Map<String, dynamic>;

          // v6 uses entityId+entityType, v1–v5 uses moveId
          final entityId =
              map['entityId'] as String? ?? map['moveId'] as String;
          final entityType = map['entityType'] as String? ?? 'move';

          if (mode == ImportMode.merge) {
            final existing = await db.fsrsCardsDao.getByEntityId(
              entityId,
              entityType: entityType,
            );
            if (existing != null) continue;
          }

          await db.fsrsCardsDao.upsert(
            FsrsCardsCompanion(
              entityId: Value(entityId),
              entityType: Value(entityType),
              stability: Value((map['stability'] as num?)?.toDouble() ?? 0.0),
              difficulty: Value((map['difficulty'] as num?)?.toDouble() ?? 0.0),
              due: Value(
                map['due'] != null
                    ? DateTime.parse(map['due'] as String)
                    : DateTime.now().toUtc(),
              ),
              lastReview: Value(
                map['lastReview'] != null
                    ? DateTime.parse(map['lastReview'] as String)
                    : null,
              ),
              reps: Value(map['reps'] as int? ?? 0),
              lapses: Value(map['lapses'] as int? ?? 0),
              fsrsState: Value(map['fsrsState'] as int? ?? 0),
            ),
          );
          fsrsCardsImported++;
        }
      }

      // Import decks
      if (decksJson.isNotEmpty) {
        final existingDeckIds = mode == ImportMode.merge
            ? (await db.decksDao.getAll()).map((final d) => d.id).toSet()
            : <String>{};

        for (final d in decksJson) {
          final map = d as Map<String, dynamic>;
          final id = map['id'] as String;
          if (mode == ImportMode.merge && existingDeckIds.contains(id)) {
            continue;
          }

          await db
              .into(db.decks)
              .insert(
                DecksCompanion.insert(
                  id: id,
                  name: map['name'] as String,
                  deckType: Value(map['deckType'] as String? ?? 'smart'),
                  filterCriteria: Value(map['filterCriteria'] as String?),
                  sessionSize: Value(map['sessionSize'] as int?),
                  createdAt: Value(
                    map['createdAt'] != null
                        ? DateTime.parse(map['createdAt'] as String)
                        : DateTime.now(),
                  ),
                  updatedAt: Value(
                    map['updatedAt'] != null
                        ? DateTime.parse(map['updatedAt'] as String)
                        : DateTime.now(),
                  ),
                ),
              );
          decksImported++;
        }
      }

      // Import deckMoves
      if (deckMovesJson.isNotEmpty) {
        final existingDmKeys = mode == ImportMode.merge
            ? (await db.select(db.deckMoves).get())
                  .map((final dm) => '${dm.deckId}:${dm.moveId}')
                  .toSet()
            : <String>{};

        for (final dm in deckMovesJson) {
          final map = dm as Map<String, dynamic>;
          final deckId = map['deckId'] as String;
          final moveId = map['moveId'] as String;
          final key = '$deckId:$moveId';
          if (mode == ImportMode.merge && existingDmKeys.contains(key)) {
            continue;
          }

          await db
              .into(db.deckMoves)
              .insert(
                DeckMovesCompanion.insert(deckId: deckId, moveId: moveId),
              );
          deckMovesImported++;
        }
      }
    });

    // Import categories to SharedPreferences
    if (categoriesJson.isNotEmpty) {
      final cats = categoriesJson
          .map((final c) => c as Map<String, dynamic>)
          .where((final c) => c['name'] != null && c['colorValue'] != null)
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
      fsrsCardsImported: fsrsCardsImported,
      decksImported: decksImported,
      deckMovesImported: deckMovesImported,
      categoriesImported: categoriesImported,
      movesWithMissingVideos: missingVideos,
    );
  }
}
