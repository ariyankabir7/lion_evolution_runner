import 'package:flutter/material.dart';

import '../app.dart';
import '../core/services/services.dart';
import '../data/chapter_catalog.dart';
import '../ui/svg/game_icons.dart';
import '../widgets/game_button.dart';
import '../widgets/stroked_text.dart';
import '../widgets/themed_backdrop.dart';

/// Placeholder: a simple list of the current chapter's unlocked levels. The full chapter-tab grid
/// arrives in Milestone 4.
class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unlocked = services.progress.unlockedLevel.value;
    final chapter = ChapterCatalog.forLevel(unlocked);
    return Scaffold(
      body: ThemedBackdrop(
        chapter: chapter,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    GameButton.round(
                      icon: GameIcon.back,
                      skin: ButtonSkin.orange,
                      size: 56,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: StrokedText('CHAPTER ${chapter.number}: ${chapter.name.toUpperCase()}', size: 22)),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      for (var l = chapter.firstLevel; l <= chapter.lastLevel; l++)
                        GameButton(
                          height: 56,
                          skin: l == unlocked ? ButtonSkin.green : ButtonSkin.blue,
                          onPressed: l <= unlocked
                              ? () => Navigator.of(context).pushReplacementNamed(Routes.game, arguments: l)
                              : null,
                          child: l <= unlocked
                              ? StrokedText('$l', size: 22)
                              : const GameSvgIcon(GameIcon.lock, size: 24),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
