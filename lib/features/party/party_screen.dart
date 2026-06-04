import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/models/reviewable_item.dart' show MoveVideoPath;
import '../../core/providers.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/video_path_resolver.dart';
import '../../shared/widgets/combo_step_line.dart';
import '../../shared/widgets/state_pill.dart';
import '../../shared/widgets/video_player_widget.dart' show RobustVideoPlayer;
import '../../core/utils/diagnostics.dart';

import '../../core/services/swing_detector.dart';
import 'bloc/party_bloc.dart';
import 'bloc/combo_party_bloc.dart';

const _partySubsystem = 'Party';

class PartyScreen extends ConsumerStatefulWidget {
  const PartyScreen({super.key});

  @override
  ConsumerState<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends ConsumerState<PartyScreen>
    with SingleTickerProviderStateMixin {
  late final SwingDetector _swingDetector;
  static const _revealLockout = Duration(seconds: 3);

  Timer? _ticker;
  bool _shakeLocked = false;
  Timer? _lockoutTimer;
  late final ComboPartyBloc _comboBloc;
  int _selectedComboStepIndex = 0;

  late final AnimationController _revealController;
  late final Animation<double> _revealScaleY;

  @override
  void initState() {
    super.initState();
    _comboBloc = ComboPartyBloc();
    _swingDetector = SwingDetector(
      threshold: 18.0,
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

    final tabIndex = ref.read(currentTabIndexProvider);
    if (tabIndex == 2) {
      _startShakeListener();
    }
  }

  @override
  void dispose() {
    _stopShakeListener();
    _ticker?.cancel();
    _lockoutTimer?.cancel();
    _revealController.dispose();
    _comboBloc.close();
    super.dispose();
  }

  void _startShakeListener() {
    DiagnosticsLog.debug(_partySubsystem, 'shake listener started');
    _swingDetector.start();
  }

  void _stopShakeListener() {
    DiagnosticsLog.debug(_partySubsystem, 'shake listener stopped');
    _swingDetector.stop();
  }

  void _onShakeDetected() {
    DiagnosticsLog.info(
      _partySubsystem,
      'shake detected; locked=$_shakeLocked',
    );
    if (_shakeLocked) {
      DiagnosticsLog.debug(_partySubsystem, 'shake ignored: locked');
      return;
    }

    final isComboMode = ref.read(partyComboModeProvider);
    if (isComboMode) {
      _onComboShake();
    } else {
      _onMoveShake();
    }
  }

  void _onMoveShake() {
    final movesAsync = ref.read(_partyMovesProvider);
    movesAsync.when(
      data: (final moves) {
        DiagnosticsLog.info(
          _partySubsystem,
          'move shake: ${moves.length} moves available',
        );
        if (moves.isEmpty) return;
        final durationMs = ref.read(partyCycleDurationMsProvider);
        DiagnosticsLog.debug(
          _partySubsystem,
          'dispatching MoveShake durationMs=$durationMs',
        );
        context.read<PartyBloc>().add(PartyEvent.shake(moves, durationMs));
      },
      loading: () => DiagnosticsLog.debug(_partySubsystem, 'moves loading'),
      error: (final e, final s) =>
          DiagnosticsLog.error(_partySubsystem, 'moves error: $e'),
    );
  }

  void _onComboShake() {
    final combosAsync = ref.read(_partyCombosProvider);
    combosAsync.when(
      data: (final combos) {
        DiagnosticsLog.info(
          _partySubsystem,
          'combo shake: ${combos.length} combos available',
        );
        if (combos.isEmpty) return;
        final durationMs = ref.read(partyCycleDurationMsProvider);
        DiagnosticsLog.info(
          _partySubsystem,
          'dispatching ComboShake to bloc; durationMs=$durationMs combos=${combos.length}',
        );
        _comboBloc.add(ComboShake(combos, durationMs));
      },
      loading: () => DiagnosticsLog.warn(_partySubsystem, 'combos still loading on shake'),
      error: (final e, final s) =>
          DiagnosticsLog.error(_partySubsystem, 'combos error on shake: $e'),
    );
  }

  void _startMoveTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (final timer) {
      if (mounted) {
        context.read<PartyBloc>().add(PartyEvent.tick(DateTime.now()));
      }
    });
  }

