import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/tables/combos.dart';
import 'package:breakdex/core/database/tables/combo_moves.dart';
import 'package:breakdex/core/database/tables/combo_note_entries.dart';
import 'package:breakdex/core/database/tables/combo_plans.dart';
import 'package:breakdex/core/database/tables/moves.dart';

part 'combos_dao.g.dart';

/// A combo with the metadata the Library list renders: move count,
/// jot count, and the most recent journal entry.
class ComboWithMeta {
  final Combo combo;
  final int moveCount;
  final int jotCount;
  final String? lastEntryBody;
  final String? lastEntryKind;
  final DateTime? lastEntryAt;

  ComboWithMeta({
    required this.combo,
    required this.moveCount,
    required this.jotCount,
    this.lastEntryBody,
    this.lastEntryKind,
    this.lastEntryAt,
  });
}

/// Per-day journal activity for the calendar heat map.
class DayActivity {
  final DateTime day;
  final int jotCount;
  final int takeCount;

  DayActivity({
    required this.day,
    required this.jotCount,
    required this.takeCount,
  });
}

/// A single Library row: combo + transition chain + counts + last entry.
class LibraryRow {
  final Combo combo;
  final String transitionChain;
  final int moveCount;
  final int jotCount;
  final String? lastEntryBody;
  final DateTime? lastEntryAt;

  LibraryRow({
    required this.combo,
    required this.transitionChain,
    required this.moveCount,
    required this.jotCount,
    this.lastEntryBody,
    this.lastEntryAt,
  });

  DateTime? get lastJotOrStatusAt => lastEntryAt ?? combo.createdAt;
}

class ComboWithMoves {
  final Combo combo;
  final List<ComboMoveWithDetail> moves;

  ComboWithMoves({required this.combo, required this.moves});
}

class ComboMoveWithDetail {
  final ComboMove comboMove;
  final Move move;

  ComboMoveWithDetail({required this.comboMove, required this.move});
}

@DriftAccessor(tables: [Combos, ComboMoves, ComboNoteEntries, ComboPlans, Moves])
class CombosDao extends DatabaseAccessor<AppDatabase> with _$CombosDaoMixin {
  CombosDao(super.db);

