import 'package:flutter_test/flutter_test.dart';
import 'package:lion_evolution_runner/data/level_generator.dart';
import 'package:lion_evolution_runner/models/item_type.dart';

void main() {
  const gen = LevelGenerator();

  test('same level number gives the same level', () {
    final a = gen.generate(437), b = gen.generate(437);
    expect(a.spawns.map((e) => e.toString()), b.spawns.map((e) => e.toString()));
    expect(a.length, b.length);
  });

  test('all 1000 levels are well-formed and meat comes before the first hazard', () {
    for (var n = 1; n <= 1000; n++) {
      final c = gen.generate(n);
      expect(c.spawns, isNotEmpty, reason: 'level $n');
      final firstHazard = c.spawns.indexWhere((e) => e.type.isObstacle || e.type == ItemType.broccoli);
      final firstMeat = c.spawns.indexWhere((e) => e.type == ItemType.meat);
      expect(firstMeat, lessThan(firstHazard), reason: 'level $n');
      for (var i = 0; i < c.spawns.length; i++) {
        final e = c.spawns[i];
        expect(e.lane, inInclusiveRange(0, 1));
        expect(e.z, lessThan(c.length));
        if (i > 0) expect(e.z, greaterThanOrEqualTo(c.spawns[i - 1].z));
      }
      expect(c.bossPower, inInclusiveRange(40, 100));
    }
  });
}
