import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/asset_paths.dart';
import '../../core/constants/game_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/evolution_stage.dart';
import '../../ui/svg/game_icons.dart';
import '../../widgets/game_button.dart';
import '../../widgets/panel.dart';
import '../../widgets/stroked_text.dart';
import '../lion_game.dart';

class ResultOverlay extends StatelessWidget {
  const ResultOverlay({super.key, required this.game});

  final LionGame game;

  @override
  Widget build(BuildContext context) {
    final r = game.result!;
    final nav = Navigator.of(context);
    return ColoredBox(
      color: const Color(0xAA000000),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              builder: (_, s, child) => Transform.scale(scale: s, child: child),
              child: Panel(
                title: r.won ? 'VICTORY!' : 'DEFEATED',
                ribbon: r.won ? AppColors.green : AppColors.red,
                ribbonShade: r.won ? AppColors.greenShade : AppColors.redShade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (r.won) _Stars(stars: r.stars),
                    SizedBox(
                      height: 170,
                      child: Image.asset(
                        AssetPaths.full(_portrait(r.won, r.hp)),
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r.hp <= 0
                          ? 'Your lion ran out of strength!'
                          : 'Your HP ${r.hp}  vs  ${game.chapter.bossName} ${r.bossPower}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.outline),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(AssetPaths.full(AssetPaths.coin), height: 40),
                        const SizedBox(width: 6),
                        StrokedText('+${r.totalCoins}', size: 34, color: AppColors.gold),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (r.won && r.level < GameConstants.totalLevels) ...[
                      GameButton(
                        label: 'NEXT',
                        icon: GameIcon.play,
                        width: double.infinity,
                        onPressed: () => nav.pushReplacementNamed(Routes.game, arguments: r.level + 1),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: GameButton(
                            label: 'RETRY',
                            icon: GameIcon.restart,
                            skin: r.won ? ButtonSkin.blue : ButtonSkin.green,
                            onPressed: () => nav.pushReplacementNamed(Routes.game, arguments: r.level),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GameButton.round(
                          icon: GameIcon.home,
                          skin: ButtonSkin.orange,
                          size: 72,
                          onPressed: () => nav.pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Victory shows the lion at the stage it finished in; only a Gladiator gets the sword-raised pose.
String _portrait(bool won, int hp) {
  if (!won) return AssetPaths.lionDefeated;
  final stage = EvolutionStage.fromHp(hp);
  return stage == EvolutionStage.gladiator ? AssetPaths.lionVictory : stage.frontSprite;
}

class _Stars extends StatelessWidget {
  const _Stars({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 3; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 350 + i * 250),
            curve: Interval(i * 0.25, 1, curve: Curves.elasticOut),
            builder: (_, t, child) => Transform.scale(scale: i < stars ? t : 1, child: child),
            child: Padding(
              padding: EdgeInsets.only(bottom: i == 1 ? 14 : 0),
              child: GameSvgIcon(
                GameIcon.star,
                size: i == 1 ? 64 : 50,
                color: i < stars ? AppColors.gold : AppColors.outline.withValues(alpha: 0.25),
              ),
            ),
          ),
      ],
    );
  }
}
