import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../lion_game.dart';
import '../world/perspective.dart';

class _Particle {
  _Particle(this.x, this.y, this.vx, this.vy, this.size, this.life, this.color, this.square, this.spin);

  double x, y, vx, vy, size, life, age = 0, angle = 0;
  final Color color;
  final bool square;
  final double spin;
}

/// One-shot burst of code-drawn bits (coin glints, meat chunks, broccoli leaves, obstacle debris).
/// Everything lives in one component, so a burst costs a single draw pass.
class ParticleBurst extends Component with HasGameReference<LionGame> {
  ParticleBurst({
    required Vector2 at,
    required List<Color> colors,
    int count = 14,
    double speed = 520,
    double size = 14,
    double life = 0.6,
    this.gravity = 1400,
    double upBias = 0.6,
    bool squares = false,
    int priority = 26000,
  }) : super(priority: priority) {
    final rnd = math.Random();
    for (var i = 0; i < count; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final v = speed * (0.45 + rnd.nextDouble() * 0.55);
      _parts.add(_Particle(
        at.x,
        at.y,
        math.cos(a) * v,
        math.sin(a) * v - speed * upBias,
        size * (0.6 + rnd.nextDouble() * 0.6),
        life * (0.7 + rnd.nextDouble() * 0.5),
        colors[rnd.nextInt(colors.length)],
        squares,
        (rnd.nextDouble() - 0.5) * 16,
      ));
    }
  }

  final double gravity;
  final _parts = <_Particle>[];
  final _paint = Paint();
  static final _outline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = const Color(0xAA2B1A12);

  @override
  void update(double dt) {
    for (final p in _parts) {
      p
        ..age += dt
        ..vy += gravity * dt
        ..vx *= 1 - 1.5 * dt
        ..x += p.vx * dt
        ..y += p.vy * dt
        ..angle += p.spin * dt;
    }
    _parts.removeWhere((p) => p.age >= p.life);
    if (_parts.isEmpty) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    for (final p in _parts) {
      final t = p.age / p.life;
      final s = p.size * (1 - t * 0.5);
      _paint.color = p.color.withValues(alpha: (1 - t * t).clamp(0.0, 1.0));
      if (p.square) {
        canvas
          ..save()
          ..translate(p.x, p.y)
          ..rotate(p.angle);
        final r = Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.7);
        canvas
          ..drawRect(r, _paint)
          ..drawRect(r, _outline..color = _outline.color.withValues(alpha: 0.6 * (1 - t)))
          ..restore();
      } else {
        canvas.drawCircle(Offset(p.x, p.y), s / 2, _paint);
      }
    }
  }
}

class _Puff {
  _Puff(this.laneX, this.offset, this.z, this.rise, this.size, this.life);

  final double laneX, offset, z, rise, size, life;
  double age = 0;
}

/// Little dust puffs kicked up behind the lion's paws. Each puff stays where it was kicked up on the
/// road, so it slides back and grows with the perspective as the lion runs on.
class DustTrail extends Component with HasGameReference<LionGame> {
  DustTrail() : super(priority: 9990);

  final _puffs = <_Puff>[];
  final _rnd = math.Random();
  final _paint = Paint();
  double _emit = 0;
  late final Color _color = Color.lerp(game.chapter.palette.ground, const Color(0xFFFFFFFF), 0.35)!;

  @override
  void update(double dt) {
    final player = game.player;
    if (game.isRunning && player.isRunningPose) {
      _emit -= dt;
      while (_emit <= 0) {
        _emit += 0.045;
        final side = _rnd.nextBool() ? -1 : 1;
        _puffs.add(_Puff(
          player.laneX,
          side * player.size.x * (0.1 + _rnd.nextDouble() * 0.18),
          game.distance + 0.3,
          40 + _rnd.nextDouble() * 60,
          12 + _rnd.nextDouble() * 10,
          0.26 + _rnd.nextDouble() * 0.1,
        ));
      }
    }
    for (final p in _puffs) {
      p.age += dt;
    }
    _puffs.removeWhere((p) => p.age >= p.life);
  }

  @override
  void render(Canvas canvas) {
    final persp = game.perspective;
    for (final p in _puffs) {
      final t = p.age / p.life;
      final z = p.z - game.distance;
      final s = persp.scaleAt(z);
      _paint.color = _color.withValues(alpha: 0.4 * (1 - t) * (1 - t));
      canvas.drawCircle(
        Offset(persp.xAt(p.laneX, z) + p.offset * s, persp.yAt(z) - p.rise * t * s),
        p.size * s * (0.6 + t),
        _paint,
      );
    }
  }
}

/// Wind streaks flying out of the vanishing point along the sides of the screen. Denser and brighter
/// on faster levels; they fade out whenever the lion isn't running at full speed.
class SpeedLines extends Component with HasGameReference<LionGame> {
  SpeedLines() : super(priority: 30000);

  static const _count = 16;
  final _rnd = math.Random();
  final _lines = <List<double>>[]; // [angle, r, speed, width]
  final _paint = Paint()..strokeCap = StrokeCap.round;
  double _alpha = 0;

  @override
  void onLoad() {
    for (var i = 0; i < _count; i++) {
      _lines.add(_spawn(randomR: true));
    }
  }

  List<double> _spawn({bool randomR = false}) {
    // Left sector 115°..205°, right sector -25°..65° (y points down): keeps the road and lion clear.
    final left = _rnd.nextBool();
    final deg = left ? 115 + _rnd.nextDouble() * 90 : -25 + _rnd.nextDouble() * 90;
    return [
      deg * math.pi / 180,
      randomR ? 120 + _rnd.nextDouble() * 700 : 120 + _rnd.nextDouble() * 120,
      1400 + _rnd.nextDouble() * 900,
      4 + _rnd.nextDouble() * 4,
    ];
  }

  @override
  void update(double dt) {
    // 12 = slowest level speed, 18 = fastest.
    final intensity = ((game.speed - 12) / 6).clamp(0.0, 1.0);
    final target = game.isRunning ? (0.3 + 0.3 * intensity) * game.speedFactor : 0.0;
    _alpha += (target - _alpha) * math.min(1, dt * 4);
    for (var i = 0; i < _lines.length; i++) {
      final l = _lines[i];
      l[1] += l[2] * dt * (0.6 + game.speedFactor * 0.4);
      if (l[1] > 1100) _lines[i] = _spawn();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_alpha < 0.01) return;
    const cx = Perspective.centerX;
    final cy = game.perspective.horizonY;
    for (final l in _lines) {
      final dx = math.cos(l[0]), dy = math.sin(l[0]);
      final r0 = l[1], len = 40 + r0 * 0.28;
      // Fade in as they leave the centre so they don't clutter the horizon.
      final a = _alpha * ((r0 - 120) / 200).clamp(0.0, 1.0);
      _paint
        ..color = const Color(0xFFFFFFFF).withValues(alpha: a)
        ..strokeWidth = l[3] * (0.5 + r0 / 800);
      canvas.drawLine(Offset(cx + dx * r0, cy + dy * r0), Offset(cx + dx * (r0 + len), cy + dy * (r0 + len)), _paint);
    }
  }
}
