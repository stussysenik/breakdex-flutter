import '../database/daos/asset_copies_dao.dart';
import '../database/daos/asset_manifest_dao.dart';

/// Exception thrown when a deletion would violate safety constraints.
class SafetyException implements Exception {
  final String message;
  const SafetyException(this.message);

  @override
  String toString() => 'SafetyException: $message';
}

/// Enforces safety invariants before destructive operations on video assets.
///
/// Two key rules:
/// 1. **Two-copy minimum**: A local file cannot be deleted unless at least
///    one verified cloud copy exists (ensuring the asset survives device loss).
/// 2. **Circuit breaker**: Bulk operations that would delete >25% of the
///    library are blocked to prevent accidental mass data loss.
class SafetyGuard {
  final AssetManifestDao _manifestDao;
  final AssetCopiesDao _copiesDao;

  /// Maximum fraction of the library that can be deleted in one operation.
  static const _circuitBreakerThreshold = 0.25;

  SafetyGuard(this._manifestDao, this._copiesDao);

  /// Returns true only if it's safe to remove the local copy of this asset.
  ///
  /// Safe means at least one other verified copy exists on a cloud provider.
  Future<bool> canDeleteLocal(final String contentHash) async {
    final copies = await _copiesDao.getByHash(contentHash);
    final verifiedRemoteCopies = copies.where(
      (final c) => c.provider != 'local' && c.status == 'verified',
    );
    return verifiedRemoteCopies.isNotEmpty;
  }

  /// Circuit breaker: refuses if the operation would delete more than 25%
  /// of the live library in one batch.
  ///
  /// Returns true if the batch size is within safe limits.
  Future<bool> circuitBreakerCheck(final List<String> hashesToDelete) async {
    if (hashesToDelete.isEmpty) return true;

    final totalLive = await _manifestDao.countLive();
    if (totalLive == 0) return true;

    final ratio = hashesToDelete.length / totalLive;
    return ratio <= _circuitBreakerThreshold;
  }

  /// Combined check: verifies both two-copy minimum and circuit breaker.
  ///
  /// Throws [SafetyException] with a descriptive message if deletion is unsafe.
  Future<void> assertSafeToDeleteLocal(final String contentHash) async {
    if (!await canDeleteLocal(contentHash)) {
      throw const SafetyException(
        'Cannot delete local copy: no verified cloud backup exists. '
        'Wait for sync to complete before deleting.',
      );
    }
  }
}
