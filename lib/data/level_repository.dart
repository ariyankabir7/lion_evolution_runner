import '../models/level_config.dart';
import 'level_generator.dart';

/// Single entry point for level data. Milestone 4 adds the hand-tuned levels 1–20 from JSON.
class LevelRepository {
  const LevelRepository({this.generator = const LevelGenerator()});

  final LevelGenerator generator;

  LevelConfig load(int level) => generator.generate(level);
}
