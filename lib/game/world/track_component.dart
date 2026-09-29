import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/theme/app_colors.dart';
import '../lion_game.dart';
import 'perspective.dart';

/// Draws the whole backdrop in code: sky, sun, hills, striped grass, asphalt road, scrolling curbs
/// and centre dashes. All colours come from the chapter palette, so every chapter re-themes for free.
class TrackComponent extends Component with HasGameReference<LionGame> {
  TrackComponent() : super(priority: -1000);

  static const _stripe = 5.0; // world units per curb/grass stripe

  late final _pal = game.chapter.palette;
  late final Color _asphalt = Color.lerp(const Color(0xFF4A4D58), _pal.nearHills, 0.12)!;
  late final Color _asphaltAlt = Color.lerp(_asphalt, const Color(0xFFFFFFFF), 0.04)!;
  late final Color _grassA = _pal.foliage;
  late final Color _grassB = Color.lerp(_pal.foliage, _pal.foliageDark, 0.35)!;
  late final Color _curbA = _pal.accent;
  static const _curbB = Color(0xFFF7F3EA);
  static const _dash = Color(0xFFE8FDFF);

  final _paint = Paint()..isAntiAlias = true;
  final _path = Path();
  late final _dashGlow = Paint()
    ..color = const Color(0xFF6FF3FF).withValues(alpha: 0.55)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  final _outline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = AppColors.outline.withValues(alpha: 0.55);

  Picture? _sky;
  double _skyForHeight = -1;

  Perspective get _p => game.perspective;

  @override
  void render(Canvas canvas) {
    final h = _p.height;
    if (_sky == null || _skyForHeight != h) {
      _sky = _buildSky(h);
      _skyForHeight = h;
    }
    canvas.drawPicture(_sky!);
    _drawGround(canvas, h);
  }

  void _drawGround(Canvas canvas, double h) {
    final p = _p;
    final dist = game.distance;
    final zNear = p.zAtY(h + 4);
    final kFar = ((dist + Perspective.maxZ) / _stripe).floor();
    final kNear = ((dist + zNear) / _stripe).floor();

    // Far-away ground under the haze.
    _paint.color = _grassB;
    canvas.drawRect(Rect.fromLTRB(0, p.horizonY, Perspective.width, p.yAt(Perspective.maxZ) + 1), _paint);

    for (var k = kFar; k >= kNear; k--) {
      final z0 = (k * _stripe - dist).clamp(zNear, Perspective.maxZ);
      final z1 = ((k + 1) * _stripe - dist).clamp(zNear, Perspective.maxZ);
      if (z1 <= z0) continue;
      final yTop = p.yAt(z1);
      final yBot = p.yAt(z0) + 0.8; // overlap a hair to hide seams
      final even = k.isEven;

      // Grass band.
      _paint.color = even ? _grassA : _grassB;
      canvas.drawRect(Rect.fromLTRB(0, yTop, Perspective.width, yBot), _paint);

      final rTop = p.roadHalfAt(z1), rBot = p.roadHalfAt(z0);
      const cx = Perspective.centerX;

      // Curbs (slightly wider than the road).
      _paint.color = even ? _curbA : _curbB;
      _quad(canvas, cx - rTop * 1.1, cx + rTop * 1.1, cx - rBot * 1.1, cx + rBot * 1.1, yTop, yBot);

      // Asphalt.
      _paint.color = even ? _asphalt : _asphaltAlt;
      _quad(canvas, cx - rTop, cx + rTop, cx - rBot, cx + rBot, yTop, yBot);

      // Centre dash on every other stripe, 60% of its length.
      if (even) {
        final zd = z0 + (z1 - z0) * 0.4;
        final yd = p.yAt(zd);
        final wTop = 7 * p.scaleAt(zd), wBot = 7 * p.scaleAt(z0);
        _path
          ..reset()
          ..moveTo(cx - wTop, yd)
          ..lineTo(cx + wTop, yd)
          ..lineTo(cx + wBot, yBot)
          ..lineTo(cx - wBot, yBot)
          ..close();
        canvas.drawPath(_path, _dashGlow);
        _paint.color = _dash;
        canvas.drawPath(_path, _paint);
      }
    }

    // Road edge outlines.
    final zTop = Perspective.maxZ;
    final yT = p.yAt(zTop), yB = h + 4;
    for (final sign in const [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(Perspective.centerX + sign * p.roadHalfAt(zTop) * 1.1, yT),
        Offset(Perspective.centerX + sign * p.roadHalfAt(zNear) * 1.1, yB),
        _outline,
      );
    }

    // Haze at the horizon hides pop-in.
    final hazeTop = p.horizonY;
    final hazeBot = p.horizonY + (p.playerY - p.horizonY) * 0.22;
    _paint.shader = Gradient.linear(
      Offset(0, hazeTop),
      Offset(0, hazeBot),
      [_pal.skyBottom.withValues(alpha: 0.85), _pal.skyBottom.withValues(alpha: 0)],
    );
    canvas.drawRect(Rect.fromLTRB(0, hazeTop, Perspective.width, hazeBot), _paint);
    _paint.shader = null;
  }

