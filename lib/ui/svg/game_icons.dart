import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';

/// Hand-authored 24×24 icons. Everything is `currentColor`, so one icon works on any button colour.
enum GameIcon {
  play('<path d="M8 5.6v12.8a1.2 1.2 0 0 0 1.8 1l10-6.4a1.2 1.2 0 0 0 0-2L9.8 4.6A1.2 1.2 0 0 0 8 5.6z"/>'),
  pause('<rect x="5.8" y="4.8" width="4.6" height="14.4" rx="1.6"/><rect x="13.6" y="4.8" width="4.6" height="14.4" rx="1.6"/>'),
  home('<path d="M12 3.2 2.6 11.3a1 1 0 0 0 .66 1.76H5V20a1 1 0 0 0 1 1h4.2v-5.6h3.6V21H18a1 1 0 0 0 1-1v-6.94h1.74a1 1 0 0 0 .66-1.76z"/>'),
  back('<path d="M10.4 4.5 3.3 11.2a1.1 1.1 0 0 0 0 1.6l7.1 6.7a1 1 0 0 0 1.7-.73V15.3h7.3a1 1 0 0 0 1-1V9.7a1 1 0 0 0-1-1h-7.3V5.23a1 1 0 0 0-1.7-.73z"/>'),
  close('<g transform="rotate(45 12 12)"><rect x="9.7" y="2.4" width="4.6" height="19.2" rx="2.3"/><rect x="2.4" y="9.7" width="19.2" height="4.6" rx="2.3"/></g>'),
  restart('<path d="M18.6 12.4A6.6 6.6 0 1 1 16.4 7" fill="none" stroke="currentColor" stroke-width="3.4" stroke-linecap="round"/>'
      '<path d="M20.4 3.6v6.6h-6.6z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>'),
  settings('<circle cx="12" cy="12" r="5.4" fill="none" stroke="currentColor" stroke-width="3.8"/>'
      '<g id="t"><rect x="9.9" y="1.6" width="4.2" height="5" rx="1.2"/></g>'
      '<use href="#t" transform="rotate(45 12 12)"/><use href="#t" transform="rotate(90 12 12)"/>'
      '<use href="#t" transform="rotate(135 12 12)"/><use href="#t" transform="rotate(180 12 12)"/>'
      '<use href="#t" transform="rotate(225 12 12)"/><use href="#t" transform="rotate(270 12 12)"/>'
      '<use href="#t" transform="rotate(315 12 12)"/>'),
  soundOn('<path d="M2.8 9.6v4.8a1 1 0 0 0 1 1h3.3l4.7 3.9a.8.8 0 0 0 1.3-.62V5.32a.8.8 0 0 0-1.3-.62L7.1 8.6H3.8a1 1 0 0 0-1 1z"/>'
      '<path d="M16 8.6a4.8 4.8 0 0 1 0 6.8M18.7 5.9a8.6 8.6 0 0 1 0 12.2" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/>'),
  soundOff('<path d="M2.8 9.6v4.8a1 1 0 0 0 1 1h3.3l4.7 3.9a.8.8 0 0 0 1.3-.62V5.32a.8.8 0 0 0-1.3-.62L7.1 8.6H3.8a1 1 0 0 0-1 1z"/>'
      '<path d="M16.3 9.3l5 5.4M21.3 9.3l-5 5.4" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"/>'),
  musicOn('<circle cx="6.8" cy="17.6" r="3.2"/><circle cx="17.2" cy="15.6" r="3.2"/>'
      '<path d="M8.4 17.6V6.5l11.6-2.9v12h-2.3V7.1l-7 1.7v8.8z"/>'),
  musicOff('<circle cx="6.8" cy="17.6" r="3.2"/><circle cx="17.2" cy="15.6" r="3.2"/>'
      '<path d="M8.4 17.6V6.5l11.6-2.9v12h-2.3V7.1l-7 1.7v8.8z"/>'
      '<path d="M3 3l18 18" stroke="currentColor" stroke-width="2.8" stroke-linecap="round"/>'),
  vibrate('<rect x="7.2" y="3" width="9.6" height="18" rx="2.2"/>'
      '<path d="M3.6 8.5v7M20.4 8.5v7" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/>'),
  lock('<rect x="4.4" y="10.2" width="15.2" height="11.2" rx="2.6"/>'
      '<path d="M8 10.4V7.8a4 4 0 0 1 8 0v2.6" fill="none" stroke="currentColor" stroke-width="2.9"/>'),
  star('<path d="M12 2.8l2.85 5.8 6.4.93-4.63 4.52 1.1 6.37L12 17.4l-5.72 3.02 1.1-6.37L2.75 9.53l6.4-.93z" '
      'stroke="currentColor" stroke-width="1.4" stroke-linejoin="round"/>'),
  heart('<path d="M12 20.6s-8.6-5.2-8.6-11.1A4.8 4.8 0 0 1 12 6.6a4.8 4.8 0 0 1 8.6 2.9c0 5.9-8.6 11.1-8.6 11.1z"/>'),
  check('<path d="M4.8 12.6l4.6 4.6L19.4 7.2" fill="none" stroke="currentColor" stroke-width="3.8" stroke-linecap="round" stroke-linejoin="round"/>'),
  bolt('<path d="M13.6 2 4.4 13.6h6.2L9 22l9.8-12.2h-6.4z" stroke="currentColor" stroke-width="1.2" stroke-linejoin="round"/>'),
  arrowUp('<path d="M12 3.2 3.6 12h5.2v8.4h6.4V12h5.2z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>'),
  plus('<rect x="9.7" y="3" width="4.6" height="18" rx="2.3"/><rect x="3" y="9.7" width="18" height="4.6" rx="2.3"/>'),
  grid('<rect x="3" y="3" width="8" height="8" rx="2"/><rect x="13" y="3" width="8" height="8" rx="2"/>'
      '<rect x="3" y="13" width="8" height="8" rx="2"/><rect x="13" y="13" width="8" height="8" rx="2"/>'),
  trophy('<path d="M6.5 3h11v5.5a5.5 5.5 0 0 1-4 5.3V17h3v4h-9v-4h3v-3.2a5.5 5.5 0 0 1-4-5.3z"/>'
      '<path d="M6.5 5.2H3.6v1.6a3.6 3.6 0 0 0 3.6 3.6M17.5 5.2h2.9v1.6a3.6 3.6 0 0 1-3.6 3.6" fill="none" stroke="currentColor" stroke-width="1.8"/>'),
  paw('<ellipse cx="12" cy="16" rx="5" ry="4.4"/><ellipse cx="5.2" cy="10.6" rx="2.2" ry="2.8"/>'
      '<ellipse cx="9.2" cy="6.4" rx="2.3" ry="3"/><ellipse cx="14.8" cy="6.4" rx="2.3" ry="3"/>'
      '<ellipse cx="18.8" cy="10.6" rx="2.2" ry="2.8"/>');

  const GameIcon(this._body);
  final String _body;

  String get svg => '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">$_body</svg>';
}

/// A [GameIcon] with a dark drop copy underneath, which gives the chunky cartoon look.
class GameSvgIcon extends StatelessWidget {
  const GameSvgIcon(
    this.icon, {
    super.key,
    this.size = 28,
    this.color = AppColors.white,
    this.shadow = true,
  });

  final GameIcon icon;
  final double size;
  final Color color;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    Widget draw(Color c) => SvgPicture.string(
          icon.svg,
          width: size,
          height: size,
          theme: SvgTheme(currentColor: c),
        );
    if (!shadow) return draw(color);
    final offset = (size * 0.07).clamp(1.5, 4.0);
    return SizedBox(
      width: size,
      height: size + offset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(top: offset, child: draw(AppColors.outline.withValues(alpha: 0.55))),
          Positioned(top: 0, child: draw(color)),
        ],
      ),
    );
  }
}
