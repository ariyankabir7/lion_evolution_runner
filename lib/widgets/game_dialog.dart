import 'package:flutter/material.dart';

import '../ui/svg/game_icons.dart';
import 'game_button.dart';
import 'panel.dart';

/// Pops a [Panel] in with a bounce, with a close button on its top-right corner.
Future<T?> showGameDialog<T>(
  BuildContext context, {
  required String title,
  required Widget child,
  bool dismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: title,
    barrierColor: const Color(0xAA000000),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, _, _) => SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Panel(title: title, child: child),
                  if (dismissible)
                    Positioned(
                      right: -8,
                      top: 12,
                      child: GameButton.round(
                        icon: GameIcon.close,
                        skin: ButtonSkin.red,
                        size: 52,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, anim, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: anim, child: child),
    ),
  );
}
