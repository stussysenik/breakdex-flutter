import 'dart:async';
import 'dart:convert';

import 'package:breakdex/core/sync/providers/gdrive_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Minimal HTTP client so a real [drive.DriveApi] can be constructed without
/// touching the network — the tests only assert on the restore *logic*.
class _FakeClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(final http.BaseRequest request) async =>
      http.StreamedResponse(const Stream.empty(), 200);
}

/// Returns a canned JSON body for any Drive API request — enough to let a real
/// operation run past the auth gate without a live network.
class _JsonClient extends http.BaseClient {
  _JsonClient(this.body);
  final String body;

  @override
  Future<http.StreamedResponse> send(final http.BaseRequest request) async =>
      http.StreamedResponse(
        Stream.value(utf8.encode(body)),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
}

/// Returns a Google-style error body with the given HTTP status so a real Drive
/// op throws [drive.DetailedApiRequestError] with that status — models an
/// expired/revoked access token (401) or a forbidden one (403).
class _StatusClient extends http.BaseClient {
  _StatusClient(this.code);
  final int code;

  @override
  Future<http.StreamedResponse> send(final http.BaseRequest request) async =>
      http.StreamedResponse(
        Stream.value(
          utf8.encode('{"error":{"code":$code,"message":"token expired"}}'),
        ),
        code,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
}

void main() {
  group('GDriveProvider session restore', () {
    // The bug: cloudProvidersProvider rebuilds a *fresh* GDriveProvider from the
    // DB row and never calls authenticate(), so isAuthenticated was always false
    // even though the native Google session is cached — uploads silently skipped.
    test(
      'isAuthenticated restores a cached session on a fresh instance',
      () async {
        var restoreCalls = 0;
        final api = drive.DriveApi(_FakeClient());
        final provider = GDriveProvider(
          restoreSession: () async {
            restoreCalls++;
            return api;
          },
        );

        expect(await provider.isAuthenticated, isTrue);
        expect(restoreCalls, 1);
      },
    );

    test('isAuthenticated is false when no cached session exists', () async {
      final provider = GDriveProvider(restoreSession: () async => null);

      expect(await provider.isAuthenticated, isFalse);
    });

    test('restores at most once, then reuses the session', () async {
      var restoreCalls = 0;
      final api = drive.DriveApi(_FakeClient());
      final provider = GDriveProvider(
        restoreSession: () async {
          restoreCalls++;
          return api;
        },
      );

      await provider.isAuthenticated;
      await provider.isAuthenticated;

      expect(restoreCalls, 1);
    });

    // AssetSyncEngine calls upload() cold (no isAuthenticated gate), so file
    // ops must self-heal too — otherwise video uploads throw after restart.
    test('a file operation restores the session before running', () async {
      var restoreCalls = 0;
      final api = drive.DriveApi(_JsonClient('{"files": []}'));
      final provider = GDriveProvider(
        restoreSession: () async {
          restoreCalls++;
          return api;
        },
      )..configFolderId = 'folder-123';

      final result = await provider.list(directory: 'breakdex');

      expect(restoreCalls, 1);
      expect(result, isEmpty);
    });

    // A burst of file ops on a fresh instance (manifest sync + asset engine
    // racing at launch) must trigger ONE silent sign-in, not one per caller.
    test('concurrent ops share a single in-flight restore', () async {
      var restoreCalls = 0;
      final gate = Completer<void>();
      final api = drive.DriveApi(_JsonClient('{"files": []}'));
      final provider = GDriveProvider(
        restoreSession: () async {
          restoreCalls++;
          await gate.future; // hold both callers until they're queued
          return api;
        },
      )..configFolderId = 'folder-123';

      final f1 = provider.isAuthenticated;
      final f2 = provider.list(directory: 'breakdex');
      gate.complete();
      await Future.wait<dynamic>([f1, f2]);

      expect(restoreCalls, 1);
    });

    // Long sessions outlive a Google access token (~1h). When the cached client
    // is rejected (401), the op must drop it, restore a fresh session, and
    // retry once — otherwise uploads silently fail until the app restarts.
    test('a 401 invalidates the client, restores fresh, and retries', () async {
      var restoreCalls = 0;
      final staleApi = drive.DriveApi(_StatusClient(401));
      final freshApi = drive.DriveApi(_JsonClient('{"files": []}'));
      final provider = GDriveProvider(
        restoreSession: () async {
          restoreCalls++;
          return restoreCalls == 1 ? staleApi : freshApi;
        },
      )..configFolderId = 'folder-123';

      final result = await provider.list(directory: 'breakdex');

      expect(restoreCalls, 2); // stale client dropped, fresh one minted
      expect(result, isEmpty);
    });
  });
}
