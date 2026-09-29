import 'dart:math' as math;

import '../core/constants/game_constants.dart';
import '../models/item_type.dart';
import '../models/level_config.dart';

/// Finds the best HP a perfect player can finish a level with, assuming no upgrades.
///
/// Items at (almost) the same depth form a row. Between rows the lion may change lane only if the
/// gap leaves time for the lane switch plus a human reaction. For each row and lane we keep the best
/// HP so far. That's exact, because HP rules are monotone (more HP never hurts later).
abstract final class LevelSimulator {
  /// Seconds needed to change lanes between two rows: base switch time + reaction margin.
  static const switchSeconds = GameConstants.baseLaneSwitchSeconds + 0.12;

  /// Items closer than this (world units) count as the same row.
  static const rowEpsilon = 0.5;

  static int bestFinalHp(LevelConfig c) => bestFinalHpFor(c.spawns, c.speed);

  static int bestFinalHpFor(List<SpawnEntry> spawns, double speed) {
    final rows = _rows(spawns);
    final minGap = speed * switchSeconds;
    const dead = -1;

    // best[lane] = best HP arriving at the current row in that lane; the run starts free to pick a lane.
    var best = [GameConstants.startHp, GameConstants.startHp];
    double? prevZ;
    for (final row in rows) {
      final canSwitch = prevZ == null || row.z - prevZ >= minGap;
      final arrive = [
        math.max(best[0], canSwitch ? best[1] : dead),
        math.max(best[1], canSwitch ? best[0] : dead),
      ];
      best = [
        for (var lane = 0; lane < 2; lane++)
          arrive[lane] <= 0 ? dead : _apply(arrive[lane], row.deltas[lane]),
      ];
      prevZ = row.z;
    }
    return math.max(best[0], best[1]);
  }

  static int _apply(int hp, int delta) {
    final v = (hp + delta).clamp(0, GameConstants.maxHp);
    return v <= 0 ? -1 : v;
  }

  static List<_Row> _rows(List<SpawnEntry> spawns) {
    final rows = <_Row>[];
    for (final e in spawns) {
      if (e.type.kind == ItemKind.coin) continue; // coins never block or change HP
      if (rows.isEmpty || e.z - rows.last.z > rowEpsilon) rows.add(_Row(e.z));
      rows.last.deltas[e.lane] += e.type.hpDelta;
    }
    return rows;
  }
}

class _Row {
  _Row(this.z);
  final double z;
  final List<int> deltas = [0, 0];
}
