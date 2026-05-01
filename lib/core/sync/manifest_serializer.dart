import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../database/daos/combos_dao.dart';
import '../database/daos/decks_dao.dart';
import '../database/daos/fsrs_cards_dao.dart';
import '../database/daos/moves_dao.dart';
import '../database/daos/reviews_dao.dart';
import '../database/database.dart';
import '../web/library_manifest.dart';

/// Serializes the entire Breakdex library into a compact `manifest.json`
/// suitable for cloud storage and consumption by the web viewer.
///
/// Unlike the full export (stats_export_service), the manifest is denormalized
/// and compact — everything the web viewer needs in a single file. It omits
/// internal state (learning states, FSRS internals) and focuses on display data.
class ManifestSerializer {
  final MovesDao _movesDao;
  final CombosDao _combosDao;
  final FsrsCardsDao _fsrsCardsDao;
  final ReviewsDao _reviewsDao;
  final DecksDao _decksDao;
  final AppDatabase _db;
  final SharedPreferences _prefs;

  ManifestSerializer({
    required MovesDao movesDao,
    required CombosDao combosDao,
    required FsrsCardsDao fsrsCardsDao,
    required ReviewsDao reviewsDao,
    required DecksDao decksDao,
    required AppDatabase db,
    required SharedPreferences prefs,
  }) : _movesDao = movesDao,
       _combosDao = combosDao,
       _fsrsCardsDao = fsrsCardsDao,
       _reviewsDao = reviewsDao,
       _decksDao = decksDao,
       _db = db,
       _prefs = prefs;

  /// Serialize the full library to a compact JSON string.
  ///
  /// Returns the JSON string ready for upload to cloud storage.
  Future<String> serialize() async {
    final moves = await _movesDao.getAll();
    final combos = await _combosDao.getAll();
    final comboMoves = await _db.select(_db.comboMoves).get();
    final fsrsCards = await _fsrsCardsDao.getAll();
    final reviews = await _reviewsDao.getAllOrdered();
    final decks = await _decksDao.getAll();
    final deckMoves = await _db.select(_db.deckMoves).get();
    final assets = await _db.select(_db.assetManifest).get();

    // Categories from SharedPreferences
    List<Map<String, dynamic>> categoriesJson = [];
    final catJson = _prefs.getString('categories');
    if (catJson != null) {
      try {
        final list = jsonDecode(catJson) as List;
        categoriesJson = list.cast<Map<String, dynamic>>();
      } catch (_) {}
    }

    final manifest = LibraryManifest(
      exportedAt: DateTime.now(),
      moves: moves
          .map(
            (move) => LibraryMove(
              id: move.id,
              name: move.name,
              category: move.category,
              contentHash: move.contentHash,
              createdAt: move.createdAt,
            ),
          )
          .toList(),
      combos: combos
          .map((combo) => LibraryCombo(id: combo.id, name: combo.name))
          .toList(),
      comboMoves: comboMoves
          .map(
            (comboMove) => LibraryComboMove(
              comboId: comboMove.comboId,
              moveId: comboMove.moveId,
              sequenceIndex: comboMove.sequenceIndex,
            ),
          )
          .toList(),
      categories: categoriesJson
          .map(
            (category) => LibraryCategory(
              name: category['name'] as String,
              colorValue: category['colorValue'] as int,
              isDefault: category['isDefault'] as bool? ?? false,
            ),
          )
          .toList(),
      fsrsCards: fsrsCards
          .map(
            (card) => LibraryFsrsCard(
              entityId: card.entityId,
              entityType: card.entityType,
              state: card.fsrsState,
              stability: card.stability,
              difficulty: card.difficulty,
              due: card.due,
            ),
          )
          .toList(),
      decks: decks
          .map(
            (deck) => LibraryDeck(
              id: deck.id,
              name: deck.name,
              deckType: deck.deckType,
            ),
          )
          .toList(),
      deckMoves: deckMoves
          .map(
            (deckMove) => LibraryDeckMove(
              deckId: deckMove.deckId,
              moveId: deckMove.moveId,
            ),
          )
          .toList(),
      reviews: reviews
          .map(
            (review) => LibraryReview(
              id: review.id,
              entityId:
                  review.entityIdSnapshot ??
                  review.moveId ??
                  review.comboId ??
                  review.id,
              entityType:
                  review.entityType ??
                  (review.comboId != null ? 'combo' : 'move'),
              rating: review.rating,
              createdAt: review.reviewedAt,
            ),
          )
          .toList(),
      assets: assets
          .map(
            (asset) => LibraryAsset(
              contentHash: asset.contentHash,
              fileSizeBytes: asset.fileSizeBytes,
              mimeType: asset.mimeType,
              durationMs: asset.durationMs,
              width: asset.width,
              height: asset.height,
              importedAt: asset.importedAt,
              sourceType: asset.sourceType,
              sourceName: asset.sourceName,
              deletedAt: asset.deletedAt,
            ),
          )
          .toList(),
    );

    return jsonEncode(manifest.toJson());
  }
}
