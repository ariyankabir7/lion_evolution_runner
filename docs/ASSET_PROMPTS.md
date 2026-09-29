# Asset Generation Prompts — Lion Evolution Runner

How to use this:
- **Always attach `Healthy Lion.png` (and the matching existing sprite where noted) as a style reference.** That one habit stops most drift in style.
- Generate **one asset per image** unless a prompt says "sheet". Image AIs are unreliable at grids.
- **Background:** ask for a **solid flat magenta `#FF00FF`** background (not "transparent"). Most generators fake transparency with a checkerboard. I'll remove the magenta cleanly in code. If your tool exports real transparent PNGs, that's fine too.
- Save each file with the **exact filename** given, and drop them all in one folder. I'll handle sizing, trimming and placement.
- If a result has text, extra characters, cropped feet or a floor or shadow, regenerate it rather than keeping it.

---

## Shared blocks (paste into every prompt where you see them)

**[STYLE]**
> Mobile hyper-casual game asset, bright cheerful 2D cartoon style, thick dark-brown outline (about 1% of image width), soft cel shading with 2–3 tones per colour, warm light from the top-left, saturated colours, clean vector-like finish, exactly matching the art style, line weight and colouring of the attached reference image.

**[SPRITE RULES]**
> Single subject, centred, fully visible with nothing cropped, about 6% empty margin on every side. Solid flat pure magenta (#FF00FF) background filling the whole canvas. No floor, no ground shadow, no cast shadow, no text, no letters, no numbers, no watermark, no border, no frame, no extra objects, no other characters.

**[NEGATIVE]** (if your tool has a negative-prompt field)
> text, watermark, signature, logo, checkerboard, gradient background, scenery, floor, shadow, multiple characters, cropped, cut off, blurry, photorealistic, 3D render, painterly, sketch, extra limbs, deformed paws

---

## P0 — needed before/while building v1

### 1–3. Lion seen from behind (the player runs away from the camera)
Attach the matching front-view sprite each time (`Starving Lion.png`, `Healthy Lion.png`, `Gladiator Lion.png`).

**`lion_starving_back.png`** — 1024×1024
> [STYLE] The exact same skinny starving lion character as the attached reference, now seen **directly from behind**, in a **mid-run pose on all four legs**, running away from the viewer into the distance. Thin body with visible ribs and hip bones along the sides, dull patchy pale-brown mane, droopy tail with a tuft, tired posture, head slightly lowered. Back view only: we see the back of the mane, the spine, the hind legs and the paw pads of one lifted hind paw. Body is symmetrical and upright, not rotated. The character fills about 80% of the canvas height. [SPRITE RULES]

**`lion_healthy_back.png`** — 1024×1024
> [STYLE] The exact same strong healthy golden lion as the attached reference, now seen **directly from behind**, in a **confident mid-run pose on all four legs**, running away from the viewer. Big fluffy orange-gold mane seen from the back, muscular shoulders and haunches, tail with a dark-brown tuft raised in an S-curve, one hind paw lifted showing pink-brown paw pads. Symmetrical, upright, not rotated. The character fills about 80% of the canvas height. [SPRITE RULES]

**`lion_gladiator_back.png`** — 1024×1024
> [STYLE] The exact same anthropomorphic gladiator lion warrior as the attached reference, now seen **directly from behind**, **running upright on two legs** away from the viewer. Big golden mane, broad muscular back, bronze shoulder armour and leather straps across the back, short red cape flowing behind, leather battle skirt, sandals, tail showing below the skirt, broadsword held in the right hand pointing down and back. Symmetrical, upright, not rotated. The character fills about 85% of the canvas height. [SPRITE RULES]

> *Optional, only if the single frames come out consistent:* the same three as a **4-frame run cycle**, `lion_<stage>_back_run.png`, 2048×512. Prompt addition: "sprite sheet, exactly 4 frames in one horizontal row, each frame 512×512, the identical character in every frame, only the leg positions change to form a looping run cycle, frames evenly spaced, nothing crossing frame borders." If they drift in style, skip them: I'll animate the single frame in code.

### 4. Coin
**`coin.png`** — 512×512
> [STYLE] A single shiny gold game coin seen from the front, perfectly round, thick raised rim, a simple embossed **lion paw print** in the centre, warm yellow-gold with an orange-gold rim, one soft white highlight on the upper left, a tiny sparkle. Flat front view, not tilted. [SPRITE RULES]

### 5–7. Upgrade icons (Home screen upgrade cards)
One per image, 512×512, same framing for all three.

**`upgrade_speed.png`**
> [STYLE] Game upgrade icon: a small, cute, determined golden lion head in three-quarter view with motion speed lines streaming behind it and a small yellow lightning bolt. Centred and compact, readable at 64px. [SPRITE RULES]

**`upgrade_food.png`**
> [STYLE] Game upgrade icon: a juicy pink-red raw meat steak on a white bone (the same style as the meat pickup in the reference) with a small green upward arrow badge in the bottom-right corner. Centred and compact, readable at 64px. [SPRITE RULES]

**`upgrade_shield.png`**
> [STYLE] Game upgrade icon: a rounded heater-shaped shield, bright blue face with a light-blue inner border and a thick gold rim, a simple gold lion paw print emblem in the centre, glossy highlight on the upper left. Centred, front view, readable at 64px. [SPRITE RULES]

### 8. Logo
**`logo.png`** — 1536×1024 *(reply with the final game title first, so the text is right)*
> [STYLE] Mobile game title logo reading exactly "**LION**" on the top line and "**RUNNER**" on the second line. No other words. Chunky rounded bold cartoon letters. "LION" is large, in glossy yellow-to-orange gradient with a thick dark-brown outline and a 3D bevelled depth, with the letter O replaced by a dark-brown lion paw print inside a golden circle. "RUNNER" is smaller, white with a dark-brown outline, sitting on a wooden plank banner. Green jungle leaves poke out from behind both sides. Spelled exactly L-I-O-N and R-U-N-N-E-R. [SPRITE RULES]
>
> ⚠ Check the spelling letter by letter. If your tool keeps misspelling it, generate it **without any text** ("an empty wooden plank banner with jungle leaves and a golden paw-print emblem") and I'll set the title text in code.

### 9. Home screen background
**`bg_home.png`** — 1080×1920 portrait, **no magenta, full scene**
> [STYLE] Vertical mobile game background, portrait 9:16. A sunny tropical jungle valley: tall orange-brown rocky cliffs on the left and right edges, lush green jungle trees and ferns, soft blue sky with a few fluffy clouds at the top. In the lower-middle, a flat sandy-brown rock platform where a character will stand. **The centre of the image is open and uncluttered** (UI will be placed over it). Gentle depth: distant cliffs are lighter and hazier. No characters, no animals, no text, no UI, no logo.

### 10. App icon
**`app_icon.png`** — 1024×1024, **full square, no magenta, no transparency**
> [STYLE] Mobile app icon. Close-up of the friendly healthy golden lion's face from the attached reference, smiling confidently, big fluffy mane filling most of the square, bright jungle-green radial background with soft light rays behind the head. No text, no border, no rounded corners (the phone adds them). Bold and readable at small sizes.

---

## P1 — polish (nice to have for v1)

**`bg_level_select.png`** — 1080×1920, full scene
> [STYLE] Vertical 9:16 mobile game background: a jungle canyon, rocky cliffs on both sides, green foliage, blue sky at the top, a sandy rocky ground strip along the bottom 20%. The middle 70% is a calm, slightly blurred, low-detail area (a grid of buttons will cover it). No characters, no text, no UI.

**`finish_gate.png`** — 1536×1024
> [STYLE] A wide finish-line arch for a running game, front view: two thick wooden jungle posts wrapped in green vines and leaves on the left and right, joined at the top by a horizontal wooden plank banner with a black-and-white checkered stripe along it. **The banner is blank, with no words.** The space between the posts is completely empty (the road passes through). [SPRITE RULES]

**`lion_gladiator_victory.png`** — 1024×1024 (attach `Gladiator Lion.png`)
> [STYLE] The exact same gladiator lion warrior as the reference, front view, triumphant victory pose: broadsword raised high above his head in the right hand, left fist pumped, mouth open in a proud roar, cape flowing. [SPRITE RULES]

**`lion_defeated.png`** — 1024×1024 (attach `Healthy Lion.png`)
> [STYLE] The exact same golden lion as the reference, knocked out: lying flat on its belly facing the viewer, legs splayed out, dizzy swirl eyes, tongue slightly out, three small cartoon stars circling above its head. Funny, not violent, no blood. [SPRITE RULES]

**Extra obstacles** (each 1024×1024, attach `Spikes Barrier Obstacle.png` for style; front view as the runner sees it; wide and low, about 2× wider than tall):
- **`obstacle_log.png`** > [STYLE] A thick fallen tree log lying horizontally across a road, front view, brown bark with rings visible on the ends, a few small green leaves. [SPRITE RULES]
- **`obstacle_rock.png`** > [STYLE] A cluster of three chunky grey boulders side by side, front view, a little moss on top. [SPRITE RULES]
- **`obstacle_thorns.png`** > [STYLE] A low, wide thorny bramble bush, dark green with sharp red-tipped thorns, front view. [SPRITE RULES]
- **`obstacle_mud.png`** > [STYLE] A flat muddy puddle seen from a low angle, dark brown mud with a few bubbles and splashes, wide oval shape. [SPRITE RULES]

---

## P2 — chapter themes (10 chapters × 100 levels)

Each chapter needs 3 images: **road**, **horizon**, **boss**. Until these arrive, all chapters reuse the current art with a colour tint.

### Road texture template — `road_<theme>.png`, 1080×1920, full scene
Attach the existing **`Base scrolling texture for Flame game road component..png`** and say:
> [STYLE] Top-down perspective game road texture, portrait 9:16, **keep exactly the same perspective, road width and road position as the attached reference image**: the road narrows toward the top and fills the full width at the bottom. Theme: **{ROAD_THEME}**. The road surface is plain and even, **with NO centre lane dashes and NO striped curbs**: instead, a plain solid-colour edge band of {EDGE_COLOUR} along both road edges. The ground outside the road shows {SIDE_DETAIL}. No characters, no objects on the road, no text, no arrows.

*(The dashes and moving curb stripes are drawn in code so they can scroll smoothly.)*

### Horizon template — `horizon_<theme>.png`, 1080×720, full scene
> [STYLE] Wide distant horizon backdrop for the top of a vertical running game: {HORIZON_SCENE}. Sky in the top half, distant scenery in the bottom half. The very bottom edge is a flat ground line in {GROUND_COLOUR} so it joins the road. No characters, no text.

### Boss template — `boss_<name>.png`, 1024×1024
Attach `Boss Gladiator Lion (Enemy).png` for style and scale:
> [STYLE] Menacing but kid-friendly cartoon boss character for a mobile game: **{BOSS_DESCRIPTION}**. Standing upright on two legs, **front view facing the viewer**, heroic wide stance, feet touching the bottom margin, filling about 90% of the canvas height, angry determined expression, a little dark armour and a weapon matching the description. Same line weight and shading as the reference. [SPRITE RULES]

### Chapter table (fill the {placeholders} above from this)

| # | theme id | ROAD_THEME / EDGE_COLOUR / SIDE_DETAIL | HORIZON_SCENE / GROUND_COLOUR | BOSS_DESCRIPTION |
|---|---|---|---|---|
| 1 | savanna | dusty dark-grey asphalt / warm tan / golden dry grass and small acacia shrubs | golden savanna, flat-topped acacia trees, orange sunset sky / golden grass | a hyena warlord, spotted fur, wild grin, bone club, leather shoulder pad |
| 2 | jungle | dark asphalt / mossy green / dense ferns and jungle leaves | thick rainforest canopy, misty waterfalls, green hills / deep green | a huge silverback gorilla brute, leaf-and-vine armour, giant wooden club |
| 3 | desert | sandy beige packed-dirt road / terracotta / sand dunes, cacti, dry rocks | red-orange canyon mesas under a hot pale sky / sand beige | an armoured rhino brute, bronze plates, spiked war hammer |
| 4 | swamp | muddy dark-brown boardwalk planks / dark wood / murky green water with lily pads and reeds | foggy swamp with twisted mangrove trees, pale green sky / murky olive | a crocodile king wearing a gold crown, scaly armour, trident |
| 5 | snow | icy blue-grey road / white snowbank / snow-covered ground and small pine trees | snowy mountain peaks, pale blue sky, light snowfall / white snow | a polar bear warrior, fur cloak, ice-crystal axe |
| 6 | bamboo | stone-slab path / light grey stone / bamboo stalks and small lanterns | bamboo forest hills and a distant pagoda, soft peach sky / mossy green | a tiger martial-arts master, black belt, red sash, bamboo staff |
| 7 | volcano | black basalt road with glowing orange cracks / dark red / black rocks and small lava pools | erupting volcano, dark red-orange sky, ash clouds / charcoal | a fire buffalo brute, glowing horns, magma armour, flaming axe |
| 8 | night | dark navy asphalt / teal glow / dark blue grass and fireflies | moonlit savanna, big full moon, starry purple sky / deep navy | a black panther assassin, purple cloak, twin curved daggers, glowing yellow eyes |
| 9 | ruins | cracked sandstone tiles / carved gold border / broken pillars and vines | ancient temple ruins, stone statues, golden hour sky / sandstone | a stone golem shaped like a lion, cracked rock body, glowing blue runes, stone fists |
| 10 | colosseum | arena sand / red stone / stone arena stands | grand Roman colosseum interior with crowds as simple shapes, blue sky / arena sand | *(use existing `Boss Gladiator Lion (Enemy).png` — final boss)* |

---

## Hand-back checklist
Send in any order. P0 first unlocks the most:
- [ ] lion_starving_back · lion_healthy_back · lion_gladiator_back
- [ ] coin · upgrade_speed · upgrade_food · upgrade_shield
- [ ] logo (after the title is confirmed) · bg_home · app_icon
- [ ] P1 set
- [ ] P2 chapters (any order; each chapter needs all 3 files)

Audio isn't image-generated. I'll list exact sound effects and suggest free CC0 sources when we reach the audio milestone.
