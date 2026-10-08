import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const MineFinderApp());

class MineFinderApp extends StatelessWidget {
  const MineFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.elegantSerif,
      title: 'Mine Finder',
      tagline: 'Flag the mines and clear the field without a boom',
      emoji: '💣',
      slug: 'minefinder',
      howToPlay:
          '• Tap a tile to reveal it. Long-press to plant a flag 🚩.\n• Numbers tell you exactly how many mines are touching that tile.\n• Your first tap is ALWAYS safe. Pinky promise. 🤞\n• Clear the whole field fast to set best times on all 3 difficulties!',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) =>
          MineFinderScreen(players: players, callbacks: cb),
    );
  }
}
