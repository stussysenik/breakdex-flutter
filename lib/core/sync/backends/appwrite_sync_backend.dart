import 'dart:async';

import '../sync_backend.dart';
import 'appwrite_transport.dart';

/// Appwrite implementation of [SyncBackend]. Maps the provider-neutral contract
/// onto the deployed Dart Functions (`sync-push`, `sync-pull`, `reviews-append`)
/// and, for the entities those Functions do not serve, onto direct TablesDB
/// reads + Realtime — all through the single swappable [AppwriteTransport] seam.
/// This class is the *only* Dart code aware the metadata backend is Appwrite;
/// callers depend on [SyncBackend].
///
/// **Routing** (the substance of task 2.2 — Appwrite splits three ways where
/// Convex had a uniform query/mutation door):
///   * descriptive push/pull → [AppwriteTransport.execute] on `sync-push` /
///     `sync-pull` (same `{table, upserts, deletes}` / `{table, since?}` wire
///     shapes as the Convex `sync:*` ops, so the marshalling is byte-identical).
///   * `reviewEvent` push → `reviews-append` (append + server-side FSRS derive).
///   * `reviewEvent` / `fsrsCard` **pull** → [AppwriteTransport.listRows]: there
///     is no pull Function for these (the log is append-only; the card is derived),
///     so the client reads its own rows directly and marshals them here.
///   * every type's [subscribe] → one cursor-advancing re-pull loop driven by an
///     Appwrite Realtime trigger, with an interval-poll fallback; both observe
///     cancellation after every await (audit B1 — no I/O survives a cancel).
class AppwriteSyncBackend implements SyncBackend {
  AppwriteSyncBackend(
    this._transport, {
    final Duration pollInterval = const Duration(seconds: 10),
  }) : _pollInterval = pollInterval;

  final AppwriteTransport _transport;

  /// Interval for the [subscribe] poll fallback used when the transport is not
  /// reactive ([AppwriteTransport.channelEvents] returns `null`). Ignored once a
  /// Realtime trigger is available.
  final Duration _pollInterval;

  /// TablesDB id and the shared soft-delete table (match the Functions).
  static const String _databaseId = 'breakdex';
  static const String _tombstonesTable = 'tombstones';
  static const String _reviewEventsTable = 'reviewEvents';
  static const String _fsrsCardsTable = 'fsrsCards';

  @override
  String get providerType => 'appwrite';

  /// The descriptive tables served by the shared `sync-push` / `sync-pull`
  /// Functions — the exact `descriptiveTable` union the Functions accept
  /// (including the Appwrite-only note-entry tables, task 4.9).
  static const Map<SyncEntityType, String> _descriptiveTable = {
    SyncEntityType.move: 'moves',
    SyncEntityType.combo: 'combos',
    SyncEntityType.comboMove: 'comboMoves',
    SyncEntityType.deck: 'decks',
    SyncEntityType.deckMove: 'deckMoves',
    SyncEntityType.moveNoteEntry: 'moveNoteEntries',
    SyncEntityType.comboNoteEntry: 'comboNoteEntries',
  };

