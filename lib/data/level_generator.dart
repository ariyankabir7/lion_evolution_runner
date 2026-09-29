import 'dart:math' as math;

import '../models/item_type.dart';
import '../models/level_config.dart';
import 'level_simulator.dart';

/// Builds any level 1..1000 from its number alone. The same number always gives the same level.
///
/// Difficulty = a slow global rise over the first 300 levels + a sawtooth inside each block of 10
/// (the 10th is a boss level, the next one eases off).
///
/// A level is a run of 3-5 themed sections (coin rush, gauntlet, feast, slalom, mixed) split by short
/// breathers, so a 45-60s run keeps changing pace instead of repeating one pattern mix.
class LevelGenerator {
  const LevelGenerator();

  /// 0..1 difficulty for [level].
  static double difficulty(int level) {
    final global = _global(level);
    final step = (level - 1) % 10; // 0..9 inside a block
    final saw = step == 9 ? 0.25 : (step == 0 && level > 1 ? -0.1 : step * 0.015);
    return (0.12 + global * 0.75 + saw).clamp(0.0, 1.0);
  }

  /// 0..1 over the first 300 levels, then flat.
  static double _global(int level) => math.min(level - 1, 300) / 300;

  /// Target running time in seconds: ~47s around levels 21-100, ~55s by 101-300, ~58s after.
  /// Rises a little inside each block of 10; boss levels run 6s longer.
  static double runSeconds(int level) {
    final step = (level - 1) % 10;
    return 37 + 19 * math.sqrt(_global(level)) + step * 0.5 + (level % 10 == 0 ? 6 : 0);
  }

  /// Levels whose best possible HP is below this are regenerated with another seed.
  static const minBestHp = 55;

  LevelConfig generate(int level) {
    for (var attempt = 0;; attempt++) {
      final c = _build(level, attempt);
      final best = LevelSimulator.bestFinalHp(c);
      if (best >= minBestHp || attempt >= 8) return c.withBossPower(bossPowerFor(level, best));
    }
  }

  /// Boss power sits between 40 and the best reachable HP. Easy levels leave lots of slack;
  /// hard ones need a nearly clean run. Rounded down to a multiple of 5 so it reads nicely.
  static int bossPowerFor(int level, int bestHp) {
    final d = difficulty(level);
    final share = (0.31 + 0.55 * d + (level % 10 == 0 ? 0.1 : 0)).clamp(0.0, 0.9);
    final raw = 40 + (bestHp - 40) * share;
    final rounded = (raw / 5).floor() * 5;
    return rounded.clamp(math.min(40, bestHp), bestHp);
  }

