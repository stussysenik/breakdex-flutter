import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@freezed
sealed class AppFailure with _$AppFailure {
  /// General network or connectivity failure
  const factory AppFailure.network([final String? message]) = _NetworkFailure;
  
  /// Database related failure (Drift/SQLite)
  const factory AppFailure.database([final String? message]) = _DatabaseFailure;
  
  /// Firebase or backend synchronization failure
  const factory AppFailure.sync([final String? message]) = _SyncFailure;
  
  /// Local file system failure (I/O, missing files)
  const factory AppFailure.fileSystem([final String? message]) = _FileSystemFailure;
  
  /// General or unknown unexpected failure
  const factory AppFailure.unexpected([final String? message]) = _UnexpectedFailure;
}
