import 'package:flutter/services.dart';

import '../models/level_config.dart';
import 'handcrafted_levels.dart';
import 'level_generator.dart';

/// Single entry point for level data: hand-tuned levels from JSON first, the generator for the rest.
class LevelRepository {
  LevelRepository._(this._handcrafted);

  static late final LevelRepository instance;

  static Future<void> init() async {
    instance = LevelRepository._(HandcraftedLevels.parse(await rootBundle.loadString(HandcraftedLevels.assetPath)));
  }

  final Map<int, LevelConfig> _handcrafted;
  final _generator = const LevelGenerator();
  final _cache = <int, LevelConfig>{};

  LevelConfig load(int level) =>
      _handcrafted[level] ?? _cache.putIfAbsent(level, () => _generator.generate(level));
}
