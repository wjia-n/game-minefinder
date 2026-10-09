import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/minefinder_themes.dart';
import '../theme/miner_ui.dart';

/// Custom theme creator (PRO): pick the physical colors of your dig site.
class CustomThemeScreen extends StatelessWidget {
  final MineAudio audio;
  final MineSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  @override
  Widget build(BuildContext context) {
    final preview = settings.customTheme;
    return SoilBackdrop(
      theme: preview,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: preview.accentLight),
            onPressed: () {
              audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Custom Theme', style: Miner.display(22, theme: preview)),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                audio.click();
                settings.resetCustomColors();
              },
              child: Text('RESET', style: Miner.label(13, theme: preview)),
            ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: settings,
            builder: (_, _) {
              final t = settings.customTheme;
              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Column(
                  children: [
                    _PreviewBoard(theme: t),
                    const SizedBox(height: 14),
                    WoodCard(
                      theme: t,
                      child: Column(
                        children: [
                          WoodButton(
                            label: 'USE MY CREATION',
                            theme: t,
                            onTap: () {
                              audio.click();
                              settings.setTheme('custom');
                              Navigator.of(context).pop();
                            },
                          ),
                          const SizedBox(height: 14),
                          for (final key in MineSettings.defaults.keys)
                            _ColorRow(
                              theme: t,
                              settings: settings,
                              colorKey: key,
                              audio: audio,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PreviewBoard extends StatelessWidget {
  final MineThemeDef theme;
  const _PreviewBoard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.35),
        border:
            Border.all(color: theme.accent.withValues(alpha: 0.4), width: 2),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: 25,
        itemBuilder: (_, i) {
          if (i == 7) {
            return Container(
              decoration: BoxDecoration(
                color: theme.tileOpen,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text('3',
                  style: TextStyle(
                      color: theme.numbers[2],
                      fontWeight: FontWeight.w900,
                      fontSize: 16)),
            );
          }
          if (i == 17) {
            return Container(
              decoration: BoxDecoration(
                color: theme.tileFace,
                borderRadius: BorderRadius.circular(6),
                border: Border(
                  top: BorderSide(color: theme.tileEdge, width: 2),
                  left: BorderSide(color: theme.tileEdge, width: 2),
                  bottom: BorderSide(color: theme.tileShadow, width: 2),
                  right: BorderSide(color: theme.tileShadow, width: 2),
                ),
              ),
              alignment: Alignment.center,
              child: Text('🚩',
                  style: TextStyle(color: theme.flag, fontSize: 14)),
            );
          }
          return Container(
            decoration: BoxDecoration(
              color: theme.tileFace,
              borderRadius: BorderRadius.circular(6),
              border: Border(
                top: BorderSide(color: theme.tileEdge, width: 2),
                left: BorderSide(color: theme.tileEdge, width: 2),
                bottom: BorderSide(color: theme.tileShadow, width: 2),
                right: BorderSide(color: theme.tileShadow, width: 2),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final MineThemeDef theme;
  final MineSettings settings;
  final String colorKey;
  final MineAudio audio;
  const _ColorRow({
    required this.theme,
    required this.settings,
    required this.colorKey,
    required this.audio,
  });

  static const _labels = {
    'soilDark': 'Deep soil',
    'soil': 'Surface soil',
    'tileFace': 'Tile face',
    'tileEdge': 'Tile bevel light',
    'tileShadow': 'Tile bevel shadow',
    'tileOpen': 'Dug earth',
    'accent': 'Brass accent',
    'accentLight': 'Brass highlight',
    'accentDark': 'Brass shadow',
    'text': 'Text',
    'flag': 'Flag cloth',
  };

  static const _palette = [
    0xFF8A5A33, 0xFFD9B06C, 0xFF9A5C34, 0xFF6B7684, // woods/stone
    0xFF3B2416, 0xFF14100B, 0xFF2A211A, 0xFF23272E, // darks
    0xFFC9A227, 0xFFE08A4C, 0xFFC0C6D4, 0xFF9AB53C, // metals
    0xFFC23B2E, 0xFF1D4E9E, 0xFF1B7A4D, 0xFFF5EFE0, // flag/jewels/ivory
  ];

  @override
  Widget build(BuildContext context) {
    final current = settings.customColors[colorKey] ?? 0xFF000000;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Color(current),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                      color: theme.accent.withValues(alpha: 0.5)),
                ),
              ),
              const SizedBox(width: 10),
              Text(_labels[colorKey] ?? colorKey, style: Miner.body(14, theme: theme)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _palette)
                GestureDetector(
                  onTap: () {
                    audio.click();
                    settings.setCustomColor(colorKey, c);
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c == current
                            ? theme.accentLight
                            : Colors.black.withValues(alpha: 0.4),
                        width: c == current ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
