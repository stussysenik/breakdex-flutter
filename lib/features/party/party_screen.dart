import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/database/database.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/models/reviewable_item.dart' show MoveVideoPath;
import '../../core/providers.dart';
import '../../core/services/settings_service.dart';
import '../../shared/widgets/state_pill.dart';
import '../../shared/widgets/video_player_widget.dart' show RobustVideoPlayer;

import '../../core/services/swing_detector.dart';

enum _PartyPhase { idle, cycling, revealing, revealed }

class PartyScreen extends ConsumerStatefulWidget {
  const PartyScreen({super.key});

  @override
  ConsumerState<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends ConsumerState<PartyScreen>
    with SingleTickerProviderStateMixin {
  List<Move> _allMoves = [];
  Move? _currentMove;

  late final SwingDetector _swingDetector;
  static const _revealLockout = Duration(seconds: 3);

  _PartyPhase _phase = _PartyPhase.idle;
  bool _shakeLocked = false;
  Timer? _lockoutTimer;
  Timer? _cyclingTimer;
  Move? _finalMove;
  DateTime? _cycleStartTime;
  DateTime? _lastFlip;
  int _cycleDurationMs = 5500;

  static const _cycleFlipBaseMs = 60;
  static const _cycleFlipMaxMs = 260;

  late final AnimationController _revealController;
  late final Animation<double> _revealScaleY;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _swingDetector = SwingDetector(
      onSwing: _onShakeDetected,
    );
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _revealScaleY = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _stopShakeListener();
    _lockoutTimer?.cancel();
    _cyclingTimer?.cancel();
    _revealController.dispose();
    super.dispose();
  }

  void _startShakeListener() {
    _swingDetector.start();
  }

  void _stopShakeListener() {
    _swingDetector.stop();
  }

