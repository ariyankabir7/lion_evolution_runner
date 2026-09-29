import '../core/constants/game_constants.dart';

class LevelResult {
  const LevelResult({
    required this.level,
    required this.won,
    required this.hp,
    required this.bossPower,
    required this.coinsCollected,
    required this.bonus,
    required this.firstWin,
  });

  final int level;
  final bool won;
  final int hp;
  final int bossPower;
  final int coinsCollected;
  final int bonus;
  final bool firstWin;

  int get stars => starsFor(won: won, hp: hp, bossPower: bossPower);
  int get totalCoins => coinsCollected + bonus;

  /// ★ win · ★★ win with more than 20 HP over the boss · ★★★ win at full HP.
  static int starsFor({required bool won, required int hp, required int bossPower}) {
    if (!won) return 0;
    if (hp >= GameConstants.maxHp) return 3;
    if (hp - bossPower > 20) return 2;
    return 1;
  }
}
