// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

part of '../providers.dart';

final canonicalFolderServiceProvider = Provider<CanonicalFolderService>((final ref) {
  return CanonicalFolderService();
});

final canonicalImportGateProvider = Provider<CanonicalImportGate>((final ref) {
  return CanonicalImportGate(
    manifestDao: ref.watch(assetManifestDaoProvider),
    hashService: ref.watch(assetHashServiceProvider),
  );
});

final canonicalReconcileServiceProvider =
    Provider<CanonicalReconcileService>((final ref) {
  return CanonicalReconcileService(
    folderService: ref.watch(canonicalFolderServiceProvider),
    manifestDao: ref.watch(assetManifestDaoProvider),
    copiesDao: ref.watch(assetCopiesDaoProvider),
    hashService: ref.watch(assetHashServiceProvider),
  );
});

final reconcileReportProvider = FutureProvider<ReconcileReport>((final ref) {
  return ref.watch(canonicalReconcileServiceProvider).scan();
});

final liveAssetsProvider = StreamProvider<List<AssetManifestData>>((final ref) {
  return ref.watch(assetManifestDaoProvider).watchAll().map(
        (final list) =>
            list.where((final a) => a.deletedAt == null).toList()
              ..sort((final a, final b) => b.importedAt.compareTo(a.importedAt)),
      );
});

final liveAssetsCountProvider = Provider<int>((final ref) {
  return ref.watch(liveAssetsProvider).valueOrNull?.length ?? 0;
});

final trashedAssetsProvider = StreamProvider<List<AssetManifestData>>((final ref) {
  return ref.watch(assetManifestDaoProvider).watchAll().map(
        (final list) =>
            list.where((final a) => a.deletedAt != null).toList()
              ..sort((final a, final b) => b.deletedAt!.compareTo(a.deletedAt!)),
      );
});

final trashedAssetsCountProvider = Provider<int>((final ref) {
  return ref.watch(trashedAssetsProvider).valueOrNull?.length ?? 0;
});

final canonicalFolderInitializedProvider = FutureProvider<bool>((final ref) {
  return ref.watch(canonicalFolderServiceProvider).verify();
});

final canonicalStorageSizeProvider = FutureProvider<int>((final ref) async {
  final folder = ref.watch(canonicalFolderServiceProvider);
  final files = await folder.listVideoFiles();
  var total = 0;
  for (final file in files) {
    try {
      final stat = await file.stat();
      total += stat.size;
    } on Object catch (_) {}
  }
  return total;
});
