import 'package:flutter/material.dart';

import '../app.dart';
import '../core/constants/asset_paths.dart';
import '../core/constants/game_constants.dart';
import '../core/services/services.dart';
import '../core/theme/app_colors.dart';
import '../data/chapter_catalog.dart';
import '../models/chapter.dart';
import '../ui/svg/game_icons.dart';
import '../widgets/game_button.dart';
import '../widgets/level_tile.dart';
import '../widgets/stroked_text.dart';
import '../widgets/themed_backdrop.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  static const _columns = 5;
  static const _spacing = 10.0;
  static const _pad = 16.0;

  late Chapter _chapter = ChapterCatalog.forLevel(services.progress.unlockedLevel.value);
  final _grid = ScrollController();
  final _tabs = ScrollController();
  final _tabKeys = [for (final _ in ChapterCatalog.all) GlobalKey()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrent(animate: false);
      _revealTab(animate: false);
    });
  }

  @override
  void dispose() {
    _grid.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _selectChapter(Chapter c) {
    setState(() => _chapter = c);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrent();
      _revealTab();
    });
  }

  /// Keeps the selected chapter tab (which widens when selected) fully on screen, centred when possible.
  /// Without this, later chapters opened from saved progress sat off the right edge of the tab strip.
  void _revealTab({bool animate = true}) {
    final ctx = _tabKeys[_chapter.index].currentContext;
    if (ctx == null) {
      // Not built yet (lazily off screen): jump near it, then retry once it exists.
      if (_tabs.hasClients) {
        _tabs.jumpTo((_chapter.index * 56.0).clamp(0.0, _tabs.position.maxScrollExtent));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_tabKeys[_chapter.index].currentContext != null) _revealTab(animate: animate);
        });
      }
      return;
    }
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  /// Scrolls the grid so the current level's row sits about a third of the way down.
  void _scrollToCurrent({bool animate = true}) {
    if (!_grid.hasClients) return;
    final current = services.progress.unlockedLevel.value;
    final index = _chapter.contains(current) ? current - _chapter.firstLevel : 0;
    final width = MediaQuery.sizeOf(context).width - _pad * 2;
    final tile = (width - _spacing * (_columns - 1)) / _columns;
    final rowH = tile + _spacing;
    final target = ((index ~/ _columns) * rowH - _grid.position.viewportDimension / 3).clamp(
      0.0,
      _grid.position.maxScrollExtent,
    );
    if (animate) {
      _grid.animateTo(target, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    } else {
      _grid.jumpTo(target);
    }
  }

  void _play(int level) => Navigator.of(context).pushNamed(Routes.game, arguments: level);

  @override
  Widget build(BuildContext context) {
    final progress = services.progress;
    return Scaffold(
      body: ThemedBackdrop(
        chapter: _chapter,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([progress.unlockedLevel, progress.revision]),
            builder: (context, _) {
              final unlocked = progress.unlockedLevel.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(_pad, 8, _pad, 0),
                    child: Row(
                      children: [
                        GameButton.round(
                          icon: GameIcon.back,
                          skin: ButtonSkin.orange,
                          size: 54,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Expanded(child: Center(child: StrokedText('LEVELS', size: 34))),
                        _StarTotal(stars: progress.totalStars),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    // Soft fade at both ends hints that the strip scrolls sideways.
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (r) => const LinearGradient(
                        colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
                        stops: [0, 0.05, 0.95, 1],
                      ).createShader(r),
                      child: ListView.separated(
                        controller: _tabs,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: _pad),
                        itemCount: ChapterCatalog.all.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final c = ChapterCatalog.all[i];
                          return _ChapterTab(
                            key: _tabKeys[i],
                            chapter: c,
                            selected: c == _chapter,
                            locked: c.firstLevel > unlocked,
                            onTap: () => _selectChapter(c),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _pad),
                    child: _ChapterHeader(chapter: _chapter),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      controller: _grid,
                      padding: const EdgeInsets.fromLTRB(_pad, 8, _pad, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _columns,
                        mainAxisSpacing: _spacing,
                        crossAxisSpacing: _spacing,
                      ),
                      itemCount: GameConstants.levelsPerChapter,
                      itemBuilder: (_, i) {
                        final level = _chapter.firstLevel + i;
                        final stars = progress.starsFor(level);
                        return LevelTile(
                          level: level,
                          state: level > unlocked
                              ? LevelTileState.locked
                              : (level == unlocked && stars == 0 ? LevelTileState.current : LevelTileState.done),
                          stars: stars,
                          isBoss: level % 10 == 0,
                          accent: _chapter.palette.accent,
                          accentShade: _chapter.palette.accentShade,
                          onTap: () => _play(level),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StarTotal extends StatelessWidget {
  const _StarTotal({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: AppColors.outline.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.outline, width: 3),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const GameSvgIcon(GameIcon.star, size: 26, color: AppColors.gold, shadow: false),
        const SizedBox(width: 4),
        StrokedText('$stars', size: 20, color: AppColors.gold, drop: false),
      ],
    ),
  );
}

class _ChapterTab extends StatelessWidget {
  const _ChapterTab({
    super.key,
    required this.chapter,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final Chapter chapter;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = chapter.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: locked ? AppColors.grey : (selected ? p.accent : AppColors.cream),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.outline, width: selected ? 4 : 3),
        ),
        child: Row(
          children: [
            if (locked) ...[const GameSvgIcon(GameIcon.lock, size: 18, shadow: false), const SizedBox(width: 6)],
            if (selected)
              StrokedText('${chapter.number}. ${chapter.name.toUpperCase()}', size: 18, drop: false)
            else
              Text(
                '${chapter.number}',
                style: TextStyle(fontSize: 20, color: locked ? AppColors.white : AppColors.outline),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({required this.chapter});

  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    final progress = services.progress;
    var stars = 0;
    for (var l = chapter.firstLevel; l <= chapter.lastLevel; l++) {
      stars += progress.starsFor(l);
    }
    const maxStars = GameConstants.levelsPerChapter * 3;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline, width: 3),
      ),
      child: Row(
        children: [
          SizedBox(width: 76, height: 76, child: Image.asset(AssetPaths.full(chapter.bossSprite), fit: BoxFit.contain)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Levels ${chapter.firstLevel}-${chapter.lastLevel}',
                  style: const TextStyle(fontSize: 14, color: AppColors.outlineSoft),
                ),
                Text('Boss: ${chapter.bossName}', style: const TextStyle(fontSize: 20, color: AppColors.outline)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: stars / maxStars,
                    minHeight: 10,
                    color: AppColors.gold,
                    backgroundColor: AppColors.outline.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              const GameSvgIcon(GameIcon.star, size: 26, color: AppColors.gold),
              Text('$stars/$maxStars', style: const TextStyle(fontSize: 13, color: AppColors.outline)),
            ],
          ),
        ],
      ),
    );
  }
}
