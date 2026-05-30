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
  ComboPartyBloc? _comboBloc;

  late final AnimationController _revealController;
  late final Animation<double> _revealScaleY;

  @override
  void initState() {
    super.initState();
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
      data: (moves) {
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
      error: (e, s) =>
          DiagnosticsLog.error(_partySubsystem, 'moves error: $e'),
    );
  }

  void _onComboShake() {
    if (_comboBloc == null) {
      DiagnosticsLog.error(
        _partySubsystem,
        'combo shake ignored: _comboBloc is null — widget not yet built in combo mode',
      );
      return;
    }
    final combosAsync = ref.read(_partyCombosProvider);
    combosAsync.when(
      data: (combos) {
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
        _comboBloc!.add(ComboShake(combos, durationMs));
      },
      loading: () => DiagnosticsLog.warn(_partySubsystem, 'combos still loading on shake'),
      error: (e, s) =>
          DiagnosticsLog.error(_partySubsystem, 'combos error on shake: $e'),
    );
  }

  void _startMoveTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (mounted) {
        context.read<PartyBloc>().add(PartyEvent.tick(DateTime.now()));
      }
    });
  }

  void _startComboTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (mounted && _comboBloc != null) {
        _comboBloc!.add(ComboTick(DateTime.now()));
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _triggerHaptics() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 80), () {
      HapticFeedback.heavyImpact();
    });
  }

  void _lockShake() {
    setState(() => _shakeLocked = true);
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer(_revealLockout, () {
      DiagnosticsLog.debug(_partySubsystem, 'shake lock cooldown expired');
      if (mounted) setState(() => _shakeLocked = false);
    });
  }

  void _onRevealAnimationComplete(void Function() onComplete) {
    _revealController.reset();
    _revealController.forward().then((_) {
      if (mounted) onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentTabIndexProvider, (prev, next) {
      if (next == 2) {
        _startShakeListener();
      } else {
        _stopShakeListener();
        _stopTicker();
      }
    });

    final isComboMode = ref.watch(partyComboModeProvider);

    if (isComboMode) {
      return BlocProvider(
        create: (_) {
          _comboBloc = ComboPartyBloc();
          return _comboBloc!;
        },
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
      listener: (context, state) {
        DiagnosticsLog.trace(_partySubsystem, 'move listener: state=${state.runtimeType}');
        state.maybeWhen(
          cycling: (_, __, ___, ____, _____, ______) {
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
        error: (e, _) => Scaffold(
          body: Center(child: Text('Error: $e')),
        ),
        data: (moves) {
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
      listener: (context, state) {
        switch (state) {
          case ComboCycling():
            DiagnosticsLog.debug(_partySubsystem, 'combo bloc → cycling');
            if (_ticker == null) {
              _triggerHaptics();
              _startComboTicker();
            }
          case ComboRevealing():
            DiagnosticsLog.debug(_partySubsystem, 'combo bloc → revealing');
            _stopTicker();
            _onRevealAnimationComplete(() {
              _comboBloc?.add(ComboTick(DateTime.now()));
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
        error: (e, _) => Scaffold(
          body: Center(child: Text('Error: $e')),
        ),
        data: (combos) {
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

  Widget _buildEmptyState(ColorScheme colorScheme, {required bool isCombo}) {
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
    BuildContext context,
    ColorScheme colorScheme,
    List<Move> allMoves,
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
            'Party',
            style: AppTypography.titleLarge.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: BlocBuilder<PartyBloc, PartyState>(
            builder: (context, state) {
              return state.when(
                idle: () => _buildIdlePrompt(
                  colorScheme,
                  allMoves.length,
                  isCombo: false,
                ),
                cycling: (_, currentMove, __, startTime, ___, durationMs) =>
                    _buildCyclingDisplay(
                  colorScheme,
                  currentMove.name,
                  key: ValueKey(currentMove.id),
                  startTime: startTime,
                  durationMs: durationMs,
                ),
                revealing: (move) =>
                    _buildMoveRevealedCard(colorScheme, move),
                revealed: (move) =>
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
            builder: (context, state) {
              return _buildBottomHint(
                colorScheme,
                state.maybeWhen(
                  cycling: (_, __, ___, ____, _____, ______) => true,
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
    BuildContext context,
    ColorScheme colorScheme,
    List<ComboPartyDisplay> combos,
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
            'Party',
            style: AppTypography.titleLarge.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: BlocBuilder<ComboPartyBloc, ComboPartyState>(
            builder: (context, state) {
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
            builder: (context, state) {
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
    ColorScheme colorScheme,
    int count, {
    required bool isCombo,
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
            'Shake to discover\na random $label',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$count $label${count == 1 ? '' : 's'} ready',
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

  Widget _buildCyclingDisplay(
    ColorScheme colorScheme,
    String name, {
    required Key key,
    required DateTime startTime,
    required int durationMs,
  }) {
    final elapsed = DateTime.now().difference(startTime);
    final duration = durationMs > 0 ? durationMs : 5500;
    final progress = (elapsed.inMilliseconds / duration).clamp(0.0, 1.0);
    if (progress.isNaN) {
      DiagnosticsLog.warn(_partySubsystem, 'cycling progress NaN — elapsed=${elapsed.inMilliseconds}ms durationMs=$durationMs');
    }

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
              name,
              key: key,
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

  Widget _buildMoveRevealedCard(ColorScheme colorScheme, Move move) {
    return _buildRevealedCardWrapper(
      colorScheme,
      child: _buildMoveCard(colorScheme, move),
    );
  }

  Widget _buildComboRevealedCard(
    ColorScheme colorScheme,
    ComboPartyDisplay combo,
  ) {
    DiagnosticsLog.info('Party',
        '_buildComboRevealedCard combo=${combo.name} videoPath=${combo.videoPath} '
        'moveNames=${combo.moveNames.join(",")} '
        'revealScaleY=${_revealScaleY.value.toStringAsFixed(2)}');
    return _buildRevealedCardWrapper(
      colorScheme,
      child: _buildComboCard(colorScheme, combo),
    );
  }

  Widget _buildRevealedCardWrapper(
    ColorScheme colorScheme, {
    required Widget child,
  }) {
    DiagnosticsLog.debug('Party',
        '_buildRevealedCardWrapper scaleY=${_revealScaleY.value.toStringAsFixed(2)} '
        'controllerStatus=${_revealController.status.name}');
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
            child: child,
          ),
        ),
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
        BlocBuilder<PartyBloc, PartyState>(
          builder: (context, state) {
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
    ColorScheme colorScheme,
    ComboPartyDisplay combo,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => context.push('/breakdex/combo/${combo.id}'),
          child: Text(
            combo.name,
            style: AppTypography.titleLarge.copyWith(
              color: colorScheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w700,
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
            children: combo.moveNames.take(5).map((name) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  name,
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: AppSpacing.md),
        if (combo.moveNames.length > 1)
          ComboStepLine(
            stepCount: combo.moveNames.length,
            activeIndex: 0,
            onStepSelected: (_) {},
            stepNames: combo.moveNames,
          ),
        const SizedBox(height: AppSpacing.lg),
        if (combo.videoPath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: RobustVideoPlayer(
              videoPath: combo.videoPath!,
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
                  Icons.link,
                  size: 32,
                  color: colorScheme.primary.withValues(alpha: 0.35),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${combo.moveNames.length} move${combo.moveNames.length == 1 ? '' : 's'}',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        BlocBuilder<ComboPartyBloc, ComboPartyState>(
          builder: (context, state) {
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
    ColorScheme colorScheme,
    bool isCycling,
    bool isIdle, {
    required bool isCombo,
  }) {
    final itemLabel = isCombo ? 'combo' : 'move';
    final icon = isCycling ? Icons.casino_outlined : Icons.vibration;

    String text;
    if (_shakeLocked && !isCycling) {
      final cap = isCombo ? 'Combo' : 'Move';
      text = '$cap locked — wait to shake again';
    } else if (isIdle) {
      text = 'Shake to discover a random $itemLabel';
    } else if (isCycling) {
      text = 'Discovering your $itemLabel...';
    } else {
      text = 'Shake again for another $itemLabel';
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
  Widget build(BuildContext context) {
    if (isRevealed) {
      return Text(
        'Shake again for another $itemLabel',
        style: AppTypography.caption.copyWith(
          color: colorScheme.secondary.withValues(alpha: 0.5),
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
        'Almost there...',
        style: AppTypography.caption.copyWith(
          color: colorScheme.primary.withValues(alpha: 0.6),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

final _moveFsrsCardProvider =
    FutureProvider.family<FsrsCard?, String>((ref, moveId) {
  return ref.watch(fsrsCardsDaoProvider).getByEntityId(moveId, entityType: 'move');
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
                const Icon(Icons.favorite, size: 14, color: AppColors.accent),
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

bool _isRevealed(PartyState s) =>
    s.maybeWhen(revealed: (_) => true, orElse: () => false);
bool _isRevealing(PartyState s) =>
    s.maybeWhen(revealing: (_) => true, orElse: () => false);
bool _isCycling(PartyState s) =>
    s.maybeWhen(cycling: (_, __, ___, ____, _____, ______) => true, orElse: () => false);
bool _isIdle(PartyState s) =>
    s.maybeWhen(idle: () => true, orElse: () => false);

final _partyMovesProvider = StreamProvider<List<Move>>((ref) {
  return ref.watch(moveRepositoryProvider).watchAll();
});

final _partyCombosProvider =
    StreamProvider<List<ComboPartyDisplay>>((ref) async* {
  final combosDao = ref.watch(combosDaoProvider);

  await for (final combos in combosDao.watchAll()) {
    final movesMap = await combosDao.getAllComboMovesMap();
    final result = <ComboPartyDisplay>[];
    for (final combo in combos) {
      final moves = movesMap[combo.id] ?? [];
      result.add(ComboPartyDisplay(
        combo: combo,
        moveNames: moves.map((m) => m.move.name).toList(),
      ));
    }
    yield result;
  }
});
