import 'package:flutter/material.dart';

/// Theme, tile-style and flag catalog for Mine Finder.
///
/// Art direction: "Wood & Brass Digger" — physical materials only: dark soil,
/// real wood grain, brass/copper/iron hardware, cloth flags, canvas. No neon,
/// no cyberpunk, no AI-dashboard looks. Every theme stays inside this world;
/// variety comes from different woods, metals, soils and leathers.
class MineThemeDef {
  final String id;
  final String name;
  final bool pro;

  /// App backdrop (dark soil).
  final Color soilDark;
  final Color soil;

  /// Raised, unopened tile (physical object).
  final Color tileFace;
  final Color tileEdge; // bevel highlight
  final Color tileShadow; // bevel shadow

  /// Opened cell (dug earth / removed plank).
  final Color tileOpen;

  /// Accent hardware (brass/copper/iron).
  final Color accent;
  final Color accentLight;
  final Color accentDark;

  final Color text;
  final Color muted;
  final Color flag; // cloth flag color
  final Color mine; // revealed mine iron color
  final List<Color> numbers; // classic 1..8 number palette per theme

  const MineThemeDef({
    required this.id,
    required this.name,
    required this.pro,
    required this.soilDark,
    required this.soil,
    required this.tileFace,
    required this.tileEdge,
    required this.tileShadow,
    required this.tileOpen,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.text,
    required this.muted,
    required this.flag,
    required this.mine,
    required this.numbers,
  });
}

class MineThemes {
  /// First 4 are FREE. The rest are PRO.
  static const freeIds = {'classic', 'pine', 'copper', 'slate'};

  static bool isProTheme(String id) => !freeIds.contains(id);

