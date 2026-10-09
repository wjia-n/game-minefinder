import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/minefinder_themes.dart';
import '../theme/miner_ui.dart';

/// Settings: audio toggles + volume, stats.
class SettingsScreen extends StatelessWidget {
  final MineAudio audio;
  final MineSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  MineThemeDef get _t => MineThemes.byId(
        settings.themeId,
        custom: settings.customTheme,
      );

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
            onPressed: () {
              audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Settings', style: Miner.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: settings,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                children: [
                  WoodCard(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sound', style: Miner.display(19, theme: t)),
                        const SizedBox(height: 12),
                        _toggle(
                          label: '🎵 Music',
                          value: settings.musicOn,
                          onChanged: (v) {
                            settings.setMusic(v);
                            audio.configure(
                              musicOn: v,
                              sfxOn: settings.sfxOn,
                              volume: settings.volume,
                            );
                            if (v) {
                              audio.click();
                              audio.startMenuMusic();
                            }
                          },
                        ),
                        _toggle(
                          label: '🔔 Sound effects',
                          value: settings.sfxOn,
                          onChanged: (v) {
                            settings.setSfx(v);
                            audio.configure(
                              musicOn: settings.musicOn,
                              sfxOn: v,
                              volume: settings.volume,
                            );
                            if (v) audio.click();
                          },
                        ),
                        const SizedBox(height: 8),
                        Text('🔊 Volume',
                            style: Miner.label(14, theme: t)),
                        Slider(
                          value: settings.volume,
                          activeColor: t.accent,
                          inactiveColor:
                              t.accent.withValues(alpha: 0.25),
                          onChanged: (v) {
                            settings.setVolume(v);
                            audio.configure(
                              musicOn: settings.musicOn,
                              sfxOn: settings.sfxOn,
                              volume: v,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  WoodCard(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your record', style: Miner.display(19, theme: t)),
                        const SizedBox(height: 10),
                        _stat('Games dug', '${settings.gamesPlayed}'),
                        _stat('Fields cleared', '${settings.wins}'),
                        _stat('Daily challenges cleared',
                            '${settings.dailyDone.length}'),
                        for (var i = 0;
                            i < mineDifficultiesShort.length;
                            i++) ...[
                          _stat(
                            'Best · ${mineDifficultiesShort[i]}',
                            settings.bestTimes[i] == null
                                ? '—'
                                : _fmt(settings.bestTimes[i]!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const mineDifficultiesShort = [
    'Cozy Dig',
    'Deep Dig',
    'Gold Rush',
    'Abyss'
  ];

  String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  Widget _toggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final t = _t;
    return Row(
      children: [
        Expanded(child: Text(label, style: Miner.body(16, theme: t))),
        Switch(
          value: value,
          activeThumbColor: t.accentLight,
          activeTrackColor: t.accentDark,
          onChanged: (v) {
            audio.click();
            onChanged(v);
          },
        ),
      ],
    );
  }

  Widget _stat(String label, String value) {
    final t = _t;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Miner.body(14, theme: t))),
          Text(value, style: Miner.label(14, theme: t)),
        ],
      ),
    );
  }
}
