import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/theme/app_colors.dart';
import '../../models/chapter.dart';
import '../lion_game.dart';
import 'perspective.dart';

/// Trees, bushes, rocks and other props lining both sides of the road. Each chapter gets its own mix,
/// all drawn in code from the chapter palette and baked into images once per run. Placement comes from
/// a hash of the slot index, so the scenery is stable while it scrolls.
class RoadsideDecor extends Component with HasGameReference<LionGame> {
  RoadsideDecor() : super(priority: -900);

  static const _spacing = 6.0; // world units between prop slots on each side
  static const _skipPercent = 30; // share of empty slots

  late final List<_PropArt> _arts;
  final _paint = Paint()..filterQuality = FilterQuality.medium;
  final _shadow = Paint();

  @override
  void onLoad() => _arts = _PropPainter(game.chapter).build();

  @override
  void onRemove() {
    for (final a in _arts.toSet()) {
      a.image.dispose();
    }
    super.onRemove();
  }

  static int _hash(int k, int side) {
    var h = (k * 73856093) ^ (side > 0 ? 19349663 : 83492791);
    h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff;
    return h ^ (h >> 16);
  }

  @override
  void render(Canvas canvas) {
    final p = game.perspective;
    final dist = game.distance;
    final kFar = ((dist + Perspective.maxZ) / _spacing).floor();
    final kNear = ((dist - Perspective.cameraDepth * 0.5) / _spacing).ceil();
    for (var k = kFar; k >= kNear; k--) {
      final z = k * _spacing - dist;
      if (z > Perspective.maxZ) continue;
      final s = p.scaleAt(z);
      final baseY = p.yAt(z);
      final fade = ((Perspective.maxZ - z) / 18).clamp(0.0, 1.0);
      for (final side in const [-1, 1]) {
        final h = _hash(k, side);
        if (h % 100 < _skipPercent) continue;
        final art = _arts[(h ~/ 100) % _arts.length];
        final gap = ((h ~/ 10000) % 100) / 100;
        final w = art.width * s, ht = art.height * s;
        final x = Perspective.centerX + side * (p.roadHalfAt(z) * 1.12 + (art.width * 0.5 + 16 + gap * 260) * s);
        if (x + w / 2 < 0 || x - w / 2 > Perspective.width) continue;
        final dst = Rect.fromLTWH(x - w / 2, baseY - ht, w, ht);
        _paint.color = Color.fromRGBO(255, 255, 255, fade);
        final flip = (h >> 20).isOdd;
        if (flip) {
          canvas
            ..save()
            ..translate(x, 0)
            ..scale(-1, 1)
            ..translate(-x, 0);
        }
        // Soft ground shadow, then the prop.
        canvas
          ..drawOval(
            Rect.fromCenter(center: Offset(x, baseY - 2 * s), width: w * 0.8, height: w * 0.14),
            _shadow..color = Color.fromRGBO(0, 0, 0, 0.18 * fade),
          )
          ..drawImageRect(art.image, art.src, dst, _paint);
        if (flip) canvas.restore();
      }
    }
  }
}

class _PropArt {
  _PropArt(this.image, this.width, this.height)
      : src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

  final Image image;

  /// Size in world pixels when level with the lion.
  final double width;
  final double height;
  final Rect src;
}

enum _Prop { roundTree, acacia, pine, palm, cactus, bush, rock, tuft, flowers, column, bamboo, mushroom, deadTree, reeds }

class _PropPainter {
  _PropPainter(this.chapter) : pal = chapter.palette;

  final Chapter chapter;
  final ChapterPalette pal;

  /// Texture pixels per world pixel. Props never get much bigger than this on screen.
  static const _res = 0.7;

