#!/usr/bin/env python3
"""
Guinea Pigs sprite sheet — PIL procedural, 64x64 spec.
640 x 384 px RGBA  (6 rows x up-to-8 cols x 64x64, padded to 10 cols).

Guinea Pigs: a small scurrying group (4 per frame) of round, earless-looking,
no-tail rodents in brown/white/tan — crowd cover, a scurrying group that
floods a floor and draws every eye in the room. New, 64x64 — no v1 to
migrate from.
"""
from PIL import Image, ImageDraw
import os

# -- Palette (sprites.md "Guinea Pigs -> Palette slots") --
INK     = ( 26,  26,  34, 255)  # #1A1A22 ink-black: outline, eyes
BROWN   = (156,  90,  46, 255)  # #9C5A2E
BROWN_SH = (120,  68,  32, 255)
WHITE   = (244, 240, 230, 255)  # #F4F0E6
WHITE_SH = (214, 210, 200, 255)
TAN     = (217, 163, 110, 255)  # #D9A36E
TAN_SH  = (184, 134,  88, 255)
TR      = (  0,   0,   0,   0)

T = 64

def tile():
    return Image.new('RGBA', (T, T), TR)

def add_outline(im):
    px = im.load(); out = im.copy(); opx = out.load()
    for y in range(T):
        for x in range(T):
            if px[x, y][3] > 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < T and 0 <= ny < T and px[nx, ny][3] > 0:
                    opx[x, y] = INK
                    break
    return out

PIGS = [
    {"pos": (16, 20), "color": BROWN, "sh": BROWN_SH, "facing": 1},
    {"pos": (44, 16), "color": WHITE, "sh": WHITE_SH, "facing": -1},
    {"pos": (20, 46), "color": TAN,   "sh": TAN_SH,   "facing": 1},
    {"pos": (46, 46), "color": BROWN, "sh": BROWN_SH, "facing": -1},
]

CENTER = (32, 32)

def draw_pig(d, cx, cy, color, color_sh, facing=1, legs=False, flipped=False):
    cx = int(round(cx)); cy = int(round(cy))
    if flipped:
        d.ellipse([cx - 9, cy - 5, cx + 9, cy + 7], fill=color)
        d.ellipse([cx - 9, cy - 5, cx + 9, cy + 1], fill=color_sh)
        d.rectangle([cx - 6, cy - 10, cx - 3, cy - 5], fill=color_sh)  # legs up
        d.rectangle([cx + 3, cy - 10, cx + 6, cy - 5], fill=color_sh)
        d.ellipse([cx - 1, cy + 1, cx + 2, cy + 4], fill=INK)
        return
    d.ellipse([cx - 9, cy - 6, cx + 9, cy + 6], fill=color)
    d.ellipse([cx - 9, cy, cx + 9, cy + 6], fill=color_sh)
    hx = cx + 6 * facing
    d.ellipse([hx - 6, cy - 7, hx + 6, cy + 5], fill=color)
    ear_cx = hx + 2 * facing
    d.ellipse([ear_cx - 3, cy - 10, ear_cx + 3, cy - 4], fill=color)
    eye_cx = hx + 3 * facing
    d.ellipse([eye_cx - 1, cy - 2, eye_cx + 2, cy + 1], fill=INK)
    if legs:
        d.rectangle([cx - 5, cy + 5, cx - 2, cy + 8], fill=color_sh)
        d.rectangle([cx + 2, cy + 5, cx + 5, cy + 8], fill=color_sh)

# -- Animation generators --------------------------------------------------------

def anim_idle_scatter():
    jitters = [
        [(0, 0), (0, 0), (0, 0), (0, 0)],
        [(1, 0), (0, 1), (-1, 0), (0, -1)],
        [(0, 1), (-1, 0), (0, -1), (1, 0)],
        [(-1, 0), (0, -1), (1, 0), (0, 1)],
        [(0, -1), (1, 0), (0, 1), (-1, 0)],
        [(0, 0), (0, 0), (0, 0), (0, 0)],
    ]
    frames = []
    for jitter in jitters:
        im = tile(); d = ImageDraw.Draw(im)
        for p, (dx, dy) in zip(PIGS, jitter):
            x, y = p["pos"][0] + dx, p["pos"][1] + dy
            draw_pig(d, x, y, p["color"], p["sh"], facing=p["facing"])
        frames.append(add_outline(im))
    return frames

def anim_scurry_right():
    frames = []
    for i in range(8):
        shift = (i % 4) - 1
        im = tile(); d = ImageDraw.Draw(im)
        for p in PIGS:
            x, y = p["pos"][0] + shift, p["pos"][1]
            draw_pig(d, x, y, p["color"], p["sh"], facing=1, legs=(i % 2 == 0))
        frames.append(add_outline(im))
    return frames

def anim_scurry_down():
    frames = []
    for i in range(8):
        shift = (i % 4) - 1
        im = tile(); d = ImageDraw.Draw(im)
        for p in PIGS:
            x, y = p["pos"][0], p["pos"][1] + shift
            draw_pig(d, x, y, p["color"], p["sh"], facing=p["facing"], legs=(i % 2 == 0))
        frames.append(add_outline(im))
    return frames

def anim_flood_panic():
    frames = []
    for i in range(8):
        t = min((i / 7.0) * 1.4, 1.4)
        im = tile(); d = ImageDraw.Draw(im)
        for p in PIGS:
            tx = CENTER[0] + (p["pos"][0] - CENTER[0]) * t
            ty = CENTER[1] + (p["pos"][1] - CENTER[1]) * t
            draw_pig(d, tx, ty, p["color"], p["sh"], facing=p["facing"], legs=(i % 2 == 0))
        frames.append(add_outline(im))
    return frames

def anim_calm_regroup():
    frames = []
    for i in range(6):
        t = 1.0 - i / 5.0
        im = tile(); d = ImageDraw.Draw(im)
        for p in PIGS:
            tx = CENTER[0] + (p["pos"][0] - CENTER[0]) * t
            ty = CENTER[1] + (p["pos"][1] - CENTER[1]) * t
            draw_pig(d, tx, ty, p["color"], p["sh"], facing=p["facing"])
        frames.append(add_outline(im))
    return frames

def anim_down():
    frames = []
    for i in range(6):
        wob = 1 if i % 2 else -1
        im = tile(); d = ImageDraw.Draw(im)
        for p in PIGS:
            x, y = p["pos"]
            draw_pig(d, x, y, p["color"], p["sh"], facing=p["facing"] * wob, flipped=True)
        frames.append(add_outline(im))
    return frames

ANIMS = [
    ("idle_scatter",  anim_idle_scatter),
    ("scurry_right",  anim_scurry_right),
    ("scurry_down",   anim_scurry_down),
    ("flood_panic",   anim_flood_panic),
    ("calm_regroup",  anim_calm_regroup),
    ("down",          anim_down),
]

if __name__ == "__main__":
    sheet = Image.new('RGBA', (T * 10, T * len(ANIMS)), TR)
    for row, (name, fn) in enumerate(ANIMS):
        for col, frame in enumerate(fn()):
            sheet.paste(frame, (col * T, row * T))

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, "assets", "art", "sprites", "guinea_pigs.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(f"Saved 640x{T*len(ANIMS)} -> {out}")
    for n, f in ANIMS:
        print(f"  {n:<16} {len(f())} frames")
