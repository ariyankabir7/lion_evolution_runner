import 'package:flutter/material.dart';

import '../app.dart';
import '../core/constants/asset_paths.dart';
import '../core/services/services.dart';
import '../core/theme/app_colors.dart';
import '../data/chapter_catalog.dart';
import '../widgets/themed_backdrop.dart';
import '../widgets/title_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  double _progress = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    const assets = AssetPaths.uiPreload;
    final minTime = Future<void>.delayed(const Duration(milliseconds: 1400));
    for (var i = 0; i < assets.length; i++) {
      await precacheImage(AssetImage(AssetPaths.full(assets[i])), context);
      if (!mounted) return;
      setState(() => _progress = (i + 1) / assets.length);
    }
    await minTime;
    if (mounted) Navigator.of(context).pushReplacementNamed(Routes.home);
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapter = ChapterCatalog.forLevel(services.progress.unlockedLevel.value);
    return Scaffold(
      body: ThemedBackdrop(
        chapter: chapter,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              ScaleTransition(
                scale: CurvedAnimation(parent: _intro, curve: Curves.elasticOut),
                child: const TitleLogo(width: 340),
              ),
              const Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.fromLTRB(60, 0, 60, 60),
                child: _LoadingBar(progress: _progress),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.outline.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.outline, width: 3),
      ),
      padding: const EdgeInsets.all(3),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 200),
          widthFactor: progress.clamp(0.06, 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFE680), AppColors.gold, AppColors.goldDeep],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
