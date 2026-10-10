import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/minefinder_themes.dart';

/// Persisted settings + stats for Mine Finder. Survives app restarts.
///
/// Stores: audio toggles, the player's renameable name, theme/appearance
/// choices (incl. custom theme colors), difficulty, daily-challenge progress,
/// Pro unlock state, and lifetime stats / best times.
class MineSettings extends ChangeNotifier {
  static const _kMusic = 'minefinder_music_on';
  static const _kSfx = 'minefinder_sfx_on';
  static const _kVolume = 'minefinder_volume';
  static const _kNames = 'minefinder_player_names'; // legacy unordered key
  /// Order-safe player-name storage: a single JSON string. Android's
  /// SharedPreferences stores StringLists as an unordered StringSet, so the
  /// old key scrambled name order on every app restart. Never use a
  /// StringList for ordered data on Android.
  static const _kNamesJson = 'minefinder_player_names_json';
  static const _kTheme = 'minefinder_theme_id';
  static const _kTileStyle = 'minefinder_tile_style';
  static const _kDifficulty = 'minefinder_difficulty'; // 0..3
  static const _kWins = 'minefinder_wins';
  static const _kGames = 'minefinder_games_played';
  static const _kBest = 'minefinder_best_times_json'; // {diffIdx: seconds}
  static const _kDaily = 'minefinder_daily_done_json'; // [yyyy-mm-dd,...]
  static const _kReviewAsked = 'minefinder_review_asked';
  static const _kIsPro = 'minefinder_is_pro';
  static const _kCustomPrefix = 'minefinder_custom_';

  static const defaultNames = ['Digger'];

  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  static String _cleanName(int i, Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultNames[i] : s;
  }

  /// Decode persisted names; falls back to defaults on missing/corrupt data.
  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return List.of(defaultNames);
    try {
      final d = jsonDecode(raw);
      if (d is List && d.length == defaultNames.length) {
        return [for (int i = 0; i < defaultNames.length; i++) _cleanName(i, d[i])];
      }
    } catch (_) {}
    return List.of(defaultNames);
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  List<String> playerNames = List.of(defaultNames);
  String themeId = 'classic';
  String tileStyleId = 'plank';
  int difficulty = 0;
  int wins = 0;
  int gamesPlayed = 0;
  Map<int, int> bestTimes = {}; // difficulty index -> best seconds
  Set<String> dailyDone = {}; // yyyy-mm-dd dates cleared
  bool reviewAsked = false;
  bool isPro = true; // everything unlocked — no Pro version

  /// Custom theme colors (ARGB ints). Defaults mirror Classic Dig.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  /// Public read-only view of the default custom-theme palette keys.
  static Map<String, int> get defaults => _defaultCustomColors;

  static const Map<String, int> _defaultCustomColors = {
    'soilDark': 0xFF14100B,
    'soil': 0xFF221A10,
    'tileFace': 0xFF8A5A33,
    'tileEdge': 0xFFB98A58,
    'tileShadow': 0xFF4E2F18,
    'tileOpen': 0xFF2A211A,
    'accent': 0xFFC9A227,
    'accentLight': 0xFFE8CE7A,
    'accentDark': 0xFF8A6D1A,
    'text': 0xFFF5EFE0,
    'flag': 0xFFC23B2E,
  };

