import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lion_evolution_runner/data/handcrafted_levels.dart';
import 'package:lion_evolution_runner/data/level_generator.dart';
import 'package:lion_evolution_runner/data/level_simulator.dart';
import 'package:lion_evolution_runner/models/item_type.dart';
import 'package:lion_evolution_runner/models/level_config.dart';

void main() {
  const gen = LevelGenerator();
  final handcrafted = HandcraftedLevels.parse(File(HandcraftedLevels.assetPath).readAsStringSync());
  LevelConfig load(int n) => handcrafted[n] ?? gen.generate(n);

  void expectWellFormed(LevelConfig c) {
    final n = c.level;
    expect(c.spawns, isNotEmpty, reason: 'level $n');
    final firstHazard = c.spawns.indexWhere((e) => e.type.isObstacle || e.type == ItemType.broccoli);
    final firstMeat = c.spawns.indexWhere((e) => e.type == ItemType.meat);
    expect(firstMeat, isNonNegative, reason: 'level $n has no meat');
    if (firstHazard >= 0) expect(firstMeat, lessThan(firstHazard), reason: 'level $n: meat must come first');
    for (var i = 0; i < c.spawns.length; i++) {
      final e = c.spawns[i];
      expect(e.lane, inInclusiveRange(0, 1));
      expect(e.z, lessThan(c.length));
      if (i > 0) expect(e.z, greaterThanOrEqualTo(c.spawns[i - 1].z));
    }
  }

  test('same level number gives the same level', () {
    final a = gen.generate(437), b = gen.generate(437);
    expect(a.spawns.map((e) => e.toString()), b.spawns.map((e) => e.toString()));
    expect(a.bossPower, b.bossPower);
  });

  test('levels 1-20 are hand-tuned', () {
    expect(handcrafted.keys.toList()..sort(), List.generate(20, (i) => i + 1));
  });

  test('hand-tuned levels leave room for mistakes', () {
    for (final c in handcrafted.values) {
      final best = LevelSimulator.bestFinalHp(c);
      expect(best - c.bossPower, greaterThanOrEqualTo(15), reason: 'level ${c.level}: best $best, boss ${c.bossPower}');
    }
  });

  test('runs are long enough: 1-20 average 30s+, 21-100 45s+, 101-300 50s+, later 55s+', () {
    double avg(int from, int to) {
      var sum = 0.0;
      for (var n = from; n <= to; n++) {
        final c = load(n);
        sum += c.length / c.speed;
      }
      return sum / (to - from + 1);
    }

    expect(avg(1, 20), greaterThan(30));
    expect(avg(21, 100), greaterThan(45));
    expect(avg(101, 300), greaterThan(50));
    expect(avg(301, 1000), greaterThan(55));
  });

  test('all 1000 levels are well-formed and winnable with a perfect run', () {
    for (var n = 1; n <= 1000; n++) {
      final c = load(n);
      expectWellFormed(c);
      final best = LevelSimulator.bestFinalHp(c);
      expect(best, greaterThanOrEqualTo(c.bossPower), reason: 'level $n: best $best < boss ${c.bossPower}');
      expect(c.bossPower, inInclusiveRange(40, 100), reason: 'level $n');
    }
  });
}
