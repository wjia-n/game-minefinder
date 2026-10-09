import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Difficulty tiers (RULES.md §2).
class MineDifficulty {
  final String name;
  final String tagline;
  final int rows;
  final int cols;
  final int mines;
  final bool pro;
  const MineDifficulty({
    required this.name,
    required this.tagline,
    required this.rows,
    required this.cols,
    required this.mines,
    required this.pro,
  });
}

const mineDifficulties = [
  MineDifficulty(
      name: 'Cozy Dig', tagline: 'gentle soil, few surprises', rows: 9, cols: 9, mines: 10, pro: false),
  MineDifficulty(
      name: 'Deep Dig', tagline: 'a real expedition', rows: 12, cols: 12, mines: 25, pro: false),
  MineDifficulty(
      name: 'Gold Rush', tagline: 'dense and dangerous', rows: 16, cols: 16, mines: 45, pro: true),
  MineDifficulty(
      name: 'Abyss', tagline: 'for the fearless', rows: 20, cols: 20, mines: 90, pro: true),
];

/// Phases owned entirely by the engine. The UI only renders.
/// [animating] = a reveal cascade (tap flood, loss mine-reveal, win flag wave)
/// is draining; input is still accepted but only logical — the visual catches
/// up via the reveal queue. A watchdog guarantees the queue always drains.
enum MinePhase { idle, ready, playing, animating, over }

enum MineEvent {
  gameStart,
  reveal,
  flag,
  chord,
  hint,
  boom,
  win,
  lose,
  invalid,
  noHint,
}

/// A minesweeper board whose every state change is engine-owned and
/// animated. Solution reveals (mine fields on loss, flag wave on win) are
/// always staged through the reveal queue — never instant.
class MineEngine extends ChangeNotifier {
  final MineDifficulty diff;
  final int? seed; // null = random; set for daily challenges
  final bool unlimitedHints; // Pro
  final int hintsPerGame;

  late final int rows = diff.rows;
  late final int cols = diff.cols;
  late final int total = rows * cols;
  late final int mineCount = diff.mines;

  Set<int> mines = {};
  List<int> adj = [];
  List<bool> open = []; // logically opened
  List<bool> visible = []; // visually revealed (animated)
  List<bool> flag = [];

  MinePhase phase = MinePhase.idle;
  bool started = false; // mines placed after first reveal tap
  bool over = false;
  bool won = false;
  int boomAt = -1;
  int seconds = 0;
  int hintsLeft = 3;
  int? hintCell; // pulsing hint target, null when none
  int openCount = 0;

  /// UI hook for sounds. Set by the screen.
  void Function(MineEvent event)? onEvent;

  final _rand = Random();
  Timer? _tick; // 1s game clock
  Timer? _revealTimer; // reveal-queue drain
  Timer? _hintTimer;
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  bool paused = false;

  static const _revealStepMs = 26;
  static const _boomStepMs = 90;
  static const _flagWaveStepMs = 70;

  final List<int> _queue = []; // cells whose visibility is pending
  bool _queueIsLoss = false;
  bool _queueIsWinWave = false;
  VoidCallback? _onQueueDone;

