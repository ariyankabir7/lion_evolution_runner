import 'dart:math' as math;

import '../../models/upgrade_type.dart';
import 'game_constants.dart';

/// Pure economy rules. No state here, so it is trivially testable.
abstract final class Economy {
  static const replayBonusFactor = 0.25;

  /// Price of buying the next level when the upgrade is currently at [level].
  static int upgradeCost(UpgradeType type, int level) =>
      (type.baseCost * math.pow(1.45, level)).round();

  static int levelBonus(int stars, {required bool replay}) {
    final full = 10 + 10 * stars;
    return replay ? (full * replayBonusFactor).round() : full;
  }

  /// Lane switch time in seconds: 0.22s at Lv 0 down to 0.12s at Lv 10.
  static double laneSwitchSeconds(int speedLevel) =>
      GameConstants.baseLaneSwitchSeconds - 0.01 * speedLevel.clamp(0, UpgradeType.maxLevel);

  static int meatHp(int foodLevel) =>
      GameConstants.meatHp + foodLevel.clamp(0, UpgradeType.maxLevel);

  static int shieldCharges(int shieldLevel) {
    if (shieldLevel <= 0) return 0;
    if (shieldLevel < 5) return 1;
    if (shieldLevel < 10) return 2;
    return 3;
  }

  static String describe(UpgradeType type, int level) => switch (type) {
        UpgradeType.speed => '${laneSwitchSeconds(level).toStringAsFixed(2)}s dodge',
        UpgradeType.food => '+${meatHp(level)} HP meat',
        UpgradeType.shield => level == 0 ? 'No shield' : 'Blocks ${shieldCharges(level)} hit${shieldCharges(level) > 1 ? 's' : ''}',
      };
}
