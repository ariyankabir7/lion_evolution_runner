import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../models/item_type.dart';
import '../../models/level_config.dart';
import '../lion_game.dart';
import '../world/perspective.dart';

/// A pickup or obstacle on the road. Its screen position and size come from its depth every frame.
class ItemComponent extends PositionComponent with HasGameReference<LionGame> {
  ItemComponent(this.entry) : super(anchor: Anchor.bottomCenter);

  final SpawnEntry entry;
  ItemType get type => entry.type;

  /// Set once the lion has passed it (hit or missed), so it's resolved only once.
  bool resolved = false;

  /// Collected pickups fly toward the HUD instead of scrolling past.
  bool _collected = false;
  double _collectT = 0;
  Vector2 _collectFrom = Vector2.zero();

  late final Sprite _sprite = Sprite(game.images.fromCache(type.sprite));
  late final double _aspect = _sprite.srcSize.y / _sprite.srcSize.x;
  final _paint = Paint()..filterQuality = FilterQuality.medium;
  static final _shadow = Paint()..color = const Color(0x40000000);

  double get z => entry.z - game.distance;
  double get laneX => Perspective.laneToX(entry.lane);

  void collect() {
    _collected = true;
    resolved = true;
    _collectFrom = position.clone();
    priority = 20000;
  }

  @override
  void update(double dt) {
    final p = game.perspective;
    if (_collected) {
      _collectT += dt / 0.45;
      if (_collectT >= 1) {
        removeFromParent();
        return;
      }
      // Pop up, then shrink and fade.
      final t = _collectT;
      position = _collectFrom + Vector2(0, -180 * math.sin(t * math.pi * 0.6));
      final s = (1 + 0.4 * math.sin(t * math.pi)) * (1 - t * 0.6);
      size = Vector2(type.width, type.width * _aspect) * s;
      _paint.color = Color.fromRGBO(255, 255, 255, (1 - t * t).clamp(0, 1));
      return;
    }

    final zz = z;
    if (zz < -Perspective.cameraDepth * 0.7) {
      removeFromParent();
      return;
    }
    final s = p.scaleAt(zz);
    final w = type.width * s;
    size = Vector2(w, w * _aspect);
    var y = p.yAt(zz);
    if (type.floats) {
      y -= (40 + 12 * math.sin(game.time * 5 + entry.z)) * s;
    }
    position = Vector2(p.xAt(laneX, zz), y);
    priority = (10000 - zz * 40).round();

    // Fade in out of the horizon haze.
    final fade = ((Perspective.maxZ - zz) / 18).clamp(0.0, 1.0);
    _paint.color = Color.fromRGBO(255, 255, 255, fade);
  }

  @override
  void render(Canvas canvas) {
    if (!_collected) {
      final sw = size.x * (type.isObstacle ? 1.0 : 0.8);
      final floorY = type.floats ? size.y + 40 * game.perspective.scaleAt(z) : size.y;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(size.x / 2, floorY - 2), width: sw, height: sw * 0.2),
        _shadow,
      );
    }
    _sprite.render(canvas, size: size, overridePaint: _paint);
  }
}
