import 'item_type.dart';

/// One item on the track. [z] is the distance from the start line in world units; [lane] is 0 (left) or 1 (right).
class SpawnEntry {
  const SpawnEntry(this.z, this.lane, this.type);

  final double z;
  final int lane;
  final ItemType type;

  @override
  String toString() => 'SpawnEntry($z, $lane, ${type.name})';
}

class LevelConfig {
  const LevelConfig({
    required this.level,
    required this.speed,
    required this.length,
    required this.bossPower,
    required this.spawns,
    this.isBossLevel = false,
    this.name,
  });

  final int level;

  /// World units per second.
  final double speed;

  /// Distance from the start to the finish line.
  final double length;

  /// The lion wins the fight when HP >= bossPower.
  final int bossPower;

  /// Sorted by [SpawnEntry.z].
  final List<SpawnEntry> spawns;

  /// Every 10th level: harder, bigger reward.
  final bool isBossLevel;

  /// Only hand-tuned levels have names.
  final String? name;

  LevelConfig withBossPower(int power) => LevelConfig(
        level: level,
        speed: speed,
        length: length,
        bossPower: power,
        spawns: spawns,
        isBossLevel: isBossLevel,
        name: name,
      );
}
