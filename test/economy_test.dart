import 'package:flutter_test/flutter_test.dart';
import 'package:lion_evolution_runner/core/constants/economy.dart';
import 'package:lion_evolution_runner/models/upgrade_type.dart';

void main() {
  test('upgrade cost grows by 1.32x per level, rounded to 5', () {
    expect(Economy.upgradeCost(UpgradeType.speed, 0), 150);
    expect(Economy.upgradeCost(UpgradeType.speed, 1), 200);
    expect(Economy.upgradeCost(UpgradeType.shield, 0), 250);
    for (final t in UpgradeType.values) {
      for (var l = 0; l < 10; l++) {
        expect(Economy.upgradeCost(t, l) % 5, 0);
        if (l > 0) expect(Economy.upgradeCost(t, l), greaterThan(Economy.upgradeCost(t, l - 1)));
      }
    }
  });

  test('maxing everything costs about 450 levels of income', () {
    var total = 0;
    for (final t in UpgradeType.values) {
      for (var l = 0; l < 10; l++) {
        total += Economy.upgradeCost(t, l);
      }
    }
    expect(total, inInclusiveRange(25000, 32000));
  });

  test('lane switch goes from 0.22s to 0.12s', () {
    expect(Economy.laneSwitchSeconds(0), closeTo(0.22, 1e-9));
    expect(Economy.laneSwitchSeconds(10), closeTo(0.12, 1e-9));
  });

  test('meat HP and shield charges', () {
    expect(Economy.meatHp(0), 20);
    expect(Economy.meatHp(10), 30);
    expect([0, 1, 4, 5, 9, 10].map(Economy.shieldCharges), [0, 1, 1, 2, 2, 3]);
  });

  test('level bonus and replay factor', () {
    expect(Economy.levelBonus(3, replay: false), 40);
    expect(Economy.levelBonus(3, replay: true), 10);
    expect(Economy.levelBonus(1, replay: false, bossLevel: true), 40);
  });
}
