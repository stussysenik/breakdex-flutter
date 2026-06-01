import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../domain/failures/failure.dart';

part 'recovery_bloc.freezed.dart';

// --- Events ---
@freezed
class RecoveryEvent with _$RecoveryEvent {
  const factory RecoveryEvent.startScan() = _StartScan;
  const factory RecoveryEvent.discardOrphans(final List<String> files) = _DiscardOrphans;
  const factory RecoveryEvent.recoverOrphans(final List<String> files) = _RecoverOrphans;
}

// --- States ---
@freezed
class RecoveryState with _$RecoveryState {
  const factory RecoveryState.idle() = _Idle;
  const factory RecoveryState.scanning() = _Scanning;
  const factory RecoveryState.orphansFound(final List<String> orphanedFiles) = _OrphansFound;
  const factory RecoveryState.reconciling() = _Reconciling;
  const factory RecoveryState.done() = _Done;
  const factory RecoveryState.error(final AppFailure failure) = _Error;
}

// --- Bloc ---
class RecoveryBloc extends Bloc<RecoveryEvent, RecoveryState> {
  RecoveryBloc() : super(const RecoveryState.idle()) {
    on<_StartScan>(_onStartScan);
    on<_DiscardOrphans>(_onDiscardOrphans);
    on<_RecoverOrphans>(_onRecoverOrphans);
  }

  Future<void> _onStartScan(final _StartScan event, final Emitter<RecoveryState> emit) async {
    emit(const RecoveryState.scanning());
    
    final result = await _scanFileSystem().run();
    
    result.match(
      (final failure) => emit(RecoveryState.error(failure)),
      (final orphans) {
        if (orphans.isEmpty) {
          emit(const RecoveryState.done());
        } else {
          emit(RecoveryState.orphansFound(orphans));
        }
      },
    );
  }

  Future<void> _onDiscardOrphans(final _DiscardOrphans event, final Emitter<RecoveryState> emit) async {
    emit(const RecoveryState.reconciling());
    
    final result = await _deleteFiles(event.files).run();
    
    result.match(
      (final failure) => emit(RecoveryState.error(failure)),
      (_) => emit(const RecoveryState.done()),
    );
  }

  Future<void> _onRecoverOrphans(final _RecoverOrphans event, final Emitter<RecoveryState> emit) async {
    emit(const RecoveryState.reconciling());
    
    final result = await _moveToRecovered(event.files).run();
    
    result.match(
      (final failure) => emit(RecoveryState.error(failure)),
      (_) => emit(const RecoveryState.done()),
    );
  }

  // --- fpdart Side Effects ---

  TaskEither<AppFailure, List<String>> _scanFileSystem() {
    return TaskEither.tryCatch(
      () async {
        final dir = await getApplicationDocumentsDirectory();
        final editsDir = Directory(p.join(dir.path, 'Moves', 'Edits'));
        
        final orphaned = <String>[];
        if (await editsDir.exists()) {
          await for (final entity in editsDir.list()) {
            if (entity is File && entity.path.endsWith('.mp4')) {
              final stat = await entity.stat();
              if (DateTime.now().difference(stat.modified).inHours > 24) {
                await entity.delete();
              } else {
                orphaned.add(entity.path);
              }
            }
          }
        }
        return orphaned;
      },
      (final error, final stackTrace) => AppFailure.fileSystem('Failed to scan file system: $error'),
    );
  }

  TaskEither<AppFailure, Unit> _deleteFiles(final List<String> files) {
    return TaskEither.tryCatch(
      () async {
        for (final file in files) {
          final f = File(file);
          if (await f.exists()) await f.delete();
        }
        return unit;
      },
      (final error, final stackTrace) => AppFailure.fileSystem('Failed to delete orphaned files: $error'),
    );
  }

  TaskEither<AppFailure, Unit> _moveToRecovered(final List<String> files) {
    return TaskEither.tryCatch(
      () async {
        final dir = await getApplicationDocumentsDirectory();
        final recoveredDir = Directory(p.join(dir.path, 'Moves', 'Recovered'));
        if (!await recoveredDir.exists()) {
          await recoveredDir.create(recursive: true);
        }

        for (final file in files) {
          final f = File(file);
          if (await f.exists()) {
            final name = p.basename(file);
            await f.rename(p.join(recoveredDir.path, name));
          }
        }
        return unit;
      },
      (final error, final stackTrace) => AppFailure.fileSystem('Failed to move files to Recovered directory: $error'),
    );
  }
}
