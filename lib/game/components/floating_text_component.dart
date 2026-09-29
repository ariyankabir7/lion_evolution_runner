import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Outlined text that rises and fades, for "+20", "-30", "EVOLVED!" and similar.
class FloatingTextComponent extends PositionComponent {
  FloatingTextComponent(
    String text, {
    required Vector2 position,
    required Color color,
    double fontSize = 56,
    this.duration = 0.9,
    this.rise = 140,
  }) : super(position: position, anchor: Anchor.center, priority: 30000) {
    _fill = _painter(text, fontSize, TextStyle(color: color));
    _stroke = _painter(
      text,
      fontSize,
      TextStyle(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = fontSize * 0.16
          ..strokeJoin = StrokeJoin.round
          ..color = AppColors.outline,
      ),
    );
    size = Vector2(_fill.width, _fill.height);
    _start = position.clone();
  }

  final double duration;
  final double rise;
  late final TextPainter _fill;
  late final TextPainter _stroke;
  late final Vector2 _start;
  double _t = 0;

  static TextPainter _painter(String text, double size, TextStyle style) => TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(fontSize: size, fontFamily: AppTheme.fontFamily),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  void update(double dt) {
    _t += dt / duration;
    if (_t >= 1) {
      removeFromParent();
      return;
    }
    final ease = 1 - (1 - _t) * (1 - _t);
    position = _start - Vector2(0, rise * ease);
    // Pop in, then hold.
    scale = Vector2.all(_t < 0.15 ? 0.6 + _t / 0.15 * 0.5 : 1.1 - (_t - 0.15) * 0.12);
  }

  @override
  void render(Canvas canvas) {
    final alpha = _t < 0.7 ? 1.0 : 1 - (_t - 0.7) / 0.3;
    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
    _stroke.paint(canvas, Offset.zero);
    _fill.paint(canvas, Offset.zero);
    canvas.restore();
  }
}
