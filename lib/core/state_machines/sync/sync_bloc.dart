import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/failures/failure.dart';
import '../../services/sync_service.dart';

part 'sync_bloc.freezed.dart';

// --- Events ---
@freezed
class SyncEvent with _$SyncEvent {
  const factory SyncEvent.startSync() = _StartSync;
  const factory SyncEvent.progressUpdated(int current, int total, String item) = _ProgressUpdated;
  const factory SyncEvent.phaseCompleted() = _PhaseCompleted;
  const factory SyncEvent.failed(AppFailure failure) = _Failed;
}

// --- States ---
@freezed
class SyncState with _$SyncState {
  const factory SyncState.idle() = _Idle;
  const factory SyncState.authenticating() = _Authenticating;
  const factory SyncState.pushingMetadata(int current, int total, String item) = _PushingMetadata;
  const factory SyncState.uploadingVideos(int current, int total, String item) = _UploadingVideos;
  const factory SyncState.pullingRemote() = _PullingRemote;
  const factory SyncState.reconcilingLegacy() = _ReconcilingLegacy;
  const factory SyncState.downloadingVideos(int current, int total, String item) = _DownloadingVideos;
  const factory SyncState.reconcilingAlbums() = _ReconcilingAlbums;
  const factory SyncState.complete() = _Complete;
  const factory SyncState.error(AppFailure failure) = _Error;
}

// --- Bloc ---
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncService _syncService;

  SyncBloc(this._syncService) : super(const SyncState.idle()) {
    on<_StartSync>(_onStartSync);
    // You can handle intermediate progress events or just await the TaskEithers sequentially
  }

  Future<void> _onStartSync(_StartSync event, Emitter<SyncState> emit) async {
    // 1. Authenticating
    emit(const SyncState.authenticating());
    final authResult = await _syncService.authenticate().run();
    if (authResult.isLeft()) {
      return emit(SyncState.error(authResult.match((l) => l, (r) => throw Exception())));
    }

    // 2. Pushing Metadata
    emit(const SyncState.pushingMetadata(0, 0, ''));
    final pushResult = await _syncService.pushMetadata((c, t, i) {
      if (!isClosed) add(SyncEvent.progressUpdated(c, t, i));
    }).run();
    if (pushResult.isLeft()) {
      return emit(SyncState.error(pushResult.match((l) => l, (r) => throw Exception())));
    }

    // 3. Uploading Videos
    emit(const SyncState.uploadingVideos(0, 0, ''));
    final uploadResult = await _syncService.uploadVideos((c, t, i) {
      if (!isClosed) add(SyncEvent.progressUpdated(c, t, i));
    }).run();
    if (uploadResult.isLeft()) {
      return emit(SyncState.error(uploadResult.match((l) => l, (r) => throw Exception())));
    }

    // 4. Pulling Remote
    emit(const SyncState.pullingRemote());
    final pullResult = await _syncService.pullRemote().run();
    if (pullResult.isLeft()) {
      return emit(SyncState.error(pullResult.match((l) => l, (r) => throw Exception())));
    }

    // 5. Reconcile Legacy
    emit(const SyncState.reconcilingLegacy());
    final reconcileLegacyResult = await _syncService.reconcileLegacy().run();
    if (reconcileLegacyResult.isLeft()) {
      return emit(SyncState.error(reconcileLegacyResult.match((l) => l, (r) => throw Exception())));
    }

    // 6. Download Videos
    emit(const SyncState.downloadingVideos(0, 0, ''));
    final downloadResult = await _syncService.downloadVideos((c, t, i) {
      if (!isClosed) add(SyncEvent.progressUpdated(c, t, i));
    }).run();
    if (downloadResult.isLeft()) {
      return emit(SyncState.error(downloadResult.match((l) => l, (r) => throw Exception())));
    }

    // 7. Reconcile Albums
    emit(const SyncState.reconcilingAlbums());
    final albumResult = await _syncService.reconcileAlbums().run();
    if (albumResult.isLeft()) {
      return emit(SyncState.error(albumResult.match((l) => l, (r) => throw Exception())));
    }

    emit(const SyncState.complete());
  }
}
