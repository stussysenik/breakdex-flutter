/// The single seam between [AppwriteSyncBackend] (task 2.2) and a concrete
/// Appwrite client, mirroring the role `ConvexTransport` played for Convex
/// (design Decision 6 in `add-convex-sync-backend`): the transport is the *only*
/// code that touches an Appwrite SDK, so the client can be swapped — Cloud for
/// self-host, or the SDK for a raw HTTP client — without touching any caller.
///
/// Where Convex distinguished `query` from `mutation`, Appwrite has a single
/// primitive: every server op (`sync-push`, `sync-pull`, `reviews-append`) is a
/// Function **execution**. So this seam exposes one [execute] door; the backend
/// selects the function by id. Realtime subscription (task 2.2's `subscribe`)
/// lands separately — this file is pure (no SDK import), so the decode +
/// error-envelope logic is unit-testable with no live backend.
library;

import 'dart:convert';

/// Thrown when a Function execution fails: the runtime crashed (`status:
/// "failed"`), the Function returned a non-success HTTP status (its
/// `{error: ...}` envelope), or the SDK could not reach the deployment at all.
///
/// Named to mirror `ConvexException`. The Appwrite SDK ships its *own*
/// `AppwriteException`; the concrete transport imports the SDK under a prefix so
/// callers of this seam only ever see this wrapper.
class AppwriteException implements Exception {
  const AppwriteException(this.message, {this.functionId});

  /// Human-readable failure detail (the Function's `error` field, its runtime
  /// `errors`, or a transport hint).
  final String message;

  /// The Function id that failed, when known.
  final String? functionId;

  @override
  String toString() =>
      'AppwriteException(${functionId == null ? '' : '$functionId: '}$message)';
}

/// A minimal, provider-neutral view of an Appwrite deployment: execute a named
/// Function with a JSON body and return its decoded response.
abstract interface class AppwriteTransport {
  /// Execute the Function [functionId] with [body] (JSON-encoded as the request
  /// body) and return its decoded response value. Throws [AppwriteException] on
  /// a runtime failure or a non-success status code returned by the Function.
  Future<Object?> execute(
    final String functionId, {
    final Map<String, Object?> body = const {},
  });
}

/// Interpret one Appwrite Function execution result into its decoded value, or
/// throw [AppwriteException]. Extracted as a pure function so the decode +
/// error-envelope logic is unit-testable without a live SDK client (the concrete
/// [AppwriteTransport] is thin glue over `Functions.createExecution`, verified by
/// task 2.3's parity tests against the seam).
///
/// Mirrors `ConvexHttpTransport`'s "prefer the body's own error, fall back to
/// the HTTP status" shape, adapted to Appwrite's `Execution` model:
///   * `status == "failed"` ⇒ the runtime crashed; surface [errors].
///   * `responseStatusCode >= 400` ⇒ the Function returned an error envelope;
///     surface its `error` field, else the raw `HTTP <code>: <body>`.
///   * otherwise ⇒ return the decoded [responseBody] (or `null` if empty).
Object? decodeExecutionResult({
  required final String status,
  required final int responseStatusCode,
  required final String responseBody,
  required final String errors,
  final String? functionId,
}) {
  if (status == 'failed') {
    throw AppwriteException(
      errors.isEmpty ? 'function execution failed' : errors,
      functionId: functionId,
    );
  }

  Object? decoded;
  if (responseBody.isNotEmpty) {
    try {
      decoded = jsonDecode(responseBody);
    } on FormatException {
      decoded = null;
    }
  }

  if (responseStatusCode >= 400) {
    final envelope = decoded is Map ? decoded['error'] : null;
    throw AppwriteException(
      envelope is String && envelope.isNotEmpty
          ? envelope
          : 'HTTP $responseStatusCode: $responseBody',
      functionId: functionId,
    );
  }

  return decoded;
}
