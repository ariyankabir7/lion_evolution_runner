#!/usr/bin/env python3
"""Turns the raw generated art in design/raw/ into game-ready PNGs in assets/images/.

- Keys out a flat magenta (#FF00FF) background (sheets that are already RGBA are left alone).
- Splits sprite sheets into single sprites by finding empty rows/columns.
- Trims transparent margins, adds a small pad, and caps the longest side.

Run from the repo root:  python3 tools/process_assets.py
Needs: pillow, numpy.
"""
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / 'design' / 'raw'
OUT = ROOT / 'assets' / 'images'
OUTLINE = np.array([58, 32, 20], dtype=np.float32)  # dark-brown outline colour of the art style
PAD = 4


def key_magenta(img: Image.Image) -> Image.Image:
    """Magenta -> transparent. Edge pixels get partial alpha and are recoloured to the outline colour."""
    if img.mode == 'RGBA' and np.array(img)[:, :, 3].min() < 255:
        return img
    a = np.asarray(img.convert('RGB')).astype(np.float32)
    dist = np.sqrt(((a - np.array([255, 0, 255], dtype=np.float32)) ** 2).sum(axis=2))
    lo, hi = 90.0, 190.0
    alpha = np.clip((dist - lo) / (hi - lo), 0, 1)
    edge = (alpha > 0) & (alpha < 1)
    rgb = a.copy()
    # Unmix the magenta out of fringe pixels: blend toward the outline colour.
    rgb[edge] = OUTLINE * (1 - alpha[edge, None]) + a[edge] * alpha[edge, None]
    rgb[edge, 0] = np.minimum(rgb[edge, 0], rgb[edge, 1] + 80)
    rgb[edge, 2] = np.minimum(rgb[edge, 2], rgb[edge, 1] + 40)
    out = np.dstack([rgb, alpha * 255]).clip(0, 255).astype(np.uint8)
    return Image.fromarray(out, 'RGBA')


def _runs(mask_1d: np.ndarray, min_gap: int):
    """Returns (start, end) spans where mask is True, merging gaps shorter than min_gap."""
    spans, start, gap = [], None, 0
    for i, v in enumerate(mask_1d):
        if v:
            if start is None:
                start = i
            gap = 0
        elif start is not None:
            gap += 1
            if gap >= min_gap:
                spans.append((start, i - gap + 1))
                start, gap = None, 0
    if start is not None:
        spans.append((start, len(mask_1d) - gap))
    return spans


def _components(mask: np.ndarray):
    """4-connected components -> ([x0, y0, x1, y1, pixel_count, {label ids}], label map)."""
    h, w = mask.shape
    seen = np.zeros_like(mask)
    labels = np.full(mask.shape, -1, dtype=np.int32)
    boxes = []
    for sy, sx in zip(*np.nonzero(mask)):
        if seen[sy, sx]:
            continue
        seen[sy, sx] = True
        label = len(boxes)
        queue = deque([(sy, sx)])
        x0 = x1 = sx
        y0 = y1 = sy
        n = 0
        while queue:
            y, x = queue.popleft()
            labels[y, x] = label
            n += 1
            x0, x1, y0, y1 = min(x0, x), max(x1, x), min(y0, y), max(y1, y)
            for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    queue.append((ny, nx))
        boxes.append([x0, y0, x1 + 1, y1 + 1, n, {label}])
    return boxes, labels


