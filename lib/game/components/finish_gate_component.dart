import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/theme/app_colors.dart';
import '../lion_game.dart';
import '../world/perspective.dart';

/// Wooden finish arch with vines and a checkered banner, drawn in code and coloured by the chapter.
class FinishGateComponent extends Component with HasGameReference<LionGame> {
  FinishGateComponent(this.worldZ);

  /// Distance of the gate from the start line.
  final double worldZ;

  static const _postHeight = 470.0;
  static const _bannerHeight = 76.0;

  final _fill = Paint()..isAntiAlias = true;
  final _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round
    ..color = AppColors.outline;

  late final _pal = game.chapter.palette;

  double get z => worldZ - game.distance;

  @override
  void update(double dt) {
    final zz = z;
    if (zz < -Perspective.cameraDepth * 0.7) {
      removeFromParent();
      return;
    }
    priority = (10000 - zz * 40).round();
  }

  @override
  void render(Canvas canvas) {
    final zz = z;
    if (zz > Perspective.maxZ) return;
    final p = game.perspective;
    final s = p.scaleAt(zz);
    final baseY = p.yAt(zz);
    final half = p.roadHalfAt(zz) * 1.2;
    const cx = Perspective.centerX;
    final postW = 40 * s;
    final postH = _postHeight * s;
    final alpha = ((Perspective.maxZ - zz) / 18).clamp(0.0, 1.0);
    _stroke.strokeWidth = (5 * s).clamp(1.0, 6.0);

    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, alpha));

    // Posts.
    for (final x in [cx - half, cx + half]) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - postW / 2, baseY - postH, postW, postH),
        Radius.circular(8 * s),
      );
      _fill.color = AppColors.wood;
      canvas
        ..drawRRect(r, _fill)
        ..drawRRect(r, _stroke);
      // Vine leaves climbing the post.
      for (var i = 0; i < 5; i++) {
        final ly = baseY - postH * (0.15 + i * 0.17);
        final lx = x + (i.isEven ? -1 : 1) * postW * 0.45;
        _leaf(canvas, Offset(lx, ly), 26 * s, i.isEven ? _pal.foliage : _pal.foliageDark);
      }
    }

    // Checkered banner.
    final top = baseY - postH - _bannerHeight * s * 0.35;
    final bh = _bannerHeight * s;
    final left = cx - half - postW * 0.9, right = cx + half + postW * 0.9;
    final banner = Rect.fromLTRB(left, top, right, top + bh);
    final rows = 2;
    final sq = bh / rows;
    final cols = ((right - left) / sq).ceil();
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(banner, Radius.circular(10 * s)));
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        _fill.color = (r + c).isEven ? const Color(0xFF222222) : const Color(0xFFFFFFFF);
        canvas.drawRect(Rect.fromLTWH(left + c * sq, top + r * sq, sq + 0.5, sq + 0.5), _fill);
      }
    }
    canvas.restore();
    canvas.drawRRect(RRect.fromRectAndRadius(banner, Radius.circular(10 * s)), _stroke);
    // Leaf clumps on the banner ends.
    for (final x in [left, right]) {
      _leaf(canvas, Offset(x, top), 40 * s, _pal.foliage);
      _leaf(canvas, Offset(x + (x == left ? 18 : -18) * s, top + bh), 34 * s, _pal.foliageDark);
    }
    canvas.restore();
  }

  void _leaf(Canvas canvas, Offset c, double r, Color color) {
    final path = Path()
      ..moveTo(c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy - r * 0.9, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy + r * 0.9, c.dx - r, c.dy)
      ..close();
    _fill.color = color;
    canvas
      ..drawPath(path, _fill)
      ..drawPath(path, _stroke);
  }
}
