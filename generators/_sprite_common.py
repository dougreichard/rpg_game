"""Shared helpers for the enemy sprite generators (Phase 1 of the
placeholder-art replacement plan).

INK/TR colors and tile()/add_outline() are factored from gen_frosty.py's
pattern, generalized for the non-square enemy tiles (Brute 96x64, Boss
128x128). save_sheet() packs a list of (anim_name, frames) rows into the
10-column sheet ENEMY_ANIMS/SpriteLoader._build() expects, padding short
rows with transparent tiles, and writes to assets/art/sprites/<out_name>.
"""
from PIL import Image
import os

# -- Ink/outline + transparent --
INK = (26, 26, 34, 255)   # #1A1A22
TR  = (0, 0, 0, 0)

# -- DESIGN.md SS2.0 extended palette (reference; import what each
#    generator needs) --
NEUTRAL_DARK   = (46, 46, 58, 255)    # #2E2E3A
NEUTRAL_GREY   = (92, 92, 110, 255)   # #5C5C6E
NEUTRAL_LIGHT  = (168, 168, 184, 255) # #A8A8B8
NEUTRAL_OFFWH  = (244, 240, 230, 255) # #F4F0E6
WHITE          = (255, 255, 255, 255)

SKIN_PALE   = (255, 227, 199, 255)  # #FFE3C7
SKIN_MED    = (242, 196, 155, 255)  # #F2C49B
SKIN_TAN    = (217, 163, 110, 255)  # #D9A36E
SKIN_DARK   = (138, 90, 60, 255)    # #8A5A3C

HAIR_BLACK  = (24, 20, 26, 255)     # #18141A
HAIR_BROWN  = (74, 46, 28, 255)     # #4A2E1C
HAIR_AUBURN = (156, 90, 46, 255)    # #9C5A2E
HAIR_BLOND  = (184, 129, 75, 255)   # #B8814B

RED         = (225, 59, 74, 255)    # #E13B4A
CORAL       = (255, 107, 92, 255)   # #FF6B5C

ORANGE      = (255, 154, 60, 255)   # #FF9A3C
AMBER       = (255, 201, 77, 255)   # #FFC94D

YELLOW      = (255, 224, 102, 255)  # #FFE066

GREEN       = (79, 176, 92, 255)    # #4FB05C
GREEN_DARK  = (46, 125, 79, 255)    # #2E7D4F

TEAL        = (79, 209, 197, 255)   # #4FD1C5
TEAL_DARK   = (31, 122, 120, 255)   # #1F7A78

BLUE        = (77, 156, 230, 255)   # #4D9CE6
NAVY        = (47, 74, 153, 255)    # #2F4A99
CYAN        = (94, 214, 255, 255)   # #5ED6FF

PURPLE      = (140, 111, 209, 255)  # #8C6FD1
MAGENTA     = (194, 82, 140, 255)   # #C2528C

OLIVE       = (156, 138, 78, 255)   # #9C8A4E
BROWN       = (110, 74, 46, 255)    # #6E4A2E

PINK        = (255, 156, 194, 255)  # #FF9CC2
STEEL       = (110, 122, 134, 255)  # #6E7A86

COLS = 10


def tile(w=64, h=64):
    return Image.new('RGBA', (w, h), TR)


def add_outline(im, w=64, h=64):
    """Returns a copy of im with INK pixels added adjacent to any opaque
    pixel, on transparent neighbors only (does not overwrite existing
    pixels)."""
    px = im.load()
    out = im.copy()
    opx = out.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 0:
                    opx[x, y] = INK
                    break
    return out


def save_sheet(anims, tile_w, tile_h, out_name):
    """anims: list of (anim_name, frame_list) in row order.
    Pads each row to COLS with transparent tiles; saves to
    assets/art/sprites/<out_name> and prints a summary."""
    sheet = Image.new('RGBA', (tile_w * COLS, tile_h * len(anims)), TR)
    for row, (_name, frames) in enumerate(anims):
        for col, frame in enumerate(frames):
            sheet.paste(frame, (col * tile_w, row * tile_h))

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, "assets", "art", "sprites", out_name)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(f"Saved {tile_w * COLS}x{tile_h * len(anims)} -> {out}")
    for name, frames in anims:
        print(f"  {name:<10} {len(frames)} frames")
    return out
