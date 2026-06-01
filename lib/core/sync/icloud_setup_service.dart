import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../database/daos/sync_providers_dao.dart';
import 'providers/icloud_provider.dart';

/// Orchestrates one-tap iCloud setup.
///
/// Flow:
/// 1. Check iCloud entitlement via [ICloudProvider.authenticate]
/// 2. If available → insert row into sync_providers table
/// 3. [cloudProvidersProvider] auto-rebuilds (watches DAO stream)
///
/// No account creation needed — iCloud uses the Apple ID already on device.
class ICloudSetupService {
  final SyncProvidersDao syncProvidersDao;

  ICloudSetupService({required this.syncProvidersDao});

  /// Returns a result message for UI feedback.
  Future<ICloudSetupResult> enable() async {
    // Check if already configured
    final existing = await syncProvidersDao.getByType('icloud');
    if (existing != null) {
      // Re-enable if it was disabled
      if (!existing.enabled) {
        await syncProvidersDao.updateProvider(
          existing.id,
          const SyncProvidersCompanion(enabled: Value(true)),
        );
        return ICloudSetupResult.enabled;
      }
      return ICloudSetupResult.alreadyEnabled;
    }

    // Check entitlement
    final available = await ICloudProvider().authenticate();
    if (!available) {
      return ICloudSetupResult.notAvailable;
    }

    // Insert provider row
    await syncProvidersDao.insertProvider(
      SyncProvidersCompanion.insert(
        id: const Uuid().v4(),
        providerType: 'icloud',
        displayName: 'iCloud Drive',
        createdAt: DateTime.now().toUtc(),
      ),
    );

    return ICloudSetupResult.enabled;
  }

  /// Disable iCloud sync (keeps the row for potential re-enable).
  Future<void> disable() async {
    final existing = await syncProvidersDao.getByType('icloud');
    if (existing != null) {
      await syncProvidersDao.updateProvider(
        existing.id,
        const SyncProvidersCompanion(enabled: Value(false)),
      );
    }
  }
}

enum ICloudSetupResult {
  enabled,
  alreadyEnabled,
  notAvailable,
}
