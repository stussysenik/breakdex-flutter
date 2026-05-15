import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/theme.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/models/reviewable_item.dart';
import '../../core/navigation/app_route_observer.dart';
import '../../core/providers.dart';
import '../../core/services/fsrs_service.dart';
import '../../core/services/native_video_album.dart';
import '../../core/services/video_path_resolver.dart';
import '../../shared/widgets/primary_button.dart';
import 'providers/deck_providers.dart';
import 'providers/review_providers.dart';
import 'widgets/rating_button_row.dart';
import 'widgets/mastery_prescreen.dart';
import 'widgets/review_card.dart';
import 'widgets/state_picker_sheet.dart';
import '../../shared/widgets/app_segmented_control.dart';
import '../../shared/widgets/celebration_overlay.dart';
import '../../shared/widgets/video_picker_sheet.dart';
import '../lab/providers/achievement_providers.dart';
import 'review_session_state.dart';

class FlashcardReviewScreen extends ConsumerStatefulWidget {
  const FlashcardReviewScreen({super.key});

  @override
  ConsumerState<FlashcardReviewScreen> createState() =>
      _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends ConsumerState<FlashcardReviewScreen>
    with SingleTickerProviderStateMixin, RouteAware, WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _completed = false;
  bool _assessmentStageVisible = false;
  List<ReviewSessionItem> _items = [];
  bool _initialized = false;
  List<ReviewSessionItem>? _pendingSessionItems;

  // Card exit animation state — scale + fade before page transition
  double _cardScale = 1.0;
  double _cardOpacity = 1.0;
  bool _animatingExit = false;

  // Double-tap guard — prevents multiple ratings while the card is
  // animating out. Set true at the start of _rateItem, cleared after
  // the page animation completes (not just the exit fade).
  bool _isProcessingRating = false;

  // Playback controls — managed at the screen level so they persist across
  // card transitions and the instrument panel can toggle them.
  bool _loopEnabled = true;
  double _playbackSpeed = 1.0;
  static const _speedPresets = [0.5, 1.0, 1.5, 2.0];

  // Breathing animation — subtle 0.6% scale oscillation when idle.
  // Signals "alive" state, draws attention to the card, invites interaction.
  late final AnimationController _breathController;

  // Shake-to-skip: accelerometer subscription + debounce
  StreamSubscription<AccelerometerEvent>? _shakeSubscription;
  DateTime _lastShakeTime = DateTime(2000);
  static const _shakeThreshold = 17.0;
  static const _shakeCooldown = Duration(milliseconds: 800);
  ModalRoute<dynamic>? _route;
  bool _tickerModeEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextRoute = ModalRoute.of(context);
    if (_route != nextRoute) {
      if (_route is ModalRoute<dynamic>) {
        appRouteObserver.unsubscribe(this);
      }
      _route = nextRoute;
      if (nextRoute is ModalRoute<dynamic>) {
        appRouteObserver.subscribe(this, nextRoute);
      }
    }

    final tickerModeEnabled = TickerMode.valuesOf(context).enabled;
    if (_tickerModeEnabled != tickerModeEnabled) {
      final becameVisible = !_tickerModeEnabled && tickerModeEnabled;
      _tickerModeEnabled = tickerModeEnabled;
      if (becameVisible) {
        _reloadSessionIfActive();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_route is ModalRoute<dynamic>) {
      appRouteObserver.unsubscribe(this);
    }
    _breathController.dispose();
    _stopShakeListener();
    super.dispose();
  }

  void _resetSessionState() {
    _stopShakeListener();
    _currentIndex = 0;
    _completed = false;
    _assessmentStageVisible = false;
    _items = [];
    _initialized = false;
    _pendingSessionItems = null;
    _cardScale = 1.0;
    _cardOpacity = 1.0;
    _animatingExit = false;
    _isProcessingRating = false;
  }

