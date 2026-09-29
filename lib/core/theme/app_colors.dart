import 'package:flutter/material.dart';

/// Fixed brand colours shared by every chapter.
abstract final class AppColors {
  static const outline = Color(0xFF3A2014);
  static const outlineSoft = Color(0xFF5C3A24);
  static const cream = Color(0xFFFFF4DC);
  static const parchment = Color(0xFFF6E2B3);
  static const wood = Color(0xFF9A5B2E);
  static const woodDark = Color(0xFF6B3A1C);

  static const gold = Color(0xFFFFC928);
  static const goldDeep = Color(0xFFE89410);
  static const white = Color(0xFFFFFFFF);

  // Button families (face / shade).
  static const green = Color(0xFF58CC3A);
  static const greenShade = Color(0xFF2F8F1E);
  static const orange = Color(0xFFFF9A1F);
  static const orangeShade = Color(0xFFC96400);
  static const blue = Color(0xFF2E9BFF);
  static const blueShade = Color(0xFF1760B8);
  static const red = Color(0xFFFF4B3E);
  static const redShade = Color(0xFFB8231A);
  static const purple = Color(0xFF9B5CFF);
  static const purpleShade = Color(0xFF5E2EB8);
  static const grey = Color(0xFFB9B2A6);
  static const greyShade = Color(0xFF7D7468);

  // HP stages.
  static const hpStarving = Color(0xFFFF5A3C);
  static const hpHealthy = Color(0xFFFFB820);
  static const hpGladiator = Color(0xFF4CD137);
}

/// Colours that change per chapter. Everything drawn in code (backdrops, panels, the road tint)
/// reads from this, so a new chapter only needs a new palette.
@immutable
class ChapterPalette {
  const ChapterPalette({
    required this.skyTop,
    required this.skyBottom,
    required this.sun,
    required this.farHills,
    required this.nearHills,
    required this.foliage,
    required this.foliageDark,
    required this.ground,
    required this.accent,
    required this.accentShade,
    this.roadTint,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color sun;
  final Color farHills;
  final Color nearHills;
  final Color foliage;
  final Color foliageDark;
  final Color ground;

  /// Main UI accent for the chapter (tabs, highlights).
  final Color accent;
  final Color accentShade;

  /// Multiplied over the base road texture until themed road art exists. Null = untinted.
  final Color? roadTint;
}
