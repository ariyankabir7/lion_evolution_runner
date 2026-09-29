import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:flame/game.dart';
import 'package:flutter/services.dart';

import '../core/constants/asset_paths.dart';
import '../core/constants/economy.dart';
import '../core/constants/game_constants.dart';
import '../core/services/services.dart';
import '../core/theme/app_colors.dart';
import '../models/chapter.dart';
import '../models/evolution_stage.dart';
import '../models/item_type.dart';
import '../models/level_config.dart';
import '../models/level_result.dart';
import 'components/boss_component.dart';
import 'components/dust_cloud_component.dart';
import 'components/finish_gate_component.dart';
import 'components/floating_text_component.dart';
import 'components/item_component.dart';
import 'components/lion_player.dart';
import 'effects/burst_effect.dart';
import 'effects/particles.dart';
import 'game_session.dart';
import 'overlays/overlay_ids.dart';
import 'world/perspective.dart';
import 'world/roadside_decor.dart';
import 'world/track_component.dart';

class LionGame extends FlameGame with KeyboardEvents {
  LionGame({required this.config, required this.chapter}) : session = GameSession(config);

  final LevelConfig config;
  final Chapter chapter;
  final GameSession session;
  final perspective = Perspective();
  final _rnd = math.Random();

  late final LionPlayer player;

  /// Distance run from the start line, in world units.
  double distance = 0;

  /// Seconds since load; drives idle animations.
  double time = 0;

  /// 0..1 multiplier on run speed. Drops after a hit and recovers.
  double speedFactor = 1;

  double get speed => config.speed;

  /// True while the world scrolls: during play and while running up to the boss.
  bool get isRunning => session.isPlaying || _phase == _EndPhase.approach;

  /// The boss stands this far past the finish gate.
  static const bossGap = 13.0;

  /// The fight starts when the lion is this close to the boss.
  static const fightDistance = 4.5;

  late final BossComponent boss;
  _EndPhase? _phase;

  int _nextSpawn = 0;
  double _shake = 0;

  /// >0 while the lion is invincible after a shield block.
  double _graceT = 0;
  LevelResult? result;

