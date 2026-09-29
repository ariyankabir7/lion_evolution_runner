import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/asset_paths.dart';
import '../core/constants/economy.dart';
import '../core/services/services.dart';
import '../core/theme/app_colors.dart';
import '../models/upgrade_type.dart';
import 'game_button.dart';
import 'stroked_text.dart';

class UpgradeCard extends StatefulWidget {
  const UpgradeCard({super.key, required this.type});

  final UpgradeType type;

  @override
  State<UpgradeCard> createState() => _UpgradeCardState();
}

class _UpgradeCardState extends State<UpgradeCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 550));

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _buy() {
    if (!services.upgrades.tryBuy(widget.type)) return;
    if (services.settings.haptics.value) HapticFeedback.mediumImpact();
    _pop.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    final upgrades = services.upgrades;
    return ListenableBuilder(
      listenable: Listenable.merge([upgrades.levels[type]!, services.wallet.coins]),
      builder: (context, _) {
        final level = upgrades.level(type);
        final maxed = upgrades.isMaxed(type);
        final affordable = upgrades.canBuy(type);
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: affordable ? 0.75 : 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: affordable ? AppColors.green : AppColors.outlineSoft, width: 3),
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pop,
                builder: (context, child) {
                  final t = _pop.value;
                  final scale = 1 + 0.35 * Curves.easeOut.transform(t < 0.4 ? t / 0.4 : (1 - t) / 0.6);
                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Transform.scale(scale: scale, child: child),
                      if (_pop.isAnimating)
                        Opacity(
                          opacity: (1 - t).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.6 + t * 1.2,
                            child: Image.asset(AssetPaths.full(AssetPaths.sparkle), width: 80),
                          ),
                        ),
                    ],
                  );
                },
                child: Image.asset(AssetPaths.full(type.icon), width: 64, height: 64),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(type.title.toUpperCase(), style: const TextStyle(fontSize: 20, color: AppColors.outline)),
                        const Spacer(),
                        Text(
                          maxed ? 'MAX' : 'Lv $level/${UpgradeType.maxLevel}',
                          style: const TextStyle(fontSize: 14, color: AppColors.outlineSoft),
                        ),
                      ],
                    ),
                    Text(type.blurb, style: const TextStyle(fontSize: 13, color: AppColors.outlineSoft)),
                    Text(
                      Economy.describeNext(type, level),
                      style: const TextStyle(fontSize: 15, color: AppColors.greenShade),
                    ),
                    const SizedBox(height: 4),
                    _LevelPips(level: level),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GameButton(
                width: 104,
                height: 54,
                skin: ButtonSkin.green,
                onPressed: affordable ? _buy : null,
                child: maxed
                    ? const StrokedText('MAX', size: 22)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(AssetPaths.full(AssetPaths.coin), height: 24),
                          const SizedBox(width: 4),
                          StrokedText('${upgrades.nextCost(type)}', size: 20),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LevelPips extends StatelessWidget {
  const _LevelPips({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < UpgradeType.maxLevel; i++)
          Expanded(
            child: Container(
              height: 9,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: i < level ? AppColors.orange : AppColors.outline.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
      ],
    );
  }
}
