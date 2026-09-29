import 'package:flutter_test/flutter_test.dart';
import 'package:lion_evolution_runner/core/constants/economy.dart';
import 'package:lion_evolution_runner/models/upgrade_type.dart';

void main() {
  test('upgrade cost grows by 1.45x per level', () {
    expect(Economy.upgradeCost(UpgradeType.speed, 0), 300);
    expect(Economy.upgradeCost(UpgradeType.speed, 1), 435);
    expect(Economy.upgradeCost(UpgradeType.shield, 0), 500);
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
  });
}
