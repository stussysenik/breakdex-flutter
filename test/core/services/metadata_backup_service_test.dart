import 'dart:convert';
import 'dart:io';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/metadata_backup_service.dart';
import 'package:breakdex/core/sync/cloud_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake Drive sink that captures the uploaded file's bytes and remote path.
class _CapturingProvider implements CloudProvider {
  _CapturingProvider({this.authed = true});

  bool authed;
  String? uploadedRemotePath;
  String? uploadedContent;
  int uploadCount = 0;

  @override
  Future<bool> get isAuthenticated async => authed;

  @override
  Future<RemoteAsset> upload({
    required final String localPath,
    required final String remotePath,
    final TransferProgress? onProgress,
    final CancellationToken? cancel,
  }) async {
    uploadCount++;
    uploadedRemotePath = remotePath;
    uploadedContent = await File(localPath).readAsString();
    return RemoteAsset(
      remotePath: remotePath,
      sizeBytes: uploadedContent!.length,
    );
  }

  @override
  String get providerType => 'gdrive';
  @override
  String get displayName => 'Fake Drive';
  @override
  Set<CloudProviderCapability> get capabilities => {};
  @override
  Future<bool> authenticate() async => true;
  @override
  Future<void> deauthenticate() async {}
  @override
  Future<void> download({
    required final String remotePath,
    required final String localPath,
    final TransferProgress? onProgress,
    final CancellationToken? cancel,
  }) async {}
  @override
  Future<bool> verify({
    required final String remotePath,
    final String? expectedHash,
    final int? expectedSize,
  }) async => true;
  @override
  Future<List<RemoteAsset>> list({required final String directory}) async => [];
  @override
  Future<void> delete({required final String remotePath}) async {}
  @override
  Future<({int totalBytes, int usedBytes})?> quota() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  Future<Directory> scratch() => Directory.systemTemp.createTemp('bdx_backup');

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await db.close();
  });

  test('backupNow uploads the v10 export to Drive and records the timestamp',
      () async {
    await db.into(db.moves).insert(
          MovesCompanion.insert(id: 'm1', name: 'Windmill'),
        );
    final provider = _CapturingProvider();
    final service = MetadataBackupService(db, prefs, provider,
        scratchDir: scratch);

    final result = await service.backupNow();

    expect(result.uploaded, isTrue);
    expect(result.remotePath, startsWith('Breakdex/backups/'));
    expect(provider.uploadCount, 1);

    // The uploaded payload is the real, restorable export.
    final data = jsonDecode(provider.uploadedContent!) as Map<String, dynamic>;
    expect(data['schemaVersion'], 10);
    expect(((data['moves'] as List).single as Map)['id'], 'm1');

    expect(service.lastBackupAt, isNotNull);
  });

  test('backupNow skips (does not throw) when provider is unauthenticated',
      () async {
    final provider = _CapturingProvider(authed: false);
    final service = MetadataBackupService(db, prefs, provider,
        scratchDir: scratch);

    final result = await service.backupNow();

    expect(result.status, BackupStatus.skipped);
    expect(provider.uploadCount, 0);
    expect(service.lastBackupAt, isNull);
  });

  test('backupIfStale runs when never backed up, then skips while fresh',
      () async {
    final provider = _CapturingProvider();
    final service = MetadataBackupService(db, prefs, provider,
        scratchDir: scratch);

    final first = await service.backupIfStale();
    expect(first.uploaded, isTrue, reason: 'never backed up ⇒ runs');
    expect(provider.uploadCount, 1);

    final second = await service.backupIfStale();
    expect(second.status, BackupStatus.skipped, reason: 'still fresh ⇒ skip');
    expect(provider.uploadCount, 1, reason: 'no second upload');
  });

  test('backupIfStale runs again once the interval has elapsed', () async {
    final provider = _CapturingProvider();
    final service = MetadataBackupService(db, prefs, provider,
        scratchDir: scratch);

    await service.backupIfStale(interval: const Duration(hours: 24));
    expect(provider.uploadCount, 1);

    // A zero interval makes the prior backup instantly stale.
    final again = await service.backupIfStale(interval: Duration.zero);
    expect(again.uploaded, isTrue);
    expect(provider.uploadCount, 2);
  });
}
