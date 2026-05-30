import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/models/reviewable_item.dart' show MoveVideoPath;
import '../../core/services/media_playback_coordinator.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/providers.dart';
import '../../core/services/media_playback_coordinator.dart';
import 'instax_video_card.dart';

enum InstaxMode {
  carousel,
  feed,
  tinder;

  InstaxMode get next {
    const values = InstaxMode.values;
    return values[(index + 1) % values.length];
  }

  String get label => switch (this) {
        InstaxMode.carousel => 'Carousel',
        InstaxMode.feed => 'Feed',
        InstaxMode.tinder => 'Tinder',
      };

  IconData get icon => switch (this) {
        InstaxMode.carousel => Icons.swap_horiz,
        InstaxMode.feed => Icons.view_agenda,
        InstaxMode.tinder => Icons.style,
      };
}

final _instaxModeProvider = StateProvider<InstaxMode>((_) => InstaxMode.carousel);
final _instaxCurrentIndexProvider = StateProvider<int>((_) => 0);

class InstaxViewerScreen extends ConsumerStatefulWidget {
  const InstaxViewerScreen({super.key, required this.category});

  final String category;

  @override
  ConsumerState<InstaxViewerScreen> createState() =>
      _InstaxViewerScreenState();
}

class _InstaxViewerScreenState extends ConsumerState<InstaxViewerScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('[InstaxViewer] init category=${widget.category}');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      MediaPlaybackCoordinator.shared.pauseAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(_instaxModeProvider);
    final movesAsync = ref.watch(_filteredMovesProvider(widget.category));
    debugPrint('[InstaxViewer] build mode=$mode category=${widget.category}');

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: _buildAppBar(mode),
      body: movesAsync.when(
        data: (moves) => InstaxVideoViewer(
          moves: moves,
          category: widget.category,
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => Center(
          child: Text('Failed to load moves', style: TextStyle(color: Colors.white38)),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(InstaxMode mode) {
    final colorScheme = Theme.of(context).colorScheme;
    return PreferredSize(
      preferredSize: const Size.fromHeight(56 + 50),
      child: Column(
        children: [
          AppBar(
            backgroundColor: AppColors.darkBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => context.pop(),
            ),
            title: Text(
              widget.category,
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdge,
            ),
            child: Row(
              children: InstaxMode.values.map((m) {
                final active = m == mode;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      debugPrint('[InstaxViewer] mode switch: $mode -> $m');
                      HapticFeedback.lightImpact();
                      ref.read(_instaxModeProvider.notifier).state = m;
                      ref.read(_instaxCurrentIndexProvider.notifier).state = 0;
                      MediaPlaybackCoordinator.shared.pauseAll();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: active
                            ? colorScheme.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: active
                            ? Border.all(
                                color: colorScheme.primary.withValues(alpha: 0.4),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              m.icon,
                              size: 14,
                              color: active ? colorScheme.primary : Colors.white54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              m.label,
                              style: AppTypography.caption.copyWith(
                                color: active ? colorScheme.primary : Colors.white54,
                                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carousel mode: horizontal PageView ──

class _CarouselMode extends StatefulWidget {
  const _CarouselMode({required this.moves, required this.category});
  final List<Move> moves;
  final String category;

  @override
  State<_CarouselMode> createState() => _CarouselModeState();
}

class _CarouselModeState extends State<_CarouselMode> {
  late final PageController _pageController;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _activeIndex = 0;
    _pageController = PageController(viewportFraction: 0.92);
    debugPrint('[Carousel] init moves=${widget.moves.length}');
  }

  @override
  void dispose() {
    _pageController.dispose();
    MediaPlaybackCoordinator.shared.pauseAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.moves.isEmpty) return const SizedBox.shrink();
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          final page = _pageController.page?.round() ?? 0;
          if (page != _activeIndex) {
            setState(() => _activeIndex = page);
            debugPrint('[Carousel] page=$page move=${widget.moves[page].name}');
          }
        }
        return false;
      },
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.moves.length,
        onPageChanged: (i) {
          setState(() => _activeIndex = i);
          debugPrint('[Carousel] onPageChanged=$i move=${widget.moves[i].name}');
        },
        itemBuilder: (context, index) {
          final move = widget.moves[index];
          return InstaxVideoCard(
            move: move,
            isActive: index == _activeIndex,
            looping: true,
            onLongPress: () => _onEditVideo(move),
            onTap: () => _onTapMove(context, move),
          ).animate(key: ValueKey('carousel-$index')).fadeIn(
                duration: AppMotion.moderate01,
                delay: Duration(milliseconds: index.clamp(0, 10) * 40),
              );
        },
      ),
    );
  }

  void _onEditVideo(Move move) {
    HapticFeedback.mediumImpact();
    debugPrint('[Carousel] _onEditVideo moveId=${move.id}');
    // TODO: wire up video editor
  }
}

// ── Feed mode: vertical scroll ──

class _FeedMode extends StatefulWidget {
  const _FeedMode({required this.moves, required this.category});
  final List<Move> moves;
  final String category;

  @override
  State<_FeedMode> createState() => _FeedModeState();
}

class _FeedModeState extends State<_FeedMode> {
  final ScrollController _scrollController = ScrollController();
  int _activeIndex = 0;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    debugPrint('[Feed] init moves=${widget.moves.length}');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    MediaPlaybackCoordinator.shared.pauseAll();
    super.dispose();
  }

  void _onScroll() {
    _scrollOffset = _scrollController.offset;
    final screenHeight = MediaQuery.of(context).size.height - kToolbarHeight - 106;
    if (screenHeight <= 0) return;
    final newIndex = (_scrollOffset / screenHeight).round().clamp(
      0,
      widget.moves.length - 1,
    );
    if (newIndex != _activeIndex) {
      setState(() => _activeIndex = newIndex);
      debugPrint('[Feed] activeIndex=$newIndex move=${widget.moves[newIndex].name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.moves.isEmpty) return const SizedBox.shrink();
    final screenHeight = MediaQuery.of(context).size.height - kToolbarHeight - 106;
    debugPrint('[Feed] build activeIndex=$_activeIndex screenHeight=$screenHeight');

    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.moves.length,
      itemBuilder: (context, index) {
        final move = widget.moves[index];
        return SizedBox(
          height: screenHeight.clamp(400, double.infinity),
          child: InstaxVideoCard(
            move: move,
            isActive: index == _activeIndex,
            looping: true,
            muted: index != _activeIndex,
            onLongPress: () => _onEditVideo(move),
            onTap: () => _onTapMove(context, move),
          ).animate(key: ValueKey('feed-$index')).fadeIn(
                duration: AppMotion.moderate01,
                delay: Duration(milliseconds: index.clamp(0, 5) * 30),
              ),
        );
      },
    );
  }

  void _onEditVideo(Move move) {
    HapticFeedback.mediumImpact();
    debugPrint('[Feed] _onEditVideo moveId=${move.id}');
  }
}

// ── Tinder mode: card stack with swipe ──

class _TinderMode extends StatefulWidget {
  const _TinderMode({required this.moves, required this.category});
  final List<Move> moves;
  final String category;

  @override
  State<_TinderMode> createState() => _TinderModeState();
}

class _TinderModeState extends State<_TinderMode> {
  int _topIndex = 0;
  bool _swiping = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[Tinder] init moves=${widget.moves.length}');
  }

  @override
  void didUpdateWidget(_TinderMode old) {
    super.didUpdateWidget(old);
    if (widget.moves.length != old.moves.length) {
      _topIndex = _topIndex.clamp(0, widget.moves.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.moves.isEmpty) return const SizedBox.shrink();

    final visibleCards = <Widget>[];
    final maxStack = 3;

    for (int i = _topIndex; i < widget.moves.length && i < _topIndex + maxStack; i++) {
      final move = widget.moves[i];
      final offset = i - _topIndex;

      Widget card = InstaxVideoCard(
        key: ValueKey('tinder-${move.id}'),
        move: move,
        isActive: offset == 0,
        looping: true,
        muted: offset != 0,
        onLongPress: () => _onEditVideo(move),
        onTap: () => context.go('/moves/move/${move.id}'),
      );

      if (offset == 0 && widget.moves.length > 1) {
        card = GestureDetector(
          onHorizontalDragUpdate: (details) {
            if (_swiping) return;
            debugPrint('[Tinder] drag dx=${details.delta.dx}');
          },
          onHorizontalDragEnd: (details) {
            if (_swiping) return;
            final velocity = details.primaryVelocity ?? 0;
            debugPrint('[Tinder] drag end velocity=$velocity');
            if (velocity.abs() > 300) {
              setState(() {
                _swiping = true;
                if (velocity > 0) {
                  debugPrint('[Tinder] swiped RIGHT: ${move.name}');
                } else {
                  debugPrint('[Tinder] swiped LEFT: ${move.name}');
                }
                _topIndex++;
                _swiping = false;
              });
            }
          },
          child: card,
        );
      }

      card = card
          .animate(key: ValueKey('tinder-anim-$i'))
          .scale(
            begin: Offset(1 - offset * 0.05, 1 - offset * 0.05),
            end: const Offset(1, 1),
            duration: AppMotion.moderate01,
          )
          .slideY(
            begin: offset * 0.02,
            end: 0,
            duration: AppMotion.moderate01,
          );

      visibleCards.add(card);
    }

    return Stack(
      children: visibleCards.reversed.toList(),
    );
  }

  void _onEditVideo(Move move) {
    HapticFeedback.mediumImpact();
    debugPrint('[Tinder] _onEditVideo moveId=${move.id}');
  }
}

void _onTapMove(BuildContext context, Move move) {
  final videoPath = move.resolvedVideoPath;
  debugPrint('[InstaxViewer] _onTapMove moveId=${move.id} name="${move.name}" '
      'hasVideo=${videoPath != null}');
  if (videoPath != null) {
    context.push('/video-viewer', extra: {
      'videoPath': videoPath,
      'title': move.name,
    });
  } else {
    context.push('/breakdex/move/${move.id}');
  }
}

final _filteredMovesProvider =
    FutureProvider.family<List<Move>, String>((ref, category) async {
  final repo = ref.watch(moveRepositoryProvider);
  final all = await repo.getAll();
  return all.where((m) => m.category == category).toList();
});

class InstaxVideoViewer extends ConsumerWidget {
  const InstaxVideoViewer({
    super.key,
    required this.moves,
    required this.category,
  });

  final List<Move> moves;
  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(_instaxModeProvider);

    if (moves.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_outlined, size: 48, color: Colors.white24),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No moves yet',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white38),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap + to add your first $category move',
              style: AppTypography.caption.copyWith(color: Colors.white24),
            ),
          ],
        ),
      );
    }

    return switch (mode) {
      InstaxMode.carousel => _CarouselMode(moves: moves, category: category),
      InstaxMode.feed => _FeedMode(moves: moves, category: category),
      InstaxMode.tinder => _TinderMode(moves: moves, category: category),
    };
  }
}
