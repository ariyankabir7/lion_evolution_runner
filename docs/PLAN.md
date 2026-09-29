# Lion Evolution Runner — Build Plan (v1, draft for confirmation)

Platform: **Android only** · Engine: **Flutter + Flame** · Orientation: **portrait** · Game resolution: **720×1280 fixed camera**

## 1. Decisions so far

| Topic | Decision |
|---|---|
| Scope | PRD core **+ coins + upgrades (Speed / Food / Shield)**. No gems, skins, shop, daily or rewards in v1. |
| Lanes | **2 lanes** (left / right) |
| Levels | **1000 levels**, made by a seeded generator (level 437 is always identical). Levels 1–20 are hand-tuned in JSON. |
| Collision | Logical (lane + distance), not pixel hitboxes |
| Boss formula | `win if HP ≥ BossPower` (the PRD's attack multiplier is dropped) |
| State | `ValueNotifier`s + small services, no Riverpod |
| Packages | `flame`, `flame_audio`, `shared_preferences`, `flutter_svg` |
| Title | **Lion Evolution Runner** (logo drawn in code: `widgets/title_logo.dart`) |
| UI art | Drawn in code/SVG wherever possible so it re-colours per chapter: buttons, panels, icons (`ui/svg/game_icons.dart`), menu backdrop (`ui/svg/backdrop_svg.dart`, built from `ChapterPalette`). Raster art only for characters, bosses, items, effects. |
| Asset pipeline | Raw art lives in `design/raw/`; `python3 tools/process_assets.py` keys out magenta, splits sheets, trims and writes `assets/images/`. |

## 2. Core rules

- HP 0–100, shown as 5 segments (20 HP each). Runs start at **35 HP** (Starving; one early obstacle hit leaves 5 HP instead of killing).
- Stages: Starving 0–39 · Healthy 40–79 · Gladiator 80–100.
- Meat **+20** (Food upgrade raises this). Broccoli **−20**. Spikes and other hard obstacles **−30**, with knockback and camera shake.
- HP reaches 0 → the lion collapses → Defeat.
- Every level puts meat before the first hazard.
- Finish line → input locks, the lion snaps to the centre, 1.2s dust-cloud fight, then Victory or Defeat.
- **Stars:** ★ win · ★★ win with more than 20 HP to spare over the boss · ★★★ win at 100 HP.

## 3. Economy (coins + upgrades)

- **Coins** are a third pickup on the track (small, in lines). Completing a level gives a bonus of `10 + 10×stars`, **doubled on boss levels**. Replays pay only 25% of the bonus. Coins collected are kept even on defeat.
- Measured income (70% of coins picked up, 2 stars on average): ~40 coins per level early, ~65 later; ~5k by level 100, ~31k by level 500.
- **Upgrades** (each max Lv 10, cost = `base × 1.32^level`, rounded to 5). First buy after ~4 levels; everything maxed around level 450 (~29k total).

| Upgrade | Effect per level | Base cost |
|---|---|---|
| Speed | Faster lane switching (agility): 0.22s → 0.12s at Lv 10. Run speed stays set by the level. | 150 |
| Food | Meat HP +20 → +30 (+1 per level) | 200 |
| Shield | +1 blocked hit at Lv 1, 3, 5, 7, 10 (5 at max). Lv 2, 4, 6, 8, 9: longer invincibility after a block (0.5s → 1.5s). Lv 10 also bounces broccoli while the shield holds. | 250 |

- Home shows a red "!" on UPGRADES whenever something is affordable; a defeat screen offers UPGRADE when affordable.

## 4. Level generation (1000 levels)

- **Chapters:** 10 chapters × 100 levels. Each chapter has a theme (road, horizon, boss). Until themed art arrives, every chapter uses the current art with a colour tint.
- **Difficulty** comes from the level number `n` in two parts:
  - a slow global rise over the first ~300 levels, then a plateau;
  - a sawtooth within each chapter: every 10th level is a "boss level" (harder, bigger coin reward) and the level after it eases off.
- **Generated from the level number:** run speed, track length (25–60s of running), spacing between items, the mix of patterns (single, zig-zag, "meat behind spikes" traps, choice rows with broccoli in one lane and meat in the other), and boss power (40 → 100, scaled so a mostly clean run always wins).
- **Checks:** the generator simulates a perfect run and rejects any level where the best possible HP is below the boss's power. A unit test runs all 1000 levels through this check.
- **Level Select:** tabs per chapter plus a lazy-loaded grid of 100 levels. It auto-scrolls to the current level, and each tile shows its state (locked / current, pulsing / stars).

## 5. Project structure

```
assets/
  images/
    characters/  lion_{starving,healthy,gladiator}[_back].png  boss_*.png
    items/       meat.png broccoli.png spikes.png coin.png (+ obstacle variants)
    effects/     dust_cloud.png
    track/       road_<theme>.png  horizon_<theme>.png
    ui/          logo.png  bg_home.png  icons/*.png  upgrades/*.png
  audio/sfx/  audio/music/
  fonts/
  levels/handcrafted.json          # levels 1–20
design/raw/                        # original generated PNGs (moved out of root)
lib/
  main.dart  app.dart
  core/
    constants/  asset_paths.dart  game_constants.dart  economy.dart
    theme/      app_colors.dart  app_theme.dart
    services/   progress_service.dart  wallet_service.dart  upgrade_service.dart
                settings_service.dart  audio_service.dart
  models/       evolution_stage.dart  item_type.dart  level_config.dart
                spawn_entry.dart  level_result.dart  upgrade_type.dart  chapter.dart
  data/         level_repository.dart   level_generator.dart   chapter_catalog.dart
  screens/      splash_screen.dart  home_screen.dart  level_select_screen.dart  game_screen.dart
  widgets/      game_button.dart  stroked_text.dart  level_tile.dart  star_rating.dart
                hp_bar.dart  coin_counter.dart  upgrade_card.dart  panel.dart
  game/
    lion_game.dart   game_session.dart
    world/       perspective.dart  track_component.dart  spawn_manager.dart
    components/  lion_player.dart  pickup_component.dart  obstacle_component.dart
                 finish_line_component.dart  boss_component.dart
                 dust_cloud_component.dart  floating_text_component.dart
    effects/     sparkle.dart  confetti.dart  hit_flash.dart  camera_shake.dart
    overlays/    overlay_ids.dart  hud_overlay.dart  pause_overlay.dart
                 victory_overlay.dart  defeat_overlay.dart
test/  evolution_stage_test  boss_resolution_test  star_rating_test
       level_generator_test (all 1000 levels winnable, deterministic)  economy_test
```

## 6. Milestones

1. **Setup:** packages, move and trim assets, theme, services, routing, splash.
2. **Core run:** perspective track, lion, lane swipe, pickups and obstacles, HP and evolution, HUD, pause.
3. **Boss and results:** finish line, fight, victory/defeat, stars, saved progress.
4. **Levels:** generator, 20 hand-tuned levels, chapters, Level Select.
5. **Economy:** coins, upgrades on Home, balancing.
6. **Polish:** audio, particles, and swapping in new art as it arrives.
   - Audio: 16 SFX + a 32s music loop synthesised by `tools/generate_audio.py`; `AudioService` plays them through low-latency pools and respects the Sound/Music toggles. Drop-in CC0 list in `docs/AUDIO.md`.
   - Roadside decor per chapter (acacias, palms, cacti, pines, bamboo, columns…) drawn in code from the chapter palette; speed lines, dust trail, pickup/hit particle bursts, lane-change swoosh, shield bubble.
   - Launcher icon (legacy + adaptive) from `design/app_icon_1024.png` via `tools/make_launcher_icon.py`.

The game is built so missing art never blocks it: every new asset has a stand-in until it arrives.
