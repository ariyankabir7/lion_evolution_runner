import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Cartoon text: a thick dark outline, an optional drop, and a solid or gradient fill.
class StrokedText extends StatelessWidget {
  const StrokedText(
    this.text, {
    super.key,
    this.size = 28,
    this.color = AppColors.white,
    this.gradient,
    this.strokeColor = AppColors.outline,
    this.strokeWidth,
    this.drop = true,
    this.align = TextAlign.center,
    this.letterSpacing,
  });

  final String text;
  final double size;
  final Color color;
  final Gradient? gradient;
  final Color strokeColor;
  final double? strokeWidth;
  final bool drop;
  final TextAlign align;
  final double? letterSpacing;

  @override
  Widget build(BuildContext context) {
    final stroke = strokeWidth ?? (size * 0.16).clamp(2.0, 12.0);
    final base = AppTheme.display.copyWith(fontSize: size, letterSpacing: letterSpacing);
    final outlined = Text(
      text,
      textAlign: align,
      style: base.copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeJoin = StrokeJoin.round
          ..color = strokeColor,
      ),
    );
    Widget fill = Text(text, textAlign: align, style: base.copyWith(color: color));
    if (gradient != null) {
      fill = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => gradient!.createShader(bounds),
        child: fill,
      );
    }
    return Stack(
      children: [
        if (drop)
          Transform.translate(
            offset: Offset(0, stroke * 0.55),
            child: outlined,
          ),
        outlined,
        fill,
      ],
    );
  }
}
