import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../core/theme/app_colors.dart';
import '../lion_game.dart';
import '../world/perspective.dart';

enum BossPose { idle, hidden, defeated, taunt }

/// The chapter boss waiting past the finish line, with its power shown on a badge above it.
class BossComponent extends PositionComponent with HasGameReference<LionGame> {
  BossComponent({required this.worldZ, required this.power, required this.spritePath})
      : super(anchor: Anchor.bottomCenter);

  final double worldZ;
  final int power;
  final String spritePath;

  static const _height = 420.0;

  late final Sprite _sprite = Sprite(game.images.fromCache(spritePath));
  final _paint = Paint()..filterQuality = FilterQuality.medium;
  static final _shadow = Paint()..color = const Color(0x55000000);
  late final TextPainter _label = _text('$power', 44, AppColors.white);
  late final TextPainter _labelStroke = _text('$power', 44, null);
  late final TextPainter _caption = _text('BOSS', 22, AppColors.gold);
  late final TextPainter _captionStroke = _text('BOSS', 22, null);

  BossPose pose = BossPose.idle;
  double _poseT = 0;

  double get z => worldZ - game.distance;

  void setPose(BossPose p) {
    pose = p;
    _poseT = 0;
  }

  static TextPainter _text(String s, double size, Color? color) => TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            color: color,
            foreground: color == null
                ? (Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = size * 0.18
                  ..strokeJoin = StrokeJoin.round
                  ..color = AppColors.outline)
                : null,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  void update(double dt) {
    _poseT += dt;
    final p = game.perspective;
    final zz = z;
    final s = p.scaleAt(zz);
    final aspect = _sprite.srcSize.x / _sprite.srcSize.y;
    size = Vector2(_height * aspect, _height) * s;
    position = Vector2(Perspective.centerX, p.yAt(zz));
    priority = (10000 - zz * 40).round();

    switch (pose) {
      case BossPose.idle:
        // Breathing and a little menace.
        scale = Vector2(1 + 0.02 * math.sin(game.time * 3), 1 - 0.02 * math.sin(game.time * 3));
        angle = 0;
      case BossPose.taunt:
        final t = math.sin(_poseT * 10).abs();
        scale = Vector2.all(1 + 0.08 * t);
        angle = 0;
      case BossPose.defeated:
        // Launched up and away, spinning.
        final t = _poseT;
        position += Vector2(260 * t, -900 * t + 900 * t * t);
        angle = t * 8;
        scale = Vector2.all(math.max(0.2, 1 - t * 0.5));
      case BossPose.hidden:
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    if (pose == BossPose.hidden) return;
    if (pose == BossPose.defeated && _poseT > 1.4) return;
    final zz = z;
    final alpha = ((Perspective.maxZ - zz) / 18).clamp(0.0, 1.0);
    if (pose != BossPose.defeated) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(size.x / 2, size.y - 4), width: size.x * 0.8, height: size.x * 0.15),
        _shadow,
      );
    }
    _paint.color = Color.fromRGBO(255, 255, 255, alpha);
    _sprite.render(canvas, size: size, overridePaint: _paint);

    if (pose == BossPose.idle || pose == BossPose.taunt) _renderBadge(canvas, alpha);
  }

  /// Red power badge above the boss's head. Kept readable when far away via a minimum scale.
  void _renderBadge(Canvas canvas, double alpha) {
    final s = math.max(game.perspective.scaleAt(z), 0.35) / scale.x;
    canvas.save();
    canvas.translate(size.x / 2, -12 * s);
    canvas.scale(s);
    final w = math.max(_label.width, _caption.width) + 44;
    const h = 86.0;
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, -h / 2), width: w, height: h),
        const Radius.circular(20));
    canvas
      ..saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, alpha))
      ..drawRRect(r.shift(const Offset(0, 6)), Paint()..color = AppColors.redShade)
      ..drawRRect(r, Paint()..color = AppColors.red)
      ..drawRRect(
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..color = AppColors.outline);
    _captionStroke.paint(canvas, Offset(-_caption.width / 2, -h + 4));
    _caption.paint(canvas, Offset(-_caption.width / 2, -h + 4));
    _labelStroke.paint(canvas, Offset(-_label.width / 2, -h + 28));
    _label.paint(canvas, Offset(-_label.width / 2, -h + 28));
    canvas
      ..restore()
      ..restore();
  }
}
