import 'dart:ui';

import 'package:flame/components.dart';

import '../lion_game.dart';

/// A one-shot sprite (sparkle, burst, explosion) that scales up and fades out.
class BurstEffect extends PositionComponent with HasGameReference<LionGame> {
  BurstEffect(
    this.spritePath, {
    required Vector2 position,
    this.startSize = 120,
    this.endSize = 260,
    this.duration = 0.45,
    this.spin = 0,
    super.priority = 25000,
  }) : super(position: position, anchor: Anchor.center);

  final String spritePath;
  final double startSize;
  final double endSize;
  final double duration;
  final double spin;

  late final Sprite _sprite = Sprite(game.images.fromCache(spritePath));
  final _paint = Paint()..filterQuality = FilterQuality.medium;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt / duration;
    if (_t >= 1) {
      removeFromParent();
      return;
    }
    final e = 1 - (1 - _t) * (1 - _t);
    final s = startSize + (endSize - startSize) * e;
    size = Vector2(s, s * _sprite.srcSize.y / _sprite.srcSize.x);
    angle += spin * dt;
    _paint.color = Color.fromRGBO(255, 255, 255, _t < 0.6 ? 1 : 1 - (_t - 0.6) / 0.4);
  }

  @override
  void render(Canvas canvas) => _sprite.render(canvas, size: size, overridePaint: _paint);
}

/// Full-screen colour flash (red when hurt, gold when evolving).
class ScreenFlash extends Component with HasGameReference<LionGame> {
  ScreenFlash(this.color, {this.duration = 0.35, this.peak = 0.35}) : super(priority: 40000);

  final Color color;
  final double duration;
  final double peak;
  double _t = 0;
  final _paint = Paint();

  @override
  void update(double dt) {
    _t += dt / duration;
    if (_t >= 1) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    _paint.color = color.withValues(alpha: peak * (1 - _t).clamp(0, 1));
    canvas.drawRect(Rect.fromLTWH(0, 0, 720, game.perspective.height), _paint);
  }
}
