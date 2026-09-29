import 'dart:math' as math;
import 'dart:ui';

import '../../core/theme/app_colors.dart';

/// Builds the menu backdrop (sky, sun rays, clouds, hills, side foliage, a stage platform) as SVG
/// from a [ChapterPalette]. The same layout re-colours for every chapter, so we need no background art.
abstract final class BackdropSvg {
  static final _cache = <ChapterPalette, String>{};

  static String build(ChapterPalette p) => _cache.putIfAbsent(p, () => _build(p));

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static String _build(ChapterPalette p) {
    final outline = _hex(AppColors.outline);
    final b = StringBuffer()
      ..write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 720 1280" '
          'preserveAspectRatio="xMidYMax slice">')
      ..write('<defs>'
          '<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">'
          '<stop offset="0" stop-color="${_hex(p.skyTop)}"/>'
          '<stop offset="0.75" stop-color="${_hex(p.skyBottom)}"/></linearGradient>'
          '<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5">'
          '<stop offset="0" stop-color="${_hex(p.sun)}" stop-opacity="0.9"/>'
          '<stop offset="1" stop-color="${_hex(p.sun)}" stop-opacity="0"/></radialGradient>'
          '</defs>')
      ..write('<rect width="720" height="1280" fill="url(#sky)"/>');

    // Sun rays.
    const cx = 360.0, cy = 500.0, rays = 16;
    b.write('<g fill="#ffffff" fill-opacity="0.13">');
    for (var i = 0; i < rays; i += 2) {
      final a0 = i * 2 * math.pi / rays, a1 = (i + 1) * 2 * math.pi / rays;
      b.write('<path d="M$cx $cy L${_p(cx + 1500 * math.cos(a0))} ${_p(cy + 1500 * math.sin(a0))} '
          'L${_p(cx + 1500 * math.cos(a1))} ${_p(cy + 1500 * math.sin(a1))}Z"/>');
    }
    b.write('</g>');
    b.write('<circle cx="$cx" cy="$cy" r="260" fill="url(#glow)"/>');

    // Clouds.
    for (final c in const [(120.0, 250.0, 1.0), (590.0, 180.0, 0.8), (470.0, 360.0, 0.6)]) {
      final (x, y, s) = c;
      b.write('<g transform="translate($x $y) scale($s)" fill="#ffffff" fill-opacity="0.92">'
          '<ellipse cx="0" cy="20" rx="95" ry="30"/><circle cx="-40" cy="5" r="36"/>'
          '<circle cx="10" cy="-10" r="48"/><circle cx="55" cy="10" r="32"/></g>');
    }

    // Hills.
    b
      ..write('<path d="M0 740 C120 640 240 680 360 710 S600 630 720 700 V1280 H0Z" '
          'fill="${_hex(p.farHills)}"/>')
      ..write('<path d="M0 830 C150 770 280 830 420 810 S640 760 720 800 V1280 H0Z" '
          'fill="${_hex(p.nearHills)}" stroke="$outline" stroke-opacity="0.3" stroke-width="4"/>')
      ..write('<path d="M0 930 Q360 880 720 930 V1280 H0Z" fill="${_hex(p.ground)}" '
          'stroke="$outline" stroke-opacity="0.45" stroke-width="5"/>');

    // Stage platform where the lion stands.
    final platTop = Color.lerp(p.ground, const Color(0xFFFFFFFF), 0.25)!;
    final platSide = Color.lerp(p.ground, AppColors.outline, 0.3)!;
    b
      ..write('<ellipse cx="360" cy="1018" rx="250" ry="62" fill="${_hex(platSide)}" stroke="$outline" stroke-width="5"/>')
      ..write('<ellipse cx="360" cy="1000" rx="250" ry="58" fill="${_hex(platTop)}" stroke="$outline" stroke-width="5"/>');

    // Side foliage, mirrored.
    final rnd = math.Random(7);
    final leaves = StringBuffer();
    for (final (y, baseAngle, len) in const [
      (560.0, -55.0, 190.0),
      (660.0, -30.0, 230.0),
      (780.0, -10.0, 250.0),
      (900.0, 10.0, 230.0),
      (1030.0, -25.0, 260.0),
      (1150.0, 5.0, 240.0),
    ]) {
      for (var k = 0; k < 2; k++) {
        final angle = baseAngle + (k == 0 ? -12 : 14) + rnd.nextDouble() * 8;
        final l = len * (k == 0 ? 1.0 : 0.8);
        final fill = k == 0 ? p.foliageDark : p.foliage;
        leaves.write('<g transform="translate(-30 ${_p(y + k * 22)}) rotate(${_p(angle)})">'
            '<path d="M0 0 C${_p(l * .25)} -${_p(l * .19)} ${_p(l * .7)} -${_p(l * .19)} $l 0 '
            'C${_p(l * .7)} ${_p(l * .19)} ${_p(l * .25)} ${_p(l * .19)} 0 0Z" fill="${_hex(fill)}" '
            'stroke="$outline" stroke-width="4" stroke-linejoin="round"/>'
            '<path d="M8 0 L${_p(l * .9)} 0" stroke="$outline" stroke-opacity="0.35" stroke-width="3" '
            'stroke-linecap="round"/></g>');
      }
    }
    b
      ..write('<g>$leaves</g>')
      ..write('<g transform="translate(720 0) scale(-1 1)">$leaves</g>');

    // Bushes along the bottom edge.
    b.write('<g stroke="$outline" stroke-width="4">');
    for (var i = 0; i < 9; i++) {
      final x = i * 90.0 + rnd.nextDouble() * 20;
      final r = 55 + rnd.nextDouble() * 30;
      b.write('<circle cx="${_p(x)}" cy="${_p(1270 - r * 0.3)}" r="${_p(r)}" '
          'fill="${_hex(i.isEven ? p.foliage : p.foliageDark)}"/>');
    }
    b
      ..write('</g>')
      ..write('</svg>');
    return b.toString();
  }

  static String _p(double v) => v.toStringAsFixed(1);
}
