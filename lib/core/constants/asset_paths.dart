/// Paths are relative to `assets/images/` because that is Flame's default image prefix.
/// Use [AssetPaths.full] for Flutter `Image.asset`.
abstract final class AssetPaths {
  static const imagePrefix = 'assets/images/';
  static String full(String path) => '$imagePrefix$path';

  static const runFrameCount = 4;

  static String lionFront(String stage) => 'characters/lion_$stage.png';
  static String lionBack(String stage) => 'characters/lion_${stage}_back.png';
  static List<String> lionRun(String stage) =>
      List.generate(runFrameCount, (i) => 'characters/lion_${stage}_run_$i.png');
  static const lionVictory = 'characters/lion_gladiator_victory.png';
  static const lionDefeated = 'characters/lion_defeated.png';

  static String boss(String id) => 'bosses/boss_$id.png';

  static const meat = 'items/meat.png';
  static const broccoli = 'items/broccoli.png';
  static const spikes = 'items/spikes.png';
  static const coin = 'items/coin.png';
  static const log = 'items/log.png';
  static const rocks = 'items/rocks.png';
  static const thorns = 'items/thorns.png';
  static const mud = 'items/mud.png';

  static const dustCloud = 'effects/dust_cloud.png';
  static const sparkle = 'effects/sparkle.png';
  static const confetti = 'effects/confetti.png';
  static const burst = 'effects/burst.png';
  static const explosion = 'effects/explosion.png';
  static const speedSwoosh = 'effects/speed_swoosh.png';

  static const roadBase = 'track/road_base.jpg';

  static const logoFace = 'ui/logo_face.png';
  static const upgradeSpeed = 'ui/upgrades/upgrade_speed.png';
  static const upgradeFood = 'ui/upgrades/upgrade_food.png';
  static const upgradeShield = 'ui/upgrades/upgrade_shield.png';

  /// Everything the home screen shows, precached during the splash.
  static const List<String> uiPreload = [
    logoFace,
    coin,
    upgradeSpeed,
    upgradeFood,
    upgradeShield,
    'characters/lion_starving.png',
    'characters/lion_healthy.png',
    'characters/lion_gladiator.png',
  ];
}
