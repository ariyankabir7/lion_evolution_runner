import 'dart:math' as math;

import '../../models/upgrade_type.dart';
import 'game_constants.dart';

/// Pure economy rules. No state here, so it is trivially testable.
abstract final class Economy {
  static const replayBonusFactor = 0.25;
  static const costGrowth = 1.32;
  static const bossLevelBonusFactor = 2;

  /// Price of buying the next level when the upgrade is currently at [level], rounded to 5.
  /// Tuned against measured income (~40-65 coins per level): first buy after ~4 levels,
  /// everything maxed around level 450.
  static int upgradeCost(UpgradeType type, int level) =>
      ((type.baseCost * math.pow(costGrowth, level)) / 5).round() * 5;

  /// Coins for finishing a level: `10 + 10×stars`, doubled on boss levels, 25% on replays.
  static int levelBonus(int stars, {required bool replay, bool bossLevel = false}) {
    final full = (10 + 10 * stars) * (bossLevel ? bossLevelBonusFactor : 1);
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

  /// "0.22s → 0.21s"-style preview of the next purchase, or just the current value when maxed.
  static String describeNext(UpgradeType type, int level) {
    if (level >= UpgradeType.maxLevel) return describe(type, level);
    if (type == UpgradeType.shield) {
      // Shield charges only step up at Lv 1, 5 and 10, so show the next milestone instead.
      final now = shieldCharges(level);
      final nextLevel = List.generate(UpgradeType.maxLevel, (i) => i + 1).firstWhere((l) => shieldCharges(l) > now);
      final nextHits = shieldCharges(nextLevel);
      final label = '$nextHits hit${nextHits > 1 ? 's' : ''}';
      return now == 0 ? '→ $label' : '$now · $label at Lv $nextLevel';
    }
    return '${_value(type, level)} → ${_value(type, level + 1)}';
  }

  static String _value(UpgradeType type, int level) => switch (type) {
        UpgradeType.speed => '${laneSwitchSeconds(level).toStringAsFixed(2)}s',
        UpgradeType.food => '+${meatHp(level)}',
        UpgradeType.shield => '${shieldCharges(level)}',
      };

  static String describe(UpgradeType type, int level) => switch (type) {
        UpgradeType.speed => '${laneSwitchSeconds(level).toStringAsFixed(2)}s dodge',
        UpgradeType.food => '+${meatHp(level)} HP meat',
        UpgradeType.shield => level == 0 ? 'No shield' : 'Blocks ${shieldCharges(level)} hit${shieldCharges(level) > 1 ? 's' : ''}',
      };
}
