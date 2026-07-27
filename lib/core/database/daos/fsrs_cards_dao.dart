import 'package:drift/drift.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/tables/fsrs_cards.dart';
import 'package:breakdex/core/database/tables/moves.dart';
import 'package:breakdex/core/database/tables/combos.dart';

part 'fsrs_cards_dao.g.dart';

/// Data class for JOIN results: an FSRS card paired with its entity (move or combo).
///
/// Exactly one of [move] or [combo] will be non-null, matching the card's
/// entityType. If the referenced entity was deleted but the card lingers,
/// both may be null (orphan — handled by integrity checks).
class FsrsCardWithEntity {
  final FsrsCard card;
  final Move? move;
  final Combo? combo;

  const FsrsCardWithEntity({required this.card, this.move, this.combo});

  /// Display name from the associated entity.
  String get displayName =>
      move?.name ?? combo?.name ?? 'Unknown';

  /// Category (only moves have categories, combos return null).
  String? get category => move?.category;

  /// Video path from the associated entity.
  String? get videoPath => move?.videoPath ?? combo?.activeVideoPath;
}

/// Legacy compat alias — keeps existing code compiling during migration.
typedef FsrsCardWithMove = FsrsCardWithEntity;

@DriftAccessor(tables: [FsrsCards, Moves, Combos])
class FsrsCardsDao extends DatabaseAccessor<AppDatabase>
    with _$FsrsCardsDaoMixin {
  FsrsCardsDao(super.db);

  /// Get a single FSRS card by entity ID and type, or null if not found.
  Future<FsrsCard?> getByEntityId(final String entityId,
      {final String entityType = 'move'}) =>
      (select(fsrsCards)
            ..where((final t) =>
                t.entityId.equals(entityId) &
                t.entityType.equals(entityType)))
          .getSingleOrNull();

  /// Backward-compat wrapper: get card by move ID.
  Future<FsrsCard?> getByMoveId(final String moveId) =>
      getByEntityId(moveId, entityType: 'move');

  /// Get all FSRS cards.
  Future<List<FsrsCard>> getAll() => select(fsrsCards).get();

  /// Watch all FSRS cards as a reactive stream.
  Stream<List<FsrsCard>> watchAll() => select(fsrsCards).watch();

  /// Get cards that are due for review (due <= now).
  Future<List<FsrsCard>> getDueCards({final DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    return (select(fsrsCards)
          ..where((final t) => t.due.isSmallerOrEqualValue(now))
          ..orderBy([(final t) => OrderingTerm.asc(t.due)]))
        .get();
  }

  /// Get due cards with their entities (moves + combos) via LEFT JOINs.
  ///
  /// Uses LEFT JOIN because entities may have been deleted — orphan cards
  /// are still returned so the integrity check can clean them up.
  Future<List<FsrsCardWithEntity>> getDueCardsWithEntities({
    final DateTime? asOf,
    final String? category,
  }) async {
    final now = asOf ?? DateTime.now();
    final query = select(fsrsCards).join([
      leftOuterJoin(moves,
          moves.id.equalsExp(fsrsCards.entityId) &
              fsrsCards.entityType.equals('move')),
      leftOuterJoin(combos,
          combos.id.equalsExp(fsrsCards.entityId) &
              fsrsCards.entityType.equals('combo')),
    ]);
    query.where(fsrsCards.due.isSmallerOrEqualValue(now));
    if (category != null) {
      // Category filter only applies to moves (combos have no category)
      query.where(
          moves.category.equals(category) |
              fsrsCards.entityType.equals('combo'));
    }
    query.orderBy([OrderingTerm.asc(fsrsCards.due)]);

    final rows = await query.get();
    return rows.map((final row) {
      return FsrsCardWithEntity(
        card: row.readTable(fsrsCards),
        move: row.readTableOrNull(moves),
        combo: row.readTableOrNull(combos),
      );
    }).toList();
  }

  /// Legacy wrapper — returns FsrsCardWithEntity (typedef'd as FsrsCardWithMove).
  Future<List<FsrsCardWithMove>> getDueCardsWithMoves({
    final DateTime? asOf,
    final String? category,
  }) =>
      getDueCardsWithEntities(asOf: asOf, category: category);

  /// Get all FSRS cards with due dates in a date range (for calendar view).
  Future<List<FsrsCardWithEntity>> getCardsInRange(
      final DateTime start, final DateTime end) async {
    final query = select(fsrsCards).join([
      leftOuterJoin(moves,
          moves.id.equalsExp(fsrsCards.entityId) &
              fsrsCards.entityType.equals('move')),
      leftOuterJoin(combos,
          combos.id.equalsExp(fsrsCards.entityId) &
              fsrsCards.entityType.equals('combo')),
    ]);
    query.where(
        fsrsCards.due.isBiggerOrEqualValue(start) &
            fsrsCards.due.isSmallerOrEqualValue(end));
    query.orderBy([OrderingTerm.asc(fsrsCards.due)]);

    final rows = await query.get();
    return rows.map((final row) {
      return FsrsCardWithEntity(
        card: row.readTable(fsrsCards),
        move: row.readTableOrNull(moves),
        combo: row.readTableOrNull(combos),
      );
    }).toList();
  }

  /// Insert or update an FSRS card (upsert on entityId+entityType PK).
  Future<void> upsert(final FsrsCardsCompanion entry) async {
    await into(fsrsCards).insertOnConflictUpdate(entry);
  }

  /// Ensure an FSRS card exists for an entity. Creates a default New card if missing.
  Future<FsrsCard> ensureCard(final String entityId,
      {final String entityType = 'move'}) async {
    final existing = await getByEntityId(entityId, entityType: entityType);
    if (existing != null) return existing;

    final companion = FsrsCardsCompanion.insert(
      entityId: entityId,
      entityType: Value(entityType),
    );
    await into(fsrsCards).insert(companion);
    return (await getByEntityId(entityId, entityType: entityType))!;
  }

  /// Get all FSRS cards joined with their entities.
  Future<List<FsrsCardWithEntity>> getCardsWithEntities({
    final String? category,
  }) async {
    final query = select(fsrsCards).join([
      leftOuterJoin(moves,
          moves.id.equalsExp(fsrsCards.entityId) &
              fsrsCards.entityType.equals('move')),
      leftOuterJoin(combos,
          combos.id.equalsExp(fsrsCards.entityId) &
              fsrsCards.entityType.equals('combo')),
    ]);
    if (category != null) {
      query.where(
          moves.category.equals(category) |
              fsrsCards.entityType.equals('combo'));
    }

    final rows = await query.get();
    return rows.map((final row) {
      return FsrsCardWithEntity(
        card: row.readTable(fsrsCards),
        move: row.readTableOrNull(moves),
        combo: row.readTableOrNull(combos),
      );
    }).toList();
  }

  /// Legacy wrapper.
  Future<List<FsrsCardWithMove>> getCardsWithMoves({
    final String? category,
  }) =>
      getCardsWithEntities(category: category);

  /// Watch all FSRS cards joined with their entities (reactive).
  Stream<List<FsrsCardWithEntity>> watchCardsWithEntities() {
    final query = select(fsrsCards).join([
      leftOuterJoin(moves,
          moves.id.equalsExp(fsrsCards.entityId) &
              fsrsCards.entityType.equals('move')),
      leftOuterJoin(combos,
          combos.id.equalsExp(fsrsCards.entityId) &
              fsrsCards.entityType.equals('combo')),
    ]);

    return query.watch().map((final rows) {
      return rows.map((final row) {
        return FsrsCardWithEntity(
          card: row.readTable(fsrsCards),
          move: row.readTableOrNull(moves),
          combo: row.readTableOrNull(combos),
        );
      }).toList();
    });
  }

  /// Legacy wrapper.
  Stream<List<FsrsCardWithMove>> watchCardsWithMoves() =>
      watchCardsWithEntities();

  /// Get the next due date across all cards (earliest future due date).
  Future<DateTime?> getNextDueDate() async {
    final now = DateTime.now().toUtc();
    final query = select(fsrsCards)
      ..where((final t) => t.due.isBiggerThanValue(now))
      ..orderBy([(final t) => OrderingTerm.asc(t.due)])
      ..limit(1);
    final result = await query.getSingleOrNull();
    return result?.due;
  }

  /// Delete an FSRS card by entity ID and type.
  Future<void> deleteByEntityId(final String entityId,
      {final String entityType = 'move'}) =>
      (delete(fsrsCards)
            ..where((final t) =>
                t.entityId.equals(entityId) &
                t.entityType.equals(entityType)))
          .go();

  /// Legacy wrapper.
  Future<void> deleteByMoveId(final String moveId) =>
      deleteByEntityId(moveId, entityType: 'move');
}