  void _startComboTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (final timer) {
      if (mounted) {
        _comboBloc.add(ComboTick(DateTime.now()));
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _triggerHaptics() {
    unawaited(HapticFeedback.heavyImpact());
    unawaited(Future<void>.delayed(const Duration(milliseconds: 80), () {
      unawaited(HapticFeedback.heavyImpact());
    }));
  }

  void _lockShake() {
    setState(() => _shakeLocked = true);
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer(_revealLockout, () {
      DiagnosticsLog.debug(_partySubsystem, 'shake lock cooldown expired');
      if (mounted) setState(() => _shakeLocked = false);
    });
  }

  void _onRevealAnimationComplete(final void Function() onComplete) {
    _revealController.reset();
    _revealController.forward().then((_) {
      if (mounted) onComplete();
    });
  }

  @override
  Widget build(final BuildContext context) {
    ref.listen(currentTabIndexProvider, (final prev, final next) {
      if (next == 2) {
        _startShakeListener();
      } else {
        _stopShakeListener();
        _stopTicker();
      }
    });

    final isComboMode = ref.watch(partyComboModeProvider);

    if (isComboMode) {
      return BlocProvider.value(
        value: _comboBloc,
        child: _buildComboParty(),
      );
    }
    return _buildMoveParty();
  }

  Widget _buildMoveParty() {
    DiagnosticsLog.info(_partySubsystem, 'building move party');
    final movesAsync = ref.watch(_partyMovesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<PartyBloc, PartyState>(
      listener: (final context, final state) {
        DiagnosticsLog.trace(_partySubsystem, 'move listener: state=${state.runtimeType}');
        state.maybeWhen(
          cycling: (_, _, _, _, _, _) {
            DiagnosticsLog.debug(_partySubsystem, 'move bloc → cycling');
            if (_ticker == null) {
              _triggerHaptics();
              _startMoveTicker();
            }
          },
          revealing: (_) {
            DiagnosticsLog.debug(_partySubsystem, 'move bloc → revealing');
            _stopTicker();
            _onRevealAnimationComplete(() {
              context.read<PartyBloc>().add(
                  PartyEvent.tick(DateTime.now()));
            });
          },
          revealed: (_) {
            DiagnosticsLog.info(_partySubsystem, 'move bloc → revealed');
            _lockShake();
          },
          orElse: () {},
        );
      },
      child: movesAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (final e, _) => Scaffold(
          body: Center(child: Text('Error: $e')),
        ),
        data: (final moves) {
          return Scaffold(
            body: SafeArea(
              child: moves.isEmpty
                  ? _buildEmptyState(colorScheme, isCombo: false)
                  : _buildMoveContent(context, colorScheme, moves),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComboParty() {
    DiagnosticsLog.info(_partySubsystem, 'building combo party');
    final combosAsync = ref.watch(_partyCombosProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<ComboPartyBloc, ComboPartyState>(
      listener: (final context, final state) {
        switch (state) {
          case ComboCycling():
            DiagnosticsLog.debug(_partySubsystem, 'combo bloc → cycling');
            if (_ticker == null) {
              _triggerHaptics();
              _startComboTicker();
            }
          case ComboRevealing():
            DiagnosticsLog.debug(_partySubsystem, 'combo bloc → revealing');
            if (mounted) setState(() => _selectedComboStepIndex = 0);
            _stopTicker();
            _onRevealAnimationComplete(() {
              _comboBloc.add(ComboTick(DateTime.now()));
            });
          case ComboRevealed():
            DiagnosticsLog.info(_partySubsystem, 'combo bloc → revealed');
            _lockShake();
          case ComboIdle():
            break;
        }
      },
      child: combosAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (final e, _) => Scaffold(
          body: Center(child: Text('Error: $e')),
        ),
        data: (final combos) {
          return Scaffold(
            body: SafeArea(
              child: combos.isEmpty
                  ? _buildEmptyState(colorScheme, isCombo: true)
                  : _buildComboContent(context, colorScheme, combos),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(final ColorScheme colorScheme, {required final bool isCombo}) {
    final itemLabel = isCombo ? 'combos' : 'moves';
    DiagnosticsLog.info(
      _partySubsystem,
      'showing empty state for $itemLabel',
    );

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
              'Add $itemLabel to get the party started.\nShake to discover random $itemLabel!',
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

  Widget _buildMoveContent(
    final BuildContext context,
    final ColorScheme colorScheme,
    final List<Move> allMoves,
  ) {
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
            'PARTY',
            style: AppTypography.sectionHeader.copyWith(
              color: colorScheme.onSurface,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: BlocBuilder<PartyBloc, PartyState>(
            builder: (final context, final state) {
              return state.when(
                idle: () => _buildIdlePrompt(
                  colorScheme,
                  allMoves.length,
                  isCombo: false,
                ),
                cycling: (_, final currentMove, _, final startTime, _, final durationMs) =>
                    _buildCyclingDisplay(
                  colorScheme,
                  currentMove.name,
                  key: ValueKey(currentMove.id),
                  startTime: startTime,
                  durationMs: durationMs,
                ),
                revealing: (final move) =>
                    _buildMoveRevealedCard(colorScheme, move),
                revealed: (final move) =>
                    _buildMoveRevealedCard(colorScheme, move),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.sm,
            AppSpacing.screenEdge,
            AppSpacing.sm + bottomPadding,
          ),
          child: BlocBuilder<PartyBloc, PartyState>(
            builder: (final context, final state) {
              return _buildBottomHint(
                colorScheme,
                state.maybeWhen(
                  cycling: (_, _, _, _, _, _) => true,
                  orElse: () => false,
                ),
                state.maybeWhen(idle: () => true, orElse: () => false),
                isCombo: false,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComboContent(
    final BuildContext context,
    final ColorScheme colorScheme,
    final List<ComboPartyDisplay> combos,
  ) {
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
            'PARTY',
            style: AppTypography.sectionHeader.copyWith(
              color: colorScheme.onSurface,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: BlocBuilder<ComboPartyBloc, ComboPartyState>(
            builder: (final context, final state) {
              DiagnosticsLog.debug('Party',
                  'ComboBlocBuilder state=${state.runtimeType}');
              return switch (state) {
                ComboIdle() => _buildIdlePrompt(
                    colorScheme,
                    combos.length,
                    isCombo: true,
                  ),
                ComboCycling(
                  :final currentCombo,
                  :final startTime,
                  :final durationMs
                ) =>
                  _buildCyclingDisplay(
                    colorScheme,
                    currentCombo.name,
                    key: ValueKey(currentCombo.id),
                    startTime: startTime,
                    durationMs: durationMs,
                  ),
                ComboRevealing(:final combo) =>
                  _buildComboRevealedCard(colorScheme, combo),
                ComboRevealed(:final combo) =>
                  _buildComboRevealedCard(colorScheme, combo),
              };
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.sm,
            AppSpacing.screenEdge,
            AppSpacing.sm + bottomPadding,
          ),
          child: BlocBuilder<ComboPartyBloc, ComboPartyState>(
            builder: (final context, final state) {
              return _buildBottomHint(
                colorScheme,
                state is ComboCycling,
                state is ComboIdle,
                isCombo: true,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIdlePrompt(
    final ColorScheme colorScheme,
    final int count, {
    required final bool isCombo,
  }) {
    final label = isCombo ? 'combo' : 'move';
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
          GestureDetector(
            onTap: _onShakeDetected,
            child: Icon(
              Icons.vibration,
              size: 56,
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'SHAKE TO DISCOVER\nA RANDOM ${label.toUpperCase()}',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$count ${label.toUpperCase()}${count == 1 ? '' : 'S'} READY',
            style: AppTypography.labelLarge.copyWith(
              color: colorScheme.secondary,
              letterSpacing: 1.0,
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

  Widget _buildCyclingDisplay(
    final ColorScheme colorScheme,
    final String name, {
    required final Key key,
    required final DateTime startTime,
    required final int durationMs,
  }) {
    final elapsed = DateTime.now().difference(startTime);
    final duration = durationMs > 0 ? durationMs : 5500;
    final progress = (elapsed.inMilliseconds / duration).clamp(0.0, 1.0);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 60),
            child: Text(
              name.toUpperCase(),
              key: key,
              style: AppTypography.titleLarge.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'SHUFFLING...',
            style: AppTypography.labelLarge.copyWith(
              color: colorScheme.secondary,
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveRevealedCard(final ColorScheme colorScheme, final Move move) {
    return _buildRevealedCardWrapper(
      colorScheme,
      child: _buildMoveCard(colorScheme, move),
    );
  }

  Widget _buildComboRevealedCard(
    final ColorScheme colorScheme,
    final ComboPartyDisplay combo,
  ) {
    return _buildRevealedCardWrapper(
      colorScheme,
      child: _buildComboCard(colorScheme, combo),
    );
  }

  Widget _buildRevealedCardWrapper(
    final ColorScheme colorScheme, {
    required final Widget child,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: AnimatedBuilder(
            animation: _revealScaleY,
            builder: (final context, final child) {
              return Transform.scale(
                scaleY: _revealScaleY.value.clamp(0.0, 1.0),
                alignment: Alignment.center,
                child: child,
              );
            },
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildMoveCard(final ColorScheme colorScheme, final Move move) {
    final state = LearningState.fromString(move.learningState);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => context.push('/breakdex/move/${move.id}'),
          child: Text(
            move.name.toUpperCase(),
            style: AppTypography.titleLarge.copyWith(
              color: colorScheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
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
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  move.category.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
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
        BlocBuilder<PartyBloc, PartyState>(
          builder: (final context, final state) {
            return _PhaseIndicator(
              isRevealed: _isRevealed(state),
              isRevealing: _isRevealing(state),
              isCycling: _isCycling(state),
              isIdle: _isIdle(state),
              colorScheme: colorScheme,
              itemLabel: 'move',
            );
          },
        ),
      ],
    );
  }

  Widget _buildComboCard(
    final ColorScheme colorScheme,
    final ComboPartyDisplay combo,
  ) {
    final activeVideoPath = _selectedComboStepIndex < combo.moveVideoPaths.length
        ? combo.moveVideoPaths[_selectedComboStepIndex]
        : combo.videoPath;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => context.push('/breakdex/combo/${combo.id}'),
          child: Text(
            combo.name.toUpperCase(),
            style: AppTypography.titleLarge.copyWith(
              color: colorScheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (combo.moveNames.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: 4,
            children: List.generate(combo.moveNames.length, (final idx) {
              final isSelected = idx == _selectedComboStepIndex;
              final name = combo.moveNames[idx];
              final beats = combo.moveBeats[idx];

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$beats',
                      style: AppTypography.caption.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimary.withValues(alpha: 0.7)
                            : colorScheme.secondary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        const SizedBox(height: AppSpacing.lg),
        if (activeVideoPath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: RobustVideoPlayer(
              key: ValueKey('party-combo-video-${combo.id}-$_selectedComboStepIndex-$activeVideoPath'),
              videoPath: activeVideoPath,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_off_outlined,
                  size: 32,
                  color: colorScheme.primary.withValues(alpha: 0.35),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'NO VIDEO FOR THIS STEP',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        
        // Total Beats above timeline
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${combo.totalBeats} BEATS',
              style: AppTypography.labelLarge.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        const SizedBox(height: 4),

        if (combo.moveNames.length > 1)
          ComboStepLine(
            stepCount: combo.moveNames.length,
            activeIndex: _selectedComboStepIndex,
            onStepSelected: (final idx) {
              DiagnosticsLog.info('Party', 'Combo step selected: $idx');
              setState(() => _selectedComboStepIndex = idx);
            },
            stepNames: combo.moveNames,
          ),
        const SizedBox(height: AppSpacing.lg),
        BlocBuilder<ComboPartyBloc, ComboPartyState>(
          builder: (final context, final state) {
            return _PhaseIndicator(
              isRevealed: state is ComboRevealed,
              isRevealing: state is ComboRevealing,
              isCycling: state is ComboCycling,
              isIdle: state is ComboIdle,
              colorScheme: colorScheme,
              itemLabel: 'combo',
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomHint(
    final ColorScheme colorScheme,
    final bool isCycling,
    final bool isIdle, {
    required final bool isCombo,
  }) {
    final itemLabel = isCombo ? 'combo' : 'move';
    final icon = isCycling ? Icons.casino_outlined : Icons.vibration;

    String text;
    if (_shakeLocked && !isCycling) {
      final cap = isCombo ? 'COMBO' : 'MOVE';
      text = '$cap LOCKED — WAIT TO SHAKE AGAIN';
    } else if (isIdle) {
      text = 'SHAKE TO DISCOVER A RANDOM $itemLabel';
    } else if (isCycling) {
      text = 'DISCOVERING YOUR $itemLabel...';
    } else {
      text = 'SHAKE AGAIN FOR ANOTHER $itemLabel';
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
            text.toUpperCase(),
            style: AppTypography.labelLarge.copyWith(
              color: _shakeLocked
                  ? colorScheme.secondary.withValues(alpha: 0.3)
                  : colorScheme.secondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _PhaseIndicator extends StatelessWidget {
  const _PhaseIndicator({
    required this.isRevealed,
    required this.isRevealing,
    required this.isCycling,
    required this.isIdle,
    required this.colorScheme,
    required this.itemLabel,
  });

  final bool isRevealed;
  final bool isRevealing;
  final bool isCycling;
  final bool isIdle;
  final ColorScheme colorScheme;
  final String itemLabel;

  @override
  Widget build(final BuildContext context) {
    if (isRevealed) {
      return Text(
        'SHAKE AGAIN FOR ANOTHER $itemLabel',
        style: AppTypography.caption.copyWith(
          color: colorScheme.secondary.withValues(alpha: 0.5),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      );
    }
    if (isRevealing) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary.withValues(alpha: 0.5),
        ),
      );
    }
    if (isCycling) {
      return Text(
        'ALMOST THERE...',
        style: AppTypography.caption.copyWith(
          color: colorScheme.primary.withValues(alpha: 0.6),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

final _moveFsrsCardProvider =
    FutureProvider.family<FsrsCard?, String>((final ref, final moveId) {
  return ref.watch(fsrsCardsDaoProvider).getByEntityId(moveId, entityType: 'move');
});

class _MoveReviewStats extends ConsumerWidget {
  const _MoveReviewStats({required this.moveId});
  final String moveId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final cardAsync = ref.watch(_moveFsrsCardProvider(moveId));

    return cardAsync.when(
      loading: () => const SizedBox(height: 28),
      error: (_, _) => const SizedBox.shrink(),
      data: (final card) {
        if (card == null) return const SizedBox.shrink();
        final hasReviews = card.reps > 0 || card.lapses > 0;
        if (!hasReviews) return const SizedBox.shrink();

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, size: 14, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(
                  '${card.reps}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
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
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colorScheme.secondary),
        const SizedBox(width: 3),
        Text(
          label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: colorScheme.secondary,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

bool _isRevealed(final PartyState s) =>
    s.maybeWhen(revealed: (_) => true, orElse: () => false);
bool _isRevealing(final PartyState s) =>
    s.maybeWhen(revealing: (_) => true, orElse: () => false);
bool _isCycling(final PartyState s) =>
    s.maybeWhen(cycling: (_, _, _, _, _, _) => true, orElse: () => false);
bool _isIdle(final PartyState s) =>
    s.maybeWhen(idle: () => true, orElse: () => false);

final _partyMovesProvider = StreamProvider<List<Move>>((final ref) {
  return ref.watch(moveRepositoryProvider).watchAll();
});

final _partyCombosProvider =
    StreamProvider<List<ComboPartyDisplay>>((final ref) async* {
  final combosDao = ref.watch(combosDaoProvider);

  // Watch a joined stream of combos and their moves so we react to any changes
  // in either table, preventing race conditions where moves are inserted after the combo.
  final comboStream = combosDao.watchAllCombosWithMoves();

  await for (final comboList in comboStream) {
    final result = <ComboPartyDisplay>[];

    for (final item in comboList) {
      final combo = item.combo;
      final moves = item.moves;

      String? absVideoPath;
      if (combo.activeVideoPath != null) {
        absVideoPath = VideoPathResolver.toAbsolute(combo.activeVideoPath!);
      } else {
        final firstWithVideo = moves.where((final m) => m.move.videoPath != null).firstOrNull;
        if (firstWithVideo != null) {
          absVideoPath = VideoPathResolver.toAbsolute(firstWithVideo.move.videoPath!);
        }
      }

      result.add(ComboPartyDisplay(
        combo: combo,
        moveNames: moves.map((final m) => m.move.name).toList(),
        moveBeats: moves.map((final m) => m.move.count).toList(),
        moveVideoPaths: moves.map((final m) => m.move.videoPath != null ? VideoPathResolver.toAbsolute(m.move.videoPath!) : null).toList(),
        resolvedVideoPath: absVideoPath,
      ));
    }
    yield result;
  }
});
