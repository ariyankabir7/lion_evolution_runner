import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../data/chapter_catalog.dart';
import '../data/level_repository.dart';
import '../game/game_session.dart';
import '../game/lion_game.dart';
import '../game/overlays/hud_overlay.dart';
import '../game/overlays/overlay_ids.dart';
import '../game/overlays/pause_overlay.dart';
import '../game/overlays/ready_overlay.dart';
import '../game/overlays/result_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level});

  final int level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final LionGame _game = LionGame(
    config: LevelRepository.instance.load(widget.level),
    chapter: ChapterCatalog.forLevel(widget.level),
  );

  /// Horizontal drag since the gesture started, so one swipe = one lane change.
  double _dragDx = 0;
  bool _dragUsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _game.pause();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final s = _game.session.state.value;
        if (s == RunState.paused) {
          _game.resume();
        } else if (s == RunState.running) {
          _game.pause();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, box) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _game.moveLane(d.localPosition.dx < box.maxWidth / 2 ? 0 : 1),
            onHorizontalDragStart: (_) {
              _dragDx = 0;
              _dragUsed = false;
            },
            onHorizontalDragUpdate: (d) {
              if (_dragUsed) return;
              _dragDx += d.delta.dx;
              if (_dragDx.abs() > 24) {
                _dragUsed = true;
                _game.moveBy(_dragDx.sign.toInt());
              }
            },
            child: GameWidget<LionGame>(
              game: _game,
              autofocus: true,
              overlayBuilderMap: {
                OverlayIds.hud: (_, g) => HudOverlay(game: g),
                OverlayIds.ready: (_, g) => ReadyOverlay(levelName: g.config.name),
                OverlayIds.pause: (_, g) => PauseOverlay(game: g),
                OverlayIds.result: (_, g) => ResultOverlay(game: g),
              },
            ),
          ),
        ),
      ),
    );
  }
}
