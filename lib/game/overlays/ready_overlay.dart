import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../ui/svg/game_icons.dart';
import '../../widgets/stroked_text.dart';

/// "Tap left / right" hint shown before the run starts. The first input starts the run.
class ReadyOverlay extends StatefulWidget {
  const ReadyOverlay({super.key, this.levelName});

  /// Shown above the hint for hand-tuned levels.
  final String? levelName;

  @override
  State<ReadyOverlay> createState() => _ReadyOverlayState();
}

class _ReadyOverlayState extends State<ReadyOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, 0.15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.levelName != null) ...[
              StrokedText(widget.levelName!.toUpperCase(), size: 40, color: AppColors.gold),
              const SizedBox(height: 18),
            ],
            AnimatedBuilder(
              animation: _c,
              builder: (_, _) => Transform.translate(
                offset: Offset((Curves.easeInOut.transform(_c.value) - 0.5) * 140, 0),
                child: const GameSvgIcon(GameIcon.paw, size: 64),
              ),
            ),
            const SizedBox(height: 12),
            const StrokedText('TAP LEFT or RIGHT', size: 30),
            const SizedBox(height: 6),
            const StrokedText('Eat meat to evolve!', size: 20),
          ],
        ),
      ),
    );
  }
}
