/// Why an asset's bytes could not be found, given what its owning entities say.
///
/// The upload engine's heal (`_healStaleLocalPath`) re-derives a dead manifest
/// path from the owning move/combo. When it returns null the engine reports
/// "Local file missing", which collapses four materially different situations
/// into one sentence — and only one of them means the video is actually gone.
/// This is the distinction, so a device dump answers design D8 instead of
/// inviting a guess.
enum AssetResolution {
  /// An **active** owner names a path whose bytes exist. The heal reads exactly
  /// these owners, so reaching this verdict means the heal failed for some
  /// reason other than its query — investigate the path, not the filter.
  activeOwnerOnDisk,

  /// Only an **archived** owner names a path whose bytes exist. The heal reads
  /// `getActiveByContentHash`, which excludes archived moves, so it cannot see
  /// this file. The bytes are recoverable; the query is the defect.
  archivedOwnerOnDisk,

  /// Owning entities exist, but none of them names a path with bytes behind it.
  /// The video is genuinely gone — a terminal failure, not a retryable one.
  bytesGone,

  /// The only entities claiming this hash are soft-deleted moves. The manifest
  /// row outlived its owner *deliberately* — distinct from [orphan], where the
  /// owner was never there. Recoverable by undeleting; terminal if the deletion
  /// was intended, in which case the manifest row should be tombstoned too.
  deletedOwner,

  /// No move or combo claims this hash at all. The manifest row outlived its
  /// owner; there is nothing to heal from.
  orphan,
}

/// Classify one unresolvable asset from facts the caller has already measured.
///
/// Pure and total: every combination of inputs lands on exactly one verdict, so
/// no asset can drop out of the report. Order matters — an asset owned by both
/// an active and an archived entity is reported against the active one, since
/// that is the owner the heal already had access to.
AssetResolution classifyAssetResolution({
  required final int ownerCount,
  required final bool activeOwnerHasBytes,
  required final bool archivedOwnerHasBytes,
  final int deletedOwnerCount = 0,
}) {
  if (activeOwnerHasBytes) return AssetResolution.activeOwnerOnDisk;
  if (archivedOwnerHasBytes) return AssetResolution.archivedOwnerOnDisk;
  if (ownerCount > 0) return AssetResolution.bytesGone;
  if (deletedOwnerCount > 0) return AssetResolution.deletedOwner;
  return AssetResolution.orphan;
}

/// Short, greppable label for a device log.
String assetResolutionLabel(final AssetResolution resolution) =>
    switch (resolution) {
      AssetResolution.activeOwnerOnDisk => 'ACTIVE-OWNER-ON-DISK',
      AssetResolution.archivedOwnerOnDisk => 'ARCHIVED-OWNER-ON-DISK',
      AssetResolution.bytesGone => 'BYTES-GONE',
      AssetResolution.deletedOwner => 'DELETED-OWNER',
      AssetResolution.orphan => 'ORPHAN',
    };

/// One-line explanation of what the verdict means for the fix.
String assetResolutionMeaning(final AssetResolution resolution) =>
    switch (resolution) {
      AssetResolution.activeOwnerOnDisk =>
        'heal had this owner and still failed — path bug, not a filter bug',
      AssetResolution.archivedOwnerOnDisk =>
        'recoverable: heal skips archived owners (moves_dao getActiveByContentHash)',
      AssetResolution.bytesGone => 'terminal: no owner path has bytes',
      AssetResolution.deletedOwner =>
        'owner exists but is soft-deleted — undelete to recover, or tombstone the manifest row',
      AssetResolution.orphan => 'terminal: manifest row has no owning entity',
    };
