class CreateMoveRequest {
  const CreateMoveRequest({
    required this.name,
    required this.category,
    this.localVideoPath,
    this.originalVideoName,
    this.videoFileSize,
    this.videoCreationDate,
    this.count = 4,
    this.learningState = 'NEW',
  });

  final String name;
  final String category;
  final String? localVideoPath;
  final String? originalVideoName;
  final int? videoFileSize;
  final DateTime? videoCreationDate;
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


