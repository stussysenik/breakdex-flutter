import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/providers.dart';
import '../../core/services/video_service.dart';
import '../../core/services/storage_action_machine.dart';
import '../../core/services/video_path_resolver.dart';
import '../../core/utils/app_clock.dart';
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
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
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
    } catch (_) {
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
    } catch (_) {
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
    } catch (_) {
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
    } catch (e) {
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('IMPORT VIDEO'),
                        ),
                      ),
                    ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutCubic),
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
      return const Center(child: CircularProgressIndicator());
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
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)));
        }
        
        final asset = assets[index];
        final isSelected = _selectedIds.contains(asset.localIdentifier);
        
        return _VideoTile(
          asset: asset,
          isSelected: isSelected,
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
                    onPressed: _handleImport,
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
                    borderRadius: BorderRadius.circular(24),
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

/// "0:12 · 48 MB · Jun 8" — duration/size first (what distinguishes
/// takes), date second. Unknown parts are simply omitted.
@visibleForTesting
String formatVideoFactsLine({
  required final double durationSeconds,
  final int? sizeBytes,
  final DateTime? date,
}) {
  final parts = <String>[];
  if (durationSeconds > 0) {
    final mins = durationSeconds ~/ 60;
    final secs = (durationSeconds % 60).round().toString().padLeft(2, '0');
    parts.add('$mins:$secs');
  }
  if (sizeBytes != null && sizeBytes > 0) {
    final mb = sizeBytes / (1024 * 1024);
    parts.add(mb >= 100 ? '${mb.round()} MB' : '${mb.toStringAsFixed(1)} MB');
  }
  if (date != null) {
    parts.add('${_monthNames[date.month - 1]} ${date.day}');
  }
  return parts.join(' · ');
}

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class _VideoTile extends ConsumerStatefulWidget {
  final MetadataAsset asset;
  final bool isSelected;
  final void Function(MetadataAsset, Uint8List?) onSelect;

  const _VideoTile({
    required this.asset,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  ConsumerState<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends ConsumerState<_VideoTile> {
  Uint8List? _thumbnail;
  bool _loading = true;
  int? _fileSizeBytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_thumbnail == null && _loading) _loadThumbnail();
    if (_fileSizeBytes == null && widget.asset.isLocal) _loadFileSize();
  }

  Future<void> _loadFileSize() async {
    try {
      final size = await File(widget.asset.localIdentifier).length();
      if (mounted) setState(() => _fileSizeBytes = size);
    } catch (_) {
      // Size stays unknown — the overlay renders without it.
    }
  }

  String get _factsLine => formatVideoFactsLine(
        durationSeconds: widget.asset.duration,
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
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => widget.onSelect(widget.asset, _thumbnail),
      child: AnimatedContainer(
        duration: 200.ms,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
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
            else if (_loading) const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 1))),
            
            if (widget.isSelected) Container(color: colorScheme.primary.withValues(alpha: 0.2)),
            
            // Metadata Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                    if (_factsLine.isNotEmpty)
                      Text(
                        _factsLine,
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      widget.asset.originalFileName,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