  static const List<MineThemeDef> all = [
    // ------------------------------ FREE ------------------------------
    MineThemeDef(
      id: 'classic',
      name: 'Classic Dig',
      pro: false,
      soilDark: Color(0xFF14100B),
      soil: Color(0xFF221A10),
      tileFace: Color(0xFF8A5A33),
      tileEdge: Color(0xFFB98A58),
      tileShadow: Color(0xFF4E2F18),
      tileOpen: Color(0xFF2A211A),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      text: Color(0xFFF5EFE0),
      muted: Color(0xFFB7A888),
      flag: Color(0xFFC23B2E),
      mine: Color(0xFF1A1A1E),
      numbers: [
        Color(0xFF4A7FC9), // 1
        Color(0xFF4CAF6D), // 2
        Color(0xFFD9534A), // 3
        Color(0xFF7B5CC9), // 4
        Color(0xFFD9A03C), // 5
        Color(0xFF45B8AC), // 6
        Color(0xFFE0E0E0), // 7
        Color(0xFF9A9AA0), // 8
      ],
    ),
    MineThemeDef(
      id: 'pine',
      name: 'Pine Workshop',
      pro: false,
      soilDark: Color(0xFF191209),
      soil: Color(0xFF2A2010),
      tileFace: Color(0xFFD9B06C),
      tileEdge: Color(0xFFF0D5A0),
      tileShadow: Color(0xFF8F6A3C),
      tileOpen: Color(0xFF3A2E1E),
      accent: Color(0xFFB0722E),
      accentLight: Color(0xFFE0A96A),
      accentDark: Color(0xFF7A4E1E),
      text: Color(0xFFFBF3E2),
      muted: Color(0xFFC6B28C),
      flag: Color(0xFFB02E22),
      mine: Color(0xFF232326),
      numbers: [
        Color(0xFF2E6BB8),
        Color(0xFF2E8B57),
        Color(0xFFC0392B),
        Color(0xFF6C3483),
        Color(0xFFB9770E),
        Color(0xFF148F77),
        Color(0xFF5D6D7E),
        Color(0xFF2C3E50),
      ],
    ),
    MineThemeDef(
      id: 'copper',
      name: 'Copper Canyon',
      pro: false,
      soilDark: Color(0xFF181009),
      soil: Color(0xFF281910),
      tileFace: Color(0xFF9A5C34),
      tileEdge: Color(0xFFD08A5A),
      tileShadow: Color(0xFF5C3320),
      tileOpen: Color(0xFF33231A),
      accent: Color(0xFFE08A4C),
      accentLight: Color(0xFFF5B984),
      accentDark: Color(0xFF9A5A2C),
      text: Color(0xFFF8EFE2),
      muted: Color(0xFFC4A686),
      flag: Color(0xFFD64541),
      mine: Color(0xFF202022),
      numbers: [
        Color(0xFF5B9BD5),
        Color(0xFF70AD47),
        Color(0xFFFF6B6B),
        Color(0xFF9B59B6),
        Color(0xFFF4B41F),
        Color(0xFF48C9B0),
        Color(0xFFF0E6D2),
        Color(0xFFB0B0B0),
      ],
    ),
    MineThemeDef(
      id: 'slate',
      name: 'Slate Quarry',
      pro: false,
      soilDark: Color(0xFF111316),
      soil: Color(0xFF1C2026),
      tileFace: Color(0xFF6B7684),
      tileEdge: Color(0xFF9AA5B3),
      tileShadow: Color(0xFF3A4048),
      tileOpen: Color(0xFF23272E),
      accent: Color(0xFFC0C6D4),
      accentLight: Color(0xFFE8ECF5),
      accentDark: Color(0xFF7E8698),
      text: Color(0xFFF2F4F8),
      muted: Color(0xFFA8B0BC),
      flag: Color(0xFFC23B2E),
      mine: Color(0xFF0E0E12),
      numbers: [
        Color(0xFF6CA8E8),
        Color(0xFF7FD08A),
        Color(0xFFE0705F),
        Color(0xFFB08AE0),
        Color(0xFFE8C56A),
        Color(0xFF6AD8C8),
        Color(0xFFE8E8E8),
        Color(0xFFA0A8B0),
      ],
    ),
    // ------------------------------- PRO ------------------------------
    MineThemeDef(
      id: 'desert',
      name: 'Desert Excavation',
      pro: true,
      soilDark: Color(0xFF1A1208),
      soil: Color(0xFF2C1F0E),
      tileFace: Color(0xFFE0B76A),
      tileEdge: Color(0xFFF5DAA5),
      tileShadow: Color(0xFF9A7438),
      tileOpen: Color(0xFF40300F),
      accent: Color(0xFFD9A03C),
      accentLight: Color(0xFFF2D38A),
      accentDark: Color(0xFF8F6A1E),
      text: Color(0xFFFBF1DC),
      muted: Color(0xFFC9AE7E),
      flag: Color(0xFFA93226),
      mine: Color(0xFF1F1F24),
      numbers: [
        Color(0xFF1D5FA8),
        Color(0xFF1E7A46),
        Color(0xFFB03A2E),
        Color(0xFF7D3C98),
        Color(0xFF935116),
        Color(0xFF0E6655),
        Color(0xFF616A6B),
        Color(0xFF212F3C),
      ],
    ),
    MineThemeDef(
      id: 'naval',
      name: 'Naval Dockyard',
      pro: true,
      soilDark: Color(0xFF0D1218),
      soil: Color(0xFF16202B),
      tileFace: Color(0xFF5A6B7A),
      tileEdge: Color(0xFF8B9DAD),
      tileShadow: Color(0xFF2E3843),
      tileOpen: Color(0xFF1E2833),
      accent: Color(0xFFB08D3C),
      accentLight: Color(0xFFE3C57E),
      accentDark: Color(0xFF7A5F26),
      text: Color(0xFFF0EDE4),
      muted: Color(0xFF9AA5A8),
      flag: Color(0xFFC0392B),
      mine: Color(0xFF101014),
      numbers: [
        Color(0xFF7FB3E8),
        Color(0xFF7ED08C),
        Color(0xFFE5735C),
        Color(0xFFB389E0),
        Color(0xFFE8C15C),
        Color(0xFF6FD8C8),
        Color(0xFFD5DBDB),
        Color(0xFF95A5A6),
      ],
    ),
    MineThemeDef(
      id: 'forest',
      name: 'Forest Floor',
      pro: true,
      soilDark: Color(0xFF0F1409),
      soil: Color(0xFF1A2410),
      tileFace: Color(0xFF7A6A3E),
      tileEdge: Color(0xFFA8965C),
      tileShadow: Color(0xFF453B20),
      tileOpen: Color(0xFF232B18),
      accent: Color(0xFF9AB53C),
      accentLight: Color(0xFFC9DE7E),
      accentDark: Color(0xFF647A26),
      text: Color(0xFFF2F0DE),
      muted: Color(0xFFA8AE8A),
      flag: Color(0xFFC0392B),
      mine: Color(0xFF15151A),
      numbers: [
        Color(0xFF6FA8DC),
        Color(0xFF93C47D),
        Color(0xFFE06666),
        Color(0xFF8E7CC3),
        Color(0xFFD9B24A),
        Color(0xFF6FD3BE),
        Color(0xFFEFEFEF),
        Color(0xFFB6B6B6),
      ],
    ),
    MineThemeDef(
      id: 'marble',
      name: 'Marble Vault',
      pro: true,
      soilDark: Color(0xFF121214),
      soil: Color(0xFF1E1E22),
      tileFace: Color(0xFFE8E4DA),
      tileEdge: Color(0xFFFFFFFF),
      tileShadow: Color(0xFF9A968C),
      tileOpen: Color(0xFF2A2A2E),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      text: Color(0xFFFBFAF6),
      muted: Color(0xFFB8B4A8),
      flag: Color(0xFFA93226),
      mine: Color(0xFF0A0A0C),
      numbers: [
        Color(0xFF2471A3),
        Color(0xFF1E8449),
        Color(0xFFCB4335),
        Color(0xFF7D3C98),
        Color(0xFFB7950B),
        Color(0xFF117A65),
        Color(0xFF5D6D7E),
        Color(0xFF2C3E50),
      ],
    ),
    MineThemeDef(
      id: 'volcano',
      name: 'Volcanic Ash',
      pro: true,
      soilDark: Color(0xFF120B0B),
      soil: Color(0xFF201414),
      tileFace: Color(0xFF4A4038),
      tileEdge: Color(0xFF7A6C5E),
      tileShadow: Color(0xFF221C18),
      tileOpen: Color(0xFF2A1E18),
      accent: Color(0xFFE86A3C),
      accentLight: Color(0xFFF5A07A),
      accentDark: Color(0xFF9A4226),
      text: Color(0xFFF8EDE4),
      muted: Color(0xFFC09A82),
      flag: Color(0xFFFFD24A),
      mine: Color(0xFF0C0C0E),
      numbers: [
        Color(0xFF85C1E9),
        Color(0xFF82E0AA),
        Color(0xFFF1948A),
        Color(0xFFBB8FCE),
        Color(0xFFF9E79F),
        Color(0xFF76D7C4),
        Color(0xFFF2F3F4),
        Color(0xFFBDC3C7),
      ],
    ),
    MineThemeDef(
      id: 'arctic',
      name: 'Arctic Mine',
      pro: true,
      soilDark: Color(0xFF0D1418),
      soil: Color(0xFF182229),
      tileFace: Color(0xFFBCD4DE),
      tileEdge: Color(0xFFE8F4F8),
      tileShadow: Color(0xFF7A94A2),
      tileOpen: Color(0xFF232F38),
      accent: Color(0xFF6AA8C9),
      accentLight: Color(0xFFA8D4E8),
      accentDark: Color(0xFF467A98),
      text: Color(0xFFF4F8FA),
      muted: Color(0xFF9AB0BC),
      flag: Color(0xFFC0392B),
      mine: Color(0xFF0A0C0E),
      numbers: [
        Color(0xFF1A5276),
        Color(0xFF1E8449),
        Color(0xFF922B21),
        Color(0xFF6C3483),
        Color(0xFF7E5109),
        Color(0xFF0E6655),
        Color(0xFF2E4053),
        Color(0xFF212F3C),
      ],
    ),
    MineThemeDef(
      id: 'autumn',
      name: 'Autumn Grove',
      pro: true,
      soilDark: Color(0xFF14100A),
      soil: Color(0xFF231A10),
      tileFace: Color(0xFFA86A3C),
      tileEdge: Color(0xFFD8985E),
      tileShadow: Color(0xFF5F3A20),
      tileOpen: Color(0xFF332415),
      accent: Color(0xFFD9A03C),
      accentLight: Color(0xFFF2D38A),
      accentDark: Color(0xFF8F6A1E),
      text: Color(0xFFFAF0DC),
      muted: Color(0xFFC4A67E),
      flag: Color(0xFF7D2E1E),
      mine: Color(0xFF16161A),
      numbers: [
        Color(0xFF5D9CEC),
        Color(0xFF6FCF97),
        Color(0xFFE5735C),
        Color(0xFFAC92EC),
        Color(0xFFFFCE54),
        Color(0xFF66D7C5),
        Color(0xFFF5F5F5),
        Color(0xFFAAB2BD),
      ],
    ),
    MineThemeDef(
      id: 'deepshaft',
      name: 'Deep Shaft',
      pro: true,
      soilDark: Color(0xFF080808),
      soil: Color(0xFF141210),
      tileFace: Color(0xFF3E3A34),
      tileEdge: Color(0xFF655E52),
      tileShadow: Color(0xFF1A1815),
      tileOpen: Color(0xFF1C1916),
      accent: Color(0xFFE8CE7A),
      accentLight: Color(0xFFF8E8B0),
      accentDark: Color(0xFF9A8A4C),
      text: Color(0xFFF5EFE0),
      muted: Color(0xFF9A9484),
      flag: Color(0xFFD64541),
      mine: Color(0xFF000000),
      numbers: [
        Color(0xFF7FB3E8),
        Color(0xFF7ED08C),
        Color(0xFFE5735C),
        Color(0xFFB389E0),
        Color(0xFFE8C15C),
        Color(0xFF6FD8C8),
        Color(0xFFE8E8E8),
        Color(0xFFA0A8B0),
      ],
    ),
  ];

