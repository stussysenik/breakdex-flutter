import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../database/daos/sync_providers_dao.dart';
import 'providers/gdrive_provider.dart';

/// Orchestrates Google Drive setup via OAuth.
///
/// Flow:
/// 1. Trigger Google Sign-In with Drive file scope
/// 2. Create/find "Breakdex" folder in user's Drive
/// 3. Insert row into sync_providers table with folder ID in configJson
/// 4. [cloudProvidersProvider] auto-rebuilds (watches DAO stream)
class GDriveSetupService {
  final SyncProvidersDao syncProvidersDao;

  GDriveSetupService({required this.syncProvidersDao});

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

    // Store the folder ID so we can skip lookup on future launches
    final configJson = jsonEncode({
      'folderId': provider.configFolderId,
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
}

enum GDriveSetupResult {
  enabled,
  alreadyEnabled,
  cancelled,
}
