import '../core/constants/asset_paths.dart';
import '../core/constants/game_constants.dart';
import '../core/theme/app_colors.dart';

class Chapter {
  const Chapter({
    required this.index,
    required this.id,
    required this.name,
    required this.bossId,
    required this.bossName,
    required this.palette,
  });

  /// 0-based.
  final int index;
  final String id;
  final String name;
  final String bossId;
  final String bossName;
  final ChapterPalette palette;

  int get number => index + 1;
  int get firstLevel => index * GameConstants.levelsPerChapter + 1;
  int get lastLevel => firstLevel + GameConstants.levelsPerChapter - 1;
  String get bossSprite => AssetPaths.boss(bossId);

  bool contains(int level) => level >= firstLevel && level <= lastLevel;
}