  static const _mix = <String, Map<_Prop, int>>{
    'savanna': {_Prop.acacia: 3, _Prop.bush: 3, _Prop.tuft: 3, _Prop.rock: 1},
    'jungle': {_Prop.palm: 3, _Prop.roundTree: 2, _Prop.bush: 3, _Prop.flowers: 2},
    'desert': {_Prop.cactus: 4, _Prop.rock: 3, _Prop.tuft: 1, _Prop.deadTree: 1},
    'swamp': {_Prop.deadTree: 2, _Prop.reeds: 4, _Prop.bush: 2, _Prop.mushroom: 1},
    'snow': {_Prop.pine: 5, _Prop.rock: 2, _Prop.bush: 1},
    'bamboo': {_Prop.bamboo: 5, _Prop.bush: 2, _Prop.rock: 1},
    'volcano': {_Prop.deadTree: 3, _Prop.rock: 4, _Prop.tuft: 1},
    'night': {_Prop.pine: 3, _Prop.mushroom: 3, _Prop.bush: 2},
    'ruins': {_Prop.column: 3, _Prop.bush: 3, _Prop.rock: 2, _Prop.roundTree: 1},
    'colosseum': {_Prop.column: 5, _Prop.bush: 2, _Prop.flowers: 1},
  };

  static const _size = <_Prop, (double, double)>{
    _Prop.roundTree: (260, 340),
    _Prop.acacia: (330, 300),
    _Prop.pine: (220, 360),
    _Prop.palm: (280, 380),
    _Prop.cactus: (160, 250),
    _Prop.bush: (210, 130),
    _Prop.rock: (170, 110),
    _Prop.tuft: (130, 80),
    _Prop.flowers: (150, 100),
    _Prop.column: (110, 330),
    _Prop.bamboo: (160, 440),
    _Prop.mushroom: (140, 140),
    _Prop.deadTree: (230, 320),
    _Prop.reeds: (140, 190),
  };

  /// One entry per weight point, so a uniform pick respects the weights.
  List<_PropArt> build() {
    final mix = _mix[chapter.id] ?? _mix['savanna']!;
    final out = <_PropArt>[];
    for (final e in mix.entries) {
      final art = _bake(e.key);
      for (var i = 0; i < e.value; i++) {
        out.add(art);
      }
    }
    return out;
  }

  _PropArt _bake(_Prop prop) {
    final (w, h) = _size[prop]!;
    final rec = PictureRecorder();
    final c = Canvas(rec)..scale(_res);
    _paint(c, prop, w, h);
    final image = rec.endRecording().toImageSync((w * _res).ceil(), (h * _res).ceil());
    return _PropArt(image, w, h);
  }

  // ---- drawing -------------------------------------------------------------------------------

  static const _trunk = Color(0xFF8B5A2B);
  static const _stone = Color(0xFFEDE3CC);
  late final _leaf = pal.foliageDark;
  late final _leafLight = Color.lerp(pal.foliageDark, pal.foliage, 0.6)!;
  late final _rock = Color.lerp(pal.nearHills, const Color(0xFF8D8A86), 0.55)!;
  late final _snowy = chapter.id == 'snow';
  late final _glow = chapter.id == 'night';

  final _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = AppColors.outline;

  void _fill(Canvas c, Path path, Color color) {
    c
      ..drawPath(path, Paint()..color = color)
      ..drawPath(path, _stroke);
  }

