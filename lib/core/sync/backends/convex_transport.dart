/// The single seam between [ConvexSyncBackend] and a concrete Convex client.
///
/// Per design Decision 6 (`openspec/changes/add-convex-sync-backend`), the
/// Convex implementation of `SyncBackend` is the *only* code that touches a
/// client, so the client can be swapped without touching any caller.
/// [ConvexHttpTransport] is the working implementation (Convex's HTTP API); a
/// reactive transport wrapping the community `convex_flutter` package can drop
/// in later to provide true realtime [ConvexTransport.watch] streams — until
/// then the backend polls [ConvexTransport.query] as the fallback.
library;

/// Thrown when a Convex function returns `status: "error"`, when the deployment
/// answers with a non-success HTTP status, or when the transport cannot reach
/// the deployment at all.
class ConvexException implements Exception {
  const ConvexException(this.message, {this.path});

  /// Human-readable failure detail (Convex `errorMessage`, or a transport hint).
  final String message;

  /// The `'module:function'` that failed, when known.
  final String? path;

  @override
  String toString() =>
      'ConvexException(${path == null ? '' : '$path: '}$message)';
}

/// A minimal, provider-neutral view of a Convex deployment: run a query, run a
/// mutation, and (optionally) watch a query reactively.
abstract interface class ConvexTransport {
  /// Run the query named [path] (`'module:function'`) with [args] and return
  /// its decoded `value`. Throws [ConvexException] on failure.
  Future<Object?> query(
    final String path, {
    final Map<String, Object?> args = const {},
  });

  /// Run the mutation named [path] with [args]; returns its decoded `value`.
  /// Throws [ConvexException] on failure.
  Future<Object?> mutation(
    final String path, {
    final Map<String, Object?> args = const {},
  });

  /// Reactive stream of the query's `value`, or `null` if this transport cannot
  /// subscribe (e.g. [ConvexHttpTransport]). When `null`, the backend falls
  /// back to polling [query] — the Decision-6 HTTP fallback.
  Stream<Object?>? watch(
    final String path, {
    final Map<String, Object?> args = const {},
  }) => null;
}