  bool _isDescriptive(final SyncEntityType type) =>
      _descriptiveTable.containsKey(type);

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
        await _transport.execute(
          'reviews-append',
          body: {'events': upserts.map(_reviewEventArg).toList()},
        );
      case SyncEntityType.move:
      case SyncEntityType.combo:
      case SyncEntityType.comboMove:
      case SyncEntityType.deck:
      case SyncEntityType.deckMove:
      case SyncEntityType.moveNoteEntry:
      case SyncEntityType.comboNoteEntry:
        if (upserts.isEmpty && deletes.isEmpty) return;
        await _transport.execute(
          'sync-push',
          body: {
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
    switch (type) {
      case SyncEntityType.reviewEvent:
        return _pullDirect(
          _reviewEventsTable,
          since: since,
          orderField: 'reviewedAt',
          decode: _decodeReviewEventRow,
        );
      case SyncEntityType.fsrsCard:
        return _pullDirect(
          _fsrsCardsTable,
          since: since,
          orderField: 'updatedAt',
          decode: _decodeFsrsCardRow,
        );
      case SyncEntityType.move:
      case SyncEntityType.combo:
      case SyncEntityType.comboMove:
      case SyncEntityType.deck:
      case SyncEntityType.deckMove:
      case SyncEntityType.moveNoteEntry:
      case SyncEntityType.comboNoteEntry:
        final value = await _transport.execute(
          'sync-pull',
          body: {
            'table': _descriptiveTable[type],
            if (since != null) 'since': since.millisecondsSinceEpoch,
          },
        );
        return _decodeDelta(type, value);
    }
  }

  @override
  Stream<SyncDelta> subscribe(final SyncEntityType type) {
    // Realtime when the transport supports it; interval polling otherwise. Both
    // paths run the same cursor-advancing re-pull loop in [_watch].
    final trigger = _transport.channelEvents(_channelsFor(type));
    return _watch(type, trigger);
  }

  // --- Direct-read pull (reviewEvent, fsrsCard) -----------------------------

  /// Pull the entities with no server pull Function by reading their table
  /// directly and folding the rows into a [SyncDelta]. Both are effectively
  /// append/derive-only, so a direct pull has no tombstones; the cursor is the
  /// max clock across the rows (or [since] unchanged when nothing came back —
  /// matching the Functions' high-water semantics).
  Future<SyncDelta> _pullDirect(
    final String table, {
    required final DateTime? since,
    required final String orderField,
    required final SyncRecord Function(Map<String, Object?>) decode,
  }) async {
    final rows = await _transport.listRows(
      table,
      orderField: orderField,
      since: since?.millisecondsSinceEpoch,
    );
    if (rows.isEmpty) {
      return SyncDelta(upserts: const [], deletes: const [], cursor: since);
    }
    final upserts = rows.map(decode).toList();
    final maxClock = upserts
        .map((final r) => r.updatedAt.millisecondsSinceEpoch)
        .reduce((final a, final b) => a > b ? a : b);
    return SyncDelta(
      upserts: upserts,
      deletes: const [],
      cursor: DateTime.fromMillisecondsSinceEpoch(maxClock),
    );
  }

  // --- subscribe: one re-pull loop, Realtime- or poll-driven ----------------

  /// Drive [SyncBackend.subscribe] off [trigger] (a Realtime stream) or, when
  /// [trigger] is `null`, an interval [Timer]. On listen it does one initial
  /// pull; each trigger coalesces into a cursor-advancing re-pull; a pull whose
  /// delta is empty is not emitted. Cancellation is observed after every await
  /// via [cancelled], and both the trigger subscription and the poll timer are
  /// torn down on cancel — so no I/O outlives the consumer (audit B1).
  Stream<SyncDelta> _watch(
    final SyncEntityType type,
    final Stream<void>? trigger,
  ) {
    late final StreamController<SyncDelta> controller;
    StreamSubscription<void>? triggerSub;
    Timer? pollTimer;
    DateTime? cursor;
    var cancelled = false;
    var draining = false;
    var pending = false;

    Future<void> drain() async {
      if (draining) {
        pending = true;
        return;
      }
      draining = true;
      try {
        do {
          pending = false;
          if (cancelled) return;
          final SyncDelta delta;
          try {
            delta = await pull(type, since: cursor);
          } on Object catch (error, stack) {
            if (!cancelled) controller.addError(error, stack);
            return;
          }
          if (cancelled) return; // cancelled during the pull → emit nothing
          if (!delta.isEmpty) {
            cursor = delta.cursor ?? cursor;
            controller.add(delta);
          }
        } while (pending && !cancelled);
      } finally {
        draining = false;
      }
    }

    controller = StreamController<SyncDelta>(
      onListen: () {
        unawaited(drain()); // initial full pull
        if (trigger != null) {
          triggerSub = trigger.listen(
            (final _) => unawaited(drain()),
            onError: controller.addError,
          );
        } else {
          pollTimer = Timer.periodic(_pollInterval, (final _) {
            unawaited(drain());
          });
        }
      },
      onCancel: () async {
        cancelled = true;
        pollTimer?.cancel();
        await triggerSub?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  List<String> _channelsFor(final SyncEntityType type) {
    if (_isDescriptive(type)) {
      // Descriptive deletes land in the shared tombstones table, so a delete
      // must wake the re-pull too.
      return [
        _rowsChannel(_descriptiveTable[type]!),
        _rowsChannel(_tombstonesTable),
      ];
    }
    return [
      _rowsChannel(
        type == SyncEntityType.reviewEvent
            ? _reviewEventsTable
            : _fsrsCardsTable,
      ),
    ];
  }

  String _rowsChannel(final String table) =>
      'databases.$_databaseId.tables.$table.rows';

  // --- Marshalling: Dart contract types -> Function args --------------------
  // (byte-identical to ConvexSyncBackend — the Functions accept the same shapes)

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
  /// — mirroring how `reviews-append` reads events back out.
  Map<String, Object?> _reviewEventArg(final SyncRecord r) => {
    'localId': r.id,
    'entityId': r.json['entityId'],
    'entityType': r.json['entityType'],
    'rating': r.json['rating'],
    'reviewedAt': r.updatedAt.millisecondsSinceEpoch,
    'clientOpId': r.clientOpId,
  };

  // --- Unmarshalling: descriptive delta (sync-pull) -------------------------

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

  // --- Unmarshalling: direct table rows (reviewEvent, fsrsCard) -------------

  /// A `reviewEvents` row → [SyncRecord]: domain fields fold back into [json],
  /// `reviewedAt` is the record clock (mirrors [_reviewEventArg]).
  SyncRecord _decodeReviewEventRow(final Map<String, Object?> m) => SyncRecord(
    id: m['id']! as String,
    type: SyncEntityType.reviewEvent,
    json: {
      'entityId': m['entityId'],
      'entityType': m['entityType'],
      'rating': m['rating'],
    },
    updatedAt: DateTime.fromMillisecondsSinceEpoch(_asInt(m['reviewedAt'])),
    clientOpId: m['clientOpId']! as String,
  );

  /// An `fsrsCards` row → [SyncRecord]. The derived card has no local id or
  /// client-op of its own — its identity is `(entityType, entityId)` — so the
  /// stable `entityType:entityId` composite is its [SyncRecord.id] and its
  /// `lastEventOpId` (the event it was last derived from) is the idempotency key.
  SyncRecord _decodeFsrsCardRow(final Map<String, Object?> m) {
    final entityType = m['entityType']! as String;
    final entityId = m['entityId']! as String;
    return SyncRecord(
      id: '$entityType:$entityId',
      type: SyncEntityType.fsrsCard,
      json: {
        'entityId': entityId,
        'entityType': entityType,
        'stability': m['stability'],
        'difficulty': m['difficulty'],
        'due': m['due'],
        'state': m['state'],
        'lastEventOpId': m['lastEventOpId'],
      },
      updatedAt: DateTime.fromMillisecondsSinceEpoch(_asInt(m['updatedAt'])),
      clientOpId: (m['lastEventOpId'] as String?) ?? '',
    );
  }

  int _asInt(final Object? v) => v is int ? v : (v! as num).toInt();
}
