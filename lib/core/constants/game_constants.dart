abstract final class GameConstants {
  static const gameWidth = 720.0;
  static const gameHeight = 1280.0;

  static const totalLevels = 1000;
  static const levelsPerChapter = 100;
  static const chapterCount = totalLevels ~/ levelsPerChapter;

  static const maxHp = 100;
  static const startHp = 20;
  static const hpPerSegment = 20;

  static const meatHp = 20;
  static const broccoliDamage = 20;
  static const obstacleDamage = 30;

  static const baseLaneSwitchSeconds = 0.22;
  static const fightSeconds = 1.2;
}