  void _quad(Canvas c, double tl, double tr, double bl, double br, double yTop, double yBot) {
    _path
      ..reset()
      ..moveTo(tl, yTop)
      ..lineTo(tr, yTop)
      ..lineTo(br, yBot)
      ..lineTo(bl, yBot)
      ..close();
    c.drawPath(_path, _paint);
  }

  Picture _buildSky(double h) {
    final rec = PictureRecorder();
    final c = Canvas(rec);
    final hy = _p.horizonY;
    const w = Perspective.width;
    final paint = Paint()
      ..shader = Gradient.linear(Offset.zero, Offset(0, hy), [_pal.skyTop, _pal.skyBottom]);
    c.drawRect(Rect.fromLTWH(0, 0, w, hy + 2), paint);

    // Sun with glow.
    final sun = Offset(w * 0.5, hy - 70);
    c.drawCircle(
      sun,
      170,
      Paint()..shader = Gradient.radial(sun, 170, [_pal.sun.withValues(alpha: 0.7), _pal.sun.withValues(alpha: 0)]),
    );
    c.drawCircle(sun, 52, Paint()..color = _pal.sun);

    // Clouds.
    final cloud = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9);
    for (final (x, y, s) in [(110.0, hy * 0.28, 1.0), (560.0, hy * 0.18, 0.8), (430.0, hy * 0.5, 0.55)]) {
      c
        ..drawOval(Rect.fromCenter(center: Offset(x, y + 18 * s), width: 180 * s, height: 50 * s), cloud)
        ..drawCircle(Offset(x - 38 * s, y + 6 * s), 32 * s, cloud)
        ..drawCircle(Offset(x + 8 * s, y - 8 * s), 44 * s, cloud)
        ..drawCircle(Offset(x + 52 * s, y + 10 * s), 28 * s, cloud);
    }

    // Two hill layers sitting on the horizon.
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AppColors.outline.withValues(alpha: 0.3);
    final far = Path()
      ..moveTo(0, hy - 60)
      ..cubicTo(120, hy - 130, 230, hy - 90, 330, hy - 70)
      ..cubicTo(450, hy - 50, 560, hy - 140, w, hy - 80)
      ..lineTo(w, hy + 2)
      ..lineTo(0, hy + 2)
      ..close();
    c.drawPath(far, Paint()..color = _pal.farHills);
    final near = Path()
      ..moveTo(0, hy - 25)
      ..cubicTo(90, hy - 60, 200, hy - 30, 300, hy - 18)
      ..cubicTo(420, hy - 5, 520, hy - 55, w, hy - 30)
      ..lineTo(w, hy + 2)
      ..lineTo(0, hy + 2)
      ..close();
    c
      ..drawPath(near, Paint()..color = _pal.nearHills)
      ..drawPath(near, outline);
    return rec.endRecording();
  }
}
