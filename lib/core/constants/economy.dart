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

  /// Shield levels that add one blocked hit each (Lv 10 blocks 5). The levels in between make the
  /// invincibility after a block last longer, so every purchase improves something.
  static const shieldHitLevels = [1, 3, 5, 7, 10];

  static int shieldCharges(int shieldLevel) => shieldHitLevels.where((l) => l <= shieldLevel).length;

  /// Seconds of invincibility after the shield blocks a hit: 0.5s, +0.2s for each in-between level
  /// owned (Lv 2, 4, 6, 8, 9), up to 1.5s.
  static double shieldGraceSeconds(int shieldLevel) {
    if (shieldLevel <= 0) return 0;
    final between = List.generate(shieldLevel.clamp(0, UpgradeType.maxLevel), (i) => i + 1)
        .where((l) => !shieldHitLevels.contains(l))
        .length;
    return 0.5 + 0.2 * between;
  }

  /// Capstone: at max level broccoli also bounces off while the shield holds.
  static bool shieldBlocksBroccoli(int shieldLevel) => shieldLevel >= UpgradeType.maxLevel;

  /// "0.22s → 0.21s"-style preview of the next purchase, or just the current value when maxed.
  static String describeNext(UpgradeType type, int level) {
    if (level >= UpgradeType.maxLevel) return describe(type, level);
    if (type == UpgradeType.shield) {
      // Each level adds either a hit or longer invincibility after a block; say which.
      final now = shieldCharges(level), next = shieldCharges(level + 1);
      if (level == 0) return '→ blocks 1 hit';
      if (shieldBlocksBroccoli(level + 1)) return '$now → $next hits + broccoli-proof';
      if (next > now) return '$now → $next hits';
      return 'Guard ${_grace(level)} → ${_grace(level + 1)}';
    }
    return '${_value(type, level)} → ${_value(type, level + 1)}';
  }

  static String _grace(int level) => '${shieldGraceSeconds(level).toStringAsFixed(1)}s';

  static String _value(UpgradeType type, int level) => switch (type) {
        UpgradeType.speed => '${laneSwitchSeconds(level).toStringAsFixed(2)}s',
        UpgradeType.food => '+${meatHp(level)}',
        UpgradeType.shield => '${shieldCharges(level)}',
      };

  static String describe(UpgradeType type, int level) => switch (type) {
        UpgradeType.speed => '${laneSwitchSeconds(level).toStringAsFixed(2)}s dodge',
        UpgradeType.food => '+${meatHp(level)} HP meat',
        UpgradeType.shield => level == 0
            ? 'No shield'
            : '${shieldCharges(level)} hit${shieldCharges(level) > 1 ? 's' : ''} · ${_grace(level)} guard'
                '${shieldBlocksBroccoli(level) ? ' · broccoli-proof' : ''}',
      };
}
