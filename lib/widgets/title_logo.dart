import 'package:flutter/material.dart';

import '../core/constants/asset_paths.dart';
import '../core/theme/app_colors.dart';
import 'stroked_text.dart';

/// "LION" in gold over an "EVOLUTION RUNNER" wooden plank, with the lion face as the emblem.
/// Drawn in code until a logo image exists.
class TitleLogo extends StatelessWidget {
  const TitleLogo({super.key, this.width = 360, this.showFace = true});

  final double width;
  final bool showFace;

  @override
  Widget build(BuildContext context) {
    final s = width / 360;
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showFace)
            Container(
              width: 96 * s,
              height: 96 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outline, width: 4 * s),
                boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.8), blurRadius: 24 * s)],
              ),
              child: ClipOval(child: Image.asset(AssetPaths.full(AssetPaths.logoFace), fit: BoxFit.cover)),
            ),
          StrokedText(
            'LION',
            size: 92 * s,
            letterSpacing: 4 * s,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF27A), AppColors.gold, AppColors.goldDeep],
              stops: [0.1, 0.5, 0.95],
            ),
          ),
          Transform.translate(
            offset: Offset(0, -8 * s),
            child: Transform.rotate(
              angle: -0.03,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 6 * s),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12 * s),
                  border: Border.all(color: AppColors.outline, width: 4 * s),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFC07A40), AppColors.wood, AppColors.woodDark],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StrokedText('EVOLUTION', size: 30 * s, letterSpacing: 2 * s, drop: false),
                    StrokedText('RUNNER', size: 24 * s, letterSpacing: 6 * s, color: AppColors.gold, drop: false),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
