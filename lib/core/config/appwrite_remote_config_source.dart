import 'dart:async';

import 'package:appwrite/appwrite.dart';

import 'appwrite_env.dart';
import 'remote_config.dart';

/// The only file that touches the Appwrite SDK for remote config.
///
/// Reads the `appConfig` singleton row via [TablesDB.getRow] and tracks live
/// edits via Appwrite [Realtime] on the row's channel
/// (`tablesdb.breakdex.tables.appConfig.rows.current`, built with the SDK's own
/// [Channel] builder so it stays correct across SDK versions). The subscription
/// closes its socket on cancel, so a disposed provider leaks nothing.
class AppwriteRemoteConfigSource implements RemoteConfigSource {
  AppwriteRemoteConfigSource({
    required final Client client,
    final bool sessionActive = false,
  }) : _tables = TablesDB(client),
       _realtime = Realtime(client),
       _sessionActive = sessionActive;

  final TablesDB _tables;
  final Realtime _realtime;

  /// Whether an Appwrite identity session is currently active (wave task 3.3).
  /// The `appConfig` row is readable only by the `users` role, so the live path
  /// is only viable with a session. Injected per-build by the provider from the
  /// auth state — see [remoteConfigSourceProvider].
  final bool _sessionActive;

  /// The live path fires only when a session exists (or a build-time override is
  /// set for testing). Without a session it would CORS-fail the fetch and spin a
  /// futile Realtime reconnect loop — the regression a signed-out boot must never
  /// hit (1R.3). Session presence now drives it, not the compile default.
  bool get _live => _sessionActive || kRemoteConfigLiveEnabled;

  @override
  Future<Map<String, Object?>> fetch() async {
    // No session ⇒ signal "unavailable" so the service keeps its
    // cache-or-defaults fallback without a doomed network request.
    if (!_live) {
      throw StateError('Remote-config live path inactive (no Appwrite session).');
    }
    final row = await _tables.getRow(
      databaseId: kAppwriteDatabaseId,
      tableId: kAppConfigTableId,
      rowId: kAppConfigRowId,
    );
    return row.data;
  }

  @override
  Stream<Map<String, Object?>> subscribe() {
    // No session ⇒ the Realtime socket would only reconnect-loop against a
    // channel this client can't read. Stay inert until a session exists.
    if (!_live) return const Stream.empty();
    final channel = Channel.tablesdb(
      kAppwriteDatabaseId,
    ).table(kAppConfigTableId).row(kAppConfigRowId);

    // Bridge the RealtimeSubscription onto a controller so cancelling the
    // listener (provider dispose) tears the websocket down deterministically.
    late final StreamController<Map<String, Object?>> controller;
    late final RealtimeSubscription subscription;
    StreamSubscription<RealtimeMessage>? inner;

    controller = StreamController<Map<String, Object?>>(
      onListen: () {
        subscription = _realtime.subscribe([channel]);
        inner = subscription.stream.listen(
          (final message) => controller.add(message.payload),
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onCancel: () async {
        await inner?.cancel();
        await subscription.close();
      },
    );

    return controller.stream;
  }
}
