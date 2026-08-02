/// Where a video's bytes actually live, and which way they are moving.
///
/// The copy ledger (`asset_copies`) already records one row per
/// `(contentHash, provider)` with a lifecycle status. This turns that ledger
/// into the one sentence a person can read off a move: *on this device and
/// Google Drive*, *sending to iCloud*, *upload failed*.
///
/// Deliberately pure — it takes facts, not rows, so the precedence rules below
/// are testable without a database and reusable by any surface (move detail,
/// library tile, trash) that has copies in hand.
///
/// **Relationship to [AssetSyncDetail]** (`lib/core/sync/asset_sync_detail.dart`),
/// which classifies the same asset as one word. That one answers *is my backup
/// pipeline making progress*, and takes `sync_operations` as its authority for
/// in-flight work; it never names which provider holds what, and it is built
/// for the whole library at once. This one answers *where does this clip live*,
/// per place, from the copy ledger alone — the question a single move's line
/// asks, and the one the pipeline view cannot answer. Same tables, different
/// question; if a surface needs both words in one sentence, compose them there
/// rather than widening either.
library;

/// A single copy row reduced to the two fields residency depends on.
class AssetCopyFact {
  const AssetCopyFact({required this.provider, required this.status});

  /// Provider key as stored: `local`, `gdrive`, `icloud`, `s3`, …
  final String provider;

  /// Copy lifecycle as stored: pending → uploading → verified → failed →
  /// deleted.
  final String status;
}

/// A named place a copy can live, other than this device.
///
/// Unknown keys are carried through rather than dropped: a provider added to
/// the ledger before this enum knows its name should still be *named* on the
/// surface, because "somewhere I cannot show you" is the failure this whole
/// line exists to remove.
class CloudPlace {
  const CloudPlace(this.key, this.label);

  final String key;

  /// Human name for the place. Not localized — these are product names
  /// ("Google Drive", "iCloud"), which do not translate.
  final String label;

  static const gdrive = CloudPlace('gdrive', 'Google Drive');
  static const icloud = CloudPlace('icloud', 'iCloud');
  static const s3 = CloudPlace('s3', 'S3');
  static const firebase = CloudPlace('firebase', 'Firebase');

  static CloudPlace fromKey(final String key) => switch (key) {
    'gdrive' => gdrive,
    'icloud' => icloud,
    's3' => s3,
    'firebase' => firebase,
    _ => CloudPlace(key, key),
  };

  @override
  bool operator ==(final Object other) =>
      other is CloudPlace && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'CloudPlace($key)';
}

/// The direction fact — deliberately separate from the location fact, because
/// *where it is* and *which way it is going* are different questions and one
/// badge that conflates them is worse than no badge (task 8.2).
enum AssetResidencyState {
  /// The copy ledger has no row for this asset. Not a claim about safety.
  untracked,

  /// On this device, nowhere else.
  localOnly,

  /// A transfer is in flight to at least one place.
  pending,

  /// At least one cloud copy is verified and nothing is in flight or failed.
  uploaded,

  /// A transfer failed. Outranks everything — it is the only state a person
  /// can act on.
  failed,

  /// Verified in the cloud with no local copy: playable only after a download.
  cloudOnly,
}

class AssetResidency {
  const AssetResidency({
    required this.state,
    this.cloudPlaces = const [],
    this.pendingPlaces = const [],
    this.failedPlaces = const [],
  });

  final AssetResidencyState state;

  /// Places holding a verified copy, ordered by provider key.
  final List<CloudPlace> cloudPlaces;

  /// Places a transfer is currently in flight to.
  final List<CloudPlace> pendingPlaces;

  /// Places whose last transfer failed.
  final List<CloudPlace> failedPlaces;

  bool get hasLocal =>
      state == AssetResidencyState.localOnly ||
      state == AssetResidencyState.pending ||
      state == AssetResidencyState.uploaded ||
      state == AssetResidencyState.failed;
}

const _live = {'pending', 'uploading', 'verified', 'failed'};

/// Reduce the copy ledger for one asset to a residency statement.
///
/// Precedence is failure → in-flight → verified, because that is the order in
/// which the facts are actionable: a failed upload is the only one asking for
/// a decision, and an in-flight one is the only one that will change on its
/// own. Locations are reported independently of that ranking, so a line can
/// read "Google Drive · sending to iCloud" without either fact hiding the
/// other.
AssetResidency describeResidency(final Iterable<AssetCopyFact> copies) {
  final rows = copies.where((final c) => _live.contains(c.status)).toList();
  if (rows.isEmpty) {
    return const AssetResidency(state: AssetResidencyState.untracked);
  }

  final hasLocal = rows.any(
    (final c) => c.provider == 'local' && c.status != 'failed',
  );
  final cloud = rows.where((final c) => c.provider != 'local').toList()
    ..sort((final a, final b) => a.provider.compareTo(b.provider));

  List<CloudPlace> placesWhere(final bool Function(String status) match) => [
    for (final c in cloud)
      if (match(c.status)) CloudPlace.fromKey(c.provider),
  ];

  final verified = placesWhere((final s) => s == 'verified');
  final pending = placesWhere((final s) => s == 'pending' || s == 'uploading');
  final failed = placesWhere((final s) => s == 'failed');

  final state = switch ((failed.isNotEmpty, pending.isNotEmpty, verified)) {
    (true, _, _) => AssetResidencyState.failed,
    (_, true, _) => AssetResidencyState.pending,
    (_, _, final v) when v.isNotEmpty && hasLocal =>
      AssetResidencyState.uploaded,
    (_, _, final v) when v.isNotEmpty => AssetResidencyState.cloudOnly,
    _ => AssetResidencyState.localOnly,
  };

  return AssetResidency(
    state: state,
    cloudPlaces: verified,
    pendingPlaces: pending,
    failedPlaces: failed,
  );
}
