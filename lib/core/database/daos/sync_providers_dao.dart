import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/sync_providers.dart';

part 'sync_providers_dao.g.dart';

/// DAO for cloud storage provider configuration.
///
/// Each row in [SyncProviders] represents a configured cloud backend
/// (iCloud, Google Drive, S3). The sync engine watches this table via
/// [watchAll] to automatically rebuild when providers are added/removed.
@DriftAccessor(tables: [SyncProviders])
class SyncProvidersDao extends DatabaseAccessor<AppDatabase>
    with _$SyncProvidersDaoMixin {
  SyncProvidersDao(super.db);

  /// Reactive stream of all configured providers.
  Stream<List<SyncProvider>> watchAll() => select(syncProviders).watch();

  /// All configured providers (one-shot).
  Future<List<SyncProvider>> getAll() => select(syncProviders).get();

  /// Look up a provider by type (e.g. 'icloud', 'gdrive', 's3').
  Future<SyncProvider?> getByType(String providerType) =>
      (select(syncProviders)..where((t) => t.providerType.equals(providerType)))
          .getSingleOrNull();

  /// Insert a new provider configuration.
  Future<int> insertProvider(SyncProvidersCompanion entry) =>
      into(syncProviders).insert(entry);

  /// Toggle enabled state or update quota/config for an existing provider.
  Future<bool> updateProvider(String id, SyncProvidersCompanion entry) =>
      (update(syncProviders)..where((t) => t.id.equals(id))).write(entry).then(
            (rows) => rows > 0,
          );

  /// Remove a provider configuration.
  Future<int> deleteProvider(String id) =>
      (delete(syncProviders)..where((t) => t.id.equals(id))).go();
}
