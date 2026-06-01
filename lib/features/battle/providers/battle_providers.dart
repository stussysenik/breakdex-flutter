import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database.dart';
import '../../../core/providers.dart';

enum BattleDifficulty {
  easy(duration: 90, label: 'Easy'),
  medium(duration: 60, label: 'Medium'),
  hard(duration: 30, label: 'Hard');

  const BattleDifficulty({required this.duration, required this.label});
  final int duration;
  final String label;
}

enum BattlePhase { intro, active, results }

class BattleState {
  final BattlePhase phase;
  final BattleDifficulty difficulty;
  final List<Move> moves;
  final int currentIndex;
  final int score;
  final int streak;
  final int longestStreak;
  final int goodCount;
  final int hardCount;
  final int againCount;
  final double timeRemaining;
  final bool isFinished;

  const BattleState({
    this.phase = BattlePhase.intro,
    this.difficulty = BattleDifficulty.medium,
    this.moves = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.streak = 0,
    this.longestStreak = 0,
    this.goodCount = 0,
    this.hardCount = 0,
    this.againCount = 0,
    this.timeRemaining = 60,
    this.isFinished = false,
  });

  BattleState copyWith({
    final BattlePhase? phase,
    final BattleDifficulty? difficulty,
    final List<Move>? moves,
    final int? currentIndex,
    final int? score,
    final int? streak,
    final int? longestStreak,
    final int? goodCount,
    final int? hardCount,
    final int? againCount,
    final double? timeRemaining,
    final bool? isFinished,
  }) =>
      BattleState(
        phase: phase ?? this.phase,
        difficulty: difficulty ?? this.difficulty,
        moves: moves ?? this.moves,
        currentIndex: currentIndex ?? this.currentIndex,
        score: score ?? this.score,
        streak: streak ?? this.streak,
        longestStreak: longestStreak ?? this.longestStreak,
        goodCount: goodCount ?? this.goodCount,
        hardCount: hardCount ?? this.hardCount,
        againCount: againCount ?? this.againCount,
        timeRemaining: timeRemaining ?? this.timeRemaining,
        isFinished: isFinished ?? this.isFinished,
      );

  int get movesReviewed => goodCount + hardCount + againCount;
  double get accuracy => movesReviewed == 0 ? 0 : goodCount / movesReviewed;
  Move? get currentMove =>
      currentIndex < moves.length ? moves[currentIndex] : null;
}

class BattleNotifier extends StateNotifier<BattleState> {
  BattleNotifier(this._db) : super(const BattleState());

  final AppDatabase _db;
  Timer? _timer;

  void selectDifficulty(final BattleDifficulty difficulty) {
    state = state.copyWith(difficulty: difficulty);
  }

  Future<void> start() async {
    final allMoves = await _db.movesDao.getAll();
    if (allMoves.isEmpty) return;

    final shuffled = List<Move>.from(allMoves)..shuffle(Random());
    // Repeat list to have enough moves for the session
    final moves = <Move>[];
    while (moves.length < 100) {
      moves.addAll(shuffled);
    }

    state = BattleState(
      phase: BattlePhase.active,
      difficulty: state.difficulty,
      moves: moves,
      timeRemaining: state.difficulty.duration.toDouble(),
    );

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (state.isFinished) {
        _timer?.cancel();
        return;
      }
      final remaining = state.timeRemaining - 0.1;
      if (remaining <= 0) {
        _finish();
      } else {
        state = state.copyWith(timeRemaining: remaining);
      }
    });
  }

  void rate(final String rating) {
    if (state.isFinished || state.phase != BattlePhase.active) return;

    int scoreAdd = 0;
    int newStreak = state.streak;
    int newGood = state.goodCount;
    int newHard = state.hardCount;
    int newAgain = state.againCount;

    switch (rating) {
      case 'GOOD':
        newStreak = state.streak + 1;
        scoreAdd = 3 * newStreak; // Streak multiplier
        newGood++;
        break;
      case 'HARD':
        newStreak = 0;
        scoreAdd = 1;
        newHard++;
        break;
      case 'AGAIN':
        newStreak = 0;
        scoreAdd = 0;
        newAgain++;
        break;
    }

    final newLongest = max(state.longestStreak, newStreak);
    final nextIndex = state.currentIndex + 1;

    if (nextIndex >= state.moves.length) {
      _finish();
      return;
    }

    state = state.copyWith(
      currentIndex: nextIndex,
      score: state.score + scoreAdd,
      streak: newStreak,
      longestStreak: newLongest,
      goodCount: newGood,
      hardCount: newHard,
      againCount: newAgain,
    );
  }

  void _finish() {
    _timer?.cancel();
    state = state.copyWith(
      phase: BattlePhase.results,
      isFinished: true,
      timeRemaining: 0,
    );
    _persistResult();
  }

  Future<void> _persistResult() async {
    const uuid = Uuid();
    await _db.into(_db.battleResults).insert(
          BattleResultsCompanion.insert(
            id: uuid.v4(),
            score: state.score,
            movesReviewed: state.movesReviewed,
            goodCount: state.goodCount,
            hardCount: state.hardCount,
            againCount: state.againCount,
            longestStreak: state.longestStreak,
            difficulty: state.difficulty.name.toUpperCase(),
          ),
        );
  }

  void reset() {
    _timer?.cancel();
    state = const BattleState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final battleProvider =
    StateNotifierProvider.autoDispose<BattleNotifier, BattleState>((final ref) {
  final db = ref.watch(databaseProvider);
  return BattleNotifier(db);
});
