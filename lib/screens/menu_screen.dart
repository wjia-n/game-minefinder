import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/minefinder_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/minefinder_themes.dart';
import '../theme/miner_ui.dart';
import 'custom_theme_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu: difficulties, daily challenge, name, themes, tile styles.
class MenuScreen extends StatefulWidget {
  final MineAudio audio;
  final MineSettings settings;
  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final StoreService _store;
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _store = StoreService();
    _store.init();
    _store.lastThanks.addListener(_onThanks);
    _nameCtrl.text = widget.settings.playerNames[0];
  }

  MineThemeDef get _t => MineThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  
  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Miner.body(15, theme: _t)),
        backgroundColor: _t.soilDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  @override
  void dispose() {
    _store.lastThanks.removeListener(_onThanks);
    _store.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Real in-app review flow: the Play in-app review sheet when available,
  /// otherwise fall back to opening the store listing. No fake dialogs.
  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  void _play({required int difficulty, bool daily = false}) {
    widget.audio.gameStart();
    final engine = MineEngine(
      diff: mineDifficulties[difficulty],
      seed: daily ? _dailySeed() : null,
      unlimitedHints: widget.settings.isPro,
    );
    widget.settings.setDifficulty(difficulty);
    // App-scoped music: keep playing across screens. GameScreen switches
    // to the game track on entry; we switch back to menu music on return.
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => GameScreen(
        engine: engine,
        audio: widget.audio,
        settings: widget.settings,
        difficultyIdx: difficulty,
        dailyDate: daily ? _dailyKey() : null,
      ),
    ))
        .then((_) {
      if (mounted) widget.audio.startMenuMusic();
    });
  }

  static String _dailyKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static int _dailySeed() {
    final n = DateTime.now();
    return n.year * 10000 + n.month * 100 + n.day;
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    return SoilBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: t.accent, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          offset: Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/minefinder_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 12),
                  Text('Mine Finder', style: Miner.display(38, theme: t)),
                  Text('tap · flag · clear the field',
                      style: Miner.body(14, theme: t, color: t.muted)),
                  const SizedBox(height: 18),
                  _DailyCard(theme: t, settings: s),
                  const SizedBox(height: 14),
                  _DiffCard(theme: t, settings: s),
                  const SizedBox(height: 14),
                  _NameCard(theme: t, settings: s, ctrl: _nameCtrl, audio: widget.audio),
                  const SizedBox(height: 14),
                  _ThemeCard(theme: t, settings: s),
                  const SizedBox(height: 14),
                  _TileCard(theme: t, settings: s),
                  const SizedBox(height: 14),
                  _SupportCard(theme: t, store: _store),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MenuIcon(
                        theme: t,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () async {
                          widget.audio.click();
                          // ignore: deprecated_member_use
                          await Share.share(
                              'I\'m digging for mines in Mine Finder! https://play.google.com/store/apps/details?id=com.gameswajiha.minefinder');
                        },
                      ),
                      const SizedBox(width: 22),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.star_rate,
                        label: 'Rate',
                        onTap: () async {
                          widget.audio.click();
                          await _requestReview();
                        },
                      ),
                      const SizedBox(width: 22),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () {
                          widget.audio.click();
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              audio: widget.audio,
                              settings: s,
                            ),
                          ));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('tap a tile to reveal · long-press to plant a flag',
                      style: Miner.body(12, theme: t, color: t.muted)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _DailyCard extends StatelessWidget {
  final MineThemeDef theme;
  final MineSettings settings;
  const _DailyCard({required this.theme, required this.settings});

  @override
  Widget build(BuildContext context) {
    final menu = context.findAncestorStateOfType<_MenuScreenState>()!;
    final done = settings.dailyDone.contains(_MenuScreenState._dailyKey());
    return GestureDetector(
      onTap: () {
        menu.widget.audio.click();
        menu._play(difficulty: 1, daily: true);
      },
      child: WoodCard(
        theme: theme,
        child: Row(
          children: [
            Text('📅', style: const TextStyle(fontSize: 38)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Challenge', style: Miner.display(19, theme: theme)),
                  Text(
                    done
                        ? 'cleared today — dig again tomorrow!'
                        : 'same field for everyone today · 12×12',
                    style: Miner.body(13, theme: theme, color: theme.muted),
                  ),
                ],
              ),
            ),
            if (done)
              Text('🏆', style: const TextStyle(fontSize: 30))
            else
              WoodButton(
                label: 'DIG IN',
                width: 110,
                small: true,
                theme: theme,
                onTap: () {
                  menu.widget.audio.click();
                  menu._play(difficulty: 1, daily: true);
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _DiffCard extends StatelessWidget {
  final MineThemeDef theme;
  final MineSettings settings;
  const _DiffCard({required this.theme, required this.settings});

  @override
  Widget build(BuildContext context) {
    final menu = context.findAncestorStateOfType<_MenuScreenState>()!;
    return WoodCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How deep today?', style: Miner.display(19, theme: theme)),
          const SizedBox(height: 4),
          Text('pick your minefield',
              style: Miner.body(13, theme: theme, color: theme.muted)),
          const SizedBox(height: 12),
          for (var i = 0; i < mineDifficulties.length; i++) ...[
            _diffRow(context, menu, theme, settings, i),
            if (i < mineDifficulties.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _diffRow(BuildContext context, _MenuScreenState menu, MineThemeDef theme,
      MineSettings settings, int i) {
    final d = mineDifficulties[i];
    final locked = d.pro && !settings.isPro;
    final best = settings.bestTimes[i];
    return GestureDetector(
      onTap: () {
        if (locked) {
          menu.widget.audio.click();
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProScreen(
              audio: menu.widget.audio,
              settings: settings,
              store: menu._store,
            ),
          ));
          return;
        }
        menu._play(difficulty: i);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: settings.difficulty == i
              ? theme.accent.withValues(alpha: 0.22)
              : Colors.black.withValues(alpha: 0.25),
          border: Border.all(
            color: settings.difficulty == i
                ? theme.accent
                : theme.accent.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(d.name, style: Miner.label(15, theme: theme)),
                      if (locked) ...[
                        const SizedBox(width: 8),
                        ProBadge(theme: theme),
                      ],
                    ],
                  ),
                  Text('${d.rows}×${d.cols} · ${d.mines} mines · ${d.tagline}',
                      style: Miner.body(12, theme: theme, color: theme.muted)),
                ],
              ),
            ),
            Text(
              best == null ? '—' : '🏆 ${_fmt(best)}',
              style: Miner.label(13, theme: theme),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
class _NameCard extends StatelessWidget {
  final MineThemeDef theme;
  final MineSettings settings;
  final TextEditingController ctrl;
  final MineAudio audio;
  const _NameCard({
    required this.theme,
    required this.settings,
    required this.ctrl,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    return WoodCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your digger name', style: Miner.display(19, theme: theme)),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            maxLength: 16,
            style: Miner.body(16, theme: theme),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Digger',
              hintStyle: Miner.body(16, theme: theme, color: theme.muted),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.accent.withValues(alpha: 0.4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.accent.withValues(alpha: 0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.accent, width: 2),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.check, color: theme.accentLight),
                onPressed: () {
                  audio.click();
                  settings.setPlayerName(0, ctrl.text);
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
            onSubmitted: (_) {
              audio.click();
              settings.setPlayerName(0, ctrl.text);
            },
            // Master rules: persist on EVERY keystroke (focus loss and
            // submit also commit; SharedPreferences order-safe via the
            // single-JSON-string key).
            onChanged: (v) => settings.setPlayerName(0, v),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _ThemeCard extends StatelessWidget {
  final MineThemeDef theme;
  final MineSettings settings;
  const _ThemeCard({required this.theme, required this.settings});

  @override
  Widget build(BuildContext context) {
    final menu = context.findAncestorStateOfType<_MenuScreenState>()!;
    final themes = [...MineThemes.all];
    return WoodCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Dig site themes', style: Miner.display(19, theme: theme)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (!settings.isPro) {
                    menu.widget.audio.click();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProScreen(
                        audio: menu.widget.audio,
                        settings: settings,
                        store: menu._store,
                      ),
                    ));
                    return;
                  }
                  menu.widget.audio.click();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CustomThemeScreen(
                      audio: menu.widget.audio,
                      settings: settings,
                    ),
                  ));
                },
                child: Row(
                  children: [
                    Text('🎨 Custom', style: Miner.label(13, theme: theme)),
                    if (!settings.isPro) ...[
                      const SizedBox(width: 6),
                      ProBadge(theme: theme),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${themes.length} hand-crafted looks',
              style: Miner.body(13, theme: theme, color: theme.muted)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.82,
            ),
            itemCount: themes.length,
            itemBuilder: (_, i) {
              final th = themes[i];
              final locked = th.pro && !settings.isPro;
              final selected = settings.themeId == th.id;
              return GestureDetector(
                onTap: () {
                  menu.widget.audio.click();
                  if (locked) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProScreen(
                        audio: menu.widget.audio,
                        settings: settings,
                        store: menu._store,
                      ),
                    ));
                    return;
                  }
                  settings.setTheme(th.id);
                },
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: th.tileFace,
                            border: Border.all(
                              color: selected
                                  ? theme.accentLight
                                  : theme.accent.withValues(alpha: 0.3),
                              width: selected ? 3 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                offset: const Offset(0, 3),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: th.tileOpen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text('3',
                                    style: TextStyle(
                                        color: th.numbers[2],
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14)),
                              ),
                            ),
                          ),
                        ),
                        if (locked)
                          const Positioned(
                            right: 2,
                            top: 2,
                            child: Text('🔒', style: TextStyle(fontSize: 14)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      th.name,
                      style: Miner.body(10,
                          theme: theme,
                          color: selected ? theme.accentLight : theme.muted),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _TileCard extends StatelessWidget {
  final MineThemeDef theme;
  final MineSettings settings;
  const _TileCard({required this.theme, required this.settings});

  @override
  Widget build(BuildContext context) {
    final menu = context.findAncestorStateOfType<_MenuScreenState>()!;
    return WoodCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tile craft', style: Miner.display(19, theme: theme)),
          const SizedBox(height: 4),
          Text('how your tiles feel',
              style: Miner.body(13, theme: theme, color: theme.muted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final st in TileStyles.all)
                _styleChip(context, menu, theme, settings, st),
            ],
          ),
        ],
      ),
    );
  }

  Widget _styleChip(BuildContext context, _MenuScreenState menu, MineThemeDef theme,
      MineSettings settings, TileStyle st) {
    final locked = st.pro && !settings.isPro;
    final selected = settings.tileStyleId == st.id;
    return GestureDetector(
      onTap: () {
        menu.widget.audio.click();
        if (locked) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProScreen(
              audio: menu.widget.audio,
              settings: settings,
              store: menu._store,
            ),
          ));
          return;
        }
        settings.setTileStyle(st.id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selected
              ? theme.accent.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.25),
          border: Border.all(
            color: selected ? theme.accent : theme.accent.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Text(
          locked ? '${st.name} 🔒' : st.name,
          style: Miner.body(13, theme: theme),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _SupportCard extends StatelessWidget {
  final MineThemeDef theme;
  final StoreService store;
  const _SupportCard({required this.theme, required this.store});

  @override
  Widget build(BuildContext context) {
    final menu = context.findAncestorStateOfType<_MenuScreenState>()!;
    return WoodCard(
      theme: theme,
      child: Row(
        children: [
          Text('⛏️', style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mine Finder PRO', style: Miner.display(18, theme: theme)),
                Text('more fields · more looks · unlimited hints',
                    style: Miner.body(12, theme: theme, color: theme.muted)),
              ],
            ),
          ),
          WoodGhostButton(
            label: menu.widget.settings.isPro ? 'VIEW' : 'GET PRO',
            theme: theme,
            onTap: () {
              menu.widget.audio.click();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ProScreen(
                  audio: menu.widget.audio,
                  settings: menu.widget.settings,
                  store: menu._store,
                ),
              ));
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _MenuIcon extends StatelessWidget {
  final MineThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuIcon({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.35),
              border: Border.all(
                  color: theme.accent.withValues(alpha: 0.6), width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black54,
                    offset: Offset(0, 4),
                    blurRadius: 8),
              ],
            ),
            child: Icon(icon, color: theme.accentLight, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: Miner.label(12, theme: theme)),
        ],
      ),
    );
  }
}
