import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart' as aw;
import 'package:appwrite/enums.dart' as enums;
import 'package:appwrite/models.dart' as models;

import 'package:breakdex/core/sync/backends/appwrite_transport.dart';

/// [AppwriteTransport] over the Appwrite client SDK — `Functions` for Function
/// executions, `TablesDB` for the direct per-user reads, and `Realtime` for the
/// subscription trigger. It is the only Dart code in the sync path aware the
/// backend is Appwrite; [AppwriteSyncBackend] (task 2.2) depends only on the
/// [AppwriteTransport] seam.
///
/// The SDK is imported under the `aw`/`enums`/`models` prefixes so its own
/// `AppwriteException` never collides with this seam's [AppwriteException].
///
/// Auth rides the injected [aw.Client]: once a Phase-3 session is set on the
/// client, Appwrite stamps the trusted `x-appwrite-user-id` header on every
/// execution and scopes every [listRows] / Realtime read to the session's own
/// rows — this transport never passes a client-supplied user id. The `TablesDB`
/// / `Realtime` doors are thin SDK glue (like [execute]); they are exercised
/// against a live deployment, while the pure marshalling they feed is unit-tested
/// through the seam (`appwrite_sync_backend_test.dart`).
class AppwriteFunctionsTransport implements AppwriteTransport {
  AppwriteFunctionsTransport(this._client)
    : _functions = aw.Functions(_client),
      _tables = aw.TablesDB(_client);

  /// TablesDB id — matches the `breakdex` database the Functions read/write.
  static const String _databaseId = 'breakdex';

  /// Page size for [listRows]; a delta larger than one page is cursor-paged to
  /// completion so it is never silently truncated (matches the Functions).
  static const int _pageSize = 100;

  final aw.Client _client;
  final aw.Functions _functions;
  final aw.TablesDB _tables;

  @override
  Future<Object?> execute(
    final String functionId, {
    final Map<String, Object?> body = const {},
  }) async {
    final models.Execution execution;
    try {
      execution = await _functions.createExecution(
        functionId: functionId,
        body: jsonEncode(body),
        method: enums.ExecutionMethod.pOST,
      );
    } on aw.AppwriteException catch (e) {
      throw AppwriteException(
        'transport error: ${e.message ?? e.type ?? e}',
        functionId: functionId,
      );
    }

    return decodeExecutionResult(
      status: execution.status.value,
      responseStatusCode: execution.responseStatusCode,
      responseBody: execution.responseBody,
      errors: execution.errors,
      functionId: functionId,
    );
  }

  @override
  Future<List<Map<String, Object?>>> listRows(
    final String table, {
    required final String orderField,
    final int? since,
  }) async {
    final out = <Map<String, Object?>>[];
    String? cursor;
    try {
      while (true) {
        final page = await _tables.listRows(
          databaseId: _databaseId,
          tableId: table,
          queries: [
            if (since != null) aw.Query.greaterThan(orderField, since),
            aw.Query.orderAsc(orderField),
            aw.Query.limit(_pageSize),
            if (cursor != null) aw.Query.cursorAfter(cursor),
          ],
        );
        for (final row in page.rows) {
          out.add(row.data.cast<String, Object?>());
        }
        if (page.rows.length < _pageSize) {
          break;
        }
        cursor = page.rows.last.$id;
      }
    } on aw.AppwriteException catch (e) {
      throw AppwriteException('transport error reading $table: ${e.message ?? e.type ?? e}');
    }
    return out;
  }

  @override
  Stream<void>? channelEvents(final List<String> channels) {
    aw.RealtimeSubscription? subscription;
    late final StreamController<void> controller;
    controller = StreamController<void>(
      onListen: () {
        final sub = aw.Realtime(_client).subscribe(channels);
        subscription = sub;
        sub.stream.listen(
          (final _) => controller.add(null),
          onError: controller.addError,
        );
      },
      onCancel: () async {
        // Close the socket so a cancelled subscribe stops all I/O (audit B1).
        await subscription?.close();
        await controller.close();
      },
    );
    return controller.stream;
  }
}
