import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@freezed
sealed class AppFailure with _$AppFailure {
  /// General network or connectivity failure
  const factory AppFailure.network([String? message]) = _NetworkFailure;
  
  /// Database related failure (Drift/SQLite)
  const factory AppFailure.database([String? message]) = _DatabaseFailure;
  
  /// Firebase or backend synchronization failure
  const factory AppFailure.sync([String? message]) = _SyncFailure;
  
  /// Local file system failure (I/O, missing files)
  const factory AppFailure.fileSystem([String? message]) = _FileSystemFailure;
  
  /// General or unknown unexpected failure
  const factory AppFailure.unexpected([String? message]) = _UnexpectedFailure;
}
