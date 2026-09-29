import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'stroked_text.dart';

/// Parchment card with a wooden frame, optionally with a title ribbon on top.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.fromLTRB(20, 28, 20, 20),
    this.ribbon = AppColors.orange,
    this.ribbonShade = AppColors.orangeShade,
  });

  final Widget child;
  final String? title;
  final EdgeInsets padding;
  final Color ribbon;
  final Color ribbonShade;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: EdgeInsets.only(top: title == null ? 0 : 26),
      decoration: BoxDecoration(
        color: AppColors.wood,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.outline, width: 4),
        boxShadow: const [BoxShadow(color: Color(0x55000000), offset: Offset(0, 8), blurRadius: 0)],
      ),
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.woodDark, width: 3),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cream, AppColors.parchment],
          ),
        ),
        padding: padding,
        child: child,
      ),
    );
    if (title == null) return card;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        card,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline, width: 4),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(ribbon, Colors.white, 0.15)!, ribbon, ribbonShade],
            ),
          ),
          child: StrokedText(title!, size: 30),
        ),
      ],
    );
  }
}
