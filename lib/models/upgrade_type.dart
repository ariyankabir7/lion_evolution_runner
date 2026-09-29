import '../core/constants/asset_paths.dart';

enum UpgradeType {
  speed(title: 'Speed', icon: AssetPaths.upgradeSpeed, baseCost: 150, blurb: 'Dodge faster'),
  food(title: 'Food', icon: AssetPaths.upgradeFood, baseCost: 200, blurb: 'Meat heals more'),
  shield(title: 'Shield', icon: AssetPaths.upgradeShield, baseCost: 250, blurb: 'Blocks obstacle hits');

  const UpgradeType({required this.title, required this.icon, required this.baseCost, required this.blurb});

  final String title;
  final String icon;
  final int baseCost;
  final String blurb;

  static const maxLevel = 10;
}