  LevelConfig _build(int level, int attempt) {
    final rnd = math.Random(level * 7919 + 17 + attempt * 104729);
    final d = difficulty(level);
    final isBoss = level % 10 == 0;

    final speed = 12.0 + 6.0 * d;
    final length = (speed * runSeconds(level)).roundToDouble();
    // Distance the lion needs to change lanes safely at this speed, plus a margin for human reaction.
    final minRowGap = speed * 0.45;

    final spawns = <SpawnEntry>[];
    var z = 26.0;
    // Rule: meat always comes before the first hazard.
    spawns.add(SpawnEntry(z, rnd.nextInt(2), ItemType.meat));
    z += minRowGap * 1.6;

    ItemType obstacle() {
      final pool = level < 25 ? const [ItemType.spikes, ItemType.log] : ItemType.obstacles;
      return pool[rnd.nextInt(pool.length)];
    }

    void coinLine(int lane, int n) {
      for (var i = 0; i < n; i++) {
        spawns.add(SpawnEntry(z + i * 2.6, lane, ItemType.coin));
      }
      z += (n - 1) * 2.6;
    }

    /// Emits one pattern starting at [z] and advances [z] to its last row.
    void pattern(_Pattern p) {
      final lane = rnd.nextInt(2);
      final other = 1 - lane;
      switch (p) {
        case _Pattern.coins:
          coinLine(lane, 3 + rnd.nextInt(3));
        case _Pattern.coinSnake:
          // Coins weaving from lane to lane: follow them for a full haul.
          var l = lane;
          for (var i = 0; i < 3; i++) {
            coinLine(l, 2);
            l = 1 - l;
            if (i < 2) z += minRowGap * 1.1;
          }
        case _Pattern.choice:
          // Meat on one side, something bad on the other.
          spawns
            ..add(SpawnEntry(z, lane, ItemType.meat))
            ..add(SpawnEntry(z, other, rnd.nextDouble() < 0.5 + d * 0.3 ? obstacle() : ItemType.broccoli));
        case _Pattern.single:
          final r = rnd.nextDouble();
          final type = r < 0.45 - d * 0.15 ? ItemType.meat : (r < 0.7 ? ItemType.broccoli : obstacle());
          spawns.add(SpawnEntry(z, lane, type));
        case _Pattern.zigzag:
          // Obstacles alternating lanes, forcing a lane change each row.
          final rows = 2 + (d * 3).floor() + rnd.nextInt(2);
          var l = lane;
          for (var i = 0; i < rows; i++) {
            spawns.add(SpawnEntry(z, l, obstacle()));
            if (i.isOdd && rnd.nextDouble() < 0.5) spawns.add(SpawnEntry(z, 1 - l, ItemType.coin));
            l = 1 - l;
            if (i < rows - 1) z += minRowGap * (1.3 - d * 0.3);
          }
        case _Pattern.trap:
          // Meat right behind an obstacle: dodge late, then switch back.
          spawns
            ..add(SpawnEntry(z, lane, obstacle()))
            ..add(SpawnEntry(z + minRowGap * 1.2, lane, ItemType.meat))
            ..add(SpawnEntry(z, other, ItemType.coin));
          z += minRowGap * 1.2;
        case _Pattern.wall:
          // A lane blocked for several rows, coins in the safe lane: hold your nerve.
          final rows = 3 + rnd.nextInt(2);
          for (var i = 0; i < rows; i++) {
            spawns.add(SpawnEntry(z, lane, obstacle()));
            if (i.isEven) spawns.add(SpawnEntry(z, other, ItemType.coin));
            if (i < rows - 1) z += minRowGap * 0.8;
          }
          z += minRowGap * 1.1;
          spawns.add(SpawnEntry(z, lane, ItemType.meat)); // reward for the lane you avoided
        case _Pattern.feast:
          // A string of meat, the first one guarded by broccoli or an obstacle in the other lane.
          final n = 2 + rnd.nextInt(2);
          spawns.add(SpawnEntry(z, other, rnd.nextDouble() < 0.3 + 0.5 * d ? obstacle() : ItemType.broccoli));
          for (var i = 0; i < n; i++) {
            spawns.add(SpawnEntry(z, lane, ItemType.meat));
            if (i < n - 1) z += minRowGap * 0.9;
          }
        case _Pattern.slalom:
          // Broccoli (and, on harder levels, obstacles) alternating lanes, meat at the end.
          var l = lane;
          final rows = 3 + rnd.nextInt(2);
          for (var i = 0; i < rows; i++) {
            spawns.add(SpawnEntry(z, l, rnd.nextDouble() < 0.25 + 0.5 * d ? obstacle() : ItemType.broccoli));
            l = 1 - l;
            z += minRowGap * 1.15;
          }
          spawns.add(SpawnEntry(z, 1 - l, ItemType.meat));
        case _Pattern.lure:
          // A coin line leading straight into an obstacle; meat waits in the other lane.
          coinLine(lane, 3);
          z += 2.6;
          spawns.add(SpawnEntry(z, lane, obstacle()));
          z += minRowGap * 1.1;
          spawns.add(SpawnEntry(z, other, ItemType.meat));
      }
    }

    // Split the run into themed sections with a breather (coins, maybe a snack) between them.
    final endZ = length - 18;
    final sections = 3 + (length > 700 ? 1 : 0) + (length > 950 ? 1 : 0);
    final sectionLength = (endZ - z) / sections;
    _Theme? previous;
    for (var s = 0; s < sections; s++) {
      final themes = _Theme.values.where((t) => t != previous && (t != _Theme.gauntlet || level > 3)).toList();
      final theme = themes[rnd.nextInt(themes.length)];
      previous = theme;
      final sectionEnd = math.min(endZ, z + sectionLength);
      while (z < sectionEnd) {
        pattern(theme.pick(rnd, d));
        z += minRowGap * (2.25 - 1.35 * d) * (0.9 + rnd.nextDouble() * 0.3);
      }
      if (s < sections - 1 && z < endZ) {
        coinLine(rnd.nextInt(2), 3);
        if (rnd.nextDouble() < 0.5) {
          z += minRowGap * 1.2;
          spawns.add(SpawnEntry(z, rnd.nextInt(2), ItemType.meat));
        }
        z += minRowGap * 2.2;
      }
    }

    // Multi-row patterns started near the end can overrun it; keep the last stretch before the finish clear.
    spawns
      ..removeWhere((e) => e.z > length - 8)
      ..sort((a, b) => a.z.compareTo(b.z));
    return LevelConfig(
      level: level,
      speed: speed,
      length: length,
      bossPower: 0, // set from the simulation in generate()
      spawns: spawns,
      isBossLevel: isBoss,
    );
  }
}

enum _Pattern { coins, coinSnake, choice, single, zigzag, trap, wall, feast, slalom, lure }

/// A section's flavour: weights over patterns. Harder patterns gain weight with difficulty.
enum _Theme {
  mixed,
  coinRush,
  gauntlet,
  feast,
  slalom;

  _Pattern pick(math.Random rnd, double d) {
    final weights = switch (this) {
      _Theme.mixed => {
          _Pattern.coins: 0.1, _Pattern.choice: 0.2, _Pattern.single: 0.12, _Pattern.zigzag: 0.12 + 0.14 * d,
          _Pattern.trap: 0.12 + 0.1 * d, _Pattern.lure: 0.06 + 0.06 * d, _Pattern.feast: 0.06,
        },
      _Theme.coinRush => {
          _Pattern.coins: 0.15, _Pattern.coinSnake: 0.2, _Pattern.lure: 0.25 + 0.1 * d, _Pattern.choice: 0.2,
          _Pattern.single: 0.1, _Pattern.zigzag: 0.1 * d,
        },
      _Theme.gauntlet => {
          _Pattern.zigzag: 0.25 + 0.1 * d, _Pattern.wall: 0.2, _Pattern.trap: 0.2 + 0.1 * d, _Pattern.choice: 0.15,
          _Pattern.coins: 0.08,
        },
      _Theme.feast => {
          _Pattern.feast: 0.25, _Pattern.choice: 0.3, _Pattern.trap: 0.15 + 0.1 * d, _Pattern.single: 0.15,
          _Pattern.coins: 0.08,
        },
      _Theme.slalom => {
          _Pattern.slalom: 0.3, _Pattern.choice: 0.2, _Pattern.single: 0.15, _Pattern.zigzag: 0.1 + 0.1 * d,
          _Pattern.coins: 0.1,
        },
    };
    final total = weights.values.fold(0.0, (a, b) => a + b);
    var r = rnd.nextDouble() * total;
    for (final e in weights.entries) {
      r -= e.value;
      if (r <= 0) return e.key;
    }
    return weights.keys.last;
  }
}