  MineEngine({
    required this.diff,
    this.seed,
    this.unlimitedHints = false,
    this.hintsPerGame = 3,
  }) {
    adj = List.filled(total, 0);
    open = List.filled(total, false);
    visible = List.filled(total, false);
    flag = List.filled(total, false);
    hintsLeft = unlimitedHints ? 999999 : hintsPerGame;
    phase = MinePhase.ready;
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _recover());
  }

  @override
  void dispose() {
    _disposed = true;
    _tick?.cancel();
    _revealTimer?.cancel();
    _hintTimer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------ pause/life
  /// Pause: freeze clock and reveal timers. Resume re-arms everything.
  void setPaused(bool v) {
    if (paused == v || _disposed || over) return;
    paused = v;
    if (v) {
      _tick?.cancel();
      _tick = null;
      _revealTimer?.cancel();
      _revealTimer = null;
      _hintTimer?.cancel();
      _hintTimer = null;
    } else {
      _recover();
      if (started && !over) _armTick();
    }
    notifyListeners();
  }

  /// Watchdog: any phase found without a live timer gets one. Stuck states
  /// are impossible by construction. Respects [paused].
  void _recover() {
    if (_disposed || paused) return;
    if (phase == MinePhase.animating) {
      if (_revealTimer == null) _drainQueue();
    }
    if (started && !over && _tick == null) _armTick();
  }

  void _armTick() {
    if (_disposed || paused) return;
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed || paused || over) return;
      seconds++;
      notifyListeners();
    });
  }

  // -------------------------------------------------------------- new game
  void restart() {
    _revealTimer?.cancel();
    _revealTimer = null;
    _hintTimer?.cancel();
    _hintTimer = null;
    _tick?.cancel();
    _tick = null;
    mines = {};
    adj = List.filled(total, 0);
    open = List.filled(total, false);
    visible = List.filled(total, false);
    flag = List.filled(total, false);
    _queue.clear();
    _queueIsLoss = false;
    _queueIsWinWave = false;
    started = false;
    over = false;
    won = false;
    boomAt = -1;
    seconds = 0;
    hintCell = null;
    openCount = 0;
    hintsLeft = unlimitedHints ? 999999 : hintsPerGame;
    phase = MinePhase.ready;
    paused = false;
    notifyListeners();
  }

  // -------------------------------------------------------------- placement
  void _placeMines(int safeIdx) {
    final rng = seed == null ? _rand : Random(seed! + safeIdx);
    final sr = safeIdx ~/ cols, sc = safeIdx % cols;
    final banned = <int>{};
    for (var r = sr - 1; r <= sr + 1; r++) {
      for (var c = sc - 1; c <= sc + 1; c++) {
        if (r >= 0 && r < rows && c >= 0 && c < cols) {
          banned.add(r * cols + c);
        }
      }
    }
    final spots = List.generate(total, (i) => i)
      ..removeWhere(banned.contains)
      ..shuffle(rng);
    mines = spots.take(mineCount).toSet();
    for (final m in mines) {
      final r = m ~/ cols, c = m % cols;
      for (var rr = r - 1; rr <= r + 1; rr++) {
        for (var cc = c - 1; cc <= c + 1; cc++) {
          if (rr == r && cc == c) continue;
          if (rr >= 0 && rr < rows && cc >= 0 && cc < cols) {
            adj[rr * cols + cc]++;
          }
        }
      }
    }
    started = true;
    phase = MinePhase.playing;
    _armTick();
    onEvent?.call(MineEvent.gameStart);
  }

  List<int> _neighbors(int i) {
    final r = i ~/ cols, c = i % cols;
    final out = <int>[];
    for (var rr = r - 1; rr <= r + 1; rr++) {
      for (var cc = c - 1; cc <= c + 1; cc++) {
        if (rr == r && cc == c) continue;
        if (rr >= 0 && rr < rows && cc >= 0 && cc < cols) {
          out.add(rr * cols + cc);
        }
      }
    }
    return out;
  }

  // ------------------------------------------------------------------ input
  /// Tap a cell: reveal, or chord when tapping an already-visible number.
  void tap(int i) {
    if (over || paused) {
      onEvent?.call(MineEvent.invalid);
      return;
    }
    if (flag[i] && !visible[i]) {
      onEvent?.call(MineEvent.invalid);
      return;
    }
    if (visible[i]) {
      _chord(i);
      return;
    }
    if (!started) _placeMines(i);
    if (mines.contains(i)) {
      _boomAt(i);
      return;
    }
    _floodOpen(i);
    onEvent?.call(MineEvent.reveal);
    _checkWin();
  }

  /// Long-press: plant / remove a flag.
  void toggleFlag(int i) {
    if (over || paused || visible[i]) {
      onEvent?.call(MineEvent.invalid);
      return;
    }
    flag[i] = !flag[i];
    hintCell = null; // a flag change may obsolete the hint
    onEvent?.call(MineEvent.flag);
    notifyListeners();
  }

  /// Chord: tap a visible number whose flag count matches → reveal the rest.
  /// Wrong flags mean this can hit a mine (RULES.md §5).
  void _chord(int i) {
    if (!visible[i] || adj[i] == 0) {
      onEvent?.call(MineEvent.invalid);
      return;
    }
    var flags = 0;
    for (final n in _neighbors(i)) {
      if (flag[n]) flags++;
    }
    if (flags != adj[i]) {
      onEvent?.call(MineEvent.invalid);
      return;
    }
    var any = false;
    for (final n in _neighbors(i)) {
      if (!visible[n] && !flag[n]) {
        any = true;
        if (mines.contains(n)) {
          _boomAt(n);
          return;
        }
      }
    }
    if (!any) {
      onEvent?.call(MineEvent.invalid);
      return;
    }
    for (final n in _neighbors(i)) {
      if (!visible[n] && !flag[n]) _floodOpen(n);
    }
    onEvent?.call(MineEvent.chord);
    _checkWin();
  }

  /// Logical flood open: marks cells open and stages their VISUAL reveal
  /// through the queue so every move animates visibly.
  void _floodOpen(int start) {
    final wave = <int>[];
    final stack = [start];
    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      if (open[i] || flag[i]) continue;
      if (mines.contains(i)) continue;
      open[i] = true;
      openCount++;
      wave.add(i);
      if (adj[i] == 0) {
        for (final n in _neighbors(i)) {
          if (!open[n] && !flag[n]) stack.add(n);
        }
      }
    }
    _enqueueReveal(wave, stepMs: _revealStepMs);
    notifyListeners();
  }

  /// Hint: reveal (pulse) one guaranteed-safe unopened cell. Free players get
  /// [hintsPerGame] per game; Pro is unlimited.
  void useHint() {
    if (over || paused) {
      onEvent?.call(MineEvent.invalid);
      return;
    }
    if (hintsLeft <= 0) {
      onEvent?.call(MineEvent.noHint);
      return;
    }
    if (!started) {
      // Before the first tap, any cell is safe — suggest the center.
      hintCell = total ~/ 2;
    } else {
      hintCell = _findSafeCell();
    }
    if (hintCell == null) {
      onEvent?.call(MineEvent.noHint);
      return;
    }
    if (!unlimitedHints) hintsLeft--;
    onEvent?.call(MineEvent.hint);
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(milliseconds: 1600), () {
      hintCell = null;
      notifyListeners();
    });
    notifyListeners();
  }

  /// Find a provably-safe unopened cell: prefer a neighbor of an open number
  /// whose remaining mines are fully accounted for by flags; fall back to any
  /// unopened non-mine cell.
  int? _findSafeCell() {
    for (var i = 0; i < total; i++) {
      if (!visible[i] || adj[i] == 0) continue;
      final ns = _neighbors(i);
      var flags = 0;
      final closed = <int>[];
      for (final n in ns) {
        if (flag[n]) {
          flags++;
        } else if (!open[n]) {
          closed.add(n);
        }
      }
      if (flags == adj[i] && closed.isNotEmpty) {
        return closed[_rand.nextInt(closed.length)];
      }
    }
    final safe = <int>[];
    for (var i = 0; i < total; i++) {
      if (!open[i] && !flag[i] && !mines.contains(i)) safe.add(i);
    }
    return safe.isEmpty ? null : safe[_rand.nextInt(safe.length)];
  }

  // ----------------------------------------------------------- reveal queue
  void _enqueueReveal(List<int> cells, {required int stepMs}) {
    if (cells.isEmpty) return;
    final wasEmpty = _queue.isEmpty;
    for (final c in cells) {
      if (!visible[c]) _queue.add(c);
    }
    if (wasEmpty && _queue.isNotEmpty) {
      phase = MinePhase.animating;
      _drainQueue(stepMs: stepMs);
    }
    notifyListeners();
  }

  void _drainQueue({int stepMs = _revealStepMs}) {
    if (_disposed || paused) return;
    _revealTimer?.cancel();
    if (_queue.isEmpty) {
      _finishQueue();
      return;
    }
    phase = MinePhase.animating;
    _revealTimer = Timer.periodic(Duration(milliseconds: stepMs), (t) {
      if (_disposed || paused) {
        t.cancel();
        return;
      }
      if (_queue.isEmpty) {
        t.cancel();
        _finishQueue();
        return;
      }
      final c = _queue.removeAt(0);
      visible[c] = true;
      notifyListeners();
    });
  }

  void _finishQueue() {
    _revealTimer = null;
    final cb = _onQueueDone;
    final wasLoss = _queueIsLoss;
    final wasWinWave = _queueIsWinWave;
    _onQueueDone = null;
    _queueIsLoss = false;
    _queueIsWinWave = false;
    if (over && (wasLoss || wasWinWave)) {
      phase = MinePhase.over;
      cb?.call();
    } else if (!over) {
      phase = started ? MinePhase.playing : MinePhase.ready;
    }
    notifyListeners();
  }

  // -------------------------------------------------------------- game end
  void _boomAt(int i) {
    boomAt = i;
    over = true;
    won = false;
    _tick?.cancel();
    _tick = null;
    // Reveal the whole minefield one mine at a time — never instant.
    final order = mines.toList()..shuffle(_rand);
    // Boom cell first for drama, then the rest.
    order.remove(i);
    order.insert(0, i);
    for (final m in order) {
      open[m] = true;
    }
    _queue.clear();
    _queueIsLoss = true;
    _queueIsWinWave = false;
    for (final m in order) {
      if (!visible[m]) _queue.add(m);
    }
    onEvent?.call(MineEvent.boom);
    phase = MinePhase.animating;
    _drainQueue(stepMs: _boomStepMs);
  }

  void _checkWin() {
    if (over) return;
    if (openCount < total - mineCount) return;
    over = true;
    won = true;
    _tick?.cancel();
    _tick = null;
    // Victory flag wave: plant flags on every unflagged mine, one by one.
    final order = mines.toList()..shuffle(_rand);
    _queue.clear();
    _queueIsWinWave = true;
    _queueIsLoss = false;
    for (final m in order) {
      flag[m] = true;
      if (!visible[m]) _queue.add(m);
    }
    onEvent?.call(MineEvent.win);
    phase = MinePhase.animating;
    _drainQueue(stepMs: _flagWaveStepMs);
  }

  int get flagsUsed => flag.where((f) => f).length;
  int get minesLeft => mineCount - flagsUsed;
}
