enum SyncPhase {
  authenticating,
  pushingMetadata,
  uploadingVideos,
  pullingMetadata,
  downloadingVideos,
  complete,
  error,
}

class SyncProgress {
  final SyncPhase phase;
  final int current;
  final int total;
  final String? currentItem;
  final double? bytesProgress; // 0.0 – 1.0 for video transfers

  const SyncProgress({
    required this.phase,
    this.current = 0,
    this.total = 0,
    this.currentItem,
    this.bytesProgress,
  });

  double get fraction => total > 0 ? current / total : 0;

  String get label => switch (phase) {
        SyncPhase.authenticating => 'Authenticating...',
        SyncPhase.pushingMetadata =>
          'Pushing $current/$total${currentItem != null ? ' — $currentItem' : ''}',
        SyncPhase.uploadingVideos =>
          'Uploading video $current/$total${currentItem != null ? ' — $currentItem' : ''}',
        SyncPhase.pullingMetadata =>
          'Pulling changes${total > 0 ? ' $current/$total' : ''}',
        SyncPhase.downloadingVideos =>
          'Downloading video $current/$total${currentItem != null ? ' — $currentItem' : ''}',
        SyncPhase.complete => 'Sync complete',
        SyncPhase.error => 'Sync failed',
      };

  static const idle = SyncProgress(phase: SyncPhase.complete);
}
