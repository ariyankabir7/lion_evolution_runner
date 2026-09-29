import 'package:flutter/material.dart';

import '../core/constants/game_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/evolution_stage.dart';
import 'stroked_text.dart';

/// Five-segment HP bar (20 HP each) with the evolution stage label. Animates between values.
class HpBar extends StatelessWidget {
  const HpBar({super.key, required this.hp, this.width = 300});

  final int hp;
  final double width;

  @override
  Widget build(BuildContext context) {
    final stage = EvolutionStage.fromHp(hp);
    const segments = GameConstants.maxHp ~/ GameConstants.hpPerSegment;
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
            child: StrokedText(
              '${stage.label.toUpperCase()}  $hp',
              key: ValueKey(stage),
              size: 20,
              color: stage.color,
              drop: false,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 26,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.outline.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.outline, width: 3),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: hp.toDouble()),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, v, _) => Row(
                children: [
                  for (var i = 0; i < segments; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(child: _Segment(fill: ((v - i * GameConstants.hpPerSegment) / GameConstants.hpPerSegment).clamp(0.0, 1.0), color: stage.color)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.fill, required this.color});

  final double fill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.white.withValues(alpha: 0.12)),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fill,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(color, Colors.white, 0.35)!, color],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
