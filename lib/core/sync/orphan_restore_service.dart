import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../data/repositories.dart';
import '../database/database.dart';
import '../services/video_path_resolver.dart';
import '../utils/filesystem_utils.dart';
import 'asset_hash_service.dart';
import 'sandbox_hash_index.dart';

/// Restores quarantined orphan assets — live manifest rows with zero owning
/// entities whose bytes survive in the sandbox (design D11, task 4.8).
///
/// The janitor's quarantine severed these from the library: the file sits in
/// `Moves/.lost+found/`, the manifest still points at the pre-quarantine path,
/// and no move or combo claims the hash. Tombstoning them would soft-delete
/// recoverable videos (the 2026-07-19 device dump read 22 of 22
/// bytes-present), so the remedy is the inverse: verify, re-home, re-own.
///
/// Per asset: (1) the sandbox candidate is **full-hash verified** against
/// `contentHash` — D10's lone-hash8 trust is for upload healing; a restore
/// rewrites library structure, and two of the 22 already showed name drift, so
/// a mismatch is reported and never adopted; (2) the file moves to
/// `Moves/<recoveredCategory>/` and `localPath` is updated in the same
/// operation (the 1.8 rule); (3) a move row is created so the asset is owned
/// and visible again. Idempotent: a restored asset's path resolves on the next
/// run, so it never re-qualifies as unreachable.
///
/// Never automatic — invoked from the dev panel, like reconcile.
class OrphanRestoreService {
  final AppDatabase _db;
  final MoveRepository _moveRepository;
  final AssetHashService _hasher;

  OrphanRestoreService({
    required final AppDatabase db,
    required final MoveRepository moveRepository,
    final AssetHashService? hasher,
  })  : _db = db,
        _moveRepository = moveRepository,
        _hasher = hasher ?? AssetHashService();

  /// Category the recreated moves land in. The original owners are
  /// hard-deleted, so their category truth is unrecoverable — a dedicated
  /// bucket makes the recovery visible instead of guessing.
  static const recoveredCategory = 'Recovered';

  Future<OrphanRestoreReport> restore() async {
    final documentsPath = VideoPathResolver.documentsPath;
    final sandbox = await SandboxHashIndex.scan(documentsPath);
    final report = OrphanRestoreReport();

    for (final manifest in await _db.assetManifestDao.getAll()) {
      if (manifest.deletedAt != null) continue;
      if (await _hasBytes(manifest.localPath, documentsPath)) continue;

      final hash = manifest.contentHash;
      if (await _hasOwner(hash)) continue; // Heal lanes' territory, not ours.

      final candidate = await sandbox.resolve(
        hash,
        documentsPath: documentsPath,
        hasher: _hasher,
      );
      if (candidate == null) {
        report.bytesNotFound.add(hash);
        continue;
      }

      // Full-hash gate (D11 ruling 2): the one failure mode a restore must
      // not have is adopting the wrong bytes under the right identity.
      final absolute = p.join(documentsPath, candidate);
      if (!await _hasher.verifyHash(absolute, hash)) {
        report.hashMismatch.add('$hash at $candidate');
        continue;
      }

      final destRelative =
          p.join('Moves', recoveredCategory, p.basename(candidate));
      final destAbsolute = p.join(documentsPath, destRelative);

      if (!p.equals(absolute, destAbsolute)) {
        if (File(destAbsolute).existsSync()) {
          // Occupied destination: same bytes means a prior run moved the file
          // and died before the DB writes — adopt in place. Different bytes
          // is a collision we refuse to overwrite.
          if (!await _hasher.verifyHash(destAbsolute, hash)) {
            report.destinationConflict.add('$hash at $destRelative');
            continue;
          }
        } else {
          await FileSystemUtils.safeMove(absolute, destAbsolute);
        }
      }

      await _db.assetManifestDao.updateLocalState(
        hash,
        localPath: Value(destRelative),
        localVerifiedAt: Value(DateTime.now()),
      );
      await _moveRepository.insert(
        MovesCompanion.insert(
          id: const Uuid().v4(),
          name: _displayName(candidate, hash),
          category: const Value(recoveredCategory),
          videoPath: Value(destRelative),
          originalVideoName: Value(manifest.sourceName),
          contentHash: Value(hash),
          videoFileSize: Value(BigInt.from(manifest.fileSizeBytes)),
        ),
      );
      report.restored.add('$hash → $destRelative');
    }

    return report;
  }

  Future<bool> _hasOwner(final String hash) async {
    final moves = await (_db.select(_db.moves)
          ..where((final t) => t.contentHash.equals(hash))
          ..where((final t) => t.deletedAt.isNull()))
        .get();
    if (moves.isNotEmpty) return true;
    final combos = await (_db.select(_db.combos)
          ..where((final t) => t.contentHash.equals(hash)))
        .get();
    return combos.isNotEmpty;
  }

  Future<bool> _hasBytes(
    final String? relative,
    final String documentsPath,
  ) async {
    if (relative == null) return false;
    return File(p.join(documentsPath, relative)).existsSync();
  }

  /// Human name from a canonical filename: `Name - hash8.ext` keeps `Name`;
  /// a bare `<fullhash>.ext` has no semantic name to keep.
  static String _displayName(final String relativePath, final String hash) {
    final base = p.basenameWithoutExtension(relativePath);
    final separator = base.lastIndexOf(' - ');
    final name = separator > 0 ? base.substring(0, separator).trim() : base;
    final hash8 = hash.length > 8 ? hash.substring(0, 8) : hash;
    final isBareHash = RegExp(r'^[0-9a-fA-F]{8,64}$').hasMatch(name);
    return (name.isEmpty || isBareHash) ? 'Recovered $hash8' : name;
  }
}

/// What one restore pass did, per asset — the panel renders [toString] and
/// tests assert on the buckets.
class OrphanRestoreReport {
  final List<String> restored = [];
  final List<String> bytesNotFound = [];
  final List<String> hashMismatch = [];
  final List<String> destinationConflict = [];

  @override
  String toString() => [
        'restored: ${restored.length}',
        for (final line in restored) '  $line',
        if (bytesNotFound.isNotEmpty)
          'bytes not found (4.10 tombstone candidates): '
              '${bytesNotFound.length}',
        for (final hash in bytesNotFound) '  $hash',
        if (hashMismatch.isNotEmpty)
          'hash mismatch (NOT adopted): ${hashMismatch.length}',
        for (final line in hashMismatch) '  $line',
        if (destinationConflict.isNotEmpty)
          'destination conflict (NOT overwritten): '
              '${destinationConflict.length}',
        for (final line in destinationConflict) '  $line',
      ].join('\n');
}
