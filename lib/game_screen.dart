import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Mine Finder — classic minesweeper with best-time chasing. 💣
class MineFinderScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const MineFinderScreen(
      {super.key, required this.players, required this.callbacks});

  @override
  State<MineFinderScreen> createState() => _MineFinderScreenState();
}

class _Diff {
  final String name, emoji;
  final int rows, cols, mines;
  const _Diff(this.name, this.emoji, this.rows, this.cols, this.mines);
}

const _diffs = [
  _Diff('Cozy', '🌱', 9, 9, 10),
  _Diff('Spicy', '🌶️', 12, 12, 25),
  _Diff('Wild', '🔥', 16, 16, 45),
];

class _MineFinderScreenState extends State<MineFinderScreen> {
  int? _diff; // null => difficulty chooser
  Set<int> _mines = {};
  List<int> _adj = [];
  List<bool> _open = [];
  List<bool> _flag = [];
  bool _started = false;
  bool _over = false;
  bool _won = false;
  int _boomAt = -1;
  int _seconds = 0;
  Timer? _timer;
  List<int?> _best = [null, null, null];
  SharedPreferences? _prefs;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      _prefs = p;
      setState(() {
        _best = List.generate(
            3, (i) => p.getInt('minefinder_best_$i'));
      });
      final cur = p.getInt('minefinder_current');
      if (cur != null && cur >= 0 && cur < _diffs.length) {
        _choose(cur, silent: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  _Diff get _d => _diffs[_diff!];
  int get _total => _d.rows * _d.cols;

  void _backToChooser() {
    _timer?.cancel();
    setState(() => _diff = null);
    Sfx.tap();
  }

  void _choose(int i, {bool silent = false}) {
    setState(() {
      _diff = i;
      _mines = {};
      _adj = List.filled(_total, 0);
      _open = List.filled(_total, false);
      _flag = List.filled(_total, false);
      _started = false;
      _over = false;
      _won = false;
      _boomAt = -1;
      _seconds = 0;
    });
    _prefs?.setInt('minefinder_current', i);
    if (!silent) Sfx.click();
  }

  void _placeMines(int safe) {
    final d = _d;
    final sr = safe ~/ d.cols, sc = safe % d.cols;
    final banned = <int>{};
    for (var r = sr - 1; r <= sr + 1; r++) {
      for (var c = sc - 1; c <= sc + 1; c++) {
        if (r >= 0 && r < d.rows && c >= 0 && c < d.cols) {
          banned.add(r * d.cols + c);
        }
      }
    }
    final spots = List.generate(_total, (i) => i)
      ..removeWhere(banned.contains)
      ..shuffle(_rng);
    _mines = spots.take(d.mines).toSet();
    for (final m in _mines) {
      final r = m ~/ d.cols, c = m % d.cols;
      for (var rr = r - 1; rr <= r + 1; rr++) {
        for (var cc = c - 1; cc <= c + 1; cc++) {
          if (rr == r && cc == c) continue;
          if (rr >= 0 && rr < d.rows && cc >= 0 && cc < d.cols) {
            _adj[rr * d.cols + cc]++;
          }
        }
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _over) return;
      setState(() => _seconds++);
    });
  }

  void _tap(int i) {
    if (_over || _open[i] || _flag[i]) return;
    if (!_started) {
      _placeMines(i);
      _started = true;
      _startTimer();
    }
    if (_mines.contains(i)) {
      setState(() {
        _over = true;
        _boomAt = i;
      });
      _timer?.cancel();
      Sfx.lose();
      widget.callbacks.finish(
        headline: 'BOOM! 💥',
        subline:
            'The minefield wins this round. ${_d.mines} sneaky mines… shake it off and retry! 💪',
      );
      return;
    }
    setState(() => _flood(i));
    Sfx.tap();
    _checkWin();
  }

  void _flood(int start) {
    final d = _d;
    final stack = [start];
    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      if (_open[i] || _flag[i]) continue;
      _open[i] = true;
      if (_adj[i] == 0 && !_mines.contains(i)) {
        final r = i ~/ d.cols, c = i % d.cols;
        for (var rr = r - 1; rr <= r + 1; rr++) {
          for (var cc = c - 1; cc <= c + 1; cc++) {
            if (rr >= 0 && rr < d.rows && cc >= 0 && cc < d.cols) {
              final j = rr * d.cols + cc;
              if (!_open[j] && !_flag[j]) stack.add(j);
            }
          }
        }
      }
    }
  }

  void _toggleFlag(int i) {
    if (_over || _open[i] || !_started) return;
    setState(() => _flag[i] = !_flag[i]);
    Sfx.click();
  }

