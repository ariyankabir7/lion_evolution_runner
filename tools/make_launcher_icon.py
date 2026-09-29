#!/usr/bin/env python3
"""Builds the Android launcher icons from design/app_icon_1024.png.

- Legacy square + round icons for every density (pre-Android 8 launchers).
- Adaptive icon (Android 8+): the art scaled into the 108dp foreground so the face survives circle,
  squircle and teardrop masks, over a blurred copy of itself so edges never show a seam.
- design/play_store_icon_512.png for the Play Console.

    python3 tools/make_launcher_icon.py
"""
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), '..')
SRC = os.path.join(ROOT, 'design', 'app_icon_1024.png')
RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
ART_SCALE = 0.80  # share of the 108dp adaptive canvas the art covers


def rounded(img, radius_frac):
    mask = Image.new('L', img.size, 0)
    r = int(img.size[0] * radius_frac)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.size[0] - 1, img.size[1] - 1], r, fill=255)
    out = img.convert('RGBA')
    out.putalpha(mask)
    return out


def circle(img):
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).ellipse([0, 0, img.size[0] - 1, img.size[1] - 1], fill=255)
    out = img.convert('RGBA')
    out.putalpha(mask)
    return out


def adaptive_foreground(src, px):
    bg = src.resize((px, px), Image.LANCZOS).filter(ImageFilter.GaussianBlur(px * 0.04))
    art = src.resize((int(px * ART_SCALE),) * 2, Image.LANCZOS)
    off = (px - art.size[0]) // 2
    bg.paste(art, (off, off))
    return bg


def main():
    src = Image.open(SRC).convert('RGB')
    for name, k in DENSITIES.items():
        d = os.path.join(RES, f'mipmap-{name}')
        os.makedirs(d, exist_ok=True)
        legacy = src.resize((int(48 * k),) * 2, Image.LANCZOS)
        rounded(legacy, 0.18).save(os.path.join(d, 'ic_launcher.png'))
        circle(legacy).save(os.path.join(d, 'ic_launcher_round.png'))
        adaptive_foreground(src, int(108 * k)).save(os.path.join(d, 'ic_launcher_foreground.png'))

    # Background colour sampled from the art's edge, used behind the foreground layer.
    r, g, b = src.resize((1, 1), Image.BOX, box=(0, 0, 1024, 60)).getpixel((0, 0))
    values = os.path.join(RES, 'values')
    with open(os.path.join(values, 'ic_launcher_background.xml'), 'w') as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
                f'    <color name="ic_launcher_background">#{r:02X}{g:02X}{b:02X}</color>\n</resources>\n')

    anydpi = os.path.join(RES, 'mipmap-anydpi-v26')
    os.makedirs(anydpi, exist_ok=True)
    xml = ('<?xml version="1.0" encoding="utf-8"?>\n'
           '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
           '    <background android:drawable="@color/ic_launcher_background" />\n'
           '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
           '</adaptive-icon>\n')
    for n in ('ic_launcher.xml', 'ic_launcher_round.xml'):
        with open(os.path.join(anydpi, n), 'w') as f:
            f.write(xml)

    src.resize((512, 512), Image.LANCZOS).save(os.path.join(ROOT, 'design', 'play_store_icon_512.png'))
    print('Launcher icons written.')


if __name__ == '__main__':
    main()
