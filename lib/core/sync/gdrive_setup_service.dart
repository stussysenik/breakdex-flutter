import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:uuid/uuid.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/daos/sync_providers_dao.dart';
import 'package:breakdex/core/sync/providers/gdrive_provider.dart';

/// Reads the connected Google account's email without UI (silent sign-in).
/// Returns null when no cached session exists. Injectable for testing.
typedef SilentEmailReader = Future<String?> Function();

/// Orchestrates Google Drive setup via OAuth.
///
/// Flow:
/// 1. Trigger Google Sign-In with Drive file scope
/// 2. Create/find "Breakdex" folder in user's Drive
/// 3. Insert row into sync_providers table with folder ID + account email in
///    configJson
/// 4. [cloudProvidersProvider] auto-rebuilds (watches DAO stream)
class GDriveSetupService {
  final SyncProvidersDao syncProvidersDao;
  final SilentEmailReader _silentEmail;

  GDriveSetupService({
    required this.syncProvidersDao,
    final SilentEmailReader? silentEmail,
  }) : _silentEmail = silentEmail ?? _defaultSilentEmail;

  static Future<String?> _defaultSilentEmail() async {
    if (kIsWeb || !GDriveProvider.isConfigured) return null;
    try {
      final account = await GoogleSignIn(
        scopes: [drive.DriveApi.driveFileScope],
      ).signInSilently();
      return account?.email;
    } on Object catch (_) {
      return null;
    }
  }

  /// The Google account holding the video backup: live silent-sign-in read
  /// when a session is restorable, the configJson cache offline. Fresh reads
  /// are written back to the row so the email keeps rendering offline.
  /// Null when Drive isn't configured or the account was never captured.
  Future<String?> connectedAccountEmail() async {
    final row = await syncProvidersDao.getByType('gdrive');
    if (row == null) return null;

    var config = <String, dynamic>{};
    if (row.configJson != null) {
      try {
        config = jsonDecode(row.configJson!) as Map<String, dynamic>;
      } on Object catch (_) {}
    }
    final cached = config['accountEmail'] as String?;

    final live = await _silentEmail();
    if (live != null && live != cached) {
      config['accountEmail'] = live;
      await syncProvidersDao.updateProvider(
        row.id,
        SyncProvidersCompanion(configJson: Value(jsonEncode(config))),
      );
    }
    return live ?? cached;
  }

  /// Trigger Google Sign-In and configure Drive provider.
  ///
  /// Returns [GDriveSetupResult.cancelled] immediately if the Google OAuth
  /// client ID hasn't been configured yet (see [GDriveProvider.isConfigured]).
  Future<GDriveSetupResult> enable() async {
    if (!GDriveProvider.isConfigured) return GDriveSetupResult.cancelled;

    // Check if already configured
    final existing = await syncProvidersDao.getByType('gdrive');
    if (existing != null) {
      if (!existing.enabled) {
        await syncProvidersDao.updateProvider(
          existing.id,
          const SyncProvidersCompanion(enabled: Value(true)),
        );
        return GDriveSetupResult.enabled;
      }
      return GDriveSetupResult.alreadyEnabled;
    }

    // Authenticate + create Breakdex folder
    final provider = GDriveProvider();
    final authenticated = await provider.authenticate();
    if (!authenticated) {
      return GDriveSetupResult.cancelled;
    }

    // Store the folder ID (skips lookup on future launches) and the account
    // email (renders offline in the Drive row).
    final configJson = jsonEncode({
      'folderId': provider.configFolderId,
      'accountEmail': provider.accountEmail,
    });

    await syncProvidersDao.insertProvider(
      SyncProvidersCompanion.insert(
        id: const Uuid().v4(),
        providerType: 'gdrive',
        displayName: 'Google Drive',
        configJson: Value(configJson),
        createdAt: DateTime.now().toUtc(),
      ),
    );

    return GDriveSetupResult.enabled;
  }

  /// Disable Google Drive sync (keeps row for re-enable without re-auth).
  Future<void> disable() async {
    final existing = await syncProvidersDao.getByType('gdrive');
    if (existing != null) {
      await syncProvidersDao.updateProvider(
        existing.id,
        const SyncProvidersCompanion(enabled: Value(false)),
      );
    }
  }

  /// Fully disconnect Google Drive: signs out of the cached Google session and
  /// removes the provider configuration. Reconnecting requires a fresh
  /// interactive sign-in.
  ///
  /// Clearing the native session is what makes the disconnect "stick" — without
  /// it, a rebuilt provider would silently restore the session via
  /// `signInSilently` and the UI would flip back to "Connected". Videos already
  /// backed up to Drive are left untouched.
  Future<void> disconnect() async {
    await GDriveProvider().deauthenticate();
    final existing = await syncProvidersDao.getByType('gdrive');
    if (existing != null) {
      await syncProvidersDao.deleteProvider(existing.id);
    }
  }
}

enum GDriveSetupResult {
  enabled,
  alreadyEnabled,
  cancelled,
}
