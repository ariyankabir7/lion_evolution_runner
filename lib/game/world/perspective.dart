import 'dart:math' as math;

/// Pseudo-3D projection for the track.
///
/// World space: `z` = distance ahead of the lion (0 at the lion, negative behind it), `laneX` in
/// -1..1 (lane centres at ±1). Screen space is the 720-wide game world.
class Perspective {
  Perspective();

  static const width = 720.0;
  static const centerX = width / 2;

  /// Camera distance. Smaller = stronger perspective.
  static const cameraDepth = 12.0;

  /// Road half-width at the lion's depth.
  static const roadHalfWidth = 310.0;

  /// Lane centre offset from the road centre at the lion's depth.
  static const laneOffset = 150.0;

  /// Furthest depth drawn.
  static const maxZ = 130.0;

  double height = 1280;
  double get horizonY => height * 0.30;
  double get playerY => height * 0.83;

  void resize(double h) => height = h;

  /// Scale factor at depth z (1 at the lion).
  double scaleAt(double z) => cameraDepth / (cameraDepth + math.max(z, -cameraDepth * 0.9));

  double yAt(double z) => horizonY + (playerY - horizonY) * scaleAt(z);

  double xAt(double laneX, double z) => centerX + laneX * laneOffset * scaleAt(z);

  double roadHalfAt(double z) => roadHalfWidth * scaleAt(z);

  /// Inverse of [yAt]: the depth that projects to screen y (only valid below the horizon).
  double zAtY(double y) {
    final s = (y - horizonY) / (playerY - horizonY);
    return cameraDepth / s - cameraDepth;
  }

  static double laneToX(int lane) => lane == 0 ? -1 : 1;
}
