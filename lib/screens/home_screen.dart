import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app.dart';
import '../core/constants/asset_paths.dart';
import '../core/services/services.dart';
import '../core/theme/app_colors.dart';
import '../data/chapter_catalog.dart';
import '../models/evolution_stage.dart';
import '../ui/svg/game_icons.dart';
import '../widgets/coin_counter.dart';
import '../widgets/dialogs.dart';
import '../widgets/game_button.dart';
import '../widgets/stroked_text.dart';
import '../widgets/themed_backdrop.dart';
import '../widgets/title_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: services.progress.unlockedLevel,
      builder: (context, level, _) {
        final chapter = ChapterCatalog.forLevel(level);
        return Scaffold(
          body: ThemedBackdrop(
            chapter: chapter,
            child: LayoutBuilder(
              builder: (context, box) {
                // The backdrop is 720×1280, cover-fit and bottom-aligned; lion feet stand at y≈992 and the
                // platform's bottom edge is at y≈1080, leaving the strip below for the PLAY button.
                final scale = math.max(box.maxWidth / 720, box.maxHeight / 1280);
                final platformY = box.maxHeight - (1280 - 992) * scale;
                final belowPlatform = (1280 - 1080) * scale;
                final lionH = 330 * scale;
                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: platformY - lionH,
                      height: lionH,
                      child: const _IdleLion(stage: EvolutionStage.healthy),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const CoinCounter(),
                                const Spacer(),
                                GameButton.round(
                                  icon: GameIcon.settings,
                                  skin: ButtonSkin.blue,
                                  size: 56,
                                  onPressed: () => showSettingsDialog(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TitleLogo(width: math.min(300, box.maxWidth * 0.72), showFace: false),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _SideButton(
                                  icon: GameIcon.grid,
                                  label: 'LEVELS',
                                  skin: ButtonSkin.purple,
                                  onPressed: () => Navigator.of(context).pushNamed(Routes.levels),
                                ),
                                ListenableBuilder(
                                  listenable: services.upgrades.changes,
                                  builder: (context, _) => _SideButton(
                                    icon: GameIcon.arrowUp,
                                    label: 'UPGRADES',
                                    skin: ButtonSkin.orange,
                                    badge: services.upgrades.anyAffordable,
                                    onPressed: () => showUpgradesDialog(context),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: box.maxHeight - platformY - 20),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 40,
                      right: 40,
                      bottom: math.max(12, (belowPlatform - 96) / 2),
                      child: Center(
                        child: _PulsingPlay(
                          level: level,
                          onPressed: () => Navigator.of(context).pushNamed(Routes.game, arguments: level),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.icon,
    required this.label,
    required this.skin,
    required this.onPressed,
    this.badge = false,
  });

  final GameIcon icon;
  final String label;
  final ButtonSkin skin;
  final VoidCallback onPressed;

  /// Red "!" dot, e.g. when an upgrade is affordable.
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GameButton.round(icon: icon, skin: skin, size: 72, onPressed: onPressed),
            if (badge)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.outline, width: 3),
                  ),
                  child: const StrokedText('!', size: 18, drop: false),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        StrokedText(label, size: 14),
      ],
    );
  }
}

class _PulsingPlay extends StatefulWidget {
  const _PulsingPlay({required this.level, required this.onPressed});

  final int level;
  final VoidCallback onPressed;

  @override
  State<_PulsingPlay> createState() => _PulsingPlayState();
}

class _PulsingPlayState extends State<_PulsingPlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: GameButton(
        width: 280,
        height: 88,
        skin: ButtonSkin.green,
        onPressed: widget.onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StrokedText('PLAY', size: 40),
            StrokedText('LEVEL ${widget.level}', size: 18, drop: false),
          ],
        ),
      ),
    );
  }
}

/// Front-view lion with a gentle breathing bob.
class _IdleLion extends StatefulWidget {
  const _IdleLion({required this.stage});

  final EvolutionStage stage;

  @override
  State<_IdleLion> createState() => _IdleLionState();
}

class _IdleLionState extends State<_IdleLion> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.diagonal3Values(1 + 0.015 * t, 1 - 0.025 * t, 1),
          child: child,
        );
      },
      child: Image.asset(
        AssetPaths.full(widget.stage.frontSprite),
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
      ),
    );
  }
}
