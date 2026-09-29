import 'package:flutter/material.dart';

import '../core/services/services.dart';
import '../core/theme/app_colors.dart';
import '../models/upgrade_type.dart';
import '../ui/svg/game_icons.dart';
import 'coin_counter.dart';
import 'game_button.dart';
import 'game_dialog.dart';
import 'upgrade_card.dart';

void showSettingsDialog(BuildContext context) {
  final s = services.settings;
  showGameDialog<void>(
    context,
    title: 'SETTINGS',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToggleRow(label: 'Sound', on: GameIcon.soundOn, off: GameIcon.soundOff, value: s.sound),
        _ToggleRow(label: 'Music', on: GameIcon.musicOn, off: GameIcon.musicOff, value: s.music),
        _ToggleRow(label: 'Vibration', on: GameIcon.vibrate, off: GameIcon.vibrate, value: s.haptics),
      ],
    ),
  );
}

void showUpgradesDialog(BuildContext context) {
  showGameDialog<void>(
    context,
    title: 'UPGRADES',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CoinCounter(height: 42),
        const SizedBox(height: 12),
        for (final t in UpgradeType.values) ...[
          UpgradeCard(type: t),
          const SizedBox(height: 10),
        ],
      ],
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.on, required this.off, required this.value});

  final String label;
  final GameIcon on;
  final GameIcon off;
  final ValueNotifier<bool> value;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: value,
      builder: (context, v, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            GameSvgIcon(v ? on : off, size: 34, color: AppColors.outlineSoft, shadow: false),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.outline),
              ),
            ),
            GameButton(
              width: 104,
              height: 50,
              label: v ? 'ON' : 'OFF',
              skin: v ? ButtonSkin.green : ButtonSkin.red,
              onPressed: () => value.value = !v,
            ),
          ],
        ),
      ),
    );
  }
}
