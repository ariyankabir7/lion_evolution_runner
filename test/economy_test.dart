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

  test('meat HP', () {
    expect(Economy.meatHp(0), 20);
    expect(Economy.meatHp(10), 30);
  });

  test('shield: +1 hit at Lv 1/3/5/7/10, longer guard on the levels between', () {
    expect(List.generate(11, Economy.shieldCharges), [0, 1, 1, 2, 2, 3, 3, 4, 4, 4, 5]);
    expect(Economy.shieldGraceSeconds(0), 0);
    expect(Economy.shieldGraceSeconds(1), closeTo(0.5, 1e-9));
    expect(Economy.shieldGraceSeconds(10), closeTo(1.5, 1e-9));
    for (var l = 1; l <= UpgradeType.maxLevel; l++) {
      final moreHits = Economy.shieldCharges(l) > Economy.shieldCharges(l - 1);
      final longerGuard = Economy.shieldGraceSeconds(l) > Economy.shieldGraceSeconds(l - 1) + 1e-9;
      expect(moreHits || longerGuard, isTrue, reason: 'Lv $l must improve something');
      expect(Economy.describeNext(UpgradeType.shield, l - 1), isNotEmpty);
    }
    expect(Economy.shieldBlocksBroccoli(9), isFalse);
    expect(Economy.shieldBlocksBroccoli(10), isTrue);
  });

  test('level bonus and replay factor', () {
    expect(Economy.levelBonus(3, replay: false), 40);
    expect(Economy.levelBonus(3, replay: true), 10);
    expect(Economy.levelBonus(1, replay: false, bossLevel: true), 40);
  });
}
