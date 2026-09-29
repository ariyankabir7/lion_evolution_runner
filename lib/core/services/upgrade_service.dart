import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/upgrade_type.dart';
import '../constants/economy.dart';
import 'wallet_service.dart';

class UpgradeService {
  UpgradeService(this._prefs, this._wallet)
      : levels = {
          for (final t in UpgradeType.values) t: ValueNotifier(_prefs.getInt(_key(t)) ?? 0),
        };

  final SharedPreferences _prefs;
  final WalletService _wallet;
  final Map<UpgradeType, ValueNotifier<int>> levels;

  static String _key(UpgradeType t) => 'upgrade.${t.name}';

  int level(UpgradeType t) => levels[t]!.value;

  bool isMaxed(UpgradeType t) => level(t) >= UpgradeType.maxLevel;

  int nextCost(UpgradeType t) => Economy.upgradeCost(t, level(t));

  bool canBuy(UpgradeType t) => !isMaxed(t) && _wallet.coins.value >= nextCost(t);

  bool get anyAffordable => UpgradeType.values.any(canBuy);

  /// Fires when coins or any upgrade level change.
  Listenable get changes => Listenable.merge([_wallet.coins, ...levels.values]);

  bool tryBuy(UpgradeType t) {
    if (isMaxed(t) || !_wallet.trySpend(nextCost(t))) return false;
    levels[t]!.value++;
    _prefs.setInt(_key(t), levels[t]!.value);
    return true;
  }
}
