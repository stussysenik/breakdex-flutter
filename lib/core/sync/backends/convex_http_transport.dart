import 'dart:convert';

import 'package:http/http.dart' as http;

import 'convex_transport.dart';

/// [ConvexTransport] over Convex's HTTP API — `POST <url>/api/query` and
/// `POST <url>/api/mutation`, body `{path, args, format: "json"}`, response
/// `{status: "success", value}` or `{status: "error", errorMessage}`.
///
/// Stateless and fully unit-testable with a mock [http.Client]; it needs no
/// native code, so it runs in headless/CI contexts where the native
/// `convex_flutter` core cannot. It holds no socket, so it cannot subscribe:
/// [watch] returns `null` and the backend polls.
class ConvexHttpTransport implements ConvexTransport {
  ConvexHttpTransport({
    required final String deploymentUrl,
    final http.Client? httpClient,
    final String? authToken,
  }) : _base = _stripTrailingSlash(deploymentUrl),
       _http = httpClient ?? http.Client(),
       _authToken = authToken;

  /// The deployment origin, e.g. `https://brilliant-mongoose-46.convex.cloud`.
  final String _base;
  final http.Client _http;

  /// Optional bearer token; unauthenticated (public) functions omit it. Real
  /// identity-scoped auth arrives in the sibling `convex-auth-and-identity`
  /// change — this backend never trusts a client-passed userId.
  final String? _authToken;

  static String _stripTrailingSlash(final String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  @override
  Future<Object?> query(
    final String path, {
    final Map<String, Object?> args = const {},
  }) => _call('query', path, args);

  @override
  Future<Object?> mutation(
    final String path, {
    final Map<String, Object?> args = const {},
  }) => _call('mutation', path, args);

  @override
  Stream<Object?>? watch(
    final String path, {
    final Map<String, Object?> args = const {},
  }) => null;

  Future<Object?> _call(
    final String kind,
    final String path,
    final Map<String, Object?> args,
  ) async {
    final http.Response response;
    try {
      response = await _http.post(
        Uri.parse('$_base/api/$kind'),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({'path': path, 'args': args, 'format': 'json'}),
      );
    } on Exception catch (e) {
      throw ConvexException('transport error: $e', path: path);
    }

    // Convex reports application errors as a JSON `status: "error"` body, which
    // may accompany either a 200 or a 4xx/5xx. Prefer the body's own status;
    // fall back to the HTTP status only when the body is not the expected JSON.
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } on FormatException {
      body = null;
    }

    if (body != null && body['status'] == 'success') {
      return body['value'];
    }
    throw ConvexException(
      (body?['errorMessage'] as String?) ??
          'HTTP ${response.statusCode}: ${response.body}',
      path: path,
    );
  }
}
