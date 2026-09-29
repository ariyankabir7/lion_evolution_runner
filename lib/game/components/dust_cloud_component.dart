import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/constants/asset_paths.dart';
import '../effects/burst_effect.dart';
import '../lion_game.dart';

/// The cartoon fight: a shaking dust cloud with impact bursts popping around it. Calls [onDone] when it ends.
class DustCloudComponent extends PositionComponent with HasGameReference<LionGame> {
  DustCloudComponent({required Vector2 position, required this.duration, required this.onDone})
      : super(position: position, anchor: Anchor.center, priority: 24000);

  final double duration;
  final void Function() onDone;

  late final Sprite _sprite = Sprite(game.images.fromCache(AssetPaths.dustCloud));
  final _paint = Paint()..filterQuality = FilterQuality.medium;
  final _rnd = math.Random();
  late final Vector2 _home = position.clone();
  double _t = 0;
  double _nextPop = 0;

  static const _baseSize = 520.0;

  @override
  void update(double dt) {
    _t += dt;
    final k = (_t / duration).clamp(0.0, 1.0);
    // Grow in fast, rumble, shrink out.
    final grow = k < 0.12 ? k / 0.12 : (k > 0.88 ? (1 - k) / 0.12 : 1.0);
    final wobble = 1 + 0.07 * math.sin(_t * 38);
    final s = _baseSize * (0.5 + 0.5 * grow) * wobble;
    size = Vector2(s, s * _sprite.srcSize.y / _sprite.srcSize.x);
    position = _home + Vector2((_rnd.nextDouble() - 0.5) * 26, (_rnd.nextDouble() - 0.5) * 20);
    angle = math.sin(_t * 23) * 0.06;
    _paint.color = Color.fromRGBO(255, 255, 255, grow.clamp(0.0, 1.0));

    _nextPop -= dt;
    if (_nextPop <= 0 && k < 0.9) {
      _nextPop = 0.09 + _rnd.nextDouble() * 0.08;
      final at = _home + Vector2((_rnd.nextDouble() - 0.5) * 360, (_rnd.nextDouble() - 0.5) * 240);
      final sprite = _rnd.nextBool() ? AssetPaths.burst : AssetPaths.sparkle;
      game.world.add(BurstEffect(sprite, position: at, startSize: 60, endSize: 170, duration: 0.25, priority: 24500));
      game.shake(0.08);
    }

    if (_t >= duration) {
      removeFromParent();
      onDone();
    }
  }

  @override
  void render(Canvas canvas) => _sprite.render(canvas, size: size, overridePaint: _paint);
}
