/// Wave task 4.1 — `moves` backfill → Appwrite shadow, byte-identical proof.
///
/// The generic backfill snapshot proof lives in `sync_backfill_service_test.dart`.
/// This is the 4.1 re-run **through the concrete `AppwriteSyncBackend`**: the
/// records `SyncBackfillService` produces reach the `sync-push` Function wire
/// unchanged (same ids, clocks, deterministic clientOpIds, and payload as the
/// local `moveToSyncRecord` projection), and the local `moves` table is
/// byte-identical afterward. The live smoke-user push against the deployed
/// Functions rides M.3 (real data on device); the Functions' wire contract was
/// already live-verified by 1.5's 14/14 curl smoke.
library;

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/backends/appwrite_sync_backend.dart';
import 'package:breakdex/core/sync/backends/appwrite_transport.dart';
import 'package:breakdex/core/sync/backfill/sync_backfill_service.dart';
import 'package:breakdex/core/sync/codecs/move_codec.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures every Function execution so the `sync-push` body can be asserted
/// byte-for-byte. Only `execute` is exercised by a descriptive push.
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

Future<void> _seedMove(
  final AppDatabase db, {
  required final String id,
  required final String name,
}) {
  return db.movesDao.insertMove(
    MovesCompanion.insert(id: id, name: name),
  );
}

Future<List<Map<String, dynamic>>> _snapshotMoves(final AppDatabase db) async {
  final rows =
      await db.customSelect('SELECT * FROM moves ORDER BY id').get();
  return rows.map((final r) => r.data).toList();
}

void main() {
  test('backfill → AppwriteSyncBackend emits byte-identical sync-push upserts',
      () async {
    final db = _freshDb();
    await _seedMove(db, id: 'm1', name: 'Windmill');
    await _seedMove(db, id: 'm2', name: 'Flare');
    await db.movesDao.archiveMove('m2', reason: 'test');

    // The local projection every upsert must match on the wire.
    final expected = {
      for (final move in await db.movesDao.getAllIncludingArchived())
        move.id: moveToSyncRecord(move),
    };

    final transport = _CapturingTransport();
    final backend = AppwriteSyncBackend(transport);
    final before = await _snapshotMoves(db);

    final report =
        await SyncBackfillService(backend, db.movesDao).backfillMoves();

    expect(report.recordCount, 2);
    // Every capture routed to sync-push, table 'moves', no deletes.
    expect(transport.executions, isNotEmpty);
    for (final e in transport.executions) {
      expect(e.functionId, 'sync-push');
      expect(e.body['table'], 'moves');
      expect((e.body['deletes']! as List), isEmpty);
    }

    // Flatten the wire upserts and assert byte-identity vs the local projection.
    final wireUpserts = transport.executions
        .expand((final e) => e.body['upserts']! as List)
        .cast<Map<String, Object?>>();
    expect(wireUpserts.map((final u) => u['localId']).toSet(), {'m1', 'm2'});
    for (final u in wireUpserts) {
      final rec = expected[u['localId']]!;
      expect(u['clientOpId'], rec.clientOpId);
      expect(u['updatedAt'], rec.updatedAt.millisecondsSinceEpoch);
      expect(u['json'], rec.json); // full payload, byte-identical
    }

    // Non-destructive: local moves unchanged.
    expect(await _snapshotMoves(db), before);

    await db.close();
  });
}
