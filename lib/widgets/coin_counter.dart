import 'package:flutter/material.dart';

import '../core/constants/asset_paths.dart';
import '../core/services/services.dart';
import '../core/theme/app_colors.dart';
import 'stroked_text.dart';

/// Dark pill with the coin sprite and the live wallet balance.
class CoinCounter extends StatelessWidget {
  const CoinCounter({super.key, this.height = 48});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: services.wallet.coins,
      builder: (context, coins, _) => Container(
        height: height,
        padding: EdgeInsets.only(left: height * 0.1, right: height * 0.4),
        decoration: BoxDecoration(
          color: AppColors.outline.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(height),
          border: Border.all(color: AppColors.outline, width: 3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AssetPaths.full(AssetPaths.coin), height: height * 0.85),
            SizedBox(width: height * 0.15),
            TweenAnimationBuilder<double>(
              tween: Tween(end: coins.toDouble()),
              duration: const Duration(milliseconds: 500),
              builder: (_, v, _) => StrokedText(
                _format(v.round()),
                size: height * 0.5,
                color: AppColors.gold,
                drop: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _format(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}