  String _normalizeName(final String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  // Rows hidden by an inbound sync tombstone (task 4.8) carry a non-null
  // `deletedAt`; every browse/list feed filters them out. For left-joins the
  // step predicate rides the ON clause so a combo whose only steps are hidden
  // still lists (it is not itself deleted) — moving it to WHERE would drop the
  // combo entirely.
  Stream<List<Combo>> watchAll() =>
      (select(combos)..where((final t) => t.deletedAt.isNull())).watch();

  Stream<List<ComboWithMoves>> watchAllCombosWithMoves() {
    final query = select(combos).join([
      leftOuterJoin(
        comboMoves,
        comboMoves.comboId.equalsExp(combos.id) & comboMoves.deletedAt.isNull(),
      ),
      leftOuterJoin(moves, moves.id.equalsExp(comboMoves.moveId)),
    ])
      ..where(combos.deletedAt.isNull())
      ..orderBy([OrderingTerm.asc(comboMoves.sequenceIndex)]);

    return query.watch().map((final rows) {
      final map = <String, ComboWithMoves>{};
      for (final row in rows) {
        final combo = row.readTable(combos);
        final cm = row.readTableOrNull(comboMoves);
        final m = row.readTableOrNull(moves);
        
        final comboWithMoves = map.putIfAbsent(
          combo.id, 
          () => ComboWithMoves(combo: combo, moves: []),
        );
        
        if (cm != null && m != null) {
          comboWithMoves.moves.add(
            ComboMoveWithDetail(comboMove: cm, move: m.copyWith(count: cm.count)),
          );
        }
      }
      return map.values.toList();
    });
  }

  Future<List<Combo>> getAll() =>
      (select(combos)..where((final t) => t.deletedAt.isNull())).get();

  /// Every combo-step row, unordered — the read side of the task 4.4 backfill.
  Future<List<ComboMove>> getAllComboMoves() => select(comboMoves).get();

  Future<Combo> getById(final String id) =>
      (select(combos)..where((final t) => t.id.equals(id))).getSingle();

  Future<bool> nameExists(final String name, {final String? excludingId}) async {
    final normalized = _normalizeName(name);
    if (normalized.isEmpty) return false;

    final rows = await select(combos).get();
    return rows.any(
      (final combo) =>
          combo.id != excludingId && _normalizeName(combo.name) == normalized,
    );
  }

  Stream<Combo> watchById(final String id) =>
      (select(combos)..where((final t) => t.id.equals(id))).watchSingle();

  /// Performance: each cell using [watchComboMoves] creates a per-combo stream
  /// subscription. With N combos in the grid this scales as O(N). Grid cells
  /// should share a single-widget subscription (see _ComboGridCell) and prefer
  /// combo.resolvedActiveVideoPath for thumbnail resolution where possible.
  Stream<List<ComboMoveWithDetail>> watchComboMoves(final String comboId) {
    final query = select(comboMoves).join([
      innerJoin(moves, moves.id.equalsExp(comboMoves.moveId)),
    ])
      ..where(comboMoves.comboId.equals(comboId) & comboMoves.deletedAt.isNull())
      ..orderBy([OrderingTerm.asc(comboMoves.sequenceIndex)]);

    return query.watch().map((final rows) => rows
        .map((final row) {
          final cm = row.readTable(comboMoves);
          final m = row.readTable(moves);
          return ComboMoveWithDetail(
            comboMove: cm,
            move: m.copyWith(count: cm.count),
          );
        })
        .toList());
  }

  /// Stamp [Combos.updatedAt] with the local mutation time for last-writer-wins
  /// sync (task 4.4), unless the caller already set it — the reconcile path
  /// passes a remote timestamp that must be preserved, not clobbered with now().
  /// Mirrors `MovesDao._stampUpdatedAt`.
  CombosCompanion _stampCombo(final CombosCompanion entry) =>
      entry.updatedAt.present
      ? entry
      : entry.copyWith(updatedAt: Value(DateTime.now().toUtc()));

  /// As [_stampCombo], for `combo_moves`. This table has no `createdAt`, so
  /// stamping on insert is what guarantees every step carries a non-null clock.
  ComboMovesCompanion _stampComboMove(final ComboMovesCompanion entry) =>
      entry.updatedAt.present
      ? entry
      : entry.copyWith(updatedAt: Value(DateTime.now().toUtc()));

  Future<void> insertCombo(final CombosCompanion entry) =>
      into(combos).insert(_stampCombo(entry));

  Future<void> addMoveToCombo(final ComboMovesCompanion entry) =>
      into(comboMoves).insert(_stampComboMove(entry));

  Future<void> updateCombo(final CombosCompanion entry) =>
      (update(combos)..where((final t) => t.id.equals(entry.id.value)))
          .write(_stampCombo(entry));

  Future<void> deleteCombo(final String id) {
    debugPrint('[CombosDao] deleteCombo id=$id');
    // Explicit child deletes: SQLite FK cascade is not enforced on this
    // connection (no PRAGMA foreign_keys), so clean up structural rows
    // ourselves. Plans and combo_moves are structure that has no meaning once
    // the combo is gone, so they go with it. Journal entries (combo_note_entries)
    // are user-authored content — we deliberately do NOT delete them; instead the
    // stats queries are scoped to existing combos so orphaned jots can't inflate
    // the "Practiced" count or calendar heat.
    return transaction(() async {
      await (delete(comboPlans)..where((final t) => t.comboId.equals(id))).go();
      await (delete(comboMoves)..where((final t) => t.comboId.equals(id))).go();
      await (delete(combos)..where((final t) => t.id.equals(id))).go();
    });
  }

  Future<void> removeComboMove(final String id) =>
      (delete(comboMoves)..where((final t) => t.id.equals(id))).go();

  Future<void> deleteAllMovesForCombo(final String comboId) =>
      (delete(comboMoves)..where((final t) => t.comboId.equals(comboId))).go();

  /// Loads all combo→moves relationships in a single join query.
  /// Returns a map keyed by comboId→list of [ComboMoveWithDetail].
  /// Avoids the N+1 query problem of calling [watchComboMoves] per combo.
  Future<Map<String, List<ComboMoveWithDetail>>> getAllComboMovesMap() async {
    final query = select(comboMoves).join([
      innerJoin(moves, moves.id.equalsExp(comboMoves.moveId)),
    ])
      ..where(comboMoves.deletedAt.isNull())
      ..orderBy([OrderingTerm.asc(comboMoves.sequenceIndex)]);

    final rows = await query.get();
    final map = <String, List<ComboMoveWithDetail>>{};
    for (final row in rows) {
      final cm = row.readTable(comboMoves);
      final m = row.readTable(moves);
      map.putIfAbsent(cm.comboId, () => []).add(
            ComboMoveWithDetail(comboMove: cm, move: m.copyWith(count: cm.count)),
          );
    }
    return map;
  }

  /// Watches all combos paired with their move count via a LEFT JOIN on
  /// combo_moves grouped by comboId. Returns (Combo, int) tuples so the
  /// UI can render move-count dots without extra queries.
  Stream<List<(Combo, int)>> watchAllWithMoveCounts() {
    final countExpr = comboMoves.id.count();
    final query = select(combos).join([
      leftOuterJoin(
        comboMoves,
        comboMoves.comboId.equalsExp(combos.id) & comboMoves.deletedAt.isNull(),
      ),
    ])
      ..addColumns([countExpr])
      ..where(combos.deletedAt.isNull())
      ..groupBy([combos.id]);

    return query.watch().map((final rows) {
      final list = rows
          .map((final row) => (
                row.readTable(combos),
                row.read(countExpr) ?? 0,
              ))
          .toList();
      
      list.sort((final a, final b) {
        final sizeCmp = a.$2.compareTo(b.$2);
        if (sizeCmp != 0) return sizeCmp;
        return a.$1.name.compareTo(b.$1.name);
      });
      
      return list;
    });
  }

  /// Returns a deduplicated list of combos that reference the given [moveId].
  Future<List<Combo>> getCombosUsingMove(final String moveId) async {
    final query = select(combos).join([
      innerJoin(comboMoves, comboMoves.comboId.equalsExp(combos.id)),
    ])..where(comboMoves.moveId.equals(moveId) &
        comboMoves.deletedAt.isNull() &
        combos.deletedAt.isNull());

    final rows = await query.get();
    return rows.map((final row) => row.readTable(combos)).toSet().toList();
  }

  /// Changes the combo's status tag and appends an immutable `kind='status'`
  /// journal row in the same transaction — both or neither.
  Future<void> updateStatus({
    required final String comboId,
    required final String newStatus,
    required final String entryId,
  }) async {
    await transaction(() async {
      final combo = await getById(comboId);
      if (combo.status == newStatus) return;

      await (update(combos)..where((final t) => t.id.equals(comboId)))
          .write(_stampCombo(CombosCompanion(status: Value(newStatus))));

      await into(comboNoteEntries).insert(
        ComboNoteEntriesCompanion.insert(
          id: entryId,
          comboId: comboId,
          body: '${combo.status} → $newStatus',
          kind: const Value('status'),
        ),
      );
    });
  }

  /// Clones a combo's structure (combo + combo_moves) as a new `idea`
  /// sketch, seeding the new journal with a `kind='duplicate'` provenance
  /// row. Videos are untouched — steps reference the same moves.
  Future<void> duplicateCombo({
    required final String sourceComboId,
    required final String newComboId,
    required final String newName,
    required final String provenanceEntryId,
    required final String Function() comboMoveIdFactory,
  }) async {
    await transaction(() async {
      final source = await getById(sourceComboId);
      final sourceMoves = await (select(comboMoves)
            ..where((final t) => t.comboId.equals(sourceComboId))
            ..orderBy([(final t) => OrderingTerm.asc(t.sequenceIndex)]))
          .get();

      await into(combos).insert(
        _stampCombo(CombosCompanion.insert(
          id: newComboId,
          name: newName,
          notes: Value(source.notes),
          activeVideoPath: Value(source.activeVideoPath),
          status: const Value('idea'),
        )),
      );

      for (final cm in sourceMoves) {
        await into(comboMoves).insert(
          _stampComboMove(ComboMovesCompanion.insert(
            id: comboMoveIdFactory(),
            comboId: newComboId,
            moveId: cm.moveId,
            sequenceIndex: cm.sequenceIndex,
            count: Value(cm.count),
          )),
        );
      }

      await into(comboNoteEntries).insert(
        ComboNoteEntriesCompanion.insert(
          id: provenanceEntryId,
          comboId: newComboId,
          body: 'Duplicated from "${source.name}"',
          kind: const Value('duplicate'),
        ),
      );
    });
  }

  /// All combos with Library metadata, newest first. customSelect with
  /// explicit readsFrom so the stream re-emits on journal/step changes too.
  Stream<List<ComboWithMeta>> watchCombosWithMeta() {
    final query = customSelect(
      '''
      SELECT c.id, c.name, c.notes, c.active_video_path, c.content_hash,
             c.status, c.created_at,
        (SELECT COUNT(*) FROM combo_moves cm
          WHERE cm.combo_id = c.id AND cm.deleted_at IS NULL) AS move_count,
        (SELECT COUNT(*) FROM combo_note_entries e
          WHERE e.combo_id = c.id AND e.kind = 'jot') AS jot_count,
        (SELECT e.body FROM combo_note_entries e
          WHERE e.combo_id = c.id
          ORDER BY e.created_at DESC, e.id DESC LIMIT 1) AS last_entry_body,
        (SELECT e.kind FROM combo_note_entries e
          WHERE e.combo_id = c.id
          ORDER BY e.created_at DESC, e.id DESC LIMIT 1) AS last_entry_kind,
        (SELECT MAX(e.created_at) FROM combo_note_entries e
          WHERE e.combo_id = c.id) AS last_entry_at
      FROM combos c
      WHERE c.deleted_at IS NULL
      ORDER BY c.created_at DESC, c.name ASC
      ''',
      readsFrom: {combos, comboMoves, comboNoteEntries},
    );

    return query.watch().map((final rows) => rows.map((final row) {
          final lastEntryAt = row.readNullable<int>('last_entry_at');
          return ComboWithMeta(
            combo: Combo(
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              notes: row.readNullable<String>('notes'),
              activeVideoPath: row.readNullable<String>('active_video_path'),
              contentHash: row.readNullable<String>('content_hash'),
              status: row.read<String>('status'),
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                row.read<int>('created_at') * 1000,
              ),
            ),
            moveCount: row.read<int>('move_count'),
            jotCount: row.read<int>('jot_count'),
            lastEntryBody: row.readNullable<String>('last_entry_body'),
            lastEntryKind: row.readNullable<String>('last_entry_kind'),
            lastEntryAt: lastEntryAt != null
                ? DateTime.fromMillisecondsSinceEpoch(lastEntryAt * 1000)
                : null,
          );
        }).toList());
  }