def split_sheet(img: Image.Image, cell: int = 2, small_ratio: float = 0.03):
    """Row-major list of sprites found as connected blobs, so sprites may overlap each other's rows.

    Works on a max-pooled mask (one cell = `cell` px, dilated by one cell) for speed. Small blobs,
    such as the stars above the knocked-out lion, are merged into the nearest big blob.
    """
    alpha = np.asarray(img)[:, :, 3] > 24
    h, w = alpha.shape
    hc, wc = h // cell, w // cell
    grid = alpha[: hc * cell, : wc * cell].reshape(hc, cell, wc, cell).any(axis=(1, 3))
    dil = grid.copy()
    dil[1:] |= grid[:-1]
    dil[:-1] |= grid[1:]
    dil[:, 1:] |= grid[:, :-1]
    dil[:, :-1] |= grid[:, 1:]

    boxes, labels = _components(dil)
    biggest = max(b[4] for b in boxes)
    big = [b for b in boxes if b[4] >= biggest * small_ratio]
    for s in (b for b in boxes if b[4] < biggest * small_ratio):
        cx, cy = (s[0] + s[2]) / 2, (s[1] + s[3]) / 2

        def gap(b):
            dx = max(b[0] - cx, 0, cx - b[2])
            dy = max(b[1] - cy, 0, cy - b[3])
            return dx * dx + dy * dy

        t = min(big, key=gap)
        t[0], t[1], t[2], t[3] = min(t[0], s[0]), min(t[1], s[1]), max(t[2], s[2]), max(t[3], s[3])
        t[5] |= s[5]

    # Row-major order: a blob starts a new row when its centre is below the current row's centres.
    big.sort(key=lambda b: (b[1] + b[3]) / 2)
    median_h = sorted(b[3] - b[1] for b in big)[len(big) // 2]
    rows, row_y = [], None
    for b in big:
        cy = (b[1] + b[3]) / 2
        if row_y is None or cy - row_y > median_h * 0.5:
            rows.append([])
            row_y = cy
        rows[-1].append(b)
    ordered = [b for row in rows for b in sorted(row, key=lambda b: b[0])]

    sprites = []
    for x0, y0, x1, y1, _, ids in ordered:
        box = (x0 * cell, y0 * cell, min(w, x1 * cell), min(h, y1 * cell))
        # Keep only this blob's own pixels, so a neighbour poking into the box is cut away.
        crop = img.crop(box)
        own = np.isin(labels[y0:y1, x0:x1], list(ids))
        keep = np.kron(own, np.ones((cell, cell), dtype=bool))[: crop.height, : crop.width]
        arr = np.array(crop)
        arr[..., 3] = np.where(keep, arr[..., 3], 0)
        sprites.append(trim(Image.fromarray(arr, 'RGBA')))
    return sprites


def grid_split(img: Image.Image, cols: int, rows: int):
    """Row-major cut of an evenly spaced sheet."""
    cw, ch = img.width / cols, img.height / rows
    return [
        trim(img.crop((round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch))))
        for r in range(rows)
        for c in range(cols)
    ]


def trim(img: Image.Image) -> Image.Image:
    a = np.asarray(img)[:, :, 3]
    ys, xs = np.where(a > 8)
    if len(xs) == 0:
        return img
    return img.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))


def save(img: Image.Image, rel: str, max_side: int):
    img = trim(img)
    w, h = img.size
    scale = min(1.0, max_side / max(w, h))
    if scale < 1:
        img = img.resize((round(w * scale), round(h * scale)), Image.LANCZOS)
    canvas = Image.new('RGBA', (img.width + PAD * 2, img.height + PAD * 2), (0, 0, 0, 0))
    canvas.paste(img, (PAD, PAD))
    dest = OUT / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(dest, optimize=True)
    print(f'  {rel:42s} {canvas.width}x{canvas.height}')


def load(name: str) -> Image.Image:
    return key_magenta(Image.open(RAW / name))


