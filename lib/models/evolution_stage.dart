import 'dart:ui';

import '../core/constants/asset_paths.dart';
import '../core/theme/app_colors.dart';

enum EvolutionStage {
  starving(minHp: 0, label: 'Starving', color: AppColors.hpStarving),
  healthy(minHp: 40, label: 'Healthy', color: AppColors.hpHealthy),
  gladiator(minHp: 80, label: 'Gladiator', color: AppColors.hpGladiator);

  const EvolutionStage({required this.minHp, required this.label, required this.color});

  final int minHp;
  final String label;
  final Color color;

  static EvolutionStage fromHp(int hp) {
    if (hp >= gladiator.minHp) return gladiator;
    if (hp >= healthy.minHp) return healthy;
    return starving;
  }

  String get frontSprite => AssetPaths.lionFront(name);
  String get backSprite => AssetPaths.lionBack(name);
  List<String> get runFrames => AssetPaths.lionRun(name);
}
