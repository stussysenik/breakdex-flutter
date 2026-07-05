import '../sync_backend.dart';
import 'convex_transport.dart';

/// Convex implementation of [SyncBackend]. Maps the provider-neutral contract
/// onto the functions in `convex/` — `sync.ts` (descriptive last-writer-wins),
/// `reviews.ts` (append-only events), `fsrs.ts` (derived cards) — through a
/// single swappable [ConvexTransport] (design Decision 6). This class is the
/// *only* Dart code aware that the metadata backend is Convex; callers depend
/// on [SyncBackend].
class ConvexSyncBackend implements SyncBackend {
  ConvexSyncBackend(
    this._transport, {
    final Duration pollInterval = const Duration(seconds: 10),
  }) : _pollInterval = pollInterval;

  final ConvexTransport _transport;

  /// Interval for the [subscribe] fallback poll when the transport is not
  /// reactive (see [_poll]). Ignored once a reactive transport supplies
  /// [ConvexTransport.watch].
  final Duration _pollInterval;

  @override
  String get providerType => 'convex';

  /// The `descriptiveTable` union in `sync.ts` — the entities served by the
  /// shared last-writer-wins `sync:pushRecords` / `sync:pullRecords` pair.
  static const Map<SyncEntityType, String> _descriptiveTable = {
    SyncEntityType.move: 'moves',
    SyncEntityType.combo: 'combos',
    SyncEntityType.comboMove: 'comboMoves',
    SyncEntityType.deck: 'decks',
    SyncEntityType.deckMove: 'deckMoves',
  };

  @override
  Future<void> push(
    final SyncEntityType type, {
    final List<SyncRecord> upserts = const [],
    final List<SyncTombstone> deletes = const [],
  }) async {
    switch (type) {
      case SyncEntityType.fsrsCard:
        throw StateError(
          'fsrsCard is derived server-side from reviewEvents and must never be '
          'pushed (see SyncBackend.push / design Decision 7).',
        );
      case SyncEntityType.reviewEvent:
        if (deletes.isNotEmpty) {
          throw StateError('reviewEvent is append-only; it has no deletes.');
        }
        if (upserts.isEmpty) return;
        await _transport.mutation(
          'reviews:appendReviewEvents',
          args: {'events': upserts.map(_reviewEventArg).toList()},
        );
      case SyncEntityType.move:
      case SyncEntityType.combo:
      case SyncEntityType.comboMove:
      case SyncEntityType.deck:
      case SyncEntityType.deckMove:
        if (upserts.isEmpty && deletes.isEmpty) return;
        await _transport.mutation(
          'sync:pushRecords',
          args: {
            'table': _descriptiveTable[type],
            'upserts': upserts.map(_recordArg).toList(),
            'deletes': deletes.map(_tombstoneArg).toList(),
          },
        );
    }
  }

  @override
  Future<SyncDelta> pull(
    final SyncEntityType type, {
    final DateTime? since,
  }) async {
    final value = await _transport.query(
      _pullPath(type),
      args: _pullArgs(type, since),
    );
    return _decodeDelta(type, value);
  }

  @override
  Stream<SyncDelta> subscribe(final SyncEntityType type) {
    final reactive = _transport.watch(
      _pullPath(type),
      args: _pullArgs(type, null),
    );
    if (reactive != null) {
      return reactive.map((final value) => _decodeDelta(type, value));
    }
    return _poll(type);
  }

  /// HTTP fallback for [subscribe]: re-pull on [_pollInterval], advancing an
  /// internal cursor and emitting only non-empty deltas. A reactive transport
  /// ([ConvexTransport.watch]) replaces this with a true server-pushed stream.
  Stream<SyncDelta> _poll(final SyncEntityType type) async* {
    DateTime? cursor;
    while (true) {
      final delta = await pull(type, since: cursor);
      if (!delta.isEmpty) {
        cursor = delta.cursor ?? cursor;
        yield delta;
      }
      await Future<void>.delayed(_pollInterval);
    }
  }

  String _pullPath(final SyncEntityType type) {
    switch (type) {
      case SyncEntityType.reviewEvent:
        return 'reviews:pullReviewEvents';
      case SyncEntityType.fsrsCard:
        return 'fsrs:pullCards';
      case SyncEntityType.move:
      case SyncEntityType.combo:
      case SyncEntityType.comboMove:
      case SyncEntityType.deck:
      case SyncEntityType.deckMove:
        return 'sync:pullRecords';
    }
  }

  Map<String, Object?> _pullArgs(
    final SyncEntityType type,
    final DateTime? since,
  ) {
    return {
      'table': ?_descriptiveTable[type],
      'since': ?since?.millisecondsSinceEpoch,
    };
  }

  // --- Marshalling: Dart contract types -> Convex function args -------------

  Map<String, Object?> _recordArg(final SyncRecord r) => {
    'localId': r.id,
    'json': r.json,
    'updatedAt': r.updatedAt.millisecondsSinceEpoch,
    'clientOpId': r.clientOpId,
  };

  Map<String, Object?> _tombstoneArg(final SyncTombstone t) => {
    'localId': t.id,
    'deletedAt': t.deletedAt.millisecondsSinceEpoch,
    'clientOpId': t.clientOpId,
  };

  /// A [reviewEvent] carries its domain fields inside [SyncRecord.json]
  /// (`entityId`, `entityType`, `rating`); `reviewedAt` is [SyncRecord.updatedAt]
  /// — mirroring how `reviews.ts` reads events back out.
  Map<String, Object?> _reviewEventArg(final SyncRecord r) => {
    'localId': r.id,
    'entityId': r.json['entityId'],
    'entityType': r.json['entityType'],
    'rating': r.json['rating'],
    'reviewedAt': r.updatedAt.millisecondsSinceEpoch,
    'clientOpId': r.clientOpId,
  };

  // --- Unmarshalling: Convex query value -> Dart contract types -------------

  SyncDelta _decodeDelta(final SyncEntityType type, final Object? value) {
    final map = (value! as Map).cast<String, dynamic>();
    final upserts = (map['upserts'] as List? ?? const [])
        .map(
          (final e) => _decodeRecord(type, (e as Map).cast<String, dynamic>()),
        )
        .toList();
    final deletes = (map['deletes'] as List? ?? const [])
        .map(
          (final e) =>
              _decodeTombstone(type, (e as Map).cast<String, dynamic>()),
        )
        .toList();
    final cursor = map['cursor'];
    return SyncDelta(
      upserts: upserts,
      deletes: deletes,
      cursor: cursor == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch((cursor as num).toInt()),
    );
  }

  SyncRecord _decodeRecord(
    final SyncEntityType type,
    final Map<String, dynamic> m,
  ) => SyncRecord(
    id: m['id'] as String,
    type: type,
    json: (m['json'] as Map?)?.cast<String, dynamic>() ?? const {},
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      (m['updatedAt'] as num).toInt(),
    ),
    clientOpId: m['clientOpId'] as String,
  );

  SyncTombstone _decodeTombstone(
    final SyncEntityType type,
    final Map<String, dynamic> m,
  ) => SyncTombstone(
    id: m['id'] as String,
    type: type,
    deletedAt: DateTime.fromMillisecondsSinceEpoch(
      (m['deletedAt'] as num).toInt(),
    ),
    clientOpId: m['clientOpId'] as String,
  );
}