def save_frames(sheet: Image.Image, rel_pattern: str, max_side: int):
    """Walk-cycle sheets: every frame is scaled by the same factor so the lion doesn't pulse in size."""
    frames = split_sheet(sheet)
    box_w = max(f.width for f in frames)
    box_h = max(f.height for f in frames)
    scale = min(1.0, max_side / max(box_w, box_h))
    cw, ch = round(box_w * scale) + PAD * 2, round(box_h * scale) + PAD * 2
    for i, f in enumerate(frames):
        f = f.resize((max(1, round(f.width * scale)), max(1, round(f.height * scale))), Image.LANCZOS)
        canvas = Image.new('RGBA', (cw, ch), (0, 0, 0, 0))
        canvas.paste(f, ((cw - f.width) // 2, ch - PAD - f.height))  # bottom-centre aligned
        dest = OUT / rel_pattern.format(i)
        dest.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(dest, optimize=True)
    print(f'  {rel_pattern.format("N"):42s} {len(frames)} frames {cw}x{ch}')


def main():
    print('characters')
    for stage, front, back in [
        ('starving', 'Starving Lion.png', 'Starving Lion back.png'),
        ('healthy', 'Healthy Lion.png', 'Healthy Lion back.png'),
        ('gladiator', 'Gladiator Lion.png', 'lion_gladiator_back.png'),
    ]:
        save(load(front), f'characters/lion_{stage}.png', 512)
        save(load(back), f'characters/lion_{stage}_back.png', 512)
    save_frames(load('Starving Lion walking sprite.png'), 'characters/lion_starving_run_{}.png', 360)
    save_frames(load('Healthy Lion walking.png'), 'characters/lion_healthy_run_{}.png', 360)
    save_frames(load('lion_gladiator_walking.png'), 'characters/lion_gladiator_run_{}.png', 360)

    print('bosses + upgrade icons (new_boss sheet)')
    names = [
        'bosses/boss_hyena', 'bosses/boss_gorilla', 'bosses/boss_rhino', 'bosses/boss_crocodile',
        'bosses/boss_polar_bear', 'bosses/boss_tiger', 'bosses/boss_buffalo', 'bosses/boss_panther',
        'bosses/boss_golem', 'bosses/boss_lion_warlord', 'characters/lion_gladiator_victory',
        'characters/lion_defeated', 'ui/upgrades/upgrade_food', 'ui/upgrades/upgrade_speed',
    ]
    sheet = load('new_boss and upgrade ui.png')
    sprites = split_sheet(sheet)
    if len(sprites) != len(names):
        debug = ROOT / 'design' / 'debug_split_mask.png'
        Image.fromarray(np.asarray(sheet)[:, :, 3]).save(debug)
        raise SystemExit(f'expected {len(names)} sprites, found {len(sprites)}; alpha mask saved to {debug}')
    for name, sprite in zip(names, sprites):
        save(sprite, f'{name}.png', 512 if name.startswith('bosses') else 384)
    save(load(' Boss Gladiator Lion (Enemy).png'), 'bosses/boss_gladiator.png', 512)
    save(load('shield.png'), 'ui/upgrades/upgrade_shield.png', 384)

    print('items')
    save(load('Meat Bone Pickup.png'), 'items/meat.png', 320)
    save(load('Broccoli Pickup.png'), 'items/broccoli.png', 320)
    save(load('Spikes Barrier Obstacle.png'), 'items/spikes.png', 400)
    save(load('coin.png'), 'items/coin.png', 192)
    names = [
        None, None, 'items/apple', 'effects/sparkle',
        'items/log', 'items/rocks', 'items/thorns', 'items/mud',
        None, None, 'effects/speed_swoosh', 'effects/burst',
        None, 'effects/confetti', 'effects/explosion', 'effects/portal',
    ]
    sprites = grid_split(load('game elements.png'), 4, 4)
    for name, sprite in zip(names, sprites):
        if name:
            save(sprite, f'{name}.png', 256)
    save(load('Cartoon Fight Dust Cloud.png'), 'effects/dust_cloud.png', 512)

    print('track')
    road = Image.open(RAW / 'Base scrolling texture for Flame game road component..png').convert('RGB')
    dest = OUT / 'track' / 'road_base.jpg'
    dest.parent.mkdir(parents=True, exist_ok=True)
    road.resize((720, 1280), Image.LANCZOS).save(dest, quality=88)
    print('  track/road_base.jpg')

    print('icon')
    icon = Image.open(RAW / 'game_icon.png').convert('RGB')
    icon.resize((1024, 1024), Image.LANCZOS).save(ROOT / 'design' / 'app_icon_1024.png')
    icon.resize((256, 256), Image.LANCZOS).save(OUT / 'ui' / 'logo_face.png')
    print('  design/app_icon_1024.png, ui/logo_face.png')


if __name__ == '__main__':
    main()
