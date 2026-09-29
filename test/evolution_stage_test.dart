import 'package:flutter_test/flutter_test.dart';
import 'package:lion_evolution_runner/data/chapter_catalog.dart';
import 'package:lion_evolution_runner/models/evolution_stage.dart';

void main() {
  test('stage thresholds', () {
    expect(EvolutionStage.fromHp(0), EvolutionStage.starving);
    expect(EvolutionStage.fromHp(39), EvolutionStage.starving);
    expect(EvolutionStage.fromHp(40), EvolutionStage.healthy);
    expect(EvolutionStage.fromHp(79), EvolutionStage.healthy);
    expect(EvolutionStage.fromHp(80), EvolutionStage.gladiator);
    expect(EvolutionStage.fromHp(100), EvolutionStage.gladiator);
  });

  test('chapters cover levels 1-1000', () {
    expect(ChapterCatalog.forLevel(1).number, 1);
    expect(ChapterCatalog.forLevel(100).number, 1);
    expect(ChapterCatalog.forLevel(101).number, 2);
    expect(ChapterCatalog.forLevel(1000).number, 10);
  });
}
