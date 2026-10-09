import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import '../engine/minefinder_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/minefinder_themes.dart';
import '../theme/miner_ui.dart';

/// The dig site. Engine owns all state; this screen only renders.
class GameScreen extends StatefulWidget {
  final MineEngine engine;
  final MineAudio audio;
  final MineSettings settings;
  final int difficultyIdx;
  final String? dailyDate; // yyyy-mm-dd for daily challenges
  const GameScreen({
    super.key,
    required this.engine,
    required this.audio,
    required this.settings,
    required this.difficultyIdx,
    this.dailyDate,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  MineEngine get _e => widget.engine;
  bool _endShown = false;
  bool _hintBlink = false;
  Timer? _blinkTimer;

  MineThemeDef get _t => MineThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    _e.onEvent = _onEngineEvent;
    _e.addListener(_onEngineChanged);
    widget.audio.startGameMusic();
    _blinkTimer =
        Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      setState(() => _hintBlink = !_hintBlink);
    });
  }

  void _onEngineEvent(MineEvent ev) {
    final a = widget.audio;
    switch (ev) {
      case MineEvent.gameStart:
        a.gameStart();
        break;
      case MineEvent.reveal:
        a.reveal();
        break;
      case MineEvent.flag:
        a.flag();
        break;
      case MineEvent.chord:
        a.chord();
        break;
      case MineEvent.hint:
        a.hint();
        break;
      case MineEvent.boom:
        a.boom();
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) widget.audio.lose();
        });
        break;
      case MineEvent.win:
        // Win jingle plays after the flag wave completes (see _onEngineChanged).
        break;
      case MineEvent.lose:
        break;
      case MineEvent.invalid:
        a.invalid();
        break;
      case MineEvent.noHint:
        a.invalid();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.settings.isPro
                    ? 'No safe cell found right now.'
                    : 'Out of hints! PRO diggers get unlimited hints.',
                style: Miner.body(14, theme: _t),
              ),
              backgroundColor: _t.soilDark,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        break;
    }
  }

  /// Watch for the engine settling into `over` (after the animated reveal
  /// finishes) — that is when we record stats and show the end dialog.
  void _onEngineChanged() {
    if (_e.over && _e.phase == MinePhase.over && !_endShown) {
      _endShown = true;
      if (_e.won) widget.audio.win();
      _showEndDialog();
    }
  }

  Future<void> _showEndDialog() async {
    final s = widget.settings;
    final newBest = await s.recordGame(
      won: _e.won,
      seconds: _e.seconds,
      difficultyIdx: widget.difficultyIdx,
      dailyDate: widget.dailyDate,
    );
    if (!mounted) return;
    final t = _t;
    final name = s.playerNames[0];
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: WoodCard(
          theme: t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_e.won ? '⛏️' : '💥',
                  style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 8),
              Text(
                _e.won ? 'Field cleared!' : 'BOOM!',
                style: Miner.display(28, theme: t),
              ),
              const SizedBox(height: 6),
              Text(
                _e.won
                    ? (newBest
                        ? 'NEW BEST TIME — $name, you legend! 🏆'
                        : 'Clean dig, $name! ${_fmt(_e.seconds)}')
                    : 'The minefield wins this round. Shake it off and retry!',
                style: Miner.body(15, theme: t),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '⏱️ ${_fmt(_e.seconds)}'
                '${widget.dailyDate != null ? ' · daily challenge' : ''}',
                style: Miner.label(14, theme: t),
              ),
              const SizedBox(height: 18),
              WoodButton(
                label: _e.won ? 'DIG AGAIN' : 'RETRY',
                theme: t,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                  _restart();
                },
              ),
              const SizedBox(height: 10),
              WoodGhostButton(
                label: 'BACK TO CAMP',
                theme: t,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(context).pop(); // dialog
                  Navigator.of(context).pop(); // game
                },
              ),
            ],
          ),
        ),
      ),
    );
    // Sensible review moment: after a win, once per install, only when the
    // player has some history. Graceful when not from Play.
    if (_e.won &&
        !s.reviewAsked &&
        s.gamesPlayed >= 3 &&
        mounted) {
      await s.markReviewAsked();
      try {
        final review = InAppReview.instance;
        if (await review.isAvailable()) {
          await review.requestReview();
        }
      } catch (_) {}
    }
  }

  void _restart() {
    setState(() {
      _endShown = false;
    });
    _e.restart();
  }

  void _togglePause() {
    if (_e.over) return;
    widget.audio.click();
    _e.setPaused(!_e.paused);
  }

  void _quit() {
    widget.audio.click();
    _e.setPaused(false);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _e.removeListener(_onEngineChanged);
    _e.dispose();
    super.dispose();
  }

  String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return SoilBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: _quit,
          ),
          title: Text(
            widget.dailyDate != null
                ? 'Daily Challenge'
                : _e.diff.name,
            style: Miner.display(20, theme: t),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _e.paused ? Icons.play_arrow : Icons.pause,
                color: t.accentLight,
              ),
              onPressed: _togglePause,
            ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _e,
            builder: (_, _) {
              if (_e.paused) return _pauseOverlay(t);
              return _board(t);
            },
          ),
        ),
      ),
    );
  }

  Widget _pauseOverlay(MineThemeDef t) {
    return Center(
      child: WoodCard(
        theme: t,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⏸️', style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            Text('Taking a breather', style: Miner.display(24, theme: t)),
            const SizedBox(height: 6),
            Text('the field is frozen — nothing moves',
                style: Miner.body(14, theme: t, color: t.muted)),
            const SizedBox(height: 18),
            WoodButton(
              label: 'RESUME',
              theme: t,
              onTap: _togglePause,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                WoodGhostButton(
                    label: 'RESTART', theme: t, onTap: () {
                  widget.audio.click();
                  _e.setPaused(false);
                  _restart();
                }),
                const SizedBox(width: 12),
                WoodGhostButton(label: 'QUIT', theme: t, onTap: _quit),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _board(MineThemeDef t) {
    final e = _e;
    final style = TileStyles.byId(widget.settings.tileStyleId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Column(
        children: [
          Row(
            children: [
              _hudChip(t, '💣 ${e.minesLeft}'),
              const SizedBox(width: 8),
              _hudChip(t, '⏱️ ${_fmt(e.seconds)}'),
              const Spacer(),
              _hudIcon(t, '💡', widget.settings.isPro ? '∞' : '${e.hintsLeft}',
                  _useHint),
              const SizedBox(width: 8),
              _hudIcon(t, '🔄', null, () {
                widget.audio.click();
                _restart();
              }),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            e.phase == MinePhase.animating
                ? 'digging…'
                : e.over
                    ? (e.won ? 'field cleared — legendary!' : 'boom…')
                    : 'tap = reveal · long-press = 🚩 · tap a number to chord',
            style: Miner.body(12, theme: t, color: t.muted),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: e.cols / e.rows,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: t.accent.withValues(alpha: 0.4), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        offset: Offset(0, 8),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: e.cols,
                            mainAxisSpacing: 3,
                            crossAxisSpacing: 3),
                    itemCount: e.total,
                    itemBuilder: (_, i) => _Cell(
                      index: i,
                      engine: e,
                      theme: t,
                      style: style,
                      hintPulse: i == e.hintCell && _hintBlink,
                      onTap: () => e.tap(i),
                      onLongPress: () => e.toggleFlag(i),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _useHint() {
    widget.audio.click();
    _e.useHint();
  }

  Widget _hudChip(MineThemeDef t, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: t.accent.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Text(label,
          style: Miner.label(14, theme: t)),
    );
  }

  Widget _hudIcon(
      MineThemeDef t, String emoji, String? badge, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: t.accent.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Text(badge, style: Miner.label(12, theme: t)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single dig tile. Unopened tiles are raised physical objects with a
/// bevel; opened cells are dug earth showing numbers, mines or flags.
class _Cell extends StatelessWidget {
  final int index;
  final MineEngine engine;
  final MineThemeDef theme;
  final TileStyle style;
  final bool hintPulse;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _Cell({
    required this.index,
    required this.engine,
    required this.theme,
    required this.style,
    required this.hintPulse,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final i = index;
    final e = engine;
    final t = theme;
    final isVisible = e.visible[i];
    final isMine = e.mines.contains(i);
    final showMine = isVisible && isMine;
    final showWrongFlag = e.over && !e.won && e.flag[i] && !isMine;
    final radius = BorderRadius.circular(4 + style.corner * 14);

    Widget? content;
    Color bg;
    BoxDecoration deco;

    if (showMine) {
      // Iron mine ball with brass studs.
      bg = t.tileOpen;
      content = _mineBall(t, i == e.boomAt);
      deco = BoxDecoration(color: bg, borderRadius: radius);
      if (i == e.boomAt) {
        deco = BoxDecoration(
          color: const Color(0xFF8B2323).withValues(alpha: 0.85),
          borderRadius: radius,
          border: Border.all(color: t.flag, width: 2),
        );
      }
    } else if (showWrongFlag) {
      bg = t.tileOpen;
      content = const Text('✖️', style: TextStyle(fontSize: 14));
      deco = BoxDecoration(color: bg, borderRadius: radius);
    } else if (isVisible) {
      bg = t.tileOpen;
      if (e.adj[i] > 0) {
        content = Text(
          '${e.adj[i]}',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: e.cols > 12 ? 11 : 15,
            color: t.numbers[(e.adj[i] - 1) % t.numbers.length],
            shadows: const [
              Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 2),
            ],
          ),
        );
      }
      deco = BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.4),
          width: 1,
        ),
      );
    } else {
      // Raised tile with physical bevel: light top/left, dark bottom/right.
      final bw = 2.0 + style.bevel * 8;
      bg = t.tileFace;
      if (e.flag[i]) {
        content = Text('🚩',
            style: TextStyle(
                fontSize: e.cols > 12 ? 11 : 15,
                color: t.flag,
                shadows: const [
                  Shadow(
                      color: Colors.black, offset: Offset(0, 1), blurRadius: 2),
                ]));
      }
      deco = BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border(
          top: BorderSide(color: t.tileEdge.withValues(alpha: 0.9), width: bw),
          left:
              BorderSide(color: t.tileEdge.withValues(alpha: 0.9), width: bw),
          bottom:
              BorderSide(color: t.tileShadow.withValues(alpha: 0.95), width: bw),
          right:
              BorderSide(color: t.tileShadow.withValues(alpha: 0.95), width: bw),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 2),
            blurRadius: 2,
          ),
        ],
      );
    }

    Widget cell = AnimatedContainer(
      duration: const Duration(milliseconds: 110),
      decoration: hintPulse
          ? deco.copyWith(
              border: Border.all(color: t.accentLight, width: 3),
              boxShadow: [
                BoxShadow(
                  color: t.accent.withValues(alpha: 0.7),
                  blurRadius: 8,
                ),
              ],
            )
          : deco,
      alignment: Alignment.center,
      child: content,
    );

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: cell,
    );
  }

  /// Iron mine: dark sphere with brass studs, drawn physically.
  Widget _mineBall(MineThemeDef t, bool exploded) {
    return LayoutBuilder(
      builder: (_, c) {
        final s = (c.maxWidth).clamp(8.0, 28.0);
        return Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.35),
              radius: 0.9,
              colors: [
                exploded ? const Color(0xFFFF8A5C) : const Color(0xFF4A4A52),
                t.mine,
              ],
            ),
            border: Border.all(
              color: t.accent.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Center(
            child: Container(
              width: s * 0.3,
              height: s * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      },
    );
  }
}
