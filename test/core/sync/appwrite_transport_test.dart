import 'package:breakdex/core/sync/backends/appwrite_transport.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for the pure [decodeExecutionResult] — the decode + error-envelope
/// logic that is the substance of task 2.1. The concrete
/// `AppwriteFunctionsTransport` is thin glue over the SDK and is exercised by
/// task 2.3's parity tests against the [AppwriteTransport] seam.
void main() {
  group('decodeExecutionResult — success', () {
    test('completed 200 returns the decoded body (sync-push shape)', () {
      final value = decodeExecutionResult(
        status: 'completed',
        responseStatusCode: 200,
        responseBody: '{"applied":2,"skipped":1,"failed":0}',
        errors: '',
        functionId: 'sync-push',
      );
      expect(value, {'applied': 2, 'skipped': 1, 'failed': 0});
    });

    test('completed 200 decodes the sync-pull delta shape', () {
      final value = decodeExecutionResult(
        status: 'completed',
        responseStatusCode: 200,
        responseBody:
            '{"upserts":[{"id":"m1","json":{"name":"Six Step"},'
            '"updatedAt":1000,"clientOpId":"op-1"}],'
            '"deletes":[],"cursor":1000}',
        errors: '',
      )! as Map;
      expect((value['upserts'] as List).single, {
        'id': 'm1',
        'json': {'name': 'Six Step'},
        'updatedAt': 1000,
        'clientOpId': 'op-1',
      });
      expect(value['cursor'], 1000);
    });

    test('completed 200 with an empty body returns null', () {
      expect(
        decodeExecutionResult(
          status: 'completed',
          responseStatusCode: 200,
          responseBody: '',
          errors: '',
        ),
        isNull,
      );
    });

    test('completed 200 with a malformed body returns null (not an error)', () {
      expect(
        decodeExecutionResult(
          status: 'completed',
          responseStatusCode: 200,
          responseBody: 'not json',
          errors: '',
        ),
        isNull,
      );
    });
  });

  group('decodeExecutionResult — Function error envelope', () {
    test('401 surfaces the {error} field (missing session)', () {
      expect(
        () => decodeExecutionResult(
          status: 'completed',
          responseStatusCode: 401,
          responseBody: '{"error":"unauthenticated: missing x-appwrite-user-id"}',
          errors: '',
          functionId: 'sync-pull',
        ),
        throwsA(
          isA<AppwriteException>()
              .having((final e) => e.message, 'message',
                  'unauthenticated: missing x-appwrite-user-id')
              .having((final e) => e.functionId, 'functionId', 'sync-pull'),
        ),
      );
    });

    test('400 surfaces the {error} field (bad payload)', () {
      expect(
        () => decodeExecutionResult(
          status: 'completed',
          responseStatusCode: 400,
          responseBody: '{"error":"unsupported table: \\"widgets\\"."}',
          errors: '',
        ),
        throwsA(
          isA<AppwriteException>().having(
            (final e) => e.message,
            'message',
            'unsupported table: "widgets".',
          ),
        ),
      );
    });

    test('non-JSON error body falls back to HTTP status + raw body', () {
      expect(
        () => decodeExecutionResult(
          status: 'completed',
          responseStatusCode: 500,
          responseBody: 'Internal Server Error',
          errors: '',
        ),
        throwsA(
          isA<AppwriteException>().having(
            (final e) => e.message,
            'message',
            'HTTP 500: Internal Server Error',
          ),
        ),
      );
    });

    test('error status with an envelope lacking "error" falls back', () {
      expect(
        () => decodeExecutionResult(
          status: 'completed',
          responseStatusCode: 403,
          responseBody: '{"detail":"forbidden"}',
          errors: '',
        ),
        throwsA(
          isA<AppwriteException>().having(
            (final e) => e.message,
            'message',
            'HTTP 403: {"detail":"forbidden"}',
          ),
        ),
      );
    });
  });

  group('decodeExecutionResult — runtime failure', () {
    test('failed status surfaces the runtime errors, ignoring the body', () {
      expect(
        () => decodeExecutionResult(
          status: 'failed',
          responseStatusCode: 200,
          responseBody: '{"applied":0}',
          errors: 'RangeError: index out of range',
          functionId: 'reviews-append',
        ),
        throwsA(
          isA<AppwriteException>()
              .having((final e) => e.message, 'message',
                  'RangeError: index out of range')
              .having((final e) => e.functionId, 'functionId', 'reviews-append'),
        ),
      );
    });

    test('failed status with empty errors uses a generic message', () {
      expect(
        () => decodeExecutionResult(
          status: 'failed',
          responseStatusCode: 0,
          responseBody: '',
          errors: '',
        ),
        throwsA(
          isA<AppwriteException>().having(
            (final e) => e.message,
            'message',
            'function execution failed',
          ),
        ),
      );
    });
  });

  group('AppwriteException.toString', () {
    test('includes the functionId when present', () {
      expect(
        const AppwriteException('boom', functionId: 'sync-push').toString(),
        'AppwriteException(sync-push: boom)',
      );
    });

    test('omits the prefix when functionId is null', () {
      expect(
        const AppwriteException('boom').toString(),
        'AppwriteException(boom)',
      );
    });
  });
}
