import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/providers.dart';
import '../../core/services/video_service.dart';
import '../../core/utils/diagnostics.dart';

class MetadataVideoPickerSheet extends ConsumerStatefulWidget {
  const MetadataVideoPickerSheet({super.key});

  static Future<VideoPickResult?> show(final BuildContext context) {
    DiagnosticsLog.info('MetadataVideoPickerSheet', 'Opening custom high-fidelity picker');
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
  List<MetadataAsset>? _libraryAssets;
  List<MetadataAsset>? _appAssets;
  bool _loading = true;
  String? _error;

  // Ghosting / Pre-rendering import state
  MetadataAsset? _importingAsset;
  Uint8List? _importingThumbnail;
  double _importProgress = 0.0;
  StreamSubscription<double>? _progressSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _progressSub?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    DiagnosticsLog.info('MetadataVideoPickerSheet', 'Starting full asset load (recursive)');
    try {
      final results = await Future.wait([
        ref.read(videoServiceProvider).fetchPhotoLibraryVideos(),
        _fetchAppVideos(),
      ]);
      if (mounted) {
        setState(() {
          _libraryAssets = results[0];
          _appAssets = results[1];
          _loading = false;
        });
        DiagnosticsLog.info('MetadataVideoPickerSheet', 'Load complete: lib=${_libraryAssets?.length ?? 0}, app=${_appAssets?.length ?? 0}');
      }
    } catch (e) {
      DiagnosticsLog.error('MetadataVideoPickerSheet', 'Failed to load assets: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<List<MetadataAsset>> _fetchAppVideos() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final movesDir = Directory(p.join(docs.path, 'Moves'));
      if (!await movesDir.exists()) {
         DiagnosticsLog.info('MetadataVideoPickerSheet', 'Moves directory does not exist at ${movesDir.path}');
         return [];
      }

      final List<FileSystemEntity> entities = await movesDir.list(recursive: true).toList();
      final List<MetadataAsset> assets = [];
      
      for (final entity in entities) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          if (path.contains('/.thumbs/') || path.contains('/.ds_store')) continue;
          
          if (path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.m4v')) {
            try {
              final stat = await entity.stat();
              assets.add(MetadataAsset(
                localIdentifier: entity.path, 
                originalFileName: p.basename(entity.path),
                creationDate: stat.changed,
                duration: 0,
                width: 0,
                height: 0,
                isLocal: true,
              ));
            } catch (e) {
              DiagnosticsLog.warn('MetadataVideoPickerSheet', 'Failed to stat local file ${entity.path}: $e');
            }
          }
        }
      }
      
      assets.sort((final a, final b) => (b.creationDate ?? DateTime(0)).compareTo(a.creationDate ?? DateTime(0)));
      DiagnosticsLog.info('MetadataVideoPickerSheet', 'App videos detected: ${assets.length}');
      return assets;
    } catch (e) {
      DiagnosticsLog.error('MetadataVideoPickerSheet', 'Error listing app videos: $e');
      return [];
    }
  }

  Future<void> _handleSelection(final MetadataAsset asset, final Uint8List? thumbnail) async {
    // Immediate pre-rendering / ghosting feedback (under 3ms)
    setState(() {
      _importingAsset = asset;
      _importingThumbnail = thumbnail;
      _importProgress = 0.0;
    });

    _progressSub?.cancel();
    _progressSub = ref.read(videoServiceProvider).importProgress.listen((final p) {
      if (mounted) setState(() => _importProgress = p);
    });

    final navigator = Navigator.of(context);
    final logger = StageLogger.begin('ImportAsset', subsystem: 'MetadataVideoPickerSheet', context: {
      'name': asset.originalFileName,
      'isLocal': asset.isLocal,
    });
    
    try {
      VideoPickResult? result;
      if (asset.isLocal) {
        // Give the UI a tiny moment to show the ghost state so the transition isn't harsh
        await Future<void>.delayed(const Duration(milliseconds: 150));
        result = VideoPickResult(
          localPath: asset.localIdentifier,
          originalFileName: asset.originalFileName,
          creationDate: asset.creationDate,
        );
      } else {
        logger.stage('import_native');
        result = await ref.read(videoServiceProvider).importSpecificAsset(asset.localIdentifier);
      }
      
      if (mounted) {
        logger.complete(result != null ? 'success' : 'cancelled');
        navigator.pop(result);
      }
    } catch (e, st) {
      logger.fail(e, st);
      if (mounted) {
        setState(() {
          _importingAsset = null;
          _importingThumbnail = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      await _progressSub?.cancel();
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _buildHandle(context),
              _buildHeader(context),
              const SizedBox(height: AppSpacing.sm),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'PHOTO LIBRARY'),
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
                    _buildGrid(_libraryAssets, 'Photos'),
                    _buildGrid(_appAssets, 'Managed'),
                  ],
                ),
              ),
            ],
          ),
          
          if (_importingAsset != null)
            _buildGhostingOverlay(context),
        ],
      ),
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
            if (_importingThumbnail != null)
              Image.memory(_importingThumbnail!, fit: BoxFit.cover),
            
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
              child: Container(color: Colors.black.withValues(alpha: 0.75)),
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _importingThumbnail != null
                      ? Image.memory(_importingThumbnail!, fit: BoxFit.cover)
                      : const Icon(Icons.videocam, size: 64, color: Colors.white54),
                ).animate().scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutCubic, duration: 400.ms),
                
                const SizedBox(height: AppSpacing.xxl),
                
                Text(
                  'IMPORTING VIDEO',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    letterSpacing: 3.0,
                    fontWeight: FontWeight.w900,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
                
                const SizedBox(height: AppSpacing.md),
                
                SizedBox(
                  width: 220,
                  height: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: _importProgress > 0 ? _importProgress : null,
                      backgroundColor: Colors.white24,
                      color: colorScheme.primary,
                    ),
                  ),
                ).animate().fadeIn(delay: 150.ms),
                
                const SizedBox(height: AppSpacing.sm),
                
                Text(
                  '${(_importProgress * 100).toInt()}%',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ).animate().fadeIn(delay: 150.ms),
              ],
            ).animate().fadeIn(duration: 300.ms),
          ],
        ),
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

  Widget _buildGrid(final List<MetadataAsset>? assets, final String sourceLabel) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: AppSpacing.md),
              Text('Sync Error', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_error!, style: AppTypography.caption, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (assets == null || assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined, size: 48, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text('NO VIDEOS FOUND', style: AppTypography.caption.copyWith(letterSpacing: 1.0, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Check your $sourceLabel storage', style: AppTypography.caption),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: assets.length,
      itemBuilder: (final context, final index) {
        return _VideoTile(
          asset: assets[index],
          onSelect: _handleSelection,
        );
      },
    );
  }
}

class _VideoTile extends ConsumerStatefulWidget {
  final MetadataAsset asset;
  final void Function(MetadataAsset, Uint8List?) onSelect;

  const _VideoTile({required this.asset, required this.onSelect});

  @override
  ConsumerState<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends ConsumerState<_VideoTile> {
  Uint8List? _thumbnail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_thumbnail == null && _loading) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    final asset = widget.asset;
    const targetDim = 200;
    
    Uint8List? bytes;
    try {
      if (asset.isLocal) {
        final thumbPath = await ref.read(videoServiceProvider).generateThumbnail(
          asset.localIdentifier, 
          maxWidth: targetDim,
        );
        if (thumbPath != null) {
          bytes = await File(thumbPath).readAsBytes();
        }
      } else {
        bytes = await ref.read(videoServiceProvider).getAssetThumbnail(
          asset.localIdentifier,
          width: targetDim,
          height: targetDim,
        );
      }
    } catch (e) {
      DiagnosticsLog.warn('MetadataVideoPickerSheet', 'Thumb load error: $e');
    }
    
    if (mounted) {
      setState(() {
        _thumbnail = bytes;
        _loading = false;
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final asset = widget.asset;
    
    final dateStr = asset.creationDate != null 
      ? DateFormat('MMM d, yyyy').format(asset.creationDate!) 
      : 'UNKNOWN';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        unawaited(HapticFeedback.mediumImpact());
        widget.onSelect(asset, _thumbnail);
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_thumbnail != null)
              Image.memory(_thumbnail!, fit: BoxFit.cover, filterQuality: FilterQuality.medium)
                  .animate()
                  .fade(duration: 300.ms)
            else if (_loading)
              const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
            else
              const Icon(Icons.videocam_rounded, size: 24),
            
            // Source Anchor (Top Left)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  asset.isLocal ? Icons.verified_user_rounded : Icons.camera_roll_rounded,
                  size: 10,
                  color: asset.isLocal ? colorScheme.primaryContainer : Colors.white,
                ),
              ),
            ),

            // Duration / Beats Anchor (Bottom Right)
            if (!asset.isLocal && asset.duration > 0)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    _formatDuration(asset.duration),
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 8, 
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

            // Metadata Overlay (Bottom Left)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 12, 32, 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent, 
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.85)
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      asset.originalFileName.toUpperCase(),
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white, 
                        fontSize: 8, 
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      dateStr,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.7), 
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(final double seconds) {
    final d = Duration(seconds: seconds.round());
    final min = d.inMinutes;
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }
}