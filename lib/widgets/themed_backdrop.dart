import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/chapter.dart';
import '../ui/svg/backdrop_svg.dart';

/// Full-screen SVG scene coloured by the chapter. Cross-fades when the chapter changes.
class ThemedBackdrop extends StatelessWidget {
  const ThemedBackdrop({super.key, required this.chapter, this.child});

  final Chapter chapter;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          layoutBuilder: (current, previous) => Stack(
            fit: StackFit.expand,
            children: [...previous, ?current],
          ),
          child: SvgPicture.string(
            BackdropSvg.build(chapter.palette),
            key: ValueKey(chapter.id),
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
        ),
        ?child,
      ],
    );
  }
}
