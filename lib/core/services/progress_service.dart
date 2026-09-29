import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/game_constants.dart';

/// Unlocked level and best stars per level.
/// Stars are stored as one 1000-char string of '0'..'3' so the whole save is a single key.
class ProgressService {
  ProgressService(this._prefs)
      : _stars = _decode(_prefs.getString(_kStars)),
        unlockedLevel = ValueNotifier(_prefs.getInt(_kUnlocked) ?? 1);

  static const _kUnlocked = 'progress.unlocked';
  static const _kStars = 'progress.stars';

  final SharedPreferences _prefs;
  final List<int> _stars;

  /// Highest level the player may start. Level N+1 unlocks when N is won.
  final ValueNotifier<int> unlockedLevel;

  /// Bumped on every stars change so grids can rebuild.
  final ValueNotifier<int> revision = ValueNotifier(0);

  int starsFor(int level) => _stars[level - 1];

  bool isUnlocked(int level) => level <= unlockedLevel.value;

  int get totalStars => _stars.fold(0, (a, b) => a + b);

  /// Records a win. Returns true if this level had never been won before.
  bool recordWin(int level, int stars) {
    final firstWin = _stars[level - 1] == 0;
    if (stars > _stars[level - 1]) {
      _stars[level - 1] = stars;
      _prefs.setString(_kStars, _stars.join());
      revision.value++;
    }
    if (level == unlockedLevel.value && level < GameConstants.totalLevels) {
      unlockedLevel.value = level + 1;
      _prefs.setInt(_kUnlocked, unlockedLevel.value);
    }
    return firstWin;
  }

  static List<int> _decode(String? raw) {
    final stars = List<int>.filled(GameConstants.totalLevels, 0);
    if (raw == null) return stars;
    for (var i = 0; i < raw.length && i < stars.length; i++) {
      stars[i] = (raw.codeUnitAt(i) - 48).clamp(0, 3);
    }
    return stars;
  }
}