  /// Builds the user-designed custom theme from stored colors.
  MineThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return MineThemeDef(
      id: 'custom',
      name: 'My Creation',
      pro: true,
      soilDark: c('soilDark'),
      soil: c('soil'),
      tileFace: c('tileFace'),
      tileEdge: c('tileEdge'),
      tileShadow: c('tileShadow'),
      tileOpen: c('tileOpen'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      accentDark: c('accentDark'),
      text: c('text'),
      muted: Color.lerp(c('text'), c('soil'), 0.45) ?? c('text'),
      flag: c('flag'),
      mine: const Color(0xFF1A1A1E),
      numbers: const [
        Color(0xFF4A7FC9),
        Color(0xFF4CAF6D),
        Color(0xFFD9534A),
        Color(0xFF7B5CC9),
        Color(0xFFD9A03C),
        Color(0xFF45B8AC),
        Color(0xFFE0E0E0),
        Color(0xFF9A9AA0),
      ],
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    // Player names: prefer the order-safe JSON key. Fall back to the legacy
    // StringList key once (one-time migration); it may already be scrambled
    // on Android, which is exactly the bug this replaces.
    final namesRaw = p.getString(_kNamesJson);
    if (namesRaw != null) {
      playerNames = decodePlayerNames(namesRaw);
    } else {
      final legacy = p.getStringList(_kNames);
      playerNames = (legacy != null && legacy.length == defaultNames.length)
          ? [for (int i = 0; i < defaultNames.length; i++) _cleanName(i, legacy[i])]
          : List.of(defaultNames);
    }
    themeId = p.getString(_kTheme) ?? 'classic';
    tileStyleId = p.getString(_kTileStyle) ?? 'plank';
    difficulty = (p.getInt(_kDifficulty) ?? 0).clamp(0, 3);
    wins = p.getInt(_kWins) ?? 0;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    bestTimes = _decodeBest(p.getString(_kBest));
    dailyDone = _decodeDaily(p.getString(_kDaily));
    reviewAsked = p.getBool(_kReviewAsked) ?? false;
    isPro = true; // everything unlocked
    for (final k in _defaultCustomColors.keys) {
      customColors[k] = p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  static Map<int, int> _decodeBest(String? raw) {
    final out = <int, int>{};
    if (raw == null) return out;
    try {
      final d = jsonDecode(raw);
      if (d is Map) {
        d.forEach((k, v) {
          final i = int.tryParse('$k');
          if (i != null && v is int && v > 0) out[i] = v;
        });
      }
    } catch (_) {}
    return out;
  }

  static Set<String> _decodeDaily(String? raw) {
    if (raw == null) return {};
    try {
      final d = jsonDecode(raw);
      if (d is List) return {for (final e in d) '$e'};
    } catch (_) {}
    return {};
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setString(_kNamesJson, encodePlayerNames(playerNames));
    await p.remove(_kNames); // drop the legacy unordered key for good
    await p.setString(_kTheme, themeId);
    await p.setString(_kTileStyle, tileStyleId);
    await p.setInt(_kDifficulty, difficulty);
    await p.setInt(_kWins, wins);
    await p.setInt(_kGames, gamesPlayed);
    await p.setString(_kBest, jsonEncode({for (final e in bestTimes.entries) '${e.key}': e.value}));
    await p.setString(_kDaily, jsonEncode(dailyDone.toList()));
    await p.setBool(_kReviewAsked, reviewAsked);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || MineThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (TileStyles.isPro(tileStyleId)) {
      tileStyleId = 'plank';
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(int index, String name) async {
    if (index < 0 || index >= defaultNames.length) return;
    final clean = name.trim();
    playerNames[index] = clean.isEmpty ? defaultNames[index] : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || MineThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setTileStyle(String id) async {
    if (!isPro && TileStyles.isPro(id)) return;
    tileStyleId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    v = v.clamp(0, 3);
    if (!isPro && v > 1) return; // Hard + Expert are Pro
    difficulty = v;
    notifyListeners();
    await _save();
  }

  Future<void> markReviewAsked() async {
    reviewAsked = true;
    await _save();
  }

  /// Record a finished game. Returns true if this set a new best time.
  Future<bool> recordGame({
    required bool won,
    required int seconds,
    required int difficultyIdx,
    String? dailyDate, // yyyy-mm-dd when this was a daily challenge
  }) async {
    gamesPlayed++;
    var newBest = false;
    if (won) {
      wins++;
      final prev = bestTimes[difficultyIdx];
      if (prev == null || seconds < prev) {
        bestTimes[difficultyIdx] = seconds;
        newBest = true;
      }
      if (dailyDate != null) dailyDone.add(dailyDate);
    }
    notifyListeners();
    await _save();
    return newBest;
  }
}
