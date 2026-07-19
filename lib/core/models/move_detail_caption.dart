/// What the caption slot under a move's name shows on the move detail screen.
///
/// That slot used to render `originalVideoName`, falling back to
/// `ID: <hash8>` — so a move whose clip came off a camera was captioned with a
/// bare UUID, and one with no filename was captioned with a truncated hash.
/// D4 rules the slot a subtitle: it shows the date. The filename is real
/// information, so it keeps its labeled row in the Video Info panel rather
/// than being deleted.
///
/// It is a preference rather than a constant because the owner asked to drive
/// it — but [contentId] is deliberately unreachable except by choosing it. See
/// [resolveMoveDetailCaption].
enum MoveDetailCaption {
  /// "Added 3 days ago" — the move's `createdAt`, the default.
  dateAdded,

  /// The clip's original filename, when it has one.
  filename,

  /// The truncated content hash. Opt-in only.
  contentId,

  /// No caption at all.
  hidden;

  /// Absent/unknown key falls back to [dateAdded] — deliberately the *new*
  /// behaviour, not the old one. The filename caption is a defect under D4,
  /// so a missing preference should not resurrect it.
  static MoveDetailCaption fromString(final String? value) => switch (value) {
    'filename' => MoveDetailCaption.filename,
    'contentId' => MoveDetailCaption.contentId,
    'hidden' => MoveDetailCaption.hidden,
    _ => MoveDetailCaption.dateAdded,
  };

  String get displayName => switch (this) {
    MoveDetailCaption.dateAdded => 'Date',
    MoveDetailCaption.filename => 'Filename',
    MoveDetailCaption.contentId => 'ID',
    MoveDetailCaption.hidden => 'None',
  };
}

/// What the caption slot resolves to for one move.
///
/// Three cases rather than a nullable string: a date has to reach the shared
/// `LibraryDateLabel` as a `DateTime` so it renders through the one localized
/// formatter, and "show nothing" is a real outcome, not an empty string.
sealed class MoveDetailCaptionSpec {
  const MoveDetailCaptionSpec();

  const factory MoveDetailCaptionSpec.date(final DateTime value) =
      MoveDetailCaptionDate;
  const factory MoveDetailCaptionSpec.text(final String value) =
      MoveDetailCaptionText;
  const factory MoveDetailCaptionSpec.none() = MoveDetailCaptionNone;
}

class MoveDetailCaptionDate extends MoveDetailCaptionSpec {
  const MoveDetailCaptionDate(this.value);
  final DateTime value;

  @override
  bool operator ==(final Object other) =>
      other is MoveDetailCaptionDate && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'MoveDetailCaptionSpec.date($value)';
}

class MoveDetailCaptionText extends MoveDetailCaptionSpec {
  const MoveDetailCaptionText(this.value);
  final String value;

  @override
  bool operator ==(final Object other) =>
      other is MoveDetailCaptionText && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'MoveDetailCaptionSpec.text($value)';
}

class MoveDetailCaptionNone extends MoveDetailCaptionSpec {
  const MoveDetailCaptionNone();

  @override
  bool operator ==(final Object other) => other is MoveDetailCaptionNone;
  @override
  int get hashCode => 0;
  @override
  String toString() => 'MoveDetailCaptionSpec.none()';
}

/// Resolves the caption for one move under the selected [mode].
///
/// **Ruling:** a raw identifier is reachable only by selecting
/// [MoveDetailCaption.contentId] — never by fallback. [MoveDetailCaption.filename]
/// on a move with no filename falls back to the *date*, because asking for a
/// name and being handed a hash is precisely the D4 defect this replaces.
/// `createdAt` is non-null on every move, so the fallback is always available.
MoveDetailCaptionSpec resolveMoveDetailCaption({
  required final MoveDetailCaption mode,
  required final DateTime createdAt,
  required final String? originalVideoName,
  required final String? contentHash,
  required final String moveId,
}) => switch (mode) {
  MoveDetailCaption.hidden => const MoveDetailCaptionSpec.none(),
  MoveDetailCaption.dateAdded => MoveDetailCaptionSpec.date(createdAt),
  MoveDetailCaption.filename => originalVideoName == null
      ? MoveDetailCaptionSpec.date(createdAt)
      : MoveDetailCaptionSpec.text(originalVideoName),
  // The hash identifies the bytes; the move id identifies the record. Falling
  // back to the id keeps the slot honest when a move has no clip yet.
  MoveDetailCaption.contentId => MoveDetailCaptionSpec.text(
    'ID: ${_short(contentHash ?? moveId)}',
  ),
};

String _short(final String id) => id.length <= 8 ? id : id.substring(0, 8);
