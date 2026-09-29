import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/services/services.dart';
import '../../core/theme/app_colors.dart';
import '../../ui/svg/game_icons.dart';
import '../../widgets/game_button.dart';
import '../../widgets/panel.dart';
import '../lion_game.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});

  final LionGame game;

  @override
  Widget build(BuildContext context) {
    final settings = services.settings;
    return ColoredBox(
      color: const Color(0xAA000000),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Panel(
              title: 'PAUSED',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GameButton(label: 'RESUME', icon: GameIcon.play, width: double.infinity, onPressed: game.resume),
                  const SizedBox(height: 12),
                  GameButton(
                    label: 'RESTART',
                    icon: GameIcon.restart,
                    skin: ButtonSkin.blue,
                    width: double.infinity,
                    onPressed: () => Navigator.of(context)
                        .pushReplacementNamed(Routes.game, arguments: game.config.level),
                  ),
                  const SizedBox(height: 12),
                  GameButton(
                    label: 'HOME',
                    icon: GameIcon.home,
                    skin: ButtonSkin.orange,
                    width: double.infinity,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Toggle(value: settings.sound, on: GameIcon.soundOn, off: GameIcon.soundOff),
                      const SizedBox(width: 16),
                      _Toggle(value: settings.music, on: GameIcon.musicOn, off: GameIcon.musicOff),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.on, required this.off});

  final ValueNotifier<bool> value;
  final GameIcon on;
  final GameIcon off;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: value,
        builder: (_, v, _) => GameButton.round(
          icon: v ? on : off,
          skin: v ? ButtonSkin.green : const ButtonSkin(AppColors.grey, AppColors.greyShade),
          size: 58,
          onPressed: () => value.value = !v,
        ),
      );
}
