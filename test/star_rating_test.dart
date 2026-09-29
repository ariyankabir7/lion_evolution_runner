import 'package:flutter_test/flutter_test.dart';
import 'package:lion_evolution_runner/models/level_result.dart';

void main() {
  int stars(int hp, int boss) => LevelResult.starsFor(won: hp >= boss, hp: hp, bossPower: boss);

  test('win if HP >= boss power', () {
    expect(stars(59, 60), 0);
    expect(stars(60, 60), 1);
  });

  test('two stars need more than 20 HP to spare', () {
    expect(stars(80, 60), 1);
    expect(stars(81, 60), 2);
  });

  test('three stars only at full HP', () {
    expect(stars(100, 60), 3);
    expect(stars(100, 100), 3);
    expect(stars(99, 40), 2);
  });
}
