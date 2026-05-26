import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/learning_state.dart';

/// All events the MoveDetail machine can receive.
sealed class MoveDetailEvent {
  const MoveDetailEvent();
}

// ── User intents (only valid from Idle) ──

final class TapRename extends MoveDetailEvent {
  const TapRename();
}
final class TapChangeState extends MoveDetailEvent {
  const TapChangeState();
}
final class TapChangeCategory extends MoveDetailEvent {
  const TapChangeCategory();
}
final class TapChangeCount extends MoveDetailEvent {
  const TapChangeCount();
}
final class TapDelete extends MoveDetailEvent {
  const TapDelete();
}
final class TapAddVideo extends MoveDetailEvent {
  const TapAddVideo();
}
final class TapEditVideo extends MoveDetailEvent {
  const TapEditVideo();
}
final class TapRemoveVideo extends MoveDetailEvent {
  const TapRemoveVideo();
}
final class TapShareVideo extends MoveDetailEvent {
  const TapShareVideo();
}
final class TapAnalyze extends MoveDetailEvent {
  const TapAnalyze();
}
final class TapAddLog extends MoveDetailEvent {
  const TapAddLog();
}
final class TapDeleteLog extends MoveDetailEvent {
  final String entryId;
  const TapDeleteLog(this.entryId);
}

// ── Dialog interactions ──

final class Cancel extends MoveDetailEvent {
  const Cancel();
}
final class Confirm extends MoveDetailEvent {
  const Confirm();
}
final class UpdateDraft extends MoveDetailEvent {
  final String name;
  const UpdateDraft(this.name);
}
final class SaveName extends MoveDetailEvent {
  final String name;
  const SaveName(this.name);
}
final class SaveState extends MoveDetailEvent {
  final LearningState learningState;
  const SaveState(this.learningState);
}
final class SaveCategory extends MoveDetailEvent {
  final String category;
  const SaveCategory(this.category);
}
final class SaveCount extends MoveDetailEvent {
  final int count;
  const SaveCount(this.count);
}
final class SaveLogBody extends MoveDetailEvent {
  final String body;
  const SaveLogBody(this.body);
}

// ── Video picker results ──

final class VideoPicked extends MoveDetailEvent {
  final String localPath;
  final String originalFileName;
  const VideoPicked(this.localPath, this.originalFileName);
}
final class VideoPickCancelled extends MoveDetailEvent {
  const VideoPickCancelled();
}
final class VideoEdited extends MoveDetailEvent {
  final String newPath;
  const VideoEdited(this.newPath);
}

// ── Async operation results ──

final class NameAvailable extends MoveDetailEvent {
  const NameAvailable();
}
final class NameTaken extends MoveDetailEvent {
  const NameTaken();
}
final class SaveSucceeded extends MoveDetailEvent {
  final Move move;
  const SaveSucceeded(this.move);
}
final class SaveFailed extends MoveDetailEvent {
  final String error;
  const SaveFailed(this.error);
}
final class DeleteSucceeded extends MoveDetailEvent {
  const DeleteSucceeded();
}
final class DeleteFailed extends MoveDetailEvent {
  final String error;
  const DeleteFailed(this.error);
}
final class AlbumSyncFailedEvent extends MoveDetailEvent {
  final String message;
  const AlbumSyncFailedEvent(this.message);
}
final class AlbumSyncSucceeded extends MoveDetailEvent {
  const AlbumSyncSucceeded();
}

// ── Data updates ──

final class StreamUpdate extends MoveDetailEvent {
  final Move move;
  const StreamUpdate(this.move);
}
final class UpdateNotes extends MoveDetailEvent {
  final String text;
  const UpdateNotes(this.text);
}
final class UpdatePhotos extends MoveDetailEvent {
  final String? json;
  const UpdatePhotos(this.json);
}
