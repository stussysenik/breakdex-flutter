// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../cloud_provider.dart';

/// Restores a Drive session without UI, returning an authenticated client or
/// `null` when no cached Google session is available. Injectable for testing.
typedef DriveApiRestorer = Future<drive.DriveApi?> Function();

/// Google Drive adapter — stores videos in a user-visible "Breakdex" folder.
///
/// Uses `DriveApi.driveFileScope` (not appDataScope) so the web viewer can
/// access files. Videos and manifest.json are stored content-addressable
/// under `Breakdex/<contentHash>.mp4` and `Breakdex/manifest.json`.
///
/// **Requirements**:
/// - `google_sign_in`, `googleapis`, `googleapis_auth` in pubspec.yaml
/// - OAuth 2.0 client ID in Google Cloud Console
/// - GoogleService-Info.plist (iOS) / google-services.json (Android)
class GDriveProvider extends CloudProvider {
  /// [restoreSession] re-hydrates a cached session without UI. Defaults to a
  /// real silent Google Sign-In; tests inject a fake.
  GDriveProvider({final DriveApiRestorer? restoreSession})
    : _restoreSession = restoreSession ?? _defaultRestoreSession;

  final DriveApiRestorer _restoreSession;

  GoogleSignInAccount? _account;
  drive.DriveApi? _driveApi;
  String? _breakdexFolderId;

  /// Shared in-flight restore so a burst of file ops triggers one silent
  /// sign-in, not one per caller.
  Future<drive.DriveApi?>? _restoreInFlight;

  /// Stored folder ID from provider config — avoids repeated lookups.
  String? configFolderId;

  static const _folderName = 'Breakdex';
  static const _folderMimeType = 'application/vnd.google-apps.folder';

  /// Resumable upload threshold: files larger than 5 MB use resumable upload.
  static const _resumableThreshold = 5 * 1024 * 1024;

  /// Whether Google Drive is configured with a valid OAuth client ID.
  ///
  /// Returns `false` until a real `GoogleService-Info.plist` (iOS) or
  /// `google-services.json` (Android) is bundled with the app. This prevents
  /// the `google_sign_in` SDK from being instantiated with a placeholder
  /// client ID, which causes a SIGABRT at launch.
  static bool get isConfigured =>
      true; // OAuth client + REVERSED_CLIENT_ID URL scheme configured

  @override
  String get providerType => 'gdrive';

  @override
  String get displayName => 'Google Drive';

  @override
  Set<CloudProviderCapability> get capabilities => {
    CloudProviderCapability.resumableUpload,
    CloudProviderCapability.rangeDownload,
    CloudProviderCapability.quota,
  };

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  @override
  Future<bool> authenticate() async {
    if (!isConfigured) {
      debugPrint('[GDriveProvider] Not configured — skipping auth');
      return false;
    }

    try {
      final googleSignIn = GoogleSignIn(
        scopes: [drive.DriveApi.driveFileScope],
      );

      // Try silent sign-in first (re-auth without UI)
      _account = await googleSignIn.signInSilently();
      _account ??= await googleSignIn.signIn();

      if (_account == null) return false;

      _driveApi = await _buildDriveApi(_account!);
      await _ensureBreakdexFolder();
      // Surface the resolved folder ID so setup can persist it (avoids a
      // Drive lookup on every subsequent launch).
      configFolderId = _breakdexFolderId;
      return true;
    } on Object catch (e) {
      debugPrint('[GDriveProvider] Auth failed: $e');
      return false;
    }
  }

  @override
  Future<void> deauthenticate() async {
    try {
      await GoogleSignIn().signOut();
    } on Object catch (_) {}
    _account = null;
    _driveApi = null;
    _breakdexFolderId = null;
  }

  @override
  Future<bool> get isAuthenticated async => (await _restoredApi()) != null;

