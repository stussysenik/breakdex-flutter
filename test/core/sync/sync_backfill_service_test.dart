import 'dart:convert';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/backfill/sync_backfill_service.dart';
import 'package:breakdex/core/sync/codecs/move_codec.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every push; never touches a real backend.
class _FakeBackend implements SyncBackend {
  final List<({SyncEntityType type, List<SyncRecord> upserts, List<SyncTombstone> deletes})>
      pushes = [];

  @override
  String get providerType => 'fake';

  @override
  Future<void> push(
    final SyncEntityType type, {
    final List<SyncRecord> upserts = const [],
    final List<SyncTombstone> deletes = const [],
  }) async {
    pushes.add((type: type, upserts: upserts, deletes: deletes));
  }

  @override
  Future<SyncDelta> pull(final SyncEntityType type, {final DateTime? since}) async =>
      const SyncDelta(upserts: [], deletes: []);

  @override
  Stream<SyncDelta> subscribe(final SyncEntityType type) => const Stream.empty();
}

/// Fresh full-schema (v23) in-memory database — onCreate builds every column,
/// so moves rows are complete.
AppDatabase _freshDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<void> _seedMove(
  final AppDatabase db, {
  required final String id,
  required final String name,
  final BigInt? videoFileSize,
  final DateTime? archivedAt,
}) {
  return db.movesDao.insertMove(
    MovesCompanion.insert(
      id: id,
      name: name,
      videoFileSize: Value(videoFileSize),
      archivedAt: Value(archivedAt),
    ),
  );
}

/// Every move row as a comparable map — the snapshot used to prove backfill
/// leaves local state byte-identical.
Future<List<Map<String, dynamic>>> _snapshotMoves(final AppDatabase db) async {
  final rows = await db
      .customSelect('SELECT * FROM moves ORDER BY id')
      .get();
  return rows.map((final r) => r.data).toList();
}

void main() {
  group('moveToSyncRecord', () {
    test('projects a move to a JSON-encodable record with all fields', () async {
      final db = _freshDb();
      await _seedMove(
        db,
        id: 'm1',
        name: 'Windmill',
        videoFileSize: BigInt.parse('9007199254740993'), // > 2^53, lossy as num
      );
      final move = await db.movesDao.getById('m1');

      final record = moveToSyncRecord(move);
      expect(record.id, 'm1');
      expect(record.type, SyncEntityType.move);
      expect(record.clientOpId, 'backfill:move:m1');
      expect(record.updatedAt, isNotNull);
      expect(record.json['name'], 'Windmill');
      // BigInt carried losslessly as a string (not a lossy JS number).
      expect(record.json['videoFileSize'], '9007199254740993');
      expect(record.json['createdAt'], isA<int>());

      // The whole record marshals through the same encoder the HTTP transport
      // uses — no BigInt/DateTime blow-up.
      final encoded = jsonEncode({
        'localId': record.id,
        'json': record.json,
        'updatedAt': record.updatedAt.millisecondsSinceEpoch,
        'clientOpId': record.clientOpId,
      });
      final round = jsonDecode(encoded) as Map<String, dynamic>;
      expect((round['json'] as Map)['videoFileSize'], '9007199254740993');

      await db.close();
    });

    test('archived move carries archive metadata (upsert, not tombstone)',
        () async {
      final db = _freshDb();
      final archivedAt = DateTime.utc(2025, 3, 1);
      await _seedMove(db, id: 'm1', name: 'Flare', archivedAt: archivedAt);
      final move = await db.movesDao.getById('m1');

      final record = moveToSyncRecord(move);
      expect(record.json['archivedAt'], archivedAt.millisecondsSinceEpoch);

      await db.close();
    });
  });

  group('SyncBackfillService.backfillMoves', () {
    test('pushes every move (including archived) as upserts, no deletes',
        () async {
      final db = _freshDb();
      await _seedMove(db, id: 'm1', name: 'Windmill');
      await _seedMove(db, id: 'm2', name: 'Flare');
      await db.movesDao.archiveMove('m2', reason: 'test');
      final backend = _FakeBackend();

      final report = await SyncBackfillService(backend, db.movesDao).backfillMoves();

      expect(report.recordCount, 2);
      final pushed = backend.pushes.expand((final p) => p.upserts).toList();
      expect(pushed.map((final r) => r.id).toSet(), {'m1', 'm2'});
      expect(
        backend.pushes.every((final p) => p.type == SyncEntityType.move),
        isTrue,
      );
      // Backfill never fabricates a delete.
      expect(backend.pushes.every((final p) => p.deletes.isEmpty), isTrue);

      await db.close();
    });

    test('is non-destructive — local moves are byte-identical afterward',
        () async {
      final db = _freshDb();
      await _seedMove(db, id: 'm1', name: 'Windmill');
      await _seedMove(db, id: 'm2', name: 'Flare');
      final before = await _snapshotMoves(db);

      await SyncBackfillService(_FakeBackend(), db.movesDao).backfillMoves();

      final after = await _snapshotMoves(db);
      expect(after, before);

      await db.close();
    });

    test('batches by batchSize', () async {
      final db = _freshDb();
      for (var i = 0; i < 5; i++) {
        await _seedMove(db, id: 'm$i', name: 'Move $i');
      }
      final backend = _FakeBackend();

      final report =
          await SyncBackfillService(backend, db.movesDao, batchSize: 2)
              .backfillMoves();

      expect(report.recordCount, 5);
      expect(report.batchCount, 3); // 2 + 2 + 1
      expect(backend.pushes, hasLength(3));
      expect(backend.pushes[0].upserts, hasLength(2));
      expect(backend.pushes[2].upserts, hasLength(1));

      await db.close();
    });

    test('empty database pushes nothing', () async {
      final db = _freshDb();
      final backend = _FakeBackend();

      final report = await SyncBackfillService(backend, db.movesDao).backfillMoves();

      expect(report.recordCount, 0);
      expect(report.batchCount, 0);
      expect(backend.pushes, isEmpty);

      await db.close();
    });

    test('re-running yields identical deterministic clientOpIds (idempotent)',
        () async {
      final db = _freshDb();
      await _seedMove(db, id: 'm1', name: 'Windmill');
      final backend = _FakeBackend();
      final service = SyncBackfillService(backend, db.movesDao);

      await service.backfillMoves();
      await service.backfillMoves();

      final opIds =
          backend.pushes.expand((final p) => p.upserts).map((final r) => r.clientOpId);
      expect(opIds.toSet(), {'backfill:move:m1'});

      await db.close();
    });
  });
}
