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
  AppwriteRemoteConfigSource({required final Client client})
    : _tables = TablesDB(client),
      _realtime = Realtime(client);

  final TablesDB _tables;
  final Realtime _realtime;

  @override
  Future<Map<String, Object?>> fetch() async {
    final row = await _tables.getRow(
      databaseId: kAppwriteDatabaseId,
      tableId: kAppConfigTableId,
      rowId: kAppConfigRowId,
    );
    return row.data;
  }

  @override
  Stream<Map<String, Object?>> subscribe() {
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
