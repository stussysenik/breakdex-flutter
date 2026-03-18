import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../database/daos/combos_dao.dart';
import '../database/daos/decks_dao.dart';
import '../database/daos/fsrs_cards_dao.dart';
import '../database/daos/moves_dao.dart';
import '../database/daos/reviews_dao.dart';
import '../database/database.dart';

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
  })  : _movesDao = movesDao,
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

    // Categories from SharedPreferences
    List<Map<String, dynamic>> categoriesJson = [];
    final catJson = _prefs.getString('categories');
    if (catJson != null) {
      try {
        final list = jsonDecode(catJson) as List;
        categoriesJson = list.cast<Map<String, dynamic>>();
      } catch (_) {}
    }

    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'moves': moves
          .map((m) => {
                'id': m.id,
                'name': m.name,
                'category': m.category,
                'contentHash': m.contentHash,
                'createdAt': m.createdAt.toUtc().toIso8601String(),
              })
          .toList(),
      'combos': combos
          .map((c) => {
                'id': c.id,
                'name': c.name,
              })
          .toList(),
      'comboMoves': comboMoves
          .map((cm) => {
                'comboId': cm.comboId,
                'moveId': cm.moveId,
                'sequenceIndex': cm.sequenceIndex,
              })
          .toList(),
      'categories': categoriesJson,
      'fsrsCards': fsrsCards
          .map((fc) => {
                'entityId': fc.entityId,
                'entityType': fc.entityType,
                'state': fc.fsrsState,
                'stability': fc.stability,
                'difficulty': fc.difficulty,
                'due': fc.due.toUtc().toIso8601String(),
              })
          .toList(),
      'decks': decks
          .map((d) => {
                'id': d.id,
                'name': d.name,
                'deckType': d.deckType,
              })
          .toList(),
      'deckMoves': deckMoves
          .map((dm) => {
                'deckId': dm.deckId,
                'moveId': dm.moveId,
              })
          .toList(),
      'reviews': reviews
          .map((r) => {
                'id': r.id,
                'entityId': r.entityIdSnapshot,
                'entityType': r.entityType,
                'rating': r.rating,
                'createdAt': r.reviewedAt.toUtc().toIso8601String(),
              })
          .toList(),
    };

    return jsonEncode(data);
  }
}
