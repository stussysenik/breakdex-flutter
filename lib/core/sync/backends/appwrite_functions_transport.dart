import 'dart:convert';

import 'package:appwrite/appwrite.dart' as aw;
import 'package:appwrite/enums.dart' as enums;
import 'package:appwrite/models.dart' as models;

import 'appwrite_transport.dart';

/// [AppwriteTransport] over the Appwrite client SDK's `Functions` service —
/// `POST /functions/{id}/executions`, body the JSON-encoded op, response an
/// [models.Execution] whose `responseBody` carries the Function's own JSON.
///
/// The SDK is imported under the `aw`/`enums`/`models` prefixes so its own
/// `AppwriteException` never collides with this seam's [AppwriteException]. This
/// class is the only Dart code in the sync path aware the backend is Appwrite;
/// [AppwriteSyncBackend] (task 2.2) depends on the [AppwriteTransport] seam.
///
/// Auth rides the injected [aw.Client]: once a Phase-3 session is set on the
/// client, Appwrite stamps the trusted `x-appwrite-user-id` header on every
/// execution — this transport never passes a client-supplied user id.
class AppwriteFunctionsTransport implements AppwriteTransport {
  AppwriteFunctionsTransport(final aw.Client client)
    : _functions = aw.Functions(client);

  final aw.Functions _functions;

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
}
