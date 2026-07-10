// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.  discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: avoid_slow_async_io, discarded_futures

import 'dart:async';
import '../../core/platform/io.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/database/database.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/providers.dart';
import '../../core/services/video_service.dart';
import '../../core/services/storage_action_machine.dart' hide assetHashServiceProvider;
import '../../core/services/video_path_resolver.dart';
import '../../core/utils/app_clock.dart';
import 'app_loader.dart';
import '../../core/utils/diagnostics.dart';
import '../../core/utils/stall_detector.dart';

class MetadataVideoPickerSheet extends ConsumerStatefulWidget {
  const MetadataVideoPickerSheet({super.key});

  static Future<VideoPickResult?> show(final BuildContext context) {
    DiagnosticsLog.info('MetadataVideoPickerSheet', 'Opening high-fidelity discovery picker');
    return showModalBottomSheet<VideoPickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const MetadataVideoPickerSheet(),
    );
  }

  @override
  ConsumerState<MetadataVideoPickerSheet> createState() => _MetadataVideoPickerSheetState();
}

class _MetadataVideoPickerSheetState extends ConsumerState<MetadataVideoPickerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  
  List<MetadataAsset> _libraryAssets = [];
  List<MetadataAsset> _managedAssets = [];
  List<MetadataAsset>? _appAssets;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  static const _pageSize = 60;
  String? _error;

  final Set<String> _selectedIds = {};

  // Which device videos are already moves. Built once per sheet-open from the
  // moves table; a best-effort overlay, so a DB hiccup leaves it empty rather
  // than breaking the picker. Local-file hashes are memoized per sheet-open.
  MoveMembershipIndex _membership = MoveMembershipIndex.empty;
  final Map<String, String> _hashByPath = {};

  MetadataAsset? _importingAsset;
  String? _importError;
  StorageProgress _currentProgress = StorageProgress.initial();
  StreamSubscription<StorageProgress>? _progressSub;
  StreamSubscription<double>? _nativeProgressSub;

  // Stall detection: while an import is in flight, 2s without the progress
  // value advancing logs a `stalled` stage entry (and `recovered` when it
  // moves again) so frozen bars are diagnosable from the field.
  StallDetector? _stallDetector;
  StageLogger? _importLog;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _progressSub?.cancel();
    _nativeProgressSub?.cancel();
    _stallDetector?.stop();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 600) {
      if (!_loadingMore && _hasMore && _tabController.index == 0) {
        _loadMore();
      }
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      final results = await Future.wait([
        ref.read(videoServiceProvider).fetchPhotoLibraryVideos(offset: 0, limit: _pageSize),
        _fetchAppVideos(),
        _fetchManagedVideos(),
      ]);
      
      if (mounted) {
        setState(() {
          _libraryAssets = results[0].where((final a) => a.duration > 0).toList();
          _appAssets = results[1];
          _managedAssets = results[2];
          _offset = results[0].length;
          _hasMore = results[0].length >= _pageSize;
          _loading = false;
        });
      }
      unawaited(_loadMembership());
    } on Object catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  /// Best-effort: build the membership index from the moves table. Never throws
  /// into the picker — an unreadable DB just leaves every tile unmarked.
  Future<void> _loadMembership() async {
    try {
      final moves = await ref.read(movesDaoProvider).getAll();
      if (mounted) setState(() => _membership = MoveMembershipIndex.fromMoves(moves));
    } on Object catch (_) {
      // Overlay stays empty — the picker still imports.
    }
  }

  /// SHA-256 of a local file, memoized per sheet-open. Photo-library assets
  /// have no path, so they never reach here — an honest membership miss.
  Future<String?> _contentHashForLocal(final String path) async {
    final cached = _hashByPath[path];
    if (cached != null) return cached;
    try {
      final hash = await ref.read(assetHashServiceProvider).computeHash(path);
      _hashByPath[path] = hash;
      return hash;
    } on Object catch (_) {
      return null;
    }
  }

  /// The owning move id if [asset] is already in Breakdex, else null. Managed
  /// assets match by exact PHAsset id (cheap); local files match by content
  /// hash; photo-library assets never match (no path to hash).
  Future<String?> _resolveMembership(final MetadataAsset asset) async {
    final byManaged = _membership.memberMoveId(asset);
    if (byManaged != null) return byManaged;
    if (asset.isLocal) {
      final hash = await _contentHashForLocal(asset.localIdentifier);
      if (hash != null) return _membership.memberMoveId(asset, contentHash: hash);
    }
    return null;
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    
    try {
      final more = await ref.read(videoServiceProvider).fetchPhotoLibraryVideos(
        offset: _offset, 
        limit: _pageSize,
      );
      
      if (mounted) {
        setState(() {
          final moreVideos = more.where((final a) => a.duration > 0).toList();
          _libraryAssets.addAll(moreVideos);
          _offset += more.length;
          _hasMore = more.length >= _pageSize;
          _loadingMore = false;
        });
      }
    } on Object catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<List<MetadataAsset>> _fetchManagedVideos() async {
    try {
      final result = await ref.read(nativeVideoAlbumProvider).discoverRecoverableManagedAssets();
      return result.assets.map((final a) => MetadataAsset(
        localIdentifier: a.assetLocalIdentifier,
        originalFileName: a.filename,
        duration: 0.0,
        width: 0,
        height: 0,
      )).toList();
    } on Object catch (_) {
      return [];
    }
  }

  Future<List<MetadataAsset>> _fetchAppVideos() async {
    try {
      final docsPath = VideoPathResolver.documentsPath.isNotEmpty
          ? VideoPathResolver.documentsPath
          : (await getApplicationDocumentsDirectory()).path;
          
      final movesDir = Directory(p.join(docsPath, 'Moves'));
      final combosDir = Directory(p.join(docsPath, 'Combos'));
      
      final List<FileSystemEntity> entities = [];
      if (await movesDir.exists()) {
        entities.addAll(await movesDir.list(recursive: true).toList());
      }
      if (await combosDir.exists()) {
        entities.addAll(await combosDir.list(recursive: true).toList());
      }

      final List<MetadataAsset> assets = [];
      
      for (final entity in entities) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          if (path.contains('/.thumbs/') || path.contains('/.ds_store')) continue;
          
          if (path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.m4v')) {
            final stat = await entity.stat();
            assets.add(MetadataAsset(
              localIdentifier: entity.path, 
              originalFileName: p.basename(entity.path),
              creationDate: stat.changed,
              duration: 1, 
              width: 0,
              height: 0,
              isLocal: true,
            ));
          }
        }
      }
      
      assets.sort((final a, final b) => (b.creationDate ?? DateTime(0)).compareTo(a.creationDate ?? DateTime(0)));
      return assets;
    } on Object catch (_) {
      return [];
    }
  }

  /// Single-select: tapping a second tile moves the selection — the import
  /// path only ever imports one asset, so the UI must not advertise more.
  void _toggleSelection(final String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds
          ..clear()
          ..add(id);
        unawaited(HapticFeedback.selectionClick());
      }
    });
  }

  Future<void> _handleImport() async {
    if (_selectedIds.isEmpty) return;

    final id = _selectedIds.first;
    final asset = _libraryAssets
        .followedBy(_managedAssets)
        .followedBy(_appAssets ?? [])
        .firstWhere((final a) => a.localIdentifier == id);

    // Already-in-Breakdex videos never import silently: offer the existing move
    // or a deliberate re-import (2.3). Photo-library assets resolve to null here
    // and import straight through.
    final memberMoveId = await _resolveMembership(asset);
    if (!mounted) return;
    if (memberMoveId != null) {
      final choice = await _showMembershipChoice();
      if (!mounted || choice == null) return;
      if (choice == _MemberChoice.openExisting) {
        final router = GoRouter.of(context);
        Navigator.of(context).pop();
        unawaited(router.push('/breakdex/move/$memberMoveId'));
        return;
      }
      // _MemberChoice.importAgain falls through to a normal import.
    }

    await _performImport(asset);
  }

  Future<_MemberChoice?> _showMembershipChoice() {
    return showModalBottomSheet<_MemberChoice>(
      context: context,
      builder: (final ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              leading: Icon(Icons.video_library_rounded),
              title: Text('Already in Breakdex'),
              subtitle: Text('This video is already a move.'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Open existing move'),
              onTap: () => Navigator.pop(ctx, _MemberChoice.openExisting),
            ),
            ListTile(
              leading: const Icon(Icons.file_copy_rounded),
              title: const Text('Import again'),
              onTap: () => Navigator.pop(ctx, _MemberChoice.importAgain),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performImport(final MetadataAsset asset) async {
    setState(() {
      _importingAsset = asset;
      _importError = null;
      _currentProgress = StorageProgress.initial();
    });

    _importLog = StageLogger.begin(
      'GalleryImport',
      subsystem: 'MetadataVideoPickerSheet',
      context: {'asset': asset.originalFileName},
    );
    _stallDetector?.stop();
    _stallDetector = StallDetector(
      log: _importLog!,
      clock: ref.read(appClockProvider),
    )..start();

    final engine = ref.read(storageActionMachineProvider);
    _progressSub = engine.progress.listen((final p) {
      if (mounted) {
        _stallDetector?.note(p.progress);
        setState(() => _currentProgress = p);
      }
    });
    // PHAsset imports report progress on the native event channel — the
    // iCloud download fraction arrives here, not via the storage machine.
    _nativeProgressSub = ref.read(videoServiceProvider).importProgress.listen(
      (final fraction) {
        if (mounted) {
          _stallDetector?.note(fraction);
          setState(() => _currentProgress = StorageProgress(
                progress: fraction.clamp(0.0, 1.0),
                stage: fraction >= 1.0 ? 'Importing' : 'Downloading',
              ));
        }
      },
    );

    final navigator = Navigator.of(context);
    try {
      VideoPickResult? result;
      
      if (asset.isLocal) {
        result = VideoPickResult(
          localPath: asset.localIdentifier,
          originalFileName: asset.originalFileName,
          creationDate: asset.creationDate,
        );
      } else {
        result = await ref.read(videoServiceProvider).importSpecificAsset(asset.localIdentifier);
      }

      _stallDetector?.stop();
      if (mounted && result != null) {
        _importLog?.complete('imported');
        unawaited(HapticFeedback.heavyImpact());
        navigator.pop(result);
      }
    } on Object catch (e) {
      _stallDetector?.stop();
      _importLog?.fail(e);
      // Stay in the overlay: edge-network failures get an in-place Retry
      // for the same asset rather than a transient snackbar.
      if (mounted) {
        setState(() => _importError = '$e');
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.9,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                _buildHandle(context),
                _buildHeader(context),
                const SizedBox(height: AppSpacing.sm),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  tabs: const [
                    Tab(text: 'PHOTO LIBRARY'),
                    Tab(text: 'VIDEO LIBRARY'),
                    Tab(text: 'APP VIDEOS'),
                  ],
                  dividerColor: Colors.transparent,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.secondary,
                  indicatorColor: colorScheme.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2),
                  unselectedLabelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w500, letterSpacing: 1.2),
                ),
                const Divider(height: 1, thickness: 0.5),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGrid(_libraryAssets, 'Device Videos', isLibrary: true),
                      _buildGrid(_managedAssets, 'Breakdex Album', isLibrary: false),
                      _buildGrid(_appAssets, 'App Storage', isLibrary: false),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _selectedIds.isNotEmpty && _importingAsset == null
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _handleImport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                            elevation: 0,
                          ),
                          child: const Text('IMPORT VIDEO'),
                        ),
                      ),
                    ).animate().slideY(
                          begin: 1,
                          end: 0,
                          duration: AppMotion.moderate02,
                          curve: AppMotion.entrance,
                        ),
                  )
                : null,
          ),
          
          if (_importingAsset != null)
            _buildGhostingOverlay(context),
        ],
      ),
    );
  }


  Widget _buildHandle(final BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'SELECT VIDEO',
            style: AppTypography.sectionHeader.copyWith(
              letterSpacing: 2.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(final List<MetadataAsset>? assets, final String sourceLabel, {required final bool isLibrary}) {
    if (_loading && isLibrary) {
      return const Center(child: AppLoader());
    }

    if (_error != null && isLibrary) {
      return Center(child: Text(_error!, style: AppTypography.caption));
    }

    if (assets == null || assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined, size: 48, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text('NO VIDEOS FOUND', style: AppTypography.caption.copyWith(letterSpacing: 1.0, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: isLibrary ? _scrollController : null,
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: assets.length + (isLibrary && _hasMore ? 1 : 0),
      itemBuilder: (final context, final index) {
        if (isLibrary && index == assets.length) {
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: AppLoader()));
        }
        
        final asset = assets[index];
        final isSelected = _selectedIds.contains(asset.localIdentifier);
        
        return _VideoTile(
          asset: asset,
          isSelected: isSelected,
          membership: _membership,
          hashResolver: _contentHashForLocal,
          onSelect: (final a, final _) => _toggleSelection(a.localIdentifier),
        );
      },
    );
  }

  Widget _buildGhostingOverlay(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
              child: Container(color: Colors.black.withValues(alpha: 0.85)),
            ),

            if (_importError != null)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      color: Colors.redAccent, size: 48),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl),
                    child: Text(
                      _importError!,
                      style: AppTypography.bodyMedium
                          .copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: _importingAsset != null
                        ? () => _performImport(_importingAsset!)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    child: const Text('RETRY'),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _importingAsset = null;
                      _importError = null;
                    }),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ],
              )
            else
              Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(child: Icon(Icons.sync_rounded, size: 48, color: Colors.white)),
                ).animate(onPlay: (final c) => c.repeat()).rotate(duration: 3.seconds),
                
                const SizedBox(height: AppSpacing.xxl),
                
                Text(
                  _currentProgress.stage.toUpperCase(),
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    letterSpacing: 4.0,
                    fontWeight: FontWeight.w900,
                  ),
                ).animate().fadeIn(),
                
                const SizedBox(height: AppSpacing.md),
                
                SizedBox(
                  width: 240,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _currentProgress.progress > 0 ? _currentProgress.progress : null,
                      backgroundColor: Colors.white10,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                Text(
                  '${(_currentProgress.progress * 100).toInt()}%',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}

/// Slot 1's `mm:ss` duration badge. Empty when unknown — the badge is then
/// omitted rather than shown as `0:00`.
@visibleForTesting
String formatDurationBadge(final double seconds) {
  if (seconds <= 0) return '';
  final mins = seconds ~/ 60;
  final secs = (seconds % 60).round().toString().padLeft(2, '0');
  return '$mins:$secs';
}

/// Slot 3's single secondary fact under the name — size preferred (it
/// distinguishes takes), else capture date. Empty when neither is known: a
/// missing fact is omitted, never padded with substitute text.
@visibleForTesting
String formatTileSecondaryFact({final int? sizeBytes, final DateTime? date}) {
  if (sizeBytes != null && sizeBytes > 0) {
    final mb = sizeBytes / (1024 * 1024);
    return mb >= 100 ? '${mb.round()} MB' : '${mb.toStringAsFixed(1)} MB';
  }
  if (date != null) return '${_monthNames[date.month - 1]} ${date.day}';
  return '';
}

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// The user's choice when a picked video already exists as a move.
enum _MemberChoice { openExisting, importAgain }

/// Exact-identity membership of a device asset against existing moves, built
/// once per sheet-open. Two cheap keys only — the managed-album PHAsset id and
/// the content hash. A camera-roll asset has no local path to hash and its
/// source id is never persisted, so an unmatched photo-library tile is an
/// honest miss, never a false "already in Breakdex" mark.
@immutable
class MoveMembershipIndex {
  const MoveMembershipIndex({
    required this.moveIdByManagedAssetId,
    required this.moveIdByContentHash,
  });

  factory MoveMembershipIndex.fromMoves(final List<Move> moves) {
    final byManaged = <String, String>{};
    final byHash = <String, String>{};
    for (final m in moves) {
      final managed = m.managedAlbumAssetId;
      if (managed != null && managed.isNotEmpty) byManaged[managed] = m.id;
      final hash = m.contentHash;
      if (hash != null && hash.isNotEmpty) byHash[hash] = m.id;
    }
    return MoveMembershipIndex(
      moveIdByManagedAssetId: byManaged,
      moveIdByContentHash: byHash,
    );
  }

  static const empty = MoveMembershipIndex(
    moveIdByManagedAssetId: <String, String>{},
    moveIdByContentHash: <String, String>{},
  );

  final Map<String, String> moveIdByManagedAssetId;
  final Map<String, String> moveIdByContentHash;

  /// The owning move id if [asset] is already in Breakdex, else null.
  /// [contentHash] is supplied only for local-file assets; photo-library
  /// assets pass null and so can only match by managed-album id.
  String? memberMoveId(final MetadataAsset asset, {final String? contentHash}) {
    final byManaged = moveIdByManagedAssetId[asset.localIdentifier];
    if (byManaged != null) return byManaged;
    if (contentHash != null) return moveIdByContentHash[contentHash];
    return null;
  }
}

class _VideoTile extends ConsumerStatefulWidget {
  final MetadataAsset asset;
  final bool isSelected;
  final MoveMembershipIndex membership;
  final Future<String?> Function(String path) hashResolver;
  final void Function(MetadataAsset, Uint8List?) onSelect;

  const _VideoTile({
    required this.asset,
    required this.isSelected,
    required this.membership,
    required this.hashResolver,
    required this.onSelect,
  });

  @override
  ConsumerState<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends ConsumerState<_VideoTile> {
  Uint8List? _thumbnail;
  bool _loading = true;
  int? _fileSizeBytes;
  String? _memberMoveId;
  bool _localResolving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_thumbnail == null && _loading) _loadThumbnail();
    if (_fileSizeBytes == null && widget.asset.isLocal) _loadFileSize();
    _resolveMembership();
  }

  @override
  void didUpdateWidget(covariant final _VideoTile old) {
    super.didUpdateWidget(old);
    // The index loads a beat after the tiles first mount — re-resolve when it
    // (or the asset) changes so a late-arriving match still marks the tile.
    if (!identical(widget.membership, old.membership) ||
        widget.asset.localIdentifier != old.asset.localIdentifier) {
      _resolveMembership();
    }
  }

  /// Managed assets match by exact id (synchronous); local files fall back to
  /// a content-hash lookup; photo-library assets never match. Called only from
  /// lifecycle hooks that a build always follows, so the managed path assigns
  /// the field directly; the async hash path uses setState.
  void _resolveMembership() {
    final byManaged = widget.membership.memberMoveId(widget.asset);
    if (byManaged != null) {
      _memberMoveId = byManaged;
      return;
    }
    if (widget.asset.isLocal && _memberMoveId == null && !_localResolving) {
      _localResolving = true;
      unawaited(_resolveLocalMembership());
    }
  }

  Future<void> _resolveLocalMembership() async {
    final hash = await widget.hashResolver(widget.asset.localIdentifier);
    _localResolving = false;
    if (hash == null || !mounted) return;
    final id = widget.membership.memberMoveId(widget.asset, contentHash: hash);
    if (id != null && mounted) setState(() => _memberMoveId = id);
  }

  Future<void> _loadFileSize() async {
    try {
      final size = await File(widget.asset.localIdentifier).length();
      if (mounted) setState(() => _fileSizeBytes = size);
    } on Object catch (_) {
      // Size stays unknown — the overlay renders without it.
    }
  }

  String get _secondaryFact => formatTileSecondaryFact(
        sizeBytes: _fileSizeBytes,
        date: widget.asset.creationDate,
      );

  Future<void> _loadThumbnail() async {
    final asset = widget.asset;
    try {
      Uint8List? bytes;
      if (asset.isLocal) {
        final path = await ref.read(videoServiceProvider).generateThumbnail(asset.localIdentifier, maxWidth: 200);
        if (path != null) bytes = await File(path).readAsBytes();
      } else {
        bytes = await ref.read(videoServiceProvider).getAssetThumbnail(asset.localIdentifier);
      }
      if (mounted) setState(() { _thumbnail = bytes; _loading = false; });
    } on Object catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final durationBadge = formatDurationBadge(widget.asset.duration);
    return GestureDetector(
      onTap: () => widget.onSelect(widget.asset, _thumbnail),
      child: AnimatedContainer(
        duration: 200.ms,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.xxs),
          border: Border.all(
            color: widget.isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_thumbnail != null) Image.memory(_thumbnail!, fit: BoxFit.cover)
            else if (_loading) const Center(child: SizedBox(width: 20, height: 20, child: AppLoader(size: 6))),
            
            if (widget.isSelected) Container(color: colorScheme.primary.withValues(alpha: 0.2)),

            // Slot 4 — membership mark: already-in-Breakdex, top-left, tinted
            // distinctly from the primary selection check so the two never read
            // as one badge.
            if (_memberMoveId != null)
              Positioned(
                top: 4, left: 4,
                child: Semantics(
                  label: 'Already in Breakdex',
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bookmark_added_rounded,
                        size: 11, color: colorScheme.onTertiary),
                  ),
                ),
              ),

            // Slot 1 pair — duration badge riding the thumbnail, bottom-right.
            if (durationBadge.isNotEmpty)
              Positioned(
                bottom: 4, right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    durationBadge,
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),

            // Slots 2 & 3 — name over one secondary fact, bottom-left. The name
            // reserves right space so it never runs under the duration badge.
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_secondaryFact.isNotEmpty)
                      Text(
                        _secondaryFact,
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Padding(
                      padding: EdgeInsets.only(right: durationBadge.isNotEmpty ? 34 : 0),
                      child: Text(
                        widget.asset.originalFileName,
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 4, right: 4,
              child: AnimatedScale(
                scale: widget.isSelected ? 1.0 : 0.0,
                duration: 200.ms,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
