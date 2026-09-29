import 'package:flutter/material.dart';

import '../core/constants/asset_paths.dart';
import '../core/constants/economy.dart';
import '../core/services/services.dart';
import '../core/theme/app_colors.dart';
import '../models/upgrade_type.dart';
import 'game_button.dart';
import 'stroked_text.dart';

class UpgradeCard extends StatelessWidget {
  const UpgradeCard({super.key, required this.type});

  final UpgradeType type;

  @override
  Widget build(BuildContext context) {
    final upgrades = services.upgrades;
    return ListenableBuilder(
      listenable: Listenable.merge([upgrades.levels[type]!, services.wallet.coins]),
      builder: (context, _) {
        final level = upgrades.level(type);
        final maxed = upgrades.isMaxed(type);
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outlineSoft, width: 3),
          ),
          child: Row(
            children: [
              Image.asset(AssetPaths.full(type.icon), width: 64, height: 64),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.title.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.outline),
                    ),
                    Text(
                      Economy.describe(type, level),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.outlineSoft),
                    ),
                    const SizedBox(height: 6),
                    _LevelPips(level: level),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GameButton(
                width: 112,
                height: 54,
                skin: ButtonSkin.green,
                onPressed: upgrades.canBuy(type) ? () => upgrades.tryBuy(type) : null,
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