  void _onShakeDetected() {
    if (_allMoves.isEmpty || _shakeLocked || _phase == _PartyPhase.cycling) return;
    _shakeLocked = true;
    _cancelCycling();

    _cycleDurationMs = ref.read(partyCycleDurationMsProvider);

    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 80), () {
      HapticFeedback.heavyImpact();
    });

    final index = _random.nextInt(_allMoves.length);
    _finalMove = _allMoves[index];
    final now = DateTime.now();
    _cycleStartTime = now;
    _lastFlip = now;

    setState(() {
      _currentMove = _allMoves[_random.nextInt(_allMoves.length)];
      _phase = _PartyPhase.cycling;
    });

    _cyclingTimer = Timer.periodic(
      const Duration(milliseconds: _cycleFlipBaseMs),
      _onCycleTick,
    );
  }

  void _onCycleTick(Timer timer) {
    if (!mounted || _cycleStartTime == null || _finalMove == null) {
      timer.cancel();
      return;
    }

    final now = DateTime.now();
    final elapsed = now.difference(_cycleStartTime!);
    if (elapsed.inMilliseconds >= _cycleDurationMs) {
      timer.cancel();
      _finishCycling();
      return;
    }

    // Decelerating flip interval: starts fast, slows down over time
    final progress = elapsed.inMilliseconds / _cycleDurationMs;
    final intervalMs = _cycleFlipBaseMs +
        ((_cycleFlipMaxMs - _cycleFlipBaseMs) * progress * progress).round();

    final sinceLastFlip = now.difference(_lastFlip!);
    if (sinceLastFlip.inMilliseconds >= intervalMs) {
      _lastFlip = now;
      setState(() {
        _currentMove = _allMoves[_random.nextInt(_allMoves.length)];
      });
    }
  }

  void _finishCycling() {
    if (_finalMove == null) return;

    setState(() {
      _currentMove = _finalMove;
      _phase = _PartyPhase.revealing;
    });

    _revealController.reset();
    _revealController.forward().then((_) {
      if (!mounted) return;
      setState(() => _phase = _PartyPhase.revealed);
      _lockoutTimer?.cancel();
      _lockoutTimer = Timer(_revealLockout, () {
        if (mounted) setState(() => _shakeLocked = false);
      });
    });
  }

  void _cancelCycling() {
    _cyclingTimer?.cancel();
    _cyclingTimer = null;
    _shakeLocked = false;
    _phase = _PartyPhase.idle;
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(currentTabIndexProvider);

    if (tabIndex == 2) {
      _startShakeListener();
    } else {
      _stopShakeListener();
      _cancelCycling();
    }

    final movesAsync = ref.watch(_partyMovesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return movesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (moves) {
        _allMoves = moves;
        return Scaffold(
          body: SafeArea(
            child: _allMoves.isEmpty
                ? _buildEmptyState(colorScheme)
                : _buildPartyContent(colorScheme),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenEdge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration_outlined,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Party',
              style: AppTypography.titleLarge.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add moves to get the party started.\nShake to discover random moves!',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyContent(ColorScheme colorScheme) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.md,
            AppSpacing.screenEdge,
            0,
          ),
          child: Text(
            'Party',
            style: AppTypography.titleLarge.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(child: _buildCenterArea(colorScheme)),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.sm,
            AppSpacing.screenEdge,
            AppSpacing.sm + bottomPadding,
          ),
          child: _buildBottomHint(colorScheme),
        ),
      ],
    );
  }

  Widget _buildCenterArea(ColorScheme colorScheme) {
    if (_phase == _PartyPhase.idle) {
      return _buildIdlePrompt(colorScheme);
    }

    if (_phase == _PartyPhase.cycling) {
      return _buildCyclingDisplay(colorScheme);
    }

    if (_currentMove == null) return _buildIdlePrompt(colorScheme);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: AnimatedBuilder(
            animation: _revealScaleY,
            builder: (context, child) {
              return Transform.scale(
                scaleY: _revealScaleY.value.clamp(0.0, 1.0),
                alignment: Alignment.center,
                child: child,
              );
            },
            child: _buildMoveCard(colorScheme, _currentMove!),
          ),
        ),
      ),
    );
  }

  Widget _buildCyclingDisplay(ColorScheme colorScheme) {
    if (_currentMove == null) return const SizedBox.shrink();

    final elapsed = _cycleStartTime != null
        ? DateTime.now().difference(_cycleStartTime!)
        : Duration.zero;
    final progress = (elapsed.inMilliseconds / _cycleDurationMs)
        .clamp(0.0, 1.0);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar — fills up over the 5.5s cycle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Rapidly cycling move name
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 60),
            child: Text(
              _currentMove!.name,
              key: ValueKey(_currentMove!.id),
              style: AppTypography.titleLarge.copyWith(
                color: colorScheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Shuffling...',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdlePrompt(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 2,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Icon(
            Icons.vibration,
            size: 56,
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Shake to discover\na random move',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${_allMoves.length} move${_allMoves.length == 1 ? '' : 's'} ready',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: 48,
            height: 2,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveCard(ColorScheme colorScheme, Move move) {
    final state = LearningState.fromString(move.learningState);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => context.push('/breakdex/move/${move.id}'),
          child: Text(
            move.name,
            style: AppTypography.titleLarge.copyWith(
              color: colorScheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatePill(state: state),
            if (move.category.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  move.category,
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (move.videoPath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: RobustVideoPlayer(
              videoPath: move.resolvedVideoPath!,
              autoPlay: true,
              looping: true,
              muted: true,
              height: 220,
            ),
          )
        else
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome_outlined,
                size: 48,
                color: colorScheme.primary.withValues(alpha: 0.35),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        _MoveReviewStats(moveId: move.id),
        if (move.notes != null && move.notes!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            move.notes!,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _PhaseIndicator(phase: _phase, colorScheme: colorScheme),
      ],
    );
  }

  Widget _buildBottomHint(ColorScheme colorScheme) {
    final icon = _phase == _PartyPhase.cycling
        ? Icons.casino_outlined
        : Icons.vibration;

    String text;
    if (_shakeLocked && _phase != _PartyPhase.cycling) {
      text = 'Move locked — wait to shake again';
    } else if (_phase == _PartyPhase.idle) {
      text = 'Shake to discover a random move';
    } else if (_phase == _PartyPhase.cycling) {
      text = 'Discovering your move...';
    } else {
      text = 'Shake again for another move';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color: _shakeLocked
              ? colorScheme.secondary.withValues(alpha: 0.3)
              : colorScheme.secondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: _shakeLocked
                  ? colorScheme.secondary.withValues(alpha: 0.3)
                  : colorScheme.secondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _PhaseIndicator extends StatelessWidget {
  const _PhaseIndicator({required this.phase, required this.colorScheme});

  final _PartyPhase phase;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    switch (phase) {
      case _PartyPhase.revealed:
        return Text(
          'Shake again for another move',
          style: AppTypography.caption.copyWith(
            color: colorScheme.secondary.withValues(alpha: 0.5),
          ),
        );
      case _PartyPhase.revealing:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary.withValues(alpha: 0.5),
          ),
        );
      case _PartyPhase.cycling:
        return Text(
          'Almost there...',
          style: AppTypography.caption.copyWith(
            color: colorScheme.primary.withValues(alpha: 0.6),
          ),
        );
      case _PartyPhase.idle:
        return const SizedBox.shrink();
    }
  }
}

final _moveFsrsCardProvider = StreamProvider.family<FsrsCard?, String>((ref, moveId) {
  return ref.watch(fsrsCardsDaoProvider).watchAll().map(
    (cards) => cards.cast<FsrsCard?>().firstWhere(
      (c) => c!.entityId == moveId && c.entityType == 'move',
      orElse: () => null,
    ),
  );
});

class _MoveReviewStats extends ConsumerWidget {
  const _MoveReviewStats({required this.moveId});
  final String moveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardAsync = ref.watch(_moveFsrsCardProvider(moveId));

    return cardAsync.when(
      loading: () => const SizedBox(height: 28),
      error: (_, _) => const SizedBox.shrink(),
      data: (card) {
        if (card == null) return const SizedBox.shrink();
        final hasReviews = card.reps > 0 || card.lapses > 0;
        if (!hasReviews) return const SizedBox.shrink();

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite,
                  size: 14,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 4),
                Text(
                  '${card.reps}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _StatChip(
                  label: '${card.stability.toStringAsFixed(1)}d',
                  icon: Icons.trending_up,
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatChip(
                  label: '${(card.difficulty * 10).round()}%',
                  icon: Icons.fitness_center,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colorScheme.secondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: colorScheme.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

final _partyMovesProvider = StreamProvider<List<Move>>((ref) {
  return ref.watch(moveRepositoryProvider).watchAll();
});
