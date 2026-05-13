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
import '../../shared/widgets/celebration_overlay.dart';

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
  static const _shakeThreshold = 15.0;
  static const _shakeCooldown = Duration(milliseconds: 600);

  late final AnimationController _pulseController;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _startShakeListener();
  }

  @override
  void dispose() {
    _stopShakeListener();
    _pulseController.dispose();
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
      if (magnitude > _shakeThreshold &&
          now.difference(_lastShakeTime) > _shakeCooldown) {
        _lastShakeTime = now;
        HapticFeedback.heavyImpact();
        _pickRandomMove();
      }
    });
  }

  void _stopShakeListener() {
    _shakeSubscription?.cancel();
    _shakeSubscription = null;
  }

  void _pickRandomMove() {
    if (_allMoves.isEmpty) return;
    final index = _random.nextInt(_allMoves.length);
    setState(() => _currentMove = _allMoves[index]);
    CelebrationOverlay.show(
      context,
      title: _allMoves[index].name,
    );
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
        // Header
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
        const SizedBox(height: AppSpacing.xs),

        Expanded(
          child: _currentMove == null
              ? _buildShakePrompt(colorScheme)
              : _buildMoveCard(colorScheme),
        ),

        // Bottom hint
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.sm,
            AppSpacing.screenEdge,
            AppSpacing.sm + bottomPadding,
          ),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final opacity = 0.3 +
                  (0.3 * Curves.easeInOut.transform(_pulseController.value));
              return Opacity(
                opacity: opacity,
                child: child,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.vibration,
                  size: 18,
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Shake to discover a random move',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShakePrompt(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.vibration,
            size: 80,
            color: colorScheme.primary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Shake your device',
            style: AppTypography.titleMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${_allMoves.length} move${_allMoves.length == 1 ? '' : 's'} ready',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveCard(ColorScheme colorScheme) {
    final move = _currentMove!;
    final state = LearningState.fromString(move.learningState);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Move name
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

              // Video placeholder or note
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
              Text(
                'Shake again for another move',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _partyMovesProvider = StreamProvider<List<Move>>((ref) {
  return ref.watch(moveRepositoryProvider).watchAll();
});