  void _endSession({bool clearTarget = true}) {
    setState(_resetSessionState);
    if (clearTarget) {
      ref.read(reviewSessionTargetMoveIdsProvider.notifier).state = null;
    }
    ref.read(reviewSessionActiveProvider.notifier).state = false;
  }

  /// Shows a confirmation sheet before ending the session — prevents
  /// accidental taps from destroying the practitioner's flow state.
  void _confirmEndSession() {
    final reviewed = _currentIndex;
    final total = _items.length;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenEdge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'End session?',
                  style: AppTypography.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  "You've reviewed $reviewed of $total cards.",
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Continue'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _endSession();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                        ),
                        child: const Text('End'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _cycleSpeed() {
    setState(() {
      final currentIdx = _speedPresets.indexOf(_playbackSpeed);
      final nextIdx = currentIdx < 0
          ? 1
          : (currentIdx + 1) % _speedPresets.length;
      _playbackSpeed = _speedPresets[nextIdx];
    });
  }

  void _toggleLoop() {
    setState(() {
      _loopEnabled = !_loopEnabled;
    });
  }

  void _setReviewMode(ReviewMode mode) {
    ref.read(reviewModeProvider.notifier).set(mode);
    setState(_resetSessionState);
    ref.read(reviewSessionActiveProvider.notifier).state = false;
  }

  void _showAssessmentStage() {
    if (_assessmentStageVisible || _items.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _assessmentStageVisible = true);
  }

  void _reloadSessionIfActive() {
    if (!mounted) return;
    if (!ref.read(reviewSessionActiveProvider)) return;
    ref.invalidate(filteredReviewSessionItemsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reviewMode = ref.watch(reviewModeProvider);
    final sessionActive = ref.watch(reviewSessionActiveProvider);

    // When session is active, the immersive card fills the screen —
    // header and segment control are hidden. End button lives in the
    // card's top overlay instead.
    if (sessionActive) {
      return Scaffold(body: SafeArea(child: _buildFlashcardSession()));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdge,
              ),
              child: Text(
                'Drill',
                style: AppTypography.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdge,
              ),
              child: AppSegmentedControl<ReviewMode>(
                items: const [
                  AppSegmentedControlItem(
                    value: ReviewMode.review,
                    icon: Icons.grid_view_rounded,
                    label: 'Review',
                  ),
                  AppSegmentedControlItem(
                    value: ReviewMode.deck,
                    icon: Icons.layers_rounded,
                    label: 'Deck',
                  ),
                ],
                selectedValue: reviewMode,
                onChanged: _setReviewMode,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            Expanded(
              child: MasteryPrescreen(
                source: reviewMode == ReviewMode.deck
                    ? ReviewSessionSource.deck
                    : ReviewSessionSource.stateBased,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardSession() {
    final itemsAsync = ref.watch(filteredReviewSessionItemsProvider);

    // Reset session when filters change (provider re-fetches)
    ref.listen(filteredReviewSessionItemsProvider, (prev, next) {
      if (next is AsyncData<List<ReviewSessionItem>> && prev != next) {
        _queueOrApplySessionItems(next.value);
      }
    });

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        // First load — also start shake listener for the active session
        if (!_initialized) {
          _items = List.from(items);
          _initialized = true;
          _startShakeListener();
        }

        final colorScheme = Theme.of(context).colorScheme;

        // No dashboard — the active card owns its compact progress badge
        if (_items.isEmpty) return _buildEmpty(colorScheme);
        if (_completed) return _buildCompleted(colorScheme);
        return _buildReviewContent();
      },
    );
  }

  /// Two-stage review layout:
  /// 1. Video + configurable learning info
  /// 2. Assessment controls
  Widget _buildReviewContent() {
    final item = _items[_currentIndex];
    final colorScheme = Theme.of(context).colorScheme;
    final displaySettings = ref.watch(reviewCardDisplaySettingsProvider);
    final intervalsAsync = ref.watch(
      intervalPreviewProvider((
        entityId: item.entityId,
        entityType: item.entityType,
      )),
    );
    final intervals = intervalsAsync.valueOrNull;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        // Immersive card fills available space
        Expanded(
          // Breathing animation: 0.6% scale oscillation when idle.
          child: AnimatedBuilder(
            animation: _breathController,
            builder: (context, child) {
              final reduceMotion = MediaQuery.of(context).disableAnimations;
              final breathScale = reduceMotion
                  ? 1.0
                  : 1.0 +
                        (0.006 *
                            Curves.easeInOut.transform(
                              _breathController.value,
                            ));
              return Transform.scale(
                scale: breathScale * _cardScale,
                child: child,
              );
            },
            child: AnimatedOpacity(
              opacity: _cardOpacity,
              duration: AppMotion.moderate01,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ReviewCard(
                      key: ValueKey(
                        'review-card-${item.entityType}-${item.entityId}',
                      ),
                      displaySettings: displaySettings,
                      showMetadataPanel: !_assessmentStageVisible,
                      title: item.displayName,
                      state: item.state,
                      category: item.category,
                      videoPath: item.videoPath,
                      originalVideoName: item.originalVideoName,
                      canEditState: item.isMove,
                      combo: item.combo,
                      currentIndex: _currentIndex,
                      totalItems: _items.length,
                      onEnd: _confirmEndSession,
                      onStatePillTap: () {
                        if (item.isMove && item.move != null) {
                          _showStatePicker(item.move!, _currentIndex);
                        }
                      },
                      onRepick: item.isMove && item.move != null
                          ? () => _repickVideo(item.move!, _currentIndex)
                          : null,
                      loopEnabled: _loopEnabled,
                      onLoopToggle: _toggleLoop,
                      playbackSpeed: _playbackSpeed,
                      onSpeedCycle: _cycleSpeed,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        AnimatedSwitcher(
          duration: AppMotion.moderate01,
          child: _assessmentStageVisible
              ? Padding(
                  key: const ValueKey('rating-strip'),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenEdge,
                    AppSpacing.sm,
                    AppSpacing.screenEdge,
                    AppSpacing.sm + bottomPadding,
                  ),
                  child: RatingButtonRow(
                    compact: true,
                    onRate: (rating) => _rateItem(item, rating),
                    intervalPreviews: intervals,
                  ),
                )
              : Padding(
                  key: const ValueKey('assessment-stage'),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenEdge,
                    AppSpacing.sm,
                    AppSpacing.screenEdge,
                    AppSpacing.sm + bottomPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Watch the clip, then move to assessment.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: 'Assess',
                          onPressed: _showAssessmentStage,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    final stateFilter = ref.watch(reviewStateFilterProvider);
    final selectedDeck = ref.watch(selectedDeckProvider);
    final targetMoveIds = ref.watch(reviewSessionTargetMoveIdsProvider);
    final reviewSource = ref.watch(reviewSessionSourceProvider);
    final entityKind = ref.watch(reviewEntityKindProvider);
    final stateLabels = ref.watch(learningStateLabelsProvider);
    final totalReviewable =
        ref.watch(totalReviewableCountProvider).valueOrNull ?? 0;

    if (targetMoveIds != null && targetMoveIds.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.remove_circle_outline,
              size: 64,
              color: colorScheme.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'That move is no longer available',
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(onPressed: _endSession, child: const Text('Back')),
          ],
        ),
      );
    }

    if (totalReviewable == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_add_outlined,
              size: 64,
              color: colorScheme.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your breakdex is empty',
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add moves from the Arsenal tab to start reviewing',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => context.go('/moves'),
              icon: const Icon(Icons.add),
              label: const Text('Add a Move'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final message = switch (reviewSource) {
      ReviewSessionSource.deck =>
        selectedDeck == null
            ? 'Pick a deck to start a review session'
            : '"${selectedDeck.name}" has no matching cards',
      ReviewSessionSource.stateBased when stateFilter != null =>
        'No due ${(stateLabels[stateFilter] ?? stateFilter.displayText).toLowerCase()} ${entityKind == ReviewEntityKind.moves ? 'move cards' : 'combo cards'} available',
      ReviewSessionSource.stateBased =>
        'No due ${entityKind == ReviewEntityKind.moves ? 'move cards' : 'combo cards'} available for this session',
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_off, size: 64, color: colorScheme.secondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.titleMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: _endSession,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back to Review'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleted(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            decoration: AppSurfaces.panel(
              context,
              raised: true,
              focused: true,
              radius: AppRadius.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.actionGood.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 48,
                    color: AppColors.actionGood,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Great work!',
                  style: AppTypography.titleLarge.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'All ${_items.length} cards reviewed',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Review Again',
                  onPressed: () {
                    setState(() {
                      _resetSessionState();
                    });
                    refreshReviewSession(ref);
                    _startShakeListener();
                  },
                  color: colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _endSession,
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.secondary,
                    textStyle: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Back to Review'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startShakeListener() {
    _shakeSubscription?.cancel();
    _shakeSubscription =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 50),
        ).listen((event) {
          final magnitude = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );
          final now = DateTime.now();
          if (magnitude > _shakeThreshold &&
              now.difference(_lastShakeTime) > _shakeCooldown) {
            _lastShakeTime = now;
            HapticFeedback.heavyImpact();
            _skip();
          }
        });
  }

  void _queueOrApplySessionItems(List<ReviewSessionItem> nextItems) {
    if (_isProcessingRating || _animatingExit) {
      _pendingSessionItems = List<ReviewSessionItem>.from(nextItems);
      return;
    }
    _applySessionItems(nextItems);
  }

  void _applySessionItems(List<ReviewSessionItem> nextItems) {
    final reconciliation = reconcileReviewSession(
      previousItems: _items,
      nextItems: nextItems,
      currentIndex: _currentIndex,
      completed: _completed,
      assessmentStageVisible: _assessmentStageVisible,
    );
    setState(() {
      _items = List.from(reconciliation.items);
      _currentIndex = reconciliation.currentIndex;
      _completed = reconciliation.completed;
      _assessmentStageVisible = reconciliation.assessmentStageVisible;
      _initialized = true;
    });
    if (_items.isEmpty) {
      _stopShakeListener();
    } else {
      _startShakeListener();
    }
  }

  void _flushPendingSessionItems() {
    final pending = _pendingSessionItems;
    if (pending == null) return;
    _pendingSessionItems = null;
    if (_completed && pending.isEmpty) {
      return;
    }
    _applySessionItems(pending);
  }

  void _stopShakeListener() {
    _shakeSubscription?.cancel();
    _shakeSubscription = null;
  }

  Future<void> _repickVideo(Move move, int index) async {
    final result = await VideoPickerSheet.show(
      context,
      previousVideoName: move.originalVideoName,
    );
    if (result == null) return;

    final relativePath = VideoPathResolver.toRelative(result.localPath);
    await ref
        .read(mediaCleanupServiceProvider)
        .cleanupDetachedAsset(
          title: move.name,
          category: move.category,
          storedVideoPath: move.videoPath,
          resolvedVideoPath: move.resolvedVideoPath,
          contentHash: move.contentHash,
          managedAlbumAssetId: move.managedAlbumAssetId,
          excludingMoveId: move.id,
        );
    await ref
        .read(moveRepositoryProvider)
        .update(
          MovesCompanion(
            id: Value(move.id),
            videoPath: Value(relativePath),
            originalVideoName: Value(result.originalFileName),
            managedAlbumAssetId: const Value(null),
            managedAlbumFilename: const Value(null),
            managedAlbumName: const Value(null),
            contentHash: const Value(null),
          ),
        );
    unawaited(
      ref
          .read(videoImportSyncHookProvider)
          .onVideoImported(localPath: result.localPath, moveId: move.id),
    );
    ManagedAlbumCopy? managedCopy;
    try {
      managedCopy = await NativeVideoAlbum().saveToAlbum(
        videoPath: result.localPath,
        albumName: NativeVideoAlbum.defaultAlbumName(),
        assetTitle: move.name,
        category: move.category,
      );
      await ref
          .read(moveRepositoryProvider)
          .update(
            MovesCompanion(
              id: Value(move.id),
              managedAlbumAssetId: Value(managedCopy?.assetLocalIdentifier),
              managedAlbumFilename: Value(managedCopy?.filename),
              managedAlbumName: Value(managedCopy?.albumName),
            ),
          );
    } catch (error) {
      debugPrint('Album save failed during review repick: $error');
    }

    setState(() {
      _items[index] = ReviewSessionItem(
        entityId: move.id,
        entityType: 'move',
        displayName: move.name,
        state: _items[index].state,
        category: move.category,
        videoPath: VideoPathResolver.toAbsolute(relativePath),
        originalVideoName: result.originalFileName,
        move: move.copyWith(
          videoPath: Value(relativePath),
          originalVideoName: Value(result.originalFileName),
          managedAlbumAssetId: Value(managedCopy?.assetLocalIdentifier),
          managedAlbumFilename: Value(managedCopy?.filename),
          managedAlbumName: Value(managedCopy?.albumName),
        ),
      );
    });
  }

  Future<void> _showStatePicker(Move move, int index) async {
    final currentState = _items[index].state;
    final newState = await StatePickerSheet.show(
      context,
      currentState: currentState,
      moveName: move.name,
    );

    if (newState == null || newState == currentState) return;

    final manualResult = await ref
        .read(manualReviewStateServiceProvider)
        .setMoveState(move, newState);

    await ref
        .read(reviewRepositoryProvider)
        .insert(
          ReviewsCompanion.insert(
            id: const Uuid().v4(),
            rating: manualResult.reviewRating.dbValue,
            reviewType: ReviewType.manual.dbValue,
            moveId: Value(move.id),
            entityIdSnapshot: Value(move.id),
            entityType: const Value('move'),
            entityDisplayName: Value(move.name),
            entityCategory: Value(move.category),
            fsrsPreState: Value(manualResult.preFsrsState),
            fsrsPostState: Value(manualResult.postFsrsState),
          ),
        );

    setState(() {
      _items[index] = ReviewSessionItem(
        entityId: move.id,
        entityType: 'move',
        displayName: move.name,
        state: newState,
        category: move.category,
        videoPath: move.resolvedVideoPath,
        originalVideoName: move.originalVideoName,
        move: move.copyWith(learningState: newState.dbValue),
      );
    });
  }

  Future<void> _rateItem(ReviewSessionItem item, ReviewRating rating) async {
    if (_isProcessingRating) return;
    _isProcessingRating = true;

    if (item.isMove && item.move != null) {
      final move = item.move!;
      final fsrsResult = await ref
          .read(fsrsServiceProvider)
          .processReview(move.id, rating, entityType: 'move');
      final nextState = learningStateFromFsrsState(fsrsResult.postState);

      await ref
          .read(moveRepositoryProvider)
          .update(
            MovesCompanion(
              id: Value(move.id),
              learningState: Value(nextState.dbValue),
            ),
          );
      await ref
          .read(syncDaoProvider)
          .logChange(entityId: move.id, table: 'fsrs_cards', action: 'update');

      await ref
          .read(reviewRepositoryProvider)
          .insert(
            ReviewsCompanion.insert(
              id: const Uuid().v4(),
              rating: rating.dbValue,
              reviewType: ReviewType.move.dbValue,
              moveId: Value(move.id),
              entityIdSnapshot: Value(move.id),
              entityType: const Value('move'),
              entityDisplayName: Value(move.name),
              entityCategory: Value(move.category),
              fsrsPreState: Value(fsrsResult.preState),
              fsrsPostState: Value(fsrsResult.postState),
            ),
          );

      setState(() {
        _items[_currentIndex] = ReviewSessionItem(
          entityId: move.id,
          entityType: 'move',
          displayName: move.name,
          state: nextState,
          category: move.category,
          videoPath: move.resolvedVideoPath,
          originalVideoName: move.originalVideoName,
          move: move.copyWith(learningState: nextState.dbValue),
        );
      });

      // Achievement Garden: check if this review pushed the move to a new tier.
      // Runs after review + FSRS update so tier criteria reflect the latest data.
      _checkAchievementAdvancement(move.id, move.name);
    } else if (item.isCombo && item.combo != null) {
      final combo = item.combo!;
      final fsrsResult = await ref
          .read(fsrsServiceProvider)
          .processReview(combo.id, rating, entityType: 'combo');
      await ref
          .read(syncDaoProvider)
          .logChange(entityId: combo.id, table: 'fsrs_cards', action: 'update');

      await ref
          .read(reviewRepositoryProvider)
          .insert(
            ReviewsCompanion.insert(
              id: const Uuid().v4(),
              rating: rating.dbValue,
              reviewType: ReviewType.combo.dbValue,
              comboId: Value(combo.id),
              entityIdSnapshot: Value(combo.id),
              entityType: const Value('combo'),
              entityDisplayName: Value(combo.name),
              entityCategory: const Value('combo'),
              fsrsPreState: Value(fsrsResult.preState),
              fsrsPostState: Value(fsrsResult.postState),
            ),
          );

      setState(() {
        _items[_currentIndex] = ReviewSessionItem(
          entityId: combo.id,
          entityType: 'combo',
          displayName: combo.name,
          state: learningStateFromFsrsState(fsrsResult.postState),
          category: 'combo',
          videoPath: combo.resolvedActiveVideoPath,
          combo: combo,
        );
      });
    }

    _animatedAdvance();
  }

  /// Fire-and-forget achievement tier check after a move review.
  ///
  /// Runs asynchronously so it doesn't block the card advance animation.
  /// If the move earns a higher tier, the celebration overlay fires on top
  /// of the current screen. The overlay auto-dismisses after 1.5s.
  void _checkAchievementAdvancement(String moveId, String moveName) {
    final service = ref.read(achievementServiceProvider);
    service.checkAndAdvanceTier(moveId).then((newTier) {
      if (newTier != null && mounted) {
        final label = switch (newTier) {
          'sprouting' => '\u{1F331} $moveName is sprouting!',
          'growing' => '\u{1F33F} $moveName is growing!',
          'mastered' => '\u{1F48E} $moveName mastered!',
          _ => '$moveName leveled up!',
        };
        CelebrationOverlay.show(context, title: label);
      }
    });
  }

  void _skip() {
    HapticFeedback.lightImpact();
    _advance();
  }

  /// Plays a scale-down + fade exit animation, then advances to the next card.
  /// The quick fade keeps the next card from popping in abruptly.
  void _animatedAdvance() {
    if (_animatingExit) return;
    setState(() {
      _animatingExit = true;
      _cardScale = 0.95;
      _cardOpacity = 0.0;
    });

    Future.delayed(AppMotion.moderate01, () {
      if (!mounted) return;
      _advance();
      _flushPendingSessionItems();
      setState(() {
        _cardScale = 1.0;
        _cardOpacity = 1.0;
        _assessmentStageVisible = false;
      });

      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        setState(() {
          _animatingExit = false;
        });
        _isProcessingRating = false;
      });
    });
  }

  void _advance() {
    if (_currentIndex < _items.length - 1) {
      setState(() {
        _currentIndex += 1;
        _assessmentStageVisible = false;
      });
    } else {
      _stopShakeListener();
      setState(() {
        _completed = true;
        _assessmentStageVisible = false;
      });
    }
  }

  @override
  void didPopNext() => _reloadSessionIfActive();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _reloadSessionIfActive();
  }
}
