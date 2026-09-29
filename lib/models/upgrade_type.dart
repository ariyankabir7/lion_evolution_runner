import '../core/constants/asset_paths.dart';

enum UpgradeType {
  speed(title: 'Speed', icon: AssetPaths.upgradeSpeed, baseCost: 300),
  food(title: 'Food', icon: AssetPaths.upgradeFood, baseCost: 400),
  shield(title: 'Shield', icon: AssetPaths.upgradeShield, baseCost: 500);

  const UpgradeType({required this.title, required this.icon, required this.baseCost});

  final String title;
  final String icon;
  final int baseCost;

  static const maxLevel = 10;
}