  Path _circles(List<(double, double, double)> cs) {
    var p = Path()..addOval(Rect.fromCircle(center: Offset(cs.first.$1, cs.first.$2), radius: cs.first.$3));
    for (final (x, y, r) in cs.skip(1)) {
      p = Path.combine(PathOperation.union, p, Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r)));
    }
    return p;
  }

  void _highlight(Canvas c, Offset at, double r, Color color) =>
      c.drawCircle(at, r, Paint()..color = color.withValues(alpha: 0.55));

  void _paint(Canvas c, _Prop prop, double w, double h) {
    switch (prop) {
      case _Prop.roundTree:
        _fill(c, Path()..addRect(Rect.fromLTRB(w * 0.44, h * 0.5, w * 0.56, h - 4)), _trunk);
        _fill(c, _circles([(w * 0.5, h * 0.33, w * 0.34), (w * 0.28, h * 0.48, w * 0.22), (w * 0.72, h * 0.48, w * 0.22)]), _leaf);
        _highlight(c, Offset(w * 0.4, h * 0.25), w * 0.12, _leafLight);
      case _Prop.acacia:
        final trunk = Path()
          ..moveTo(w * 0.45, h - 4)
          ..lineTo(w * 0.48, h * 0.55)
          ..lineTo(w * 0.3, h * 0.3)
          ..lineTo(w * 0.36, h * 0.28)
          ..lineTo(w * 0.52, h * 0.48)
          ..lineTo(w * 0.66, h * 0.28)
          ..lineTo(w * 0.72, h * 0.3)
          ..lineTo(w * 0.57, h * 0.56)
          ..lineTo(w * 0.57, h - 4)
          ..close();
        _fill(c, trunk, _trunk);
        final canopy = Path.combine(
          PathOperation.union,
          Path()..addOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.26), width: w * 0.94, height: h * 0.22)),
          Path()..addOval(Rect.fromCenter(center: Offset(w * 0.52, h * 0.16), width: w * 0.55, height: h * 0.16)),
        );
        _fill(c, canopy, _leaf);
        _highlight(c, Offset(w * 0.42, h * 0.14), w * 0.08, _leafLight);
      case _Prop.pine:
        _fill(c, Path()..addRect(Rect.fromLTRB(w * 0.44, h * 0.8, w * 0.56, h - 4)), _trunk);
        for (final (top, bot, half) in [(0.44, 0.84, 0.48), (0.22, 0.6, 0.38), (0.04, 0.38, 0.27)]) {
          final tri = Path()
            ..moveTo(w * 0.5, h * top)
            ..lineTo(w * (0.5 + half), h * bot)
            ..lineTo(w * (0.5 - half), h * bot)
            ..close();
          _fill(c, tri, _leaf);
          if (_snowy) {
            final cap = Path()
              ..moveTo(w * 0.5, h * top)
              ..lineTo(w * (0.5 + half * 0.45), h * (top + (bot - top) * 0.45))
              ..lineTo(w * 0.5, h * (top + (bot - top) * 0.36))
              ..lineTo(w * (0.5 - half * 0.45), h * (top + (bot - top) * 0.45))
              ..close();
            _fill(c, cap, AppColors.white);
          }
        }
      case _Prop.palm:
        final trunk = Path()
          ..moveTo(w * 0.42, h - 4)
          ..quadraticBezierTo(w * 0.42, h * 0.5, w * 0.56, h * 0.24)
          ..lineTo(w * 0.62, h * 0.26)
          ..quadraticBezierTo(w * 0.52, h * 0.5, w * 0.56, h - 4)
          ..close();
        _fill(c, trunk, _trunk);
        final top = Offset(w * 0.59, h * 0.24);
        for (final a in [-2.7, -2.1, -1.5, -0.9, -0.35, 0.3, 2.9]) {
          c
            ..save()
            ..translate(top.dx, top.dy)
            ..rotate(a);
          _fill(c, Path()..addOval(Rect.fromLTWH(0, -w * 0.07, w * 0.44, w * 0.14)), _leaf);
          c.restore();
        }
        _fill(c, _circles([(top.dx, top.dy + 6, w * 0.05)]), _trunk);
      case _Prop.cactus:
        final body = Path()
          ..addRRect(RRect.fromLTRBR(w * 0.36, h * 0.06, w * 0.64, h - 4, Radius.circular(w * 0.14)))
          ..addRRect(RRect.fromLTRBR(w * 0.08, h * 0.32, w * 0.3, h * 0.62, Radius.circular(w * 0.11)))
          ..addRRect(RRect.fromLTRBR(w * 0.7, h * 0.22, w * 0.92, h * 0.5, Radius.circular(w * 0.11)))
          ..addRect(Rect.fromLTRB(w * 0.2, h * 0.52, w * 0.4, h * 0.62))
          ..addRect(Rect.fromLTRB(w * 0.6, h * 0.42, w * 0.8, h * 0.5));
        final merged = Path.combine(PathOperation.union, body, Path());
        _fill(c, merged, Color.lerp(pal.foliage, const Color(0xFF2E7D32), 0.4)!);
        c.drawLine(Offset(w * 0.5, h * 0.14), Offset(w * 0.5, h * 0.9),
            Paint()..color = _leafLight.withValues(alpha: 0.6)..strokeWidth = 6..strokeCap = StrokeCap.round);
      case _Prop.bush:
        final path = Path.combine(
          PathOperation.intersect,
          _circles([(w * 0.3, h * 0.62, h * 0.36), (w * 0.52, h * 0.45, h * 0.44), (w * 0.74, h * 0.62, h * 0.34)]),
          Path()..addRect(Rect.fromLTRB(0, 0, w, h - 4)),
        );
        _fill(c, path, _leaf);
        _highlight(c, Offset(w * 0.45, h * 0.32), h * 0.13, _leafLight);
      case _Prop.rock:
        final path = Path()
          ..moveTo(w * 0.06, h - 4)
          ..lineTo(w * 0.14, h * 0.45)
          ..lineTo(w * 0.38, h * 0.12)
          ..lineTo(w * 0.7, h * 0.18)
          ..lineTo(w * 0.92, h * 0.55)
          ..lineTo(w * 0.95, h - 4)
          ..close();
        _fill(c, path, _rock);
        final shine = Path()
          ..moveTo(w * 0.24, h * 0.45)
          ..lineTo(w * 0.4, h * 0.22)
          ..lineTo(w * 0.52, h * 0.26)
          ..lineTo(w * 0.34, h * 0.5)
          ..close();
        c.drawPath(shine, Paint()..color = const Color(0x55FFFFFF));
        if (_snowy) _fill(c, _circles([(w * 0.5, h * 0.2, w * 0.14), (w * 0.34, h * 0.24, w * 0.1)]), AppColors.white);
      case _Prop.tuft:
        for (var i = 0; i < 6; i++) {
          final x = w * (0.18 + i * 0.13);
          final blade = Path()
            ..moveTo(x - w * 0.07, h - 4)
            ..quadraticBezierTo(x, h * 0.5, x + (i.isEven ? -1 : 1) * w * 0.08, h * (0.05 + (i % 3) * 0.12))
            ..quadraticBezierTo(x + w * 0.02, h * 0.55, x + w * 0.07, h - 4)
            ..close();
          _fill(c, blade, i.isEven ? _leaf : Color.lerp(pal.ground, _leaf, 0.4)!);
        }
      case _Prop.flowers:
        _paint(c, _Prop.bush, w, h);
        for (final (x, y, col) in [(0.3, 0.42, pal.accent), (0.55, 0.3, AppColors.white), (0.72, 0.5, pal.accent), (0.45, 0.6, AppColors.gold)]) {
          _fill(c, _circles([(w * x, h * y, w * 0.07)]), col);
          c.drawCircle(Offset(w * x, h * y), w * 0.025, Paint()..color = AppColors.goldDeep);
        }
      case _Prop.column:
        _fill(c, Path()..addRect(Rect.fromLTRB(w * 0.05, h * 0.9, w * 0.95, h - 4)), _stone);
        _fill(c, Path()..addRect(Rect.fromLTRB(w * 0.18, h * 0.14, w * 0.82, h * 0.9)), _stone);
        final flute = Paint()
          ..color = AppColors.outline.withValues(alpha: 0.35)
          ..strokeWidth = 4;
        for (final x in [0.36, 0.5, 0.64]) {
          c.drawLine(Offset(w * x, h * 0.17), Offset(w * x, h * 0.87), flute);
        }
        _fill(c, Path()..addRect(Rect.fromLTRB(w * 0.04, h * 0.06, w * 0.96, h * 0.14)), _stone);
        // Broken top.
        final chip = Path()
          ..moveTo(w * 0.1, h * 0.06)
          ..lineTo(w * 0.3, h * 0.0 + 4)
          ..lineTo(w * 0.5, h * 0.04)
          ..lineTo(w * 0.7, h * 0.01 + 4)
          ..lineTo(w * 0.9, h * 0.06)
          ..close();
        _fill(c, chip, _stone);
      case _Prop.bamboo:
        final stalk = Color.lerp(pal.foliage, const Color(0xFFB8D86A), 0.4)!;
        for (final (x, top) in [(0.3, 0.1), (0.52, 0.02), (0.72, 0.18)]) {
          _fill(c, Path()..addRRect(RRect.fromLTRBR(w * (x - 0.07), h * top, w * (x + 0.07), h - 4, const Radius.circular(8))), stalk);
          for (var y = top + 0.14; y < 0.95; y += 0.16) {
            c.drawLine(Offset(w * (x - 0.07), h * y), Offset(w * (x + 0.07), h * y), _stroke);
          }
          c
            ..save()
            ..translate(w * (x + 0.06), h * (top + 0.2))
            ..rotate(-0.5);
          _fill(c, Path()..addOval(Rect.fromLTWH(0, -8, w * 0.3, 16)), _leaf);
          c.restore();
        }
      case _Prop.mushroom:
        _fill(c, Path()..addRRect(RRect.fromLTRBR(w * 0.4, h * 0.45, w * 0.6, h - 4, const Radius.circular(10))), _stone);
        final cap = Path()
          ..moveTo(w * 0.08, h * 0.55)
          ..quadraticBezierTo(w * 0.1, h * 0.08, w * 0.5, h * 0.08)
          ..quadraticBezierTo(w * 0.9, h * 0.08, w * 0.92, h * 0.55)
          ..close();
        if (_glow) {
          c.drawCircle(Offset(w * 0.5, h * 0.35), w * 0.48,
              Paint()..color = pal.accent.withValues(alpha: 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
        }
        _fill(c, cap, pal.accent);
        for (final (x, y, r) in [(0.3, 0.35, 0.06), (0.55, 0.22, 0.07), (0.72, 0.4, 0.05)]) {
          c.drawCircle(Offset(w * x, h * y), w * r, Paint()..color = AppColors.white);
        }
      case _Prop.deadTree:
        final bark = Color.lerp(_trunk, const Color(0xFF4A4A4A), 0.5)!;
        final wood = Paint()
          ..color = bark
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final outline = Paint()
          ..color = AppColors.outline
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final branches = [
          (Offset(w * 0.5, h - 6), Offset(w * 0.5, h * 0.35), 26.0),
          (Offset(w * 0.5, h * 0.6), Offset(w * 0.2, h * 0.3), 14.0),
          (Offset(w * 0.5, h * 0.45), Offset(w * 0.82, h * 0.15), 14.0),
          (Offset(w * 0.5, h * 0.36), Offset(w * 0.4, h * 0.06), 11.0),
          (Offset(w * 0.3, h * 0.4), Offset(w * 0.12, h * 0.36), 8.0),
        ];
        for (final (a, b, sw) in branches) {
          c.drawLine(a, b, outline..strokeWidth = sw + 12);
        }
        for (final (a, b, sw) in branches) {
          c.drawLine(a, b, wood..strokeWidth = sw);
        }
      case _Prop.reeds:
        final stem = Paint()
          ..color = _leaf
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round;
        for (final (x, top, lean) in [(0.25, 0.2, -0.08), (0.45, 0.05, 0.0), (0.62, 0.15, 0.06), (0.8, 0.3, 0.1)]) {
          final tip = Offset(w * (x + lean), h * top);
          c
            ..drawLine(Offset(w * x, h - 4), tip, _stroke..strokeWidth = 12)
            ..drawLine(Offset(w * x, h - 4), tip, stem);
          _stroke.strokeWidth = 7;
          _fill(c, Path()..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(center: tip + Offset(0, h * 0.1), width: w * 0.1, height: h * 0.18), Radius.circular(w * 0.05))),
              const Color(0xFF7A4A24));
        }
    }
  }
}
