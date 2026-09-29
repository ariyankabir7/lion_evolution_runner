import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../ui/svg/game_icons.dart';
import 'stroked_text.dart';

enum LevelTileState { locked, current, done }

class LevelTile extends StatelessWidget {
  const LevelTile({
    super.key,
    required this.level,
    required this.state,
    required this.stars,
    required this.isBoss,
    required this.accent,
    required this.accentShade,
    required this.onTap,
  });

  final int level;
  final LevelTileState state;
  final int stars;
  final bool isBoss;
  final Color accent;
  final Color accentShade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (face, shade) = switch (state) {
      LevelTileState.locked => (AppColors.grey, AppColors.greyShade),
      LevelTileState.current => (AppColors.green, AppColors.greenShade),
      LevelTileState.done => (accent, accentShade),
    };
    final tile = GestureDetector(
      onTap: state == LevelTileState.locked ? null : onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(shade, AppColors.outline, 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline, width: 3),
              ),
            ),
          ),
          Positioned.fill(
            bottom: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isBoss && state != LevelTileState.locked ? AppColors.red : AppColors.outline,
                  width: isBoss && state != LevelTileState.locked ? 4 : 3,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(face, Colors.white, 0.2)!, face, shade],
                  stops: const [0, 0.55, 1],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (state == LevelTileState.locked)
                    const GameSvgIcon(GameIcon.lock, size: 24)
                  else
                    FittedBox(child: StrokedText('$level', size: 22)),
                  if (state == LevelTileState.done) ...[
                    const SizedBox(height: 2),
                    _MiniStars(stars: stars),
                  ],
                ],
              ),
            ),
          ),
          if (isBoss)
            const Positioned(
              right: -6,
              top: -8,
              child: _BossBadge(),
            ),
        ],
      ),
    );
    return state == LevelTileState.current ? _Pulse(child: tile) : tile;
  }
}

class _MiniStars extends StatelessWidget {
  const _MiniStars({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            GameSvgIcon(
              GameIcon.star,
              size: 13,
              shadow: false,
              color: i < stars ? AppColors.gold : AppColors.outline.withValues(alpha: 0.35),
            ),
        ],
      );
}

class _BossBadge extends StatelessWidget {
  const _BossBadge();

  @override
  Widget build(BuildContext context) => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.red,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outline, width: 2.5),
        ),
        alignment: Alignment.center,
        child: const GameSvgIcon(GameIcon.paw, size: 13, shadow: false),
      );
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: Tween(begin: 0.95, end: 1.08).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: widget.child,
      );
}
