import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/failures/failure.dart';
import '../../services/sync_service.dart';

part 'sync_bloc.freezed.dart';

// --- Events ---
@freezed
class SyncEvent with _$SyncEvent {
  const factory SyncEvent.startSync() = _StartSync;
  const factory SyncEvent.progressUpdated(final int current, final int total, final String item) = _ProgressUpdated;
  const factory SyncEvent.phaseCompleted() = _PhaseCompleted;
  const factory SyncEvent.failed(final AppFailure failure) = _Failed;
}

// --- States ---
@freezed
class SyncState with _$SyncState {
  const factory SyncState.idle() = _Idle;
  const factory SyncState.authenticating() = _Authenticating;
  const factory SyncState.pushingMetadata(final int current, final int total, final String item) = _PushingMetadata;
  const factory SyncState.uploadingVideos(final int current, final int total, final String item) = _UploadingVideos;
  const factory SyncState.pullingRemote() = _PullingRemote;
  const factory SyncState.reconcilingLegacy() = _ReconcilingLegacy;
  const factory SyncState.downloadingVideos(final int current, final int total, final String item) = _DownloadingVideos;
  const factory SyncState.reconcilingAlbums() = _ReconcilingAlbums;
  const factory SyncState.complete() = _Complete;
  const factory SyncState.error(final AppFailure failure) = _Error;
}

// --- Bloc ---
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncService _syncService;

  SyncBloc(this._syncService) : super(const SyncState.idle()) {
    on<_StartSync>(_onStartSync);
    // You can handle intermediate progress events or just await the TaskEithers sequentially
  }

  Future<void> _onStartSync(final _StartSync event, final Emitter<SyncState> emit) async {
    // 1. Authenticating
    emit(const SyncState.authenticating());
    final authResult = await _syncService.authenticate().run();
    if (authResult.isLeft()) {
      return emit(SyncState.error(authResult.match((final l) => l, (final r) => throw Exception())));
    }

    // 2. Pushing Metadata
    emit(const SyncState.pushingMetadata(0, 0, ''));
    final pushResult = await _syncService.pushMetadata((final c, final t, final i) {
      if (!isClosed) add(SyncEvent.progressUpdated(c, t, i));
    }).run();
    if (pushResult.isLeft()) {
      return emit(SyncState.error(pushResult.match((final l) => l, (final r) => throw Exception())));
    }

    // 3. Uploading Videos
    emit(const SyncState.uploadingVideos(0, 0, ''));
    final uploadResult = await _syncService.uploadVideos((final c, final t, final i) {
      if (!isClosed) add(SyncEvent.progressUpdated(c, t, i));
    }).run();
    if (uploadResult.isLeft()) {
      return emit(SyncState.error(uploadResult.match((final l) => l, (final r) => throw Exception())));
    }

    // 4. Pulling Remote
    emit(const SyncState.pullingRemote());
    final pullResult = await _syncService.pullRemote().run();
    if (pullResult.isLeft()) {
      return emit(SyncState.error(pullResult.match((final l) => l, (final r) => throw Exception())));
    }

    // 5. Reconcile Legacy
    emit(const SyncState.reconcilingLegacy());
    final reconcileLegacyResult = await _syncService.reconcileLegacy().run();
    if (reconcileLegacyResult.isLeft()) {
      return emit(SyncState.error(reconcileLegacyResult.match((final l) => l, (final r) => throw Exception())));
    }

    // 6. Download Videos
    emit(const SyncState.downloadingVideos(0, 0, ''));
    final downloadResult = await _syncService.downloadVideos((final c, final t, final i) {
      if (!isClosed) add(SyncEvent.progressUpdated(c, t, i));
    }).run();
    if (downloadResult.isLeft()) {
      return emit(SyncState.error(downloadResult.match((final l) => l, (final r) => throw Exception())));
    }

    // 7. Reconcile Albums
    emit(const SyncState.reconcilingAlbums());
    final albumResult = await _syncService.reconcileAlbums().run();
    if (albumResult.isLeft()) {
      return emit(SyncState.error(albumResult.match((final l) => l, (final r) => throw Exception())));
    }

    emit(const SyncState.complete());
  }
}
