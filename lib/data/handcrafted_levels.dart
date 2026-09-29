import 'dart:convert';

import '../models/item_type.dart';
import '../models/level_config.dart';
import 'level_generator.dart';
import 'level_simulator.dart';

/// Parses `assets/levels/handcrafted.json` (see its `_format` note for the row syntax).
abstract final class HandcraftedLevels {
  static const assetPath = 'assets/levels/handcrafted.json';

  static const _startZ = 26.0;
  static const _coinSpacing = 2.6;
  static const _coinLine = 5;
  static const _runOut = 30.0; // clear road between the last row and the finish gate

  static const _codes = {
    'M': ItemType.meat,
    'B': ItemType.broccoli,
    'S': ItemType.spikes,
    'L': ItemType.log,
    'R': ItemType.rocks,
    'T': ItemType.thorns,
    'C': ItemType.coin,
  };

  static Map<int, LevelConfig> parse(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final out = <int, LevelConfig>{};
    for (final raw in data['levels'] as List<dynamic>) {
      final c = _level(raw as Map<String, dynamic>);
      out[c.level] = c;
    }
    return out;
  }

  static LevelConfig _level(Map<String, dynamic> j) {
    final level = j['level'] as int;
    final speed = (j['speed'] as num).toDouble();
    final gap = (j['gap'] as num).toDouble();
    final spawns = <SpawnEntry>[];
    var z = _startZ;
    for (final row in (j['rows'] as List<dynamic>).cast<String>()) {
      if (row == 'c0' || row == 'c1') {
        final lane = row == 'c0' ? 0 : 1;
        for (var i = 0; i < _coinLine; i++) {
          spawns.add(SpawnEntry(z + i * _coinSpacing, lane, ItemType.coin));
        }
        z += (_coinLine - 1) * _coinSpacing;
      } else if (row != '-') {
        if (row.length != 2) throw FormatException('Level $level: bad row "$row"');
        for (var lane = 0; lane < 2; lane++) {
          final ch = row[lane];
          if (ch == '.') continue;
          final type = _codes[ch] ?? (throw FormatException('Level $level: unknown item "$ch"'));
          spawns.add(SpawnEntry(z, lane, type));
        }
      }
      z += gap;
    }
    final base = LevelConfig(
      level: level,
      speed: speed,
      length: z + _runOut,
      bossPower: 0,
      spawns: spawns,
      isBossLevel: level % 10 == 0,
      name: j['name'] as String?,
    );
    final boss = j['boss'] as int? ??
        LevelGenerator.bossPowerFor(level, LevelSimulator.bestFinalHp(base));
    return base.withBossPower(boss);
  }
}
