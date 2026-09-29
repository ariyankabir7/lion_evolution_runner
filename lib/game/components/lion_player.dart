import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/animation.dart';

import '../../core/constants/asset_paths.dart';
import '../../models/evolution_stage.dart';
import '../lion_game.dart';
import '../world/perspective.dart';

enum LionPose { run, hidden, celebrate, knockedOut }

/// The lion, seen from behind. Handles lane switching, the run cycle per stage, hit and evolve
/// feedback, and the end-of-level poses.
class LionPlayer extends PositionComponent with HasGameReference<LionGame> {
  LionPlayer() : super(anchor: Anchor.bottomCenter, priority: 10000);

  static const _heights = {
    EvolutionStage.starving: 300.0,
    EvolutionStage.healthy: 330.0,
    EvolutionStage.gladiator: 380.0,
  };

  late final Map<EvolutionStage, SpriteAnimationTicker> _run = {
    for (final s in EvolutionStage.values)
      s: SpriteAnimation.spriteList(
        [for (final f in s.runFrames) Sprite(game.images.fromCache(f))],
        stepTime: 0.1,
      ).createTicker(),
  };
  late final Sprite _knockedOut = Sprite(game.images.fromCache(AssetPaths.lionDefeated));
  late final Sprite _victory = Sprite(game.images.fromCache(AssetPaths.lionVictory));
  late final Map<EvolutionStage, Sprite> _front = {
    for (final s in EvolutionStage.values) s: Sprite(game.images.fromCache(s.frontSprite)),
  };

  EvolutionStage stage = EvolutionStage.starving;
  LionPose pose = LionPose.run;
  int lane = 0;

  /// Current horizontal position, -1 (left lane) .. 1 (right lane).
  double laneX = -1;
  double _fromX = -1;
  double _toX = -1;
  double _switchT = 1;

  /// Once locked (at the finish line), lane input is ignored.
  bool _locked = false;

  double _hurtT = 0; // >0 while blinking after a hit
  double _popT = 0; // >0 while doing the evolve pop
  double _bobPhase = 0;
  double _poseT = 0; // time since the pose changed

  final _paint = Paint()..filterQuality = FilterQuality.medium;
  static final _shadow = Paint()..color = const Color(0x55000000);
  final _bubble = Paint();
  final _bubbleRim = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6;
  static final _hurtFilter = ColorFilter.mode(const Color(0xFFFF3B30).withValues(alpha: 0.6), BlendMode.srcATop);

  bool get isSwitching => _switchT < 1;

  /// Lane the lion counts as being in for collisions.
  int get collisionLane => laneX < 0 ? 0 : 1;

  /// Seconds of shield invincibility left; drives the bubble. Set by the game.
  double shieldGlow = 0;

  bool get isRunningPose => pose == LionPose.run;

  /// Returns false when the move was ignored.
  bool moveTo(int newLane) {
    if (_locked || pose != LionPose.run || newLane == lane) return false;
    lane = newLane;
    _slideTo(Perspective.laneToX(newLane));
    return true;
  }

  /// Finish line: glide to the road centre and ignore further input.
  void lockToCenter() {
    _locked = true;
    _slideTo(0);
  }

  void _slideTo(double x) {
    _fromX = laneX;
    _toX = x;
    _switchT = 0;
  }

  void setStage(EvolutionStage s, {bool animate = true}) {
    if (s == stage) return;
    stage = s;
    if (animate) _popT = 1;
  }

  void setPose(LionPose p) {
    pose = p;
    _poseT = 0;
  }

  void hurt() => _hurtT = 0.8;

  void collapse() => setPose(LionPose.knockedOut);

  Sprite get _sprite => switch (pose) {
        LionPose.knockedOut => _knockedOut,
        // Winning: turn round to face the camera. A Gladiator raises its sword.
        LionPose.celebrate => stage == EvolutionStage.gladiator ? _victory : _front[stage]!,
        _ => _run[stage]!.getSprite(),
      };

  @override
  void update(double dt) {
    final p = game.perspective;
    _poseT += dt;
    if (_switchT < 1) {
      _switchT = math.min(1, _switchT + dt / game.session.laneSwitchSeconds);
      laneX = _fromX + (_toX - _fromX) * Curves.easeOutCubic.transform(_switchT);
    }
    _hurtT = math.max(0, _hurtT - dt);
    _popT = math.max(0, _popT - dt / 0.45);

    if (pose == LionPose.run && game.isRunning) {
      final speedFactor = game.speed / 14 * game.speedFactor;
      _run[stage]!.update(dt * speedFactor);
      _bobPhase += dt * 14 * speedFactor;
    } else if (pose == LionPose.celebrate) {
      _bobPhase += dt * 9;
    }

    final h = _heights[stage]!;
    final sprite = _sprite;
    final aspect = sprite.srcSize.x / sprite.srcSize.y;
    final pop = _popT > 0 ? 1 + 0.35 * math.sin(_popT * math.pi) : 1.0;
    size = switch (pose) {
      LionPose.knockedOut => Vector2(h * 1.3, h * 1.3 / aspect),
      LionPose.celebrate => Vector2(h * 1.05 * aspect, h * 1.05),
      _ => Vector2(h * aspect, h) * pop,
    };
    position = Vector2(p.xAt(laneX, 0), p.playerY);
    // Lean into the lane change.
    angle = isSwitching ? (_toX - _fromX) * 0.08 * math.sin(_switchT * math.pi) : 0;
  }

  @override
  void render(Canvas canvas) {
    if (pose == LionPose.hidden) return;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.x / 2, size.y - 4), width: size.x * 0.75, height: size.x * 0.16),
      _shadow,
    );
    final bob = switch (pose) {
      LionPose.run => -math.sin(_bobPhase).abs() * 10,
      LionPose.celebrate => -math.sin(_bobPhase).abs() * 40, // victory hops
      _ => 0.0,
    };
    final blink = _hurtT > 0 && (_hurtT * 12).floor().isEven;
    final fadeIn = pose == LionPose.knockedOut ? (0.4 + _poseT / 0.5 * 0.6).clamp(0.0, 1.0) : 1.0;
    _paint
      ..colorFilter = blink ? _hurtFilter : null
      ..color = Color.fromRGBO(255, 255, 255, fadeIn);
    canvas.save();
    canvas.translate(0, bob);
    _sprite.render(canvas, size: size, overridePaint: _paint);
    if (shieldGlow > 0) _renderBubble(canvas);
    canvas.restore();
  }

  /// Blue bubble while the shield's invincibility lasts; flickers in the last 0.3s.
  void _renderBubble(Canvas canvas) {
    if (shieldGlow < 0.3 && (shieldGlow * 20).floor().isEven) return;
    final r = size.y * 0.55 * (1 + 0.03 * math.sin(_poseT * 18 + shieldGlow * 10));
    final c = Offset(size.x / 2, size.y * 0.52);
    _bubble.shader = Gradient.radial(c, r, [
      const Color(0x002E9BFF),
      const Color(0x332E9BFF),
      const Color(0x888FD3FF),
    ], [0, 0.75, 1]);
    _bubbleRim.color = const Color(0xCCFFFFFF);
    canvas
      ..drawCircle(c, r, _bubble)
      ..drawArc(Rect.fromCircle(center: c, radius: r * 0.9), -2.6, 0.9, false, _bubbleRim);
  }
}
