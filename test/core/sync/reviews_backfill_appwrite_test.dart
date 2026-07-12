/// Wave task 4.5 — `reviews` backfill → Appwrite shadow, byte-identical proof
/// (mirrors `combos_backfill_appwrite_test.dart`, but through `reviews-append`).
///
/// The events `SyncBackfillService.backfillReviews` produces reach the
/// `reviews-append` Function wire unchanged (same ids, clocks, rating index,
/// entity + deterministic clientOpId as the local codec projection), a legacy
/// row with no identifiable entity is skipped, and the local table is
/// byte-identical afterward. The live smoke-user push rides M.3.
library;

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/sync/backends/appwrite_sync_backend.dart';
import 'package:breakdex/core/sync/backends/appwrite_transport.dart';
import 'package:breakdex/core/sync/backfill/sync_backfill_service.dart';
import 'package:breakdex/core/sync/codecs/review_codec.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturingTransport implements AppwriteTransport {
  final List<({String functionId, Map<String, Object?> body})> executions = [];

  @override
  Future<Object?> execute(
    final String functionId, {
    final Map<String, Object?> body = const {},
  }) async {
    executions.add((functionId: functionId, body: body));
    return {'applied': 1, 'skipped': 0, 'failed': 0};
  }

  @override
  Future<List<Map<String, Object?>>> listRows(
    final String table, {
    required final String orderField,
    final int? since,
  }) async => const [];

  @override
  Stream<void>? channelEvents(final List<String> channels) => null;
}

AppDatabase _freshDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<List<Map<String, dynamic>>> _snapshot(final AppDatabase db) async {
  final rows = await db.customSelect('SELECT * FROM reviews ORDER BY id').get();
  return rows.map((final r) => r.data).toList();
}

Future<void> _insert(
  final AppDatabase db, {
  required final String id,
  required final String rating,
  final String? moveId,
  final String? comboId,
  final String? entityIdSnapshot,
  final String? entityType,
}) => db.into(db.reviews).insert(
      ReviewsCompanion.insert(
        id: id,
        rating: rating,
        reviewType: ReviewType.move.dbValue,
        moveId: Value(moveId),
        comboId: Value(comboId),
        entityIdSnapshot: Value(entityIdSnapshot),
        entityType: Value(entityType),
      ),
    );

void main() {
  test('backfill → reviews-append emits byte-identical events; skips unencodable', () async {
    final db = _freshDb();
    await _insert(db, id: 'r1', rating: ReviewRating.good.dbValue, entityIdSnapshot: 'm1', entityType: 'move');
    await _insert(db, id: 'r2', rating: ReviewRating.easy.dbValue, comboId: 'c1');
    // Legacy row: no snapshot and no FK → unencodable → must be skipped.
    await _insert(db, id: 'r3', rating: ReviewRating.again.dbValue);

    final expected = <String, SyncRecord>{};
    for (final r in await db.reviewsDao.getAllOrdered()) {
      final rec = reviewToSyncRecord(r);
      if (rec != null) expected[r.id] = rec;
    }
    expect(expected.keys, unorderedEquals({'r1', 'r2'}));

    final transport = _CapturingTransport();
    final service = SyncBackfillService(
      AppwriteSyncBackend(transport),
      db.movesDao,
      reviewsDao: db.reviewsDao,
    );

    final before = await _snapshot(db);
    final report = await service.backfillReviews();
    expect(report.recordCount, 2); // r3 filtered out

    // Every capture routed to reviews-append with the flattened event shape.
    final events = <Map<String, Object?>>[];
    for (final e in transport.executions) {
      expect(e.functionId, 'reviews-append');
      events.addAll((e.body['events']! as List).cast<Map<String, Object?>>());
    }
    for (final ev in events) {
      final rec = expected[ev['localId']]!;
      expect(ev['clientOpId'], rec.clientOpId);
      expect(ev['reviewedAt'], rec.updatedAt.millisecondsSinceEpoch);
      expect(ev['entityId'], rec.json['entityId']);
      expect(ev['entityType'], rec.json['entityType']);
      expect(ev['rating'], rec.json['rating']);
    }
    expect(events.map((final e) => e['localId']).toSet(), {'r1', 'r2'});

    // Non-destructive: local table unchanged.
    expect(await _snapshot(db), before);
    await db.close();
  });
}
