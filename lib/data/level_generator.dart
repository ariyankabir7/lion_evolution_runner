import 'dart:math' as math;

import '../models/item_type.dart';
import '../models/level_config.dart';
import 'level_simulator.dart';

/// Builds any level 1..1000 from its number alone. The same number always gives the same level.
///
/// Difficulty = a slow global rise over the first 300 levels + a sawtooth inside each block of 10
/// (the 10th is a boss level, the next one eases off).
class LevelGenerator {
  const LevelGenerator();

  /// 0..1 difficulty for [level].
  static double difficulty(int level) {
    final global = math.min(level - 1, 300) / 300; // 0..1 over the first 300 levels
    final step = (level - 1) % 10; // 0..9 inside a block
    final saw = step == 9 ? 0.25 : (step == 0 && level > 1 ? -0.1 : step * 0.015);
    return (0.1 + global * 0.7 + saw).clamp(0.0, 1.0);
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
    final share = (0.3 + 0.55 * d + (level % 10 == 0 ? 0.1 : 0)).clamp(0.0, 0.9);
    final raw = 40 + (bestHp - 40) * share;
    final rounded = (raw / 5).floor() * 5;
    return rounded.clamp(math.min(40, bestHp), bestHp);
  }

  LevelConfig _build(int level, int attempt) {
    final rnd = math.Random(level * 7919 + 17 + attempt * 104729);
    final d = difficulty(level);
    final isBoss = level % 10 == 0;

    final speed = 12.0 + 6.0 * d;
    final seconds = 25.0 + 25.0 * d + (isBoss ? 6 : 0);
    final length = (speed * seconds).roundToDouble();
    // Distance the lion needs to change lanes safely at this speed, plus a margin for human reaction.
    final minRowGap = speed * 0.45;

    final spawns = <SpawnEntry>[];
    var z = 26.0;
    // Rule: meat always comes before the first hazard.
    spawns.add(SpawnEntry(z, rnd.nextInt(2), ItemType.meat));
    z += minRowGap * 1.6;

    ItemType obstacle() {
      final pool = level < 5 ? const [ItemType.spikes] : ItemType.obstacles;
      return pool[rnd.nextInt(pool.length)];
    }

    final endZ = length - 18;
    while (z < endZ) {
      final roll = rnd.nextDouble();
      final lane = rnd.nextInt(2);
      final other = 1 - lane;
      if (roll < 0.22) {
        // Coin line.
        final n = 4 + rnd.nextInt(3);
        for (var i = 0; i < n; i++) {
          spawns.add(SpawnEntry(z + i * 2.6, lane, ItemType.coin));
        }
        z += (n - 1) * 2.6;
      } else if (roll < 0.42) {
        // Choice row: meat on one side, something bad on the other.
        spawns
          ..add(SpawnEntry(z, lane, ItemType.meat))
          ..add(SpawnEntry(z, other, rnd.nextDouble() < 0.5 + d * 0.3 ? obstacle() : ItemType.broccoli));
      } else if (roll < 0.58) {
        // Single item.
        final r = rnd.nextDouble();
        final type = r < 0.45 - d * 0.15
            ? ItemType.meat
            : r < 0.7
                ? ItemType.broccoli
                : obstacle();
        spawns.add(SpawnEntry(z, lane, type));
      } else if (roll < 0.58 + 0.2 * (0.4 + d)) {
        // Zig-zag of obstacles, forcing a lane change each row.
        final rows = 2 + (d * 3).floor() + rnd.nextInt(2);
        var l = lane;
        for (var i = 0; i < rows; i++) {
          spawns.add(SpawnEntry(z, l, obstacle()));
          if (i.isOdd && rnd.nextDouble() < 0.5) spawns.add(SpawnEntry(z, 1 - l, ItemType.coin));
          l = 1 - l;
          if (i < rows - 1) z += minRowGap * (1.3 - d * 0.3);
        }
      } else {
        // Trap: meat right behind an obstacle, so the player must dodge late then switch back.
        spawns
          ..add(SpawnEntry(z, lane, obstacle()))
          ..add(SpawnEntry(z + minRowGap * 1.2, lane, ItemType.meat))
          ..add(SpawnEntry(z, other, ItemType.coin));
        z += minRowGap * 1.2;
      }
      z += minRowGap * (2.4 - 1.1 * d) * (0.9 + rnd.nextDouble() * 0.35);
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
