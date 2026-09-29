import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/splash_screen.dart';

abstract final class Routes {
  static const splash = '/';
  static const home = '/home';
  static const levels = '/levels';

  /// Argument: the level number (int).
  static const game = '/game';
}

class LionApp extends StatelessWidget {
  const LionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lion Evolution Runner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      initialRoute: Routes.splash,
      onGenerateRoute: (settings) {
        final Widget page = switch (settings.name) {
          Routes.home => const HomeScreen(),
          Routes.levels => const LevelSelectScreen(),
          Routes.game => GameScreen(level: settings.arguments as int? ?? 1),
          _ => const SplashScreen(),
        };
        return PageRouteBuilder<void>(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (_, _, _) => page,
          transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }
}
