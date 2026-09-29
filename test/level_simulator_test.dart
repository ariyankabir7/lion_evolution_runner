import 'package:flutter_test/flutter_test.dart';
import 'package:lion_evolution_runner/core/constants/game_constants.dart';
import 'package:lion_evolution_runner/data/level_simulator.dart';
import 'package:lion_evolution_runner/models/item_type.dart';
import 'package:lion_evolution_runner/models/level_config.dart';

void main() {
  const start = GameConstants.startHp;
  int best(List<SpawnEntry> s, {double speed = 12}) => LevelSimulator.bestFinalHpFor(s, speed);

  test('empty level keeps the starting HP', () => expect(best([]), start));

  test('eats every reachable meat and dodges hazards', () {
    expect(
      best(const [
        SpawnEntry(20, 0, ItemType.meat),
        SpawnEntry(40, 0, ItemType.spikes),
        SpawnEntry(60, 1, ItemType.meat),
      ]),
      start + 40,
    );
  });

  test('HP is capped at 100', () {
    expect(best([for (var i = 0; i < 8; i++) SpawnEntry(20.0 + i * 10, 0, ItemType.meat)]), 100);
  });

  test('a full-width hazard row forces the lesser damage', () {
    expect(best(const [SpawnEntry(20, 0, ItemType.spikes), SpawnEntry(20, 1, ItemType.broccoli)]), start - 20);
  });

  test('no lane change when rows are too close', () {
    // Meat on the left, then 1 unit later spikes on the left and meat on the right: no time to switch.
    expect(
      best(const [
        SpawnEntry(20, 0, ItemType.meat),
        SpawnEntry(21, 0, ItemType.spikes),
        SpawnEntry(21, 1, ItemType.meat),
      ]),
      // Either take meat+spikes (35+20-30=25) or skip the first meat for the second (35+20=55).
      start + 20,
    );
  });

  test('a run that must die is reported as impossible', () {
    expect(best(const [SpawnEntry(20, 0, ItemType.spikes), SpawnEntry(20, 1, ItemType.spikes),
      SpawnEntry(40, 0, ItemType.spikes), SpawnEntry(40, 1, ItemType.spikes)]), lessThan(0));
  });
}
