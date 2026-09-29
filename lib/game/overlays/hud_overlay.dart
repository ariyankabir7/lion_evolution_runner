import 'package:flutter/material.dart';

import '../../core/constants/asset_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../ui/svg/game_icons.dart';
import '../../widgets/game_button.dart';
import '../../widgets/hp_bar.dart';
import '../../widgets/stroked_text.dart';
import '../lion_game.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});

  final LionGame game;

  @override
  Widget build(BuildContext context) {
    final s = game.session;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GameButton.round(icon: GameIcon.pause, skin: ButtonSkin.orange, size: 50, onPressed: game.pause),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      StrokedText('LEVEL ${game.config.level}', size: 22),
                      const SizedBox(height: 4),
                      ValueListenableBuilder<double>(
                        valueListenable: s.progress,
                        builder: (_, p, _) => _ProgressBar(progress: p),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ValueListenableBuilder<int>(
                  valueListenable: s.coins,
                  builder: (_, c, _) => _Pill(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(AssetPaths.full(AssetPaths.coin), height: 30),
                        const SizedBox(width: 4),
                        StrokedText('$c', size: 22, color: AppColors.gold, drop: false),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: s.hp,
                  builder: (_, hp, _) => HpBar(hp: hp, width: 250),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: s.shield,
                  builder: (_, n, _) => n == 0
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(left: 8, top: 20),
                          // One icon plus a count: up to 5 charges would not fit beside the HP bar.
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(AssetPaths.full(AssetPaths.upgradeShield), height: 34),
                              StrokedText('×$n', size: 20, color: AppColors.white, drop: false),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        height: 44,
        padding: const EdgeInsets.only(left: 5, right: 12),
        decoration: BoxDecoration(
          color: AppColors.outline.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.outline, width: 3),
        ),
        child: child,
      );
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.outline.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline, width: 2),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.02, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}