  static MineThemeDef byId(String id, {MineThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}

/// Physical tile styles — how the raised tile looks (bevel, corners).
/// First 4 FREE, rest PRO.
class TileStyle {
  final String id;
  final String name;
  final bool pro;
  final double corner; // 0..1 fraction of tile size
  final double bevel; // 0..1 bevel thickness fraction
  const TileStyle({
    required this.id,
    required this.name,
    required this.pro,
    required this.corner,
    required this.bevel,
  });
}

class TileStyles {
  static const List<TileStyle> all = [
    TileStyle(id: 'plank', name: 'Oak Plank', pro: false, corner: 0.12, bevel: 0.10),
    TileStyle(id: 'brass', name: 'Brass Plate', pro: false, corner: 0.20, bevel: 0.14),
    TileStyle(id: 'stone', name: 'Stone Slab', pro: false, corner: 0.06, bevel: 0.08),
    TileStyle(id: 'leather', name: 'Leather Pad', pro: false, corner: 0.30, bevel: 0.06),
    TileStyle(id: 'iron', name: 'Riveted Iron', pro: true, corner: 0.16, bevel: 0.18),
    TileStyle(id: 'ceramic', name: 'Glazed Ceramic', pro: true, corner: 0.26, bevel: 0.05),
    TileStyle(id: 'marble', name: 'Cut Marble', pro: true, corner: 0.04, bevel: 0.12),
    TileStyle(id: 'canvas', name: 'Canvas Patch', pro: true, corner: 0.34, bevel: 0.04),
  ];

  static const List<String> freeIds = ['plank', 'brass', 'stone', 'leather'];
  static bool isPro(String id) => !freeIds.contains(id);
  static TileStyle byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return all.first;
  }
}