  /// Production session restore: silent Google Sign-In → Drive client, no UI.
  static Future<drive.DriveApi?> _defaultRestoreSession() async {
    if (!isConfigured) return null;
    try {
      final googleSignIn = GoogleSignIn(
        scopes: [drive.DriveApi.driveFileScope],
      );
      final account = await googleSignIn.signInSilently();
      if (account == null) return null;
      final auth = await account.authentication;
      return drive.DriveApi(GoogleAuthClient(auth));
    } on Object catch (e) {
      debugPrint('[GDriveProvider] Silent session restore failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // File operations
  // ---------------------------------------------------------------------------

  @override
  Future<RemoteAsset> upload({
    required final String localPath,
    required final String remotePath,
    final TransferProgress? onProgress,
    final CancellationToken? cancel,
  }) => _run(() async {
    final api = await _ensureApi();
    final file = File(localPath);
    final stat = await file.stat();
    final folderId = await _requireFolderId();

    // Check if file already exists (dedup by name in Breakdex folder)
    final existing = await _findFile(remotePath);
    if (existing != null) {
      return RemoteAsset(
        remotePath: existing.id!,
        sizeBytes: int.tryParse(existing.size ?? '') ?? stat.size,
        etag: existing.md5Checksum,
      );
    }

    // Create file metadata
    final driveFile = drive.File()
      ..name = remotePath.split('/').last
      ..parents = [folderId];

    // Choose upload strategy based on file size
    final media = drive.Media(file.openRead(), stat.size);
    drive.File result;

    if (stat.size > _resumableThreshold) {
      result = await api.files.create(
        driveFile,
        uploadMedia: media,
        uploadOptions: drive.UploadOptions.resumable,
        $fields: 'id,size,md5Checksum',
      );
    } else {
      result = await api.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id,size,md5Checksum',
      );
    }

    debugPrint('[GDriveProvider] Uploaded ${result.id} (${stat.size} bytes)');

    return RemoteAsset(
      remotePath: result.id!,
      sizeBytes: int.tryParse(result.size ?? '') ?? stat.size,
      etag: result.md5Checksum,
    );
  });

  @override
  Future<void> download({
    required final String remotePath,
    required final String localPath,
    final TransferProgress? onProgress,
    final CancellationToken? cancel,
  }) => _run(() async {
    final api = await _ensureApi();

    // remotePath is either a Drive file ID or a filename in Breakdex
    final fileId = await _resolveFileId(remotePath);
    if (fileId == null) {
      throw StateError('File not found: $remotePath');
    }

    final response =
        await api.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final outFile = File(localPath);
    final sink = outFile.openWrite();
    int bytesWritten = 0;

    await for (final chunk in response.stream) {
      if (cancel?.isCancelled ?? false) {
        await sink.close();
        await outFile.delete();
        return;
      }
      sink.add(chunk);
      bytesWritten += chunk.length;
      onProgress?.call(bytesWritten, response.length ?? 0);
    }

    await sink.close();
    debugPrint('[GDriveProvider] Downloaded $fileId → $localPath');
  });

  @override
  Future<bool> verify({
    required final String remotePath,
    final String? expectedHash,
    final int? expectedSize,
  }) async {
    final api = await _ensureApi();

    final fileId = await _resolveFileId(remotePath);
    if (fileId == null) return false;

    try {
      final file =
          await api.files.get(fileId, $fields: 'size,md5Checksum')
              as drive.File;

      if (expectedSize != null) {
        final actualSize = int.tryParse(file.size ?? '');
        if (actualSize != expectedSize) return false;
      }

      // Note: Drive uses MD5, we use SHA-256 — size check is the primary guard.
      // Full hash verification requires download + rehash.
      return true;
    } on Object catch (e) {
      debugPrint('[GDriveProvider] Verify failed for $remotePath: $e');
      return false;
    }
  }

  @override
  Future<List<RemoteAsset>> list({required final String directory}) =>
      _run(() async {
        final api = await _ensureApi();
        final folderId = await _requireFolderId();

        final result = await api.files.list(
          q: "'$folderId' in parents and trashed = false",
          $fields: 'files(id,name,size,md5Checksum,modifiedTime)',
          pageSize: 1000,
        );

        return (result.files ?? []).map((final f) {
          return RemoteAsset(
            remotePath: f.id!,
            sizeBytes: int.tryParse(f.size ?? '') ?? 0,
            etag: f.md5Checksum,
            modifiedAt: f.modifiedTime,
          );
        }).toList();
      });

  @override
  Future<void> delete({required final String remotePath}) => _run(() async {
    final api = await _ensureApi();

    final fileId = await _resolveFileId(remotePath);
    if (fileId == null) return;

    await api.files.delete(fileId);
    debugPrint('[GDriveProvider] Deleted $fileId');
  });

  @override
  Future<({int totalBytes, int usedBytes})?> quota() async {
    final api = await _ensureApi();

    try {
      final about = await api.about.get($fields: 'storageQuota');
      final sq = about.storageQuota;
      if (sq == null) return null;

      return (
        totalBytes: int.tryParse(sq.limit ?? '') ?? 0,
        usedBytes: int.tryParse(sq.usage ?? '') ?? 0,
      );
    } on Object catch (e) {
      debugPrint('[GDriveProvider] Quota check failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Returns the live Drive client, restoring a cached session on demand so a
  /// fresh provider (rebuilt from the DB row) can operate without an explicit
  /// re-authenticate. Throws only when no session can be restored.
  Future<drive.DriveApi> _ensureApi() async {
    final api = await _restoredApi();
    if (api == null) {
      throw StateError('GDriveProvider not authenticated');
    }
    return api;
  }

  /// Memoised restore: returns the live client if present, otherwise a single
  /// shared restore future so concurrent callers don't each silent-sign-in.
  Future<drive.DriveApi?> _restoredApi() {
    if (_driveApi != null) return Future.value(_driveApi);
    return _restoreInFlight ??= _doRestore();
  }

  Future<drive.DriveApi?> _doRestore() async {
    try {
      return _driveApi = await _restoreSession();
    } finally {
      _restoreInFlight = null;
    }
  }

  /// Drops the cached client so the next op restores a fresh session — the
  /// recovery path when an access token has expired or been revoked.
  void _invalidateSession() {
    _driveApi = null;
    _restoreInFlight = null;
  }

  /// Runs a Drive op, transparently restoring a fresh session and retrying
  /// once if the cached token is rejected (401/403). Every wrapped op
  /// re-derives its request (and file streams) on retry, so one retry is safe.
  Future<T> _run<T>(final Future<T> Function() op) async {
    try {
      return await op();
    } on drive.DetailedApiRequestError catch (e) {
      if (e.status != 401 && e.status != 403) rethrow;
      debugPrint('[GDriveProvider] Auth rejected (${e.status}) — restoring');
      _invalidateSession();
      return await op();
    }
  }

  Future<String> _requireFolderId() async {
    if (_breakdexFolderId != null) return _breakdexFolderId!;
    if (configFolderId != null) {
      _breakdexFolderId = configFolderId;
      return configFolderId!;
    }
    await _ensureBreakdexFolder();
    return _breakdexFolderId!;
  }

  /// Find or create the "Breakdex" folder in the user's Drive root.
  Future<void> _ensureBreakdexFolder() async {
    final api = await _ensureApi();

    // Search for existing folder
    final result = await api.files.list(
      q: "name = '$_folderName' and mimeType = '$_folderMimeType' and trashed = false",
      $fields: 'files(id)',
      pageSize: 1,
    );

    if (result.files != null && result.files!.isNotEmpty) {
      _breakdexFolderId = result.files!.first.id;
      debugPrint('[GDriveProvider] Found Breakdex folder: $_breakdexFolderId');
      return;
    }

    // Create new folder
    final folder = drive.File()
      ..name = _folderName
      ..mimeType = _folderMimeType;

    final created = await api.files.create(folder, $fields: 'id');
    _breakdexFolderId = created.id;
    debugPrint('[GDriveProvider] Created Breakdex folder: $_breakdexFolderId');
  }

  /// Find a file by name in the Breakdex folder.
  Future<drive.File?> _findFile(final String remotePath) async {
    final api = await _ensureApi();
    final folderId = await _requireFolderId();
    final fileName = remotePath.split('/').last;

    final result = await api.files.list(
      q: "name = '$fileName' and '$folderId' in parents and trashed = false",
      $fields: 'files(id,size,md5Checksum)',
      pageSize: 1,
    );

    return result.files?.firstOrNull;
  }

  /// Resolve a remotePath (either a Drive file ID or filename) to a file ID.
  Future<String?> _resolveFileId(final String remotePath) async {
    // If it looks like a Drive file ID (no path separators), use directly
    if (!remotePath.contains('/')) return remotePath;

    final file = await _findFile(remotePath);
    return file?.id;
  }

  /// Build an authenticated Drive API client from a Google Sign-In account.
  Future<drive.DriveApi> _buildDriveApi(
    final GoogleSignInAccount account,
  ) async {
    final auth = await account.authentication;
    final client = GoogleAuthClient(auth);
    return drive.DriveApi(client);
  }
}

/// HTTP client that injects Google Sign-In auth headers.
class GoogleAuthClient extends http.BaseClient {
  final GoogleSignInAuthentication _auth;
  final http.Client _inner = http.Client();

  GoogleAuthClient(this._auth);

  @override
  Future<http.StreamedResponse> send(final http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer ${_auth.accessToken}';
    return _inner.send(request);
  }
}
