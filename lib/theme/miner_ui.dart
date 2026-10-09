import 'package:flutter/material.dart';
import 'minefinder_themes.dart';

/// "Wood & Brass Digger" design system — physical materials, readable UI.
/// All widgets take a [MineThemeDef]; never neon, never generic Material.
class Miner {
  static const displayFont = 'serif';

  static TextStyle display(double size, {Color? color, MineThemeDef? theme}) =>
      TextStyle(
        fontFamily: displayFont,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8CE7A),
        letterSpacing: 1.2,
        shadows: const [
          Shadow(color: Color(0xFF000000), offset: Offset(0, 2), blurRadius: 4),
        ],
      );

  static TextStyle body(double size, {Color? color, MineThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? theme?.text ?? Colors.white,
        height: 1.35,
      );

  static TextStyle label(double size, {Color? color, MineThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8CE7A),
        letterSpacing: 0.8,
      );

  static ThemeData theme([MineThemeDef? t]) {
    t ??= MineThemes.byId('classic');
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: t.soilDark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: t.accent,
        onPrimary: t.soilDark,
        secondary: t.accentLight,
        onSecondary: t.soilDark,
        surface: t.soil,
        onSurface: t.text,
        error: t.flag,
        onError: t.text,
      ),
      textTheme: TextTheme(
        displayLarge: display(34, theme: t),
        displayMedium: display(26, theme: t),
        titleLarge: display(22, theme: t),
        bodyLarge: body(16, theme: t),
      ),
    );
  }
}

/// Soil backdrop with a vignette and subtle grain streaks.
class SoilBackdrop extends StatelessWidget {
  final MineThemeDef theme;
  final Widget child;
  const SoilBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.35),
          radius: 1.25,
          colors: [theme.soil, theme.soilDark],
        ),
      ),
      child: child,
    );
  }
}

/// Raised wooden panel card.
class WoodCard extends StatelessWidget {
  final MineThemeDef theme;
  final Widget child;
  final EdgeInsetsGeometry padding;
  const WoodCard({
    super.key,
    required this.theme,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.tileFace.withValues(alpha: 0.55),
            theme.soil.withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(color: theme.accent.withValues(alpha: 0.65), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Chunky physical button with a top bevel highlight.
class WoodButton extends StatelessWidget {
  final String label;
  final double width;
  final MineThemeDef theme;
  final VoidCallback onTap;
  final bool small;
  const WoodButton({
    super.key,
    required this.label,
    this.width = 260,
    required this.theme,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(vertical: small ? 9 : 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.accentLight, theme.accent, theme.accentDark],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            const BoxShadow(
              color: Colors.black54,
              offset: Offset(0, 5),
              blurRadius: 10,
            ),
            BoxShadow(
              color: theme.accent.withValues(alpha: 0.25),
              offset: const Offset(0, 1),
              blurRadius: 6,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Miner.label(
            small ? 14 : 17,
            theme: theme,
            color: theme.soilDark,
          ),
        ),
      ),
    );
  }
}

/// Ghost/outline button for secondary actions.
class WoodGhostButton extends StatelessWidget {
  final String label;
  final MineThemeDef theme;
  final VoidCallback onTap;
  const WoodGhostButton(
      {super.key, required this.label, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(color: theme.accent.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Text(label, style: Miner.label(14, theme: theme)),
      ),
    );
  }
}

/// Lock badge for Pro-only content.
class ProBadge extends StatelessWidget {
  final MineThemeDef theme;
  const ProBadge({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.accent.withValues(alpha: 0.28),
        border: Border.all(color: theme.accentLight),
      ),
      child: Text('PRO', style: Miner.label(10, theme: theme)),
    );
  }
}