  @override
  Color backgroundColor() => chapter.palette.skyBottom;

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      for (final s in EvolutionStage.values) ...[...s.runFrames, s.frontSprite],
      AssetPaths.lionDefeated,
      for (final t in ItemType.values) t.sprite,
      AssetPaths.sparkle,
      AssetPaths.burst,
      AssetPaths.explosion,
      AssetPaths.upgradeShield,
      AssetPaths.dustCloud,
      AssetPaths.confetti,
      AssetPaths.lionVictory,
      AssetPaths.speedSwoosh,
      chapter.bossSprite,
    ]);
    camera.viewfinder.anchor = Anchor.topLeft;
    world.addAll([
      TrackComponent(),
      RoadsideDecor(),
      DustTrail(),
      SpeedLines(),
      FinishGateComponent(config.length),
      boss = BossComponent(
        worldZ: config.length + bossGap,
        power: config.bossPower,
        spritePath: chapter.bossSprite,
      ),
      player = LionPlayer(),
    ]);
    overlays.addAll([OverlayIds.hud, OverlayIds.ready]);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Fixed 720-wide world; its height follows the phone's aspect, so there are no letterbox bars.
    final h = Perspective.width * size.y / size.x;
    perspective.resize(h);
    camera.viewfinder.visibleGameSize = Vector2(Perspective.width, h);
  }

  // ---- Input ---------------------------------------------------------------------------------

  void moveLane(int lane) {
    if (session.state.value == RunState.ready) start();
    if (!session.isPlaying || lane == player.lane) return;
    if (!player.moveTo(lane)) return;
    services.audio.play(Sfx.swoosh);
    // Wind swoosh trailing on the side the lion is leaving.
    final dir = lane == 0 ? -1.0 : 1.0;
    world.add(BurstEffect(AssetPaths.speedSwoosh,
        position: player.position + Vector2(-dir * 110, -150),
        startSize: 150, endSize: 230, duration: 0.3, flipX: dir < 0, priority: player.priority - 1));
  }

  void moveBy(int dir) => moveLane((player.lane + dir).clamp(0, 1));

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.keyA) {
      moveLane(0);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.keyD) {
      moveLane(1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // ---- Flow ----------------------------------------------------------------------------------

  void start() {
    if (session.state.value != RunState.ready) return;
    session.state.value = RunState.running;
    overlays.remove(OverlayIds.ready);
  }

  void pause() {
    if (!session.isPlaying) return;
    session.state.value = RunState.paused;
    pauseEngine();
    services.audio.duckMusic(true);
    overlays.add(OverlayIds.pause);
  }

  void resume() {
    if (session.state.value != RunState.paused) return;
    overlays.remove(OverlayIds.pause);
    services.audio.duckMusic(false);
    session.state.value = RunState.running;
    resumeEngine();
  }

  @override
  void update(double dt) {
    dt = math.min(dt, 1 / 20); // avoid tunnelling through items after a frame hitch
    time += dt;
    if (_graceT > 0) {
      _graceT = math.max(0, _graceT - dt);
      player.shieldGlow = _graceT;
    }
    _spawnAhead(); // also while waiting to start, so the road ahead is already populated
    if (session.isPlaying) {
      speedFactor = math.min(1, speedFactor + dt * 1.2);
      distance += speed * speedFactor * dt;
      session.progress.value = (distance / config.length).clamp(0, 1);
      _resolvePassing();
      if (distance >= config.length) _reachFinish();
    } else if (_phase == _EndPhase.approach) {
      // Run up to the boss, slowing down as we arrive.
      final remaining = config.length + bossGap - fightDistance - distance;
      distance += speed * math.max(0.3, math.min(1, remaining / 6)) * dt;
      if (remaining <= 0) _startFight();
    }
    _updateShake(dt);
    super.update(dt);
  }

  void _spawnAhead() {
    final spawns = config.spawns;
    while (_nextSpawn < spawns.length && spawns[_nextSpawn].z - distance < Perspective.maxZ) {
      world.add(ItemComponent(spawns[_nextSpawn++]));
    }
  }

  void _resolvePassing() {
    for (final item in world.children.whereType<ItemComponent>().toList()) {
      if (item.resolved || item.z > 0.4) continue;
      item.resolved = true;
      if (item.entry.lane == player.collisionLane) _hit(item);
      if (!session.isPlaying) return;
    }
  }

  void _hit(ItemComponent item) {
    final at = item.position.clone() - Vector2(0, item.size.y * 0.6);
    switch (item.type.kind) {
      case ItemKind.food:
        item.collect();
        _floatText('+${session.meatHp}', AppColors.hpGladiator, at);
        world
          ..add(BurstEffect(AssetPaths.sparkle, position: at, startSize: 80, endSize: 220))
          ..add(ParticleBurst(at: at, colors: _meatBits, count: 12, size: 16, squares: true));
        services.audio.play(Sfx.meat);
        _applyHp(session.meatHp);
      case ItemKind.junk:
        if (session.shieldBlocksBroccoli && (session.shield.value > 0 || _graceT > 0)) {
          // Shield Lv 10: broccoli bounces off without using a charge.
          item.removeFromParent();
          _deflect(at, 'NO THANKS!');
          return;
        }
        item.collect();
        _floatText('${item.type.hpDelta}', AppColors.orange, at);
        world
          ..add(ScreenFlash(const Color(0xFF7BC043), peak: 0.18))
          ..add(ParticleBurst(at: at, colors: _leafBits, count: 12, size: 15, squares: true));
        services.audio.play(Sfx.broccoli);
        _haptic(HapticFeedback.lightImpact);
        _applyHp(item.type.hpDelta);
      case ItemKind.coin:
        item.collect();
        session.coins.value++;
        world
          ..add(BurstEffect(AssetPaths.sparkle, position: at, startSize: 40, endSize: 110, duration: 0.3))
          ..add(ParticleBurst(at: at, colors: _coinBits, count: 7, size: 9, speed: 380, life: 0.4));
        services.audio.play(Sfx.coin);
      case ItemKind.obstacle:
        item.removeFromParent();
        if (_graceT > 0) {
          _deflect(at, 'SAFE!');
          return;
        }
        if (session.consumeShield()) {
          _graceT = session.shieldGraceSeconds;
          world
            ..add(BurstEffect(AssetPaths.upgradeShield, position: player.position - Vector2(0, 140),
                startSize: 180, endSize: 300, duration: 0.5))
            ..add(BurstEffect(AssetPaths.burst, position: at, startSize: 120, endSize: 280))
            ..add(ParticleBurst(at: at, colors: _shieldBits, count: 16, size: 14, squares: true));
          _floatText('BLOCKED!', AppColors.blue, at, size: 52);
          services.audio.play(Sfx.shieldBlock);
          _shake = 0.15;
          _haptic(HapticFeedback.mediumImpact);
          return;
        }
        world
          ..add(BurstEffect(AssetPaths.explosion, position: at, startSize: 140, endSize: 320))
          ..add(ParticleBurst(at: at, colors: _debrisBits, count: 18, size: 18, speed: 650, squares: true))
          ..add(ScreenFlash(AppColors.red));
        services.audio.play(Sfx.hit);
        _floatText('${item.type.hpDelta}', AppColors.red, at);
        player.hurt();
        speedFactor = 0.35;
        _shake = 0.35;
        _haptic(HapticFeedback.heavyImpact);
        _applyHp(item.type.hpDelta);
    }
  }

  static const _meatBits = [Color(0xFFE8503A), Color(0xFFFF8A65), Color(0xFFFFF4DC)];
  static const _leafBits = [Color(0xFF4E8F2A), Color(0xFF7BC043), Color(0xFFB5E36B)];
  static const _coinBits = [AppColors.gold, Color(0xFFFFF3A0), AppColors.white];
  static const _shieldBits = [AppColors.blue, Color(0xFF8FD3FF), AppColors.white];
  static const _debrisBits = [Color(0xFF8B5A2B), Color(0xFF6E6A66), Color(0xFFB9B2A6), Color(0xFFD9C29A)];

  /// Something bounced off the shield bubble without costing a charge.
  void _deflect(Vector2 at, String text) {
    world.add(ParticleBurst(at: at, colors: _shieldBits, count: 10, size: 12, squares: true));
    _floatText(text, AppColors.blue, at, size: 44);
    services.audio.play(Sfx.shieldGraze);
    _haptic(HapticFeedback.selectionClick);
  }

  void _applyHp(int delta) {
    final before = player.stage;
    final after = session.changeHp(delta);
    if (after != before) {
      player.setStage(after);
      final at = player.position - Vector2(0, 320);
      if (after.index > before.index) {
        services.audio.play(Sfx.evolve);
        world.add(ParticleBurst(at: player.position - Vector2(0, 160),
            colors: const [AppColors.gold, Color(0xFFFFF3A0), AppColors.orange, AppColors.white],
            count: 26, size: 16, speed: 700, life: 0.9, squares: true));
        _floatText('${after.label.toUpperCase()}!', AppColors.gold, at, size: 64, duration: 1.2);
        world
          ..add(ScreenFlash(AppColors.gold, peak: 0.4, duration: 0.5))
          ..add(BurstEffect(AssetPaths.burst, position: player.position - Vector2(0, 130),
              startSize: 200, endSize: 520, duration: 0.6, spin: 2, priority: player.priority - 1));
      } else {
        services.audio.play(Sfx.devolve);
        _floatText(after.label.toUpperCase(), AppColors.grey, at, size: 48, duration: 1.0);
      }
    }
    if (session.hp.value <= 0) _die();
  }

  void _die() {
    session.state.value = RunState.finishing;
    player.collapse();
    services.audio.play(Sfx.defeat);
    _shake = 0.4;
    add(TimerComponent(period: 1.4, removeOnFinish: true, onTick: () => _endRun(won: false)));
  }

  /// Crossing the gate: lock input, snap to the centre and run at the boss.
  void _reachFinish() {
    session.state.value = RunState.finishing;
    session.progress.value = 1;
    _phase = _EndPhase.approach;
    speedFactor = 1;
    player.lockToCenter();
    services.audio.play(Sfx.finish);
    _floatText('FINISH!', AppColors.gold, Vector2(Perspective.centerX, perspective.height * 0.45), size: 72);
  }

  void _startFight() {
    _phase = _EndPhase.fight;
    player.setPose(LionPose.hidden);
    boss.setPose(BossPose.hidden);
    final between = Vector2(Perspective.centerX, perspective.yAt(fightDistance * 0.45) - 150);
    world.add(DustCloudComponent(
      position: between,
      duration: GameConstants.fightSeconds,
      onDone: _resolveFight,
    ));
    services.audio.play(Sfx.fight);
    _haptic(HapticFeedback.heavyImpact);
  }

  void _resolveFight() {
    _phase = _EndPhase.outro;
    final won = session.hp.value >= config.bossPower;
    final textAt = Vector2(Perspective.centerX, perspective.height * 0.4);
    if (won) {
      boss.setPose(BossPose.defeated);
      player.setPose(LionPose.celebrate);
      _floatText('VICTORY!', AppColors.gold, textAt, size: 84, duration: 1.4);
      services.audio.play(Sfx.victory);
      world.add(ScreenFlash(AppColors.gold, peak: 0.35, duration: 0.5));
      for (var i = 0; i < 6; i++) {
        final at = Vector2(80 + _rnd.nextDouble() * 560, perspective.height * (0.25 + _rnd.nextDouble() * 0.35));
        add(TimerComponent(
          period: 0.05 + i * 0.12,
          removeOnFinish: true,
          onTick: () => world.add(BurstEffect(AssetPaths.confetti, position: at,
              startSize: 100, endSize: 280, duration: 0.8, spin: 1.5)),
        ));
      }
    } else {
      boss.setPose(BossPose.taunt);
      player.collapse();
      _floatText('DEFEATED', AppColors.red, textAt, size: 72, duration: 1.4);
      services.audio.play(Sfx.defeat);
      shake(0.3);
    }
    _haptic(won ? HapticFeedback.mediumImpact : HapticFeedback.heavyImpact);
    add(TimerComponent(period: 1.6, removeOnFinish: true, onTick: () => _endRun(won: won)));
  }

  void _endRun({required bool won}) {
    final progress = services.progress;
    final replay = progress.starsFor(config.level) > 0;
    final stars = LevelResult.starsFor(won: won, hp: session.hp.value, bossPower: config.bossPower);
    final firstWin = won && progress.recordWin(config.level, stars);
    final bonus = won ? Economy.levelBonus(stars, replay: replay, bossLevel: config.isBossLevel) : 0;
    result = LevelResult(
      level: config.level,
      won: won,
      hp: session.hp.value,
      bossPower: config.bossPower,
      coinsCollected: session.coins.value,
      bonus: bonus,
      firstWin: firstWin,
      replay: replay,
      bossLevel: config.isBossLevel,
    );
    services.wallet.add(result!.totalCoins);
    session.state.value = won ? RunState.won : RunState.lost;
    overlays.add(OverlayIds.result);
  }

  // ---- Feedback helpers ----------------------------------------------------------------------

  void _floatText(String text, Color color, Vector2 at, {double size = 56, double duration = 0.9}) =>
      world.add(FloatingTextComponent(text, position: at, color: color, fontSize: size, duration: duration));

  void _haptic(Future<void> Function() fn) {
    if (services.settings.haptics.value) fn();
  }

  void shake(double seconds) => _shake = math.max(_shake, seconds);

  void _updateShake(double dt) {
    if (_shake > 0) {
      _shake = math.max(0, _shake - dt);
      final m = 22 * _shake;
      camera.viewfinder.position = Vector2((_rnd.nextDouble() - 0.5) * m, (_rnd.nextDouble() - 0.5) * m);
    } else if (!camera.viewfinder.position.isZero()) {
      camera.viewfinder.position = Vector2.zero();
    }
  }

  @override
  void onRemove() {
    services.audio.duckMusic(false);
    session.dispose();
    super.onRemove();
  }
}

enum _EndPhase { approach, fight, outro }
