import 'package:flutter/foundation.dart';

import '../core/constants/economy.dart';
import '../core/constants/game_constants.dart';
import '../core/services/services.dart';
import '../models/evolution_stage.dart';
import '../models/level_config.dart';
import '../models/upgrade_type.dart';

enum RunState { ready, running, paused, finishing, won, lost }

/// Observable state of one run. The Flame game writes it, and the Flutter HUD overlays read it.
class GameSession {
  GameSession(this.config)
      : meatHp = Economy.meatHp(services.upgrades.level(UpgradeType.food)),
        laneSwitchSeconds = Economy.laneSwitchSeconds(services.upgrades.level(UpgradeType.speed)),
        shield = ValueNotifier(Economy.shieldCharges(services.upgrades.level(UpgradeType.shield)));

  final LevelConfig config;
  final int meatHp;
  final double laneSwitchSeconds;

  final ValueNotifier<int> hp = ValueNotifier(GameConstants.startHp);
  final ValueNotifier<int> coins = ValueNotifier(0);
  final ValueNotifier<int> shield;
  final ValueNotifier<RunState> state = ValueNotifier(RunState.ready);

  /// 0..1 progress to the finish line.
  final ValueNotifier<double> progress = ValueNotifier(0);

  EvolutionStage get stage => EvolutionStage.fromHp(hp.value);

  bool get isPlaying => state.value == RunState.running;

  /// Applies an HP change and returns the new stage.
  EvolutionStage changeHp(int delta) {
    hp.value = (hp.value + delta).clamp(0, GameConstants.maxHp);
    return stage;
  }

  /// Uses one shield charge if any are left.
  bool consumeShield() {
    if (shield.value <= 0) return false;
    shield.value--;
    return true;
  }

  void dispose() {
    hp.dispose();
    coins.dispose();
    shield.dispose();
    state.dispose();
    progress.dispose();
  }
}