  void _checkWin() {
    if (_over) return;
    final need = _total - _d.mines;
    var got = 0;
    for (var i = 0; i < _total; i++) {
      if (_open[i]) got++;
    }
    if (got < need) return;
    setState(() {
      _over = true;
      _won = true;
    });
    _timer?.cancel();
    Sfx.win();
    final prev = _best[_diff!];
    final isBest = prev == null || _seconds < prev;
    if (isBest) {
      _best[_diff!] = _seconds;
      _prefs?.setInt('minefinder_best_${_diff!}', _seconds);
    }
    widget.callbacks.finish(
      headline: 'Field cleared in ${_fmt(_seconds)}! 💣✨',
      subline: isBest
          ? 'NEW BEST TIME on ${_d.name}! You absolute legend 🏆'
          : 'So clean! Best on ${_d.name} is ${_fmt(prev)} — chase it! 🏃',
    );
  }

  String _fmt(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  List<Color> _numPalette(GameTheme t) {
    final base = HSLColor.fromColor(t.primary);
    return List.generate(8, (i) {
      final h = (base.hue + 200 + i * 38 + 360) % 360;
      return HSLColor.fromAHSL(1, h, 0.65, t.dark ? 0.62 : 0.42).toColor();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    if (_diff == null) return _chooser(t);
    return _game(t);
  }

  Widget _chooser(GameTheme t) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How brave today? 💣',
              style: TextStyle(
                  color: t.text, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('bigger field, more mines, more glory',
              style: TextStyle(color: t.muted, fontSize: 14)),
          const SizedBox(height: 20),
          for (var i = 0; i < _diffs.length; i++) ...[
            _diffCard(t, i),
            const SizedBox(height: 12),
          ],
          const Spacer(),
          Center(
            child: Text('tap = reveal · long-press = 🚩',
                style: TextStyle(color: t.muted, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _diffCard(GameTheme t, int i) {
    final d = _diffs[i];
    final best = i < _best.length ? _best[i] : null;
    return GestureDetector(
      onTap: () => _choose(i),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: t.radius,
          border: Border.all(color: t.primary.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: t.primary.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          children: [
            Text(d.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.name,
                      style: TextStyle(
                          color: t.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                  Text('${d.rows}×${d.cols} · ${d.mines} mines',
                      style: TextStyle(color: t.muted, fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: t.primary.withValues(alpha: 0.15),
                borderRadius: t.radius,
              ),
              child: Text(best == null ? '—' : '🏆 ${_fmt(best)}',
                  style: TextStyle(
                      color: t.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _game(GameTheme t) {
    final d = _d;
    final flags = _flag.where((f) => f).length;
    final pal = _numPalette(t);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              _iconBtn(t, '◀️', _backToChooser),
              const SizedBox(width: 8),
              Text('${d.emoji} ${d.name}',
                  style: TextStyle(
                      color: t.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const Spacer(),
              _hudChip(t, '💣 ${d.mines - flags}'),
              const SizedBox(width: 8),
              _hudChip(t, '⏱️ ${_fmt(_seconds)}'),
              const SizedBox(width: 8),
              _iconBtn(t, '🔄', () => _choose(_diff!)),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: d.cols / d.rows,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: t.surface.withValues(alpha: 0.5),
                    borderRadius: t.radius,
                    border: Border.all(
                        color: t.primary.withValues(alpha: 0.3), width: 2),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: d.cols,
                            mainAxisSpacing: 3,
                            crossAxisSpacing: 3),
                    itemCount: _total,
                    itemBuilder: (_, i) => _cell(i, t, pal),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_won)
            Text('field cleared — legendary! 🏆',
                style: TextStyle(color: t.accent, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _hudChip(GameTheme t, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration:
          BoxDecoration(color: t.surface, borderRadius: t.radius),
      child: Text(label,
          style: TextStyle(
              color: t.text, fontWeight: FontWeight.w800, fontSize: 14)),
    );
  }

  Widget _iconBtn(GameTheme t, String emoji, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: t.surface,
            borderRadius: t.radius,
            border: Border.all(color: t.primary.withValues(alpha: 0.3))),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _cell(int i, GameTheme t, List<Color> pal) {
    final isOpen = _open[i];
    final isMine = _mines.contains(i);
    final showAll = _over && !_won;
    Widget content = const SizedBox.shrink();
    Color bg = t.primary.withValues(alpha: 0.16);
    if (isOpen || (showAll && isMine)) {
      bg = t.background.withValues(alpha: 0.7);
      if (isMine) {
        content = Text(i == _boomAt ? '💥' : '💣',
            style: TextStyle(fontSize: _d.cols > 12 ? 12 : 16));
        if (i == _boomAt) bg = const Color(0xFFE5484D).withValues(alpha: 0.5);
      } else if (_adj[i] > 0) {
        content = Text('${_adj[i]}',
            style: TextStyle(
                fontSize: _d.cols > 12 ? 11 : 15,
                fontWeight: FontWeight.w900,
                color: pal[(_adj[i] - 1) % pal.length]));
      }
    } else if (_flag[i]) {
      content =
          Text('🚩', style: TextStyle(fontSize: _d.cols > 12 ? 11 : 15));
    }
    return GestureDetector(
      onTap: () => _tap(i),
      onLongPress: () => _toggleFlag(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: isOpen
              ? null
              : Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.25), width: 2),
                  left: BorderSide(
                      color: Colors.white.withValues(alpha: 0.25), width: 2),
                ),
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}
