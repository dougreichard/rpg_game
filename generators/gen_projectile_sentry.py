#!/usr/bin/env python3
"""Sentry projectile sprite sheet — PIL procedural.
320x32 px RGBA (1 row x 10 cols x 32x32).
Single animation "fly" — 4 frames of a spinning cyan/orange energy disc.
Remaining 6 columns are transparent padding (SpriteLoader pads to 10 cols).

Note: tile size is 32x32 (not 64x64) — projectiles live at the 32px
gameplay-grid scale, no oversample needed.
"""
from PIL import Image, ImageDraw
from _sprite_common import INK, TR, save_sheet
import math, os

T = 32

CYAN_CORE  = (100, 220, 210, 255)   # #64DCD2 cyan inner disc
ORANGE_OUT = (255, 154,  60, 255)   # #FF9A3C orange outer ring / glow arms
HOTSPOT    = (240, 240, 200, 255)   # #F0F0C8 bright white-yellow center
GLOW_DIM   = (200, 100,  30, 180)   # semi-transparent outer halo
TR         = (  0,   0,   0,   0)

COLS = 10


def _frame(phase_deg: float) -> Image.Image:
    """One 32x32 projectile frame.
    phase_deg: rotation of the glow arms (0, 45, 90, 135).
    """
    im = Image.new("RGBA", (T, T), TR)
    d  = ImageDraw.Draw(im, "RGBA")
    cx, cy = T // 2, T // 2

    # Outer halo ring (semi-transparent)
    d.ellipse([cx - 10, cy - 10, cx + 10, cy + 10], fill=GLOW_DIM)

    # Four glow arms emanating at phase_deg, 90° apart
    for i in range(4):
        angle = math.radians(phase_deg + i * 90)
        for r in range(7, 12):
            px = int(cx + math.cos(angle) * r)
            py = int(cy + math.sin(angle) * r)
            if 0 <= px < T and 0 <= py < T:
                # Fade alpha with distance
                alpha = int(200 - (r - 7) * 35)
                im.putpixel((px, py), ORANGE_OUT[:3] + (alpha,))

    # Cyan core disc
    d.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=CYAN_CORE)

    # INK outline on core
    d.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], outline=INK, width=1)

    # Bright hotspot center
    d.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=HOTSPOT)

    return im


def generate():
    phases = [0.0, 45.0, 90.0, 135.0]
    frames = [_frame(p) for p in phases]

    # Pack into 320x32 sheet (10 cols, first 4 used, rest transparent)
    sheet = Image.new("RGBA", (T * COLS, T), TR)
    for col, frame in enumerate(frames):
        sheet.paste(frame, (col * T, 0))

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out  = os.path.join(root, "assets", "art", "sprites", "projectile_sentry.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(f"Saved 320x32 -> {out}")
    print(f"  fly  {len(frames)} frames")


if __name__ == "__main__":
    generate()
