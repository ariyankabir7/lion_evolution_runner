import '../core/constants/asset_paths.dart';
import '../core/constants/game_constants.dart';

enum ItemKind { food, junk, coin, obstacle }

/// Everything that can appear on the track. [width] is the on-road width in world pixels when the
/// item is level with the player (a lane is 300 wide).
enum ItemType {
  meat(ItemKind.food, AssetPaths.meat, width: 150, hpDelta: GameConstants.meatHp),
  broccoli(ItemKind.junk, AssetPaths.broccoli, width: 140, hpDelta: -GameConstants.broccoliDamage),
  coin(ItemKind.coin, AssetPaths.coin, width: 84, hpDelta: 0, floats: true),
  spikes(ItemKind.obstacle, AssetPaths.spikes, width: 260, hpDelta: -GameConstants.obstacleDamage),
  log(ItemKind.obstacle, AssetPaths.log, width: 260, hpDelta: -GameConstants.obstacleDamage),
  rocks(ItemKind.obstacle, AssetPaths.rocks, width: 250, hpDelta: -GameConstants.obstacleDamage),
  thorns(ItemKind.obstacle, AssetPaths.thorns, width: 260, hpDelta: -GameConstants.obstacleDamage);

  const ItemType(this.kind, this.sprite, {required this.width, required this.hpDelta, this.floats = false});

  final ItemKind kind;
  final String sprite;
  final double width;

  /// Base HP change on contact. Meat is further raised by the Food upgrade.
  final int hpDelta;

  /// Hovers above the road with a bob (coins).
  final bool floats;

  bool get isObstacle => kind == ItemKind.obstacle;

  static const obstacles = [spikes, log, rocks, thorns];
}
