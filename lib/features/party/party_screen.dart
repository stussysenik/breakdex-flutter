import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/database/database.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/providers.dart';
import '../../shared/widgets/settings_gear_button.dart';
import '../../shared/widgets/state_pill.dart';

enum _PartyPhase { idle, revealing, revealed }

class PartyScreen extends ConsumerStatefulWidget {
  const PartyScreen({super.key});

  @override
  ConsumerState<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends ConsumerState<PartyScreen>
    with SingleTickerProviderStateMixin {
  List<Move> _allMoves = [];
  Move? _currentMove;

  StreamSubscription<AccelerometerEvent>? _shakeSubscription;
  DateTime _lastShakeTime = DateTime(2000);
  static const _shakeThreshold = 20.0;
  static const _shakeCooldown = Duration(milliseconds: 1000);
  static const _revealLockout = Duration(seconds: 3);

  _PartyPhase _phase = _PartyPhase.idle;
  bool _shakeLocked = false;
  Timer? _lockoutTimer;

  late final AnimationController _revealController;
  late final Animation<double> _revealScaleY;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _revealScaleY = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutBack,
    );
    _startShakeListener();
  }

  @override
  void dispose() {
    _stopShakeListener();
    _lockoutTimer?.cancel();
    _revealController.dispose();
    super.dispose();
  }

  void _startShakeListener() {
    _shakeSubscription?.cancel();
    _shakeSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      final now = DateTime.now();
      if (_shakeLocked) return;
      if (magnitude > _shakeThreshold &&
          now.difference(_lastShakeTime) > _shakeCooldown) {
        _lastShakeTime = now;
        _onShakeDetected();
      }
    });
  }

  void _stopShakeListener() {
    _shakeSubscription?.cancel();
    _shakeSubscription = null;
  }

  void _onShakeDetected() {
    if (_allMoves.isEmpty) return;
    _shakeLocked = true;
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 80), () {
      HapticFeedback.heavyImpact();
    });

    final index = _random.nextInt(_allMoves.length);
    setState(() {
      _currentMove = _allMoves[index];
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

  @override
  Widget build(BuildContext context) {
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Party',
                style: AppTypography.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SettingsGearButton(),
            ],
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
        Text(
          move.name,
          style: AppTypography.titleLarge.copyWith(
            color: colorScheme.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
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
              move.videoPath != null
                  ? Icons.play_circle_outline
                  : Icons.auto_awesome_outlined,
              size: 48,
              color: colorScheme.primary.withValues(alpha: 0.35),
            ),
          ),
        ),
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
    final icon = Icons.vibration;
    final text = _shakeLocked
        ? 'Move locked — wait to shake again'
        : _phase == _PartyPhase.idle
            ? 'Shake to discover a random move'
            : 'Shake again for another move';

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
    if (phase == _PartyPhase.revealed) {
      return Text(
        'Shake again for another move',
        style: AppTypography.caption.copyWith(
          color: colorScheme.secondary.withValues(alpha: 0.5),
        ),
      );
    }
    if (phase == _PartyPhase.revealing) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary.withValues(alpha: 0.5),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

final _partyMovesProvider = StreamProvider<List<Move>>((ref) {
  return ref.watch(moveRepositoryProvider).watchAll();
});
