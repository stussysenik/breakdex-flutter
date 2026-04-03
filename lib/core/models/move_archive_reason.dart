enum MoveArchiveReason {
  externalAlbumDelete(
    dbValue: 'external_album_delete',
    title: 'Deleted from Photos',
    description: 'The managed album copy disappeared from Photos.',
  ),
  removedFromManagedAlbum(
    dbValue: 'removed_from_managed_album',
    title: 'Removed from Breakdex Album',
    description: 'The managed copy is no longer inside the Breakdex album.',
  ),
  missingLocalVideo(
    dbValue: 'missing_local_video',
    title: 'Local Video Missing',
    description: 'Breakdex could not find the local video file.',
  );

  const MoveArchiveReason({
    required this.dbValue,
    required this.title,
    required this.description,
  });

  final String dbValue;
  final String title;
  final String description;

  static MoveArchiveReason? fromDbValue(String? value) {
    for (final reason in values) {
      if (reason.dbValue == value) return reason;
    }
    return null;
  }
}

const moveArchiveRetention = Duration(days: 30);
