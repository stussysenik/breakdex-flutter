part of '../providers.dart';

final canonicalFolderServiceProvider = Provider<CanonicalFolderService>((ref) {
  return CanonicalFolderService();
});

final canonicalImportGateProvider = Provider<CanonicalImportGate>((ref) {
  return CanonicalImportGate(
    manifestDao: ref.watch(assetManifestDaoProvider),
    hashService: ref.watch(assetHashServiceProvider),
  );
});

final canonicalReconcileServiceProvider =
    Provider<CanonicalReconcileService>((ref) {
  return CanonicalReconcileService(
    folderService: ref.watch(canonicalFolderServiceProvider),
    manifestDao: ref.watch(assetManifestDaoProvider),
    copiesDao: ref.watch(assetCopiesDaoProvider),
    hashService: ref.watch(assetHashServiceProvider),
  );
});

final reconcileReportProvider = FutureProvider<ReconcileReport>((ref) {
  return ref.watch(canonicalReconcileServiceProvider).scan();
});

final liveAssetsProvider = StreamProvider<List<AssetManifestData>>((ref) {
  return ref.watch(assetManifestDaoProvider).watchAll().map(
        (list) =>
            list.where((a) => a.deletedAt == null).toList()
              ..sort((a, b) => b.importedAt.compareTo(a.importedAt)),
      );
});

final liveAssetsCountProvider = Provider<int>((ref) {
  return ref.watch(liveAssetsProvider).valueOrNull?.length ?? 0;
});

final trashedAssetsProvider = StreamProvider<List<AssetManifestData>>((ref) {
  return ref.watch(assetManifestDaoProvider).watchAll().map(
        (list) =>
            list.where((a) => a.deletedAt != null).toList()
              ..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!)),
      );
});

final trashedAssetsCountProvider = Provider<int>((ref) {
  return ref.watch(trashedAssetsProvider).valueOrNull?.length ?? 0;
});

final canonicalFolderInitializedProvider = FutureProvider<bool>((ref) {
  return ref.watch(canonicalFolderServiceProvider).verify();
});

final canonicalStorageSizeProvider = FutureProvider<int>((ref) async {
  final folder = ref.watch(canonicalFolderServiceProvider);
  final files = await folder.listVideoFiles();
  var total = 0;
  for (final file in files) {
    try {
      final stat = await file.stat();
      total += stat.size;
    } catch (_) {}
  }
  return total;
});