  /// Per-day journal activity (jots, and jots carrying a video reference)
  /// for the calendar heat map. Days are local dates.
  Stream<List<DayActivity>> watchActivityRollup() {
    final query = customSelect(
      '''
      SELECT date(created_at, 'unixepoch', 'localtime') AS day,
        SUM(CASE WHEN kind = 'jot' THEN 1 ELSE 0 END) AS jot_count,
        SUM(CASE WHEN kind = 'jot'
              AND (video_path IS NOT NULL OR video_hash IS NOT NULL)
            THEN 1 ELSE 0 END) AS take_count
      FROM combo_note_entries e
      WHERE EXISTS (SELECT 1 FROM combos c
        WHERE c.id = e.combo_id AND c.deleted_at IS NULL)
      GROUP BY day
      ORDER BY day ASC
      ''',
      readsFrom: {comboNoteEntries, combos},
    );

    return query.watch().map((final rows) => rows
        .map((final row) => DayActivity(
              day: DateTime.parse(row.read<String>('day')),
              jotCount: row.read<int>('jot_count'),
              takeCount: row.read<int>('take_count'),
            ))
        .toList());
  }

  /// Single-query Library feed: combos + transition chain names + meta.
  /// Uses GROUP_CONCAT on moves ordered by sequence_index for the chain.
  Stream<List<LibraryRow>> watchLibraryRows() {
    final query = customSelect(
      '''
      SELECT c.id, c.name, c.notes, c.active_video_path, c.content_hash,
             c.status, c.created_at, c.updated_at,
        (SELECT GROUP_CONCAT(m.name, ' → ')
         FROM combo_moves cm
         JOIN moves m ON m.id = cm.move_id
         WHERE cm.combo_id = c.id AND cm.deleted_at IS NULL
         ORDER BY cm.sequence_index) AS transition_chain,
        (SELECT COUNT(*) FROM combo_moves cm
          WHERE cm.combo_id = c.id AND cm.deleted_at IS NULL) AS move_count,
        (SELECT COUNT(*) FROM combo_note_entries e
          WHERE e.combo_id = c.id AND e.kind = 'jot') AS jot_count,
        (SELECT e.body FROM combo_note_entries e
          WHERE e.combo_id = c.id
          ORDER BY e.created_at DESC, e.id DESC LIMIT 1) AS last_entry_body,
        (SELECT MAX(e.created_at) FROM combo_note_entries e
          WHERE e.combo_id = c.id) AS last_entry_at
      FROM combos c
      WHERE c.deleted_at IS NULL
      ORDER BY c.created_at DESC, c.name ASC
      ''',
      readsFrom: {combos, comboMoves, moves, comboNoteEntries},
    );

    return query.watch().map((final rows) => rows.map((final row) {
          final lastEntryAt = row.readNullable<int>('last_entry_at');
          final updatedAt = row.readNullable<int>('updated_at');
          return LibraryRow(
            combo: Combo(
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              notes: row.readNullable<String>('notes'),
              activeVideoPath: row.readNullable<String>('active_video_path'),
              contentHash: row.readNullable<String>('content_hash'),
              status: row.read<String>('status'),
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                row.read<int>('created_at') * 1000,
              ),
              // Hydrated because the "recently practiced" chain reads it for
              // combos edited but never jotted (design D2).
              updatedAt: updatedAt != null
                  ? DateTime.fromMillisecondsSinceEpoch(updatedAt * 1000)
                  : null,
            ),
            transitionChain: row.readNullable<String>('transition_chain') ?? '',
            moveCount: row.read<int>('move_count'),
            jotCount: row.read<int>('jot_count'),
            lastEntryBody: row.readNullable<String>('last_entry_body'),
            lastEntryAt: lastEntryAt != null
                ? DateTime.fromMillisecondsSinceEpoch(lastEntryAt * 1000)
                : null,
          );
        }).toList());
  }

  /// Per-day plans (planDate → count), for calendar future plan dots.
  Stream<List<(DateTime, int)>> watchPlanCountByDay() {
    final query = customSelect(
      '''
      SELECT plan_date, COUNT(*) AS plan_count
      FROM combo_plans
      GROUP BY plan_date
      ORDER BY plan_date ASC
      ''',
      readsFrom: {comboPlans},
    );

    return query.watch().map((final rows) => rows
        .map((final row) => (
              DateTime.fromMillisecondsSinceEpoch(
                row.read<int>('plan_date') * 1000,
              ),
              row.read<int>('plan_count'),
            ))
        .toList());
  }

  /// Planned tab progress strip numbers — all derived from ledger, documented.
  Stream<(int, int, int)> watchProgressStrip() {
    final query = customSelect(
      '''
      SELECT
        (SELECT COUNT(*) FROM combo_plans
          WHERE completed_at IS NOT NULL) AS landed_count,
        (SELECT COUNT(DISTINCT e.combo_id) FROM combo_note_entries e
          WHERE e.kind = 'jot'
            AND EXISTS (SELECT 1 FROM combos c
              WHERE c.id = e.combo_id AND c.deleted_at IS NULL))
            AS practiced_count,
        (SELECT COUNT(*) FROM combo_plans) AS total_plans_count
      ''',
      readsFrom: {comboPlans, comboNoteEntries, combos},
    );

    return query.watch().map((final rows) {
      final row = rows.first;
      return (
        row.read<int>('landed_count'),
        row.read<int>('practiced_count'),
        row.read<int>('total_plans_count'),
      );
    });
  }

  /// Combo move videos for the library video picker "THIS COMBO'S MOVES"
  /// section: move name, filename, path, size, duration, usage counts.
  Future<List<(Move, int)>> getComboMoveVideos(final String comboId) async {
    final query = select(comboMoves).join([
      innerJoin(moves, moves.id.equalsExp(comboMoves.moveId)),
    ])
      ..where(comboMoves.comboId.equals(comboId) & comboMoves.deletedAt.isNull())
      ..where(moves.videoPath.isNotNull())
      ..orderBy([OrderingTerm.asc(comboMoves.sequenceIndex)]);

    final rows = await query.get();
    return rows.map((final row) {
      final m = row.readTable(moves);
      return (m, 0);
    }).toList();
  }
}
