import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletService {
  WalletService(this._prefs) : coins = ValueNotifier(_prefs.getInt(_kCoins) ?? 0);

  static const _kCoins = 'wallet.coins';

  final SharedPreferences _prefs;
  final ValueNotifier<int> coins;

  void add(int amount) {
    if (amount <= 0) return;
    _set(coins.value + amount);
  }

  bool trySpend(int amount) {
    if (amount > coins.value) return false;
    _set(coins.value - amount);
    return true;
  }

  void _set(int value) {
    coins.value = value;
    _prefs.setInt(_kCoins, value);
  }
}
