import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database.dart';
import '../database/daos/sync_dao.dart';
import '../models/sync_progress.dart';
import 'auth_service.dart';
import 'video_path_resolver.dart';

const _lastSyncKey = 'last_sync_at';

class SyncService {
  final AuthService authService;
  final SyncDao syncDao;
  final AppDatabase db;
  final SharedPreferences prefs;

  final _progressController = StreamController<SyncProgress>.broadcast();
  Stream<SyncProgress> get progressStream => _progressController.stream;

  bool _syncing = false;

  SyncService({
    required this.authService,
    required this.syncDao,
    required this.db,
    required this.prefs,
  });

  SupabaseClient get _sb => authService.client;

  DateTime? get lastSyncAt {
    final ms = prefs.getInt(_lastSyncKey);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  /// Run a full sync cycle: push local → pull remote.
  Future<void> sync() async {
    if (_syncing) return;
    _syncing = true;

    try {
      // 1. Refresh auth
      _emit(const SyncProgress(phase: SyncPhase.authenticating));
      final valid = await authService.refreshAuth();
      if (!valid) {
        _emit(const SyncProgress(phase: SyncPhase.error));
        return;
      }

      // 2. Push pending metadata
      await _pushMetadata();

      // 3. Upload pending videos
      await _uploadVideos();

      // 4. Pull remote changes
      await _pullRemote();

      // 5. Download missing videos
      await _downloadVideos();

      // 6. Update last sync timestamp
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      _emit(const SyncProgress(phase: SyncPhase.complete));
    } catch (e) {
      _emit(const SyncProgress(phase: SyncPhase.error));
    } finally {
      _syncing = false;
    }
  }

  // ─── Push local changes ─────────────────────────────────────────

  Future<void> _pushMetadata() async {
    final pending = await syncDao.getPendingChanges();
    if (pending.isEmpty) return;

    for (var i = 0; i < pending.length; i++) {
      final entry = pending[i];
      _emit(
        SyncProgress(
          phase: SyncPhase.pushingMetadata,
          current: i + 1,
          total: pending.length,
          currentItem: entry.entityTable,
        ),
      );

      try {
        await _pushEntry(entry);
        await syncDao.markSynced(
          entry.entityId,
          entry.entityTable,
          entry.action,
        );
      } catch (e) {
        // Skip failed entries — they'll retry next sync
      }
    }
  }

  Future<void> _pushEntry(SyncLogData entry) async {
    final table = entry.entityTable;
    final userId = authService.userId;

    if (entry.action == 'delete') {
      if (table == 'fsrs_cards') {
        await _sb.from(table).delete().eq('entity_id', entry.entityId);
      } else {
        await _sb.from(table).delete().eq('id', entry.entityId);
      }
      return;
    }

    // Get local record data as a map
    final body = await _getLocalRecordBody(table, entry.entityId);
    if (body == null) return;
    body['user_id'] = userId;

    // Upsert — handles both create and update
    await _sb.from(table).upsert(body);
  }

  Future<Map<String, dynamic>?> _getLocalRecordBody(
    String table,
    String id,
  ) async {
    try {
      switch (table) {
        case 'moves':
          final move = await db.movesDao.getById(id);
          return {
            'id': move.id,
            'name': move.name,
            'learning_state': move.learningState,
            'category': move.category,
            'created_at': move.createdAt.toIso8601String(),
          };
        case 'combos':
          final combo = await db.combosDao.getById(id);
          return {
            'id': combo.id,
            'name': combo.name,
            'active_video_path': combo.activeVideoPath,
          };
        case 'combo_moves':
          final result = await (db.select(
            db.comboMoves,
          )..where((t) => t.id.equals(id))).getSingle();
          return {
            'id': result.id,
            'sequence_index': result.sequenceIndex,
            'combo_id': result.comboId,
            'move_id': result.moveId,
          };
        case 'reviews':
          final results = await (db.select(
            db.reviews,
          )..where((t) => t.id.equals(id))).get();
          if (results.isEmpty) return null;
          final review = results.first;
          return {
            'id': review.id,
            'rating': review.rating,
            'review_type': review.reviewType,
            'reviewed_at': review.reviewedAt.toIso8601String(),
            'move_id': review.moveId,
            'combo_id': review.comboId,
            'entity_id_snapshot': review.entityIdSnapshot,
            'entity_type': review.entityType,
            'entity_display_name': review.entityDisplayName,
            'entity_category': review.entityCategory,
            'fsrs_pre_state': review.fsrsPreState,
            'fsrs_post_state': review.fsrsPostState,
          };
        case 'fsrs_cards':
          final card =
              await db.fsrsCardsDao.getByEntityId(id) ??
              await db.fsrsCardsDao.getByEntityId(id, entityType: 'combo');
          if (card == null) return null;
          return {
            'entity_id': card.entityId,
            'entity_type': card.entityType,
            'stability': card.stability,
            'difficulty': card.difficulty,
            'due': card.due.toIso8601String(),
            'last_review': card.lastReview?.toIso8601String(),
            'reps': card.reps,
            'lapses': card.lapses,
            'fsrs_state': card.fsrsState,
          };
        case 'battle_results':
          final results = await (db.select(
            db.battleResults,
          )..where((t) => t.id.equals(id))).get();
          if (results.isEmpty) return null;
          final br = results.first;
          return {
            'id': br.id,
            'score': br.score,
            'moves_reviewed': br.movesReviewed,
            'good_count': br.goodCount,
            'hard_count': br.hardCount,
            'again_count': br.againCount,
            'longest_streak': br.longestStreak,
            'difficulty': br.difficulty,
            'played_at': br.playedAt.toIso8601String(),
          };
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  // ─── Upload videos ──────────────────────────────────────────────

  Future<void> _uploadVideos() async {
    final pending = await syncDao.getPendingVideoUploads();
    if (pending.isEmpty) return;

    final userId = authService.userId;

    for (var i = 0; i < pending.length; i++) {
      final entry = pending[i];
      _emit(
        SyncProgress(
          phase: SyncPhase.uploadingVideos,
          current: i + 1,
          total: pending.length,
          currentItem: entry.entityId,
        ),
      );

      try {
        String? videoPath;

        if (entry.entityTable == 'moves') {
          final move = await db.movesDao.getById(entry.entityId);
          videoPath = move.videoPath;
        } else if (entry.entityTable == 'combos') {
          final combo = await db.combosDao.getById(entry.entityId);
          videoPath = combo.activeVideoPath;
        } else {
          continue;
        }

        if (videoPath == null) continue;

        final absolutePath = VideoPathResolver.toAbsolute(videoPath);
        final file = File(absolutePath);
        if (!await file.exists()) continue;

        final storagePath =
            '$userId/${entry.entityTable}/${entry.entityId}.mp4';

        await _sb.storage
            .from('videos')
            .upload(
              storagePath,
              file,
              fileOptions: const FileOptions(upsert: true),
            );

        await syncDao.markVideoSynced(entry.entityId, entry.entityTable);
      } catch (_) {
        // Skip — retry next sync
      }
    }
  }

  // ─── Pull remote changes ────────────────────────────────────────

  Future<void> _pullRemote() async {
    _emit(const SyncProgress(phase: SyncPhase.pullingMetadata));

    final userId = authService.userId;
    final since = lastSyncAt;

    for (final table in [
      'moves',
      'combos',
      'combo_moves',
      'reviews',
      'fsrs_cards',
      'battle_results',
    ]) {
      try {
        var query = _sb.from(table).select().eq('user_id', userId);
        if (since != null) {
          query = query.gt('updated_at', since.toUtc().toIso8601String());
        }

        final records = await query;

        for (final record in records) {
          await _mergeRemoteRecord(table, record);
        }
      } catch (_) {
        // Skip table on error
      }
    }
  }

  Future<void> _mergeRemoteRecord(
    String table,
    Map<String, dynamic> record,
  ) async {
    try {
      switch (table) {
        case 'moves':
          final companion = MovesCompanion(
            id: Value(record['id'] as String),
            name: Value(record['name'] as String),
            learningState: Value(record['learning_state'] as String),
            category: Value(record['category'] as String),
            createdAt: Value(DateTime.parse(record['created_at'] as String)),
          );
          await db.into(db.moves).insertOnConflictUpdate(companion);
          break;
        case 'combos':
          final companion = CombosCompanion(
            id: Value(record['id'] as String),
            name: Value(record['name'] as String),
            activeVideoPath: Value(
              record['active_video_path'] != null
                  ? VideoPathResolver.toRelative(record['active_video_path'] as String)
                  : null,
            ),
          );
          await db.into(db.combos).insertOnConflictUpdate(companion);
          break;
        case 'combo_moves':
          final companion = ComboMovesCompanion(
            id: Value(record['id'] as String),
            sequenceIndex: Value(record['sequence_index'] as int),
            comboId: Value(record['combo_id'] as String),
            moveId: Value(record['move_id'] as String),
          );
          await db.into(db.comboMoves).insertOnConflictUpdate(companion);
          break;
        case 'reviews':
          final companion = ReviewsCompanion(
            id: Value(record['id'] as String),
            rating: Value(record['rating'] as String),
            reviewType: Value(record['review_type'] as String),
            reviewedAt: Value(DateTime.parse(record['reviewed_at'] as String)),
            moveId: Value(record['move_id'] as String?),
            comboId: Value(record['combo_id'] as String?),
            entityIdSnapshot: Value(record['entity_id_snapshot'] as String?),
            entityType: Value(record['entity_type'] as String?),
            entityDisplayName: Value(record['entity_display_name'] as String?),
            entityCategory: Value(record['entity_category'] as String?),
            fsrsPreState: Value(record['fsrs_pre_state'] as int?),
            fsrsPostState: Value(record['fsrs_post_state'] as int?),
          );
          await db.into(db.reviews).insertOnConflictUpdate(companion);
          break;
        case 'fsrs_cards':
          final companion = FsrsCardsCompanion(
            entityId: Value(record['entity_id'] as String),
            entityType: Value((record['entity_type'] as String?) ?? 'move'),
            stability: Value((record['stability'] as num).toDouble()),
            difficulty: Value((record['difficulty'] as num).toDouble()),
            due: Value(DateTime.parse(record['due'] as String)),
            lastReview: Value(
              record['last_review'] == null
                  ? null
                  : DateTime.parse(record['last_review'] as String),
            ),
            reps: Value(record['reps'] as int),
            lapses: Value(record['lapses'] as int),
            fsrsState: Value(record['fsrs_state'] as int),
          );
          await db.into(db.fsrsCards).insertOnConflictUpdate(companion);
          break;
        case 'battle_results':
          final companion = BattleResultsCompanion(
            id: Value(record['id'] as String),
            score: Value(record['score'] as int),
            movesReviewed: Value(record['moves_reviewed'] as int),
            goodCount: Value(record['good_count'] as int),
            hardCount: Value(record['hard_count'] as int),
            againCount: Value(record['again_count'] as int),
            longestStreak: Value(record['longest_streak'] as int),
            difficulty: Value(record['difficulty'] as String),
            playedAt: Value(DateTime.parse(record['played_at'] as String)),
          );
          await db.into(db.battleResults).insertOnConflictUpdate(companion);
          break;
      }
    } catch (_) {
      // Skip record on merge error
    }
  }

  // ─── Download videos ────────────────────────────────────────────

  Future<void> _downloadVideos() async {
    final userId = authService.userId;

    try {
      // List all video files for this user in storage
      final moveVideos = await _sb.storage
          .from('videos')
          .list(path: '$userId/moves');

      final toDownload = <FileObject>[];
      for (final fileObj in moveVideos) {
        final moveId = p.basenameWithoutExtension(fileObj.name);
        try {
          final localMove = await db.movesDao.getById(moveId);
          if (localMove.videoPath == null || localMove.videoPath!.isEmpty) {
            toDownload.add(fileObj);
          } else if (!await File(VideoPathResolver.toAbsolute(localMove.videoPath!)).exists()) {
            toDownload.add(fileObj);
          }
        } catch (_) {
          // Move doesn't exist locally — skip
        }
      }

      for (var i = 0; i < toDownload.length; i++) {
        final fileObj = toDownload[i];
        final moveId = p.basenameWithoutExtension(fileObj.name);
        _emit(
          SyncProgress(
            phase: SyncPhase.downloadingVideos,
            current: i + 1,
            total: toDownload.length,
            currentItem: moveId,
          ),
        );

        try {
          final bytes = await _sb.storage
              .from('videos')
              .download('$userId/moves/${fileObj.name}');

          final dir = await getApplicationDocumentsDirectory();
          final movesDir = Directory(p.join(dir.path, 'Moves'));
          if (!await movesDir.exists()) {
            await movesDir.create(recursive: true);
          }
          final localPath = p.join(movesDir.path, '$moveId.mp4');

          await File(localPath).writeAsBytes(bytes);

          await (db.update(db.moves)..where((t) => t.id.equals(moveId))).write(
            MovesCompanion(videoPath: Value(VideoPathResolver.toRelative(localPath))),
          );
        } catch (_) {
          // Skip — retry next sync
        }
      }

      final comboVideos = await _sb.storage
          .from('videos')
          .list(path: '$userId/combos');
      final comboDownloads = <FileObject>[];
      for (final fileObj in comboVideos) {
        final comboId = p.basenameWithoutExtension(fileObj.name);
        try {
          final localCombo = await db.combosDao.getById(comboId);
          if (localCombo.activeVideoPath == null ||
              localCombo.activeVideoPath!.isEmpty) {
            comboDownloads.add(fileObj);
          } else if (!await File(VideoPathResolver.toAbsolute(localCombo.activeVideoPath!)).exists()) {
            comboDownloads.add(fileObj);
          }
        } catch (_) {
          // Combo doesn't exist locally — skip
        }
      }

      for (var i = 0; i < comboDownloads.length; i++) {
        final fileObj = comboDownloads[i];
        final comboId = p.basenameWithoutExtension(fileObj.name);
        _emit(
          SyncProgress(
            phase: SyncPhase.downloadingVideos,
            current: i + 1,
            total: comboDownloads.length,
            currentItem: comboId,
          ),
        );

        try {
          final bytes = await _sb.storage
              .from('videos')
              .download('$userId/combos/${fileObj.name}');

          final dir = await getApplicationDocumentsDirectory();
          final combosDir = Directory(p.join(dir.path, 'Combos'));
          if (!await combosDir.exists()) {
            await combosDir.create(recursive: true);
          }
          final localPath = p.join(combosDir.path, '$comboId.mp4');

          await File(localPath).writeAsBytes(bytes);

          await (db.update(db.combos)..where((t) => t.id.equals(comboId)))
              .write(CombosCompanion(activeVideoPath: Value(VideoPathResolver.toRelative(localPath))));
        } catch (_) {
          // Skip — retry next sync
        }
      }
    } catch (_) {
      // Skip video download phase on error
    }
  }

  // ─── Seed initial sync ──────────────────────────────────────────

  /// Seed SyncLog with all existing local data for first-time push.
  Future<void> seedInitialSync() async {
    final moves = await db.movesDao.getAll();
    for (final move in moves) {
      await syncDao.logChange(
        entityId: move.id,
        table: 'moves',
        action: 'create',
        hasVideo: move.videoPath != null,
      );
    }

    final combos = await db.combosDao.getAll();
    for (final combo in combos) {
      await syncDao.logChange(
        entityId: combo.id,
        table: 'combos',
        action: 'create',
        hasVideo: combo.activeVideoPath != null,
      );
    }

    final comboMoves = await db.select(db.comboMoves).get();
    for (final cm in comboMoves) {
      await syncDao.logChange(
        entityId: cm.id,
        table: 'combo_moves',
        action: 'create',
      );
    }

    final fsrsCards = await db.fsrsCardsDao.getAll();
    for (final card in fsrsCards) {
      await syncDao.logChange(
        entityId: card.entityId,
        table: 'fsrs_cards',
        action: 'create',
      );
    }

    final reviews = await db.select(db.reviews).get();
    for (final review in reviews) {
      await syncDao.logChange(
        entityId: review.id,
        table: 'reviews',
        action: 'create',
      );
    }

    final battles = await db.select(db.battleResults).get();
    for (final br in battles) {
      await syncDao.logChange(
        entityId: br.id,
        table: 'battle_results',
        action: 'create',
      );
    }
  }

  void _emit(SyncProgress progress) {
    _progressController.add(progress);
  }
}
