class CreateMoveRequest {
  const CreateMoveRequest({
    required this.name,
    required this.category,
    this.localVideoPath,
    this.originalVideoName,
    this.count = 4,
    this.learningState = 'NEW',
  });

  final String name;
  final String category;
  final String? localVideoPath;
  final String? originalVideoName;
  final int count;
  final String learningState;
}

class CreateMoveResult {
  const CreateMoveResult({
    required this.moveId,
    required this.name,
    required this.category,
    this.videoPath,
  });

  final String moveId;
  final String name;
  final String category;
  final String? videoPath;

  bool get hasVideo => videoPath != null;
}

class CreateRecoveredMoveRequest {
  const CreateRecoveredMoveRequest({
    required this.preferredName,
    required this.category,
    required this.localVideoPath,
    required this.originalVideoName,
    required this.managedAlbumAssetId,
    required this.managedAlbumFilename,
    required this.managedAlbumName,
  });

  final String preferredName;
  final String category;
  final String localVideoPath;
  final String originalVideoName;
  final String managedAlbumAssetId;
  final String managedAlbumFilename;
  final String managedAlbumName;
}
