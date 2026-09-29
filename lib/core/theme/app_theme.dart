import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  /// Lilita One (SIL OFL, assets/fonts). It has a single weight, so never ask for bold:
  /// that would make the engine synthesise a smeared fake bold.
  static const fontFamily = 'LilitaOne';

  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        primary: AppColors.orange,
        secondary: AppColors.green,
        surface: AppColors.cream,
      ),
      scaffoldBackgroundColor: const Color(0xFF7CC8F2),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.outline,
        displayColor: AppColors.outline,
      ),
    );
  }

  /// Chunky display text used for titles, numbers and buttons.
  static const display = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: 0.5,
    height: 1.05,
    color: AppColors.white,
  );
}
