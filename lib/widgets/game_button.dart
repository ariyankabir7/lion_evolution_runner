import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/services/services.dart';
import '../core/theme/app_colors.dart';
import '../ui/svg/game_icons.dart';
import 'stroked_text.dart';

/// Colour pair for a chunky 3D button: a bright face over a darker base.
@immutable
class ButtonSkin {
  const ButtonSkin(this.face, this.shade);
  final Color face;
  final Color shade;

  static const green = ButtonSkin(AppColors.green, AppColors.greenShade);
  static const orange = ButtonSkin(AppColors.orange, AppColors.orangeShade);
  static const blue = ButtonSkin(AppColors.blue, AppColors.blueShade);
  static const red = ButtonSkin(AppColors.red, AppColors.redShade);
  static const purple = ButtonSkin(AppColors.purple, AppColors.purpleShade);
  static const gold = ButtonSkin(AppColors.gold, AppColors.goldDeep);
  static const grey = ButtonSkin(AppColors.grey, AppColors.greyShade);
}

/// Hyper-casual button: dark outline, a darker "depth" base, a glossy face and a squash when pressed.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.child,
    this.skin = ButtonSkin.green,
    this.width,
    this.height = 72,
    this.fontSize,
    this.radius,
  });

  /// Circular icon-only button.
  const GameButton.round({
    super.key,
    required this.onPressed,
    required GameIcon this.icon,
    this.skin = ButtonSkin.blue,
    double size = 60,
  })  : label = null,
        child = null,
        width = size,
        height = size,
        fontSize = null,
        radius = size / 2;

  final VoidCallback? onPressed;
  final String? label;
  final GameIcon? icon;
  final Widget? child;
  final ButtonSkin skin;
  final double? width;
  final double height;
  final double? fontSize;
  final double? radius;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _down = false;

  bool get _enabled => widget.onPressed != null;

  void _setDown(bool v) {
    if (_enabled && _down != v) setState(() => _down = v);
  }

  void _tap() {
    if (!_enabled) return;
    if (services.settings.haptics.value) HapticFeedback.lightImpact();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final skin = _enabled ? widget.skin : ButtonSkin.grey;
    final h = widget.height;
    final depth = (h * 0.1).clamp(4.0, 8.0);
    final r = widget.radius ?? h * 0.3;
    const border = 3.5;
    final press = _down ? depth * 0.7 : 0.0;

    final content = widget.child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) GameSvgIcon(widget.icon!, size: h * 0.46),
            if (widget.icon != null && widget.label != null) SizedBox(width: h * 0.14),
            if (widget.label != null) StrokedText(widget.label!, size: widget.fontSize ?? h * 0.38),
          ],
        );

    return GestureDetector(
      onTapDown: (_) => _setDown(true),
      onTapUp: (_) => _setDown(false),
      onTapCancel: () => _setDown(false),
      onTap: _tap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 80),
        child: SizedBox(
          width: widget.width,
          height: h + depth,
          child: Stack(
            children: [
              // Depth base.
              Positioned.fill(
                top: depth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(skin.shade, AppColors.outline, 0.25),
                    borderRadius: BorderRadius.circular(r),
                    border: Border.all(color: AppColors.outline, width: border),
                  ),
                ),
              ),
              // Face.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 80),
                left: 0,
                right: 0,
                top: press,
                height: h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(r),
                    border: Border.all(color: AppColors.outline, width: border),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.lerp(skin.face, Colors.white, 0.18)!, skin.face, skin.shade],
                      stops: const [0, 0.55, 1],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Gloss strip.
                      Positioned(
                        left: r * 0.5,
                        right: r * 0.5,
                        top: h * 0.1,
                        height: h * 0.2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(h),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: h * 0.25),
                          child: FittedBox(fit: BoxFit.scaleDown, child: content),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
