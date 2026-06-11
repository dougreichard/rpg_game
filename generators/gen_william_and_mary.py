#!/usr/bin/env python3
"""
William & Mary sprite sheet — PIL procedural, 64x64 spec.
640 x 512 px RGBA  (8 rows x up-to-8 cols x 64x64, padded to 10 cols).

William & Mary: a pair of rabbits, ALWAYS together — every frame contains
both. William (mid-grey, slightly larger, curious/adventurous, looks around)
on the left half of the tile, Mary (off-white, smaller, calm, still) on the
right half. Puzzle scouts — see the_drop.gd's two-point "brace" puzzle and
CLAUDE.md. New, 64x64 — no v1 to migrate from.
"""
from PIL import Image, ImageDraw
import os

# -- Palette (sprites.md "William & Mary -> Palette slots") --
INK        = ( 26,  26,  34, 255)  # #1A1A22 ink-black: outline, eyes
WILLIAM    = ( 92,  92, 110, 255)  # #5C5C6E mid-grey, William's main fur
WILLIAM_SH = ( 70,  70,  86, 255)  # William fur shadow
MARY       = (244, 240, 230, 255)  # #F4F0E6 off-white, Mary's fur
MARY_SH    = (214, 210, 200, 255)  # Mary fur shadow
PINK       = (255, 156, 194, 255)  # #FF9CC2 inner ears
TR         = (  0,   0,   0,   0)

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

WILLIAM_CX = 18
MARY_CX = 46

# -- Side profile rabbit -----------------------------------------------------------

def draw_rabbit(d, cx, fur, fur_sh, body_dy=0, head_dx=0, ear_mode="up", leg_phase=0, eye_x=False):
    by = 38 + body_dy
    d.ellipse([cx - 11, by, cx + 11, by + 16], fill=fur)
    d.ellipse([cx - 11, by + 9, cx + 11, by + 16], fill=fur_sh)
    d.ellipse([cx - 14, by + 2, cx - 8, by + 8], fill=fur_sh)  # tail puff
    lift = 3 if leg_phase else 0
    d.rectangle([cx - 9, by + 13, cx - 3, by + 19 - lift], fill=fur_sh)
    d.rectangle([cx + 1, by + 13, cx + 7, by + 19 - (0 if leg_phase else 3)], fill=fur_sh)
    hx = cx + head_dx
    hy = by - 12
    d.ellipse([hx - 9, hy, hx + 9, hy + 14], fill=fur)
    if ear_mode == "up":
        d.rectangle([hx - 8, hy - 14, hx - 3, hy + 1], fill=fur)
        d.rectangle([hx + 3, hy - 14, hx + 8, hy + 1], fill=fur)
        d.rectangle([hx - 7, hy - 12, hx - 4, hy - 1], fill=PINK)
        d.rectangle([hx + 4, hy - 12, hx + 7, hy - 1], fill=PINK)
    elif ear_mode == "flat":
        d.rectangle([hx - 12, hy - 1, hx - 2, hy + 3], fill=fur)
        d.rectangle([hx + 2, hy - 1, hx + 12, hy + 3], fill=fur)
    elif ear_mode == "back":
        d.rectangle([hx - 12, hy - 10, hx - 3, hy], fill=fur)
        d.rectangle([hx + 3, hy - 10, hx + 12, hy], fill=fur)
    if eye_x:
        d.line([(hx + 1, hy + 4), (hx + 5, hy + 8)], fill=INK, width=1)
        d.line([(hx + 5, hy + 4), (hx + 1, hy + 8)], fill=INK, width=1)
    else:
        d.ellipse([hx + 2, hy + 4, hx + 5, hy + 7], fill=INK)

def f_pair(w_kwargs=None, m_kwargs=None):
    im = tile(); d = ImageDraw.Draw(im)
    draw_rabbit(d, WILLIAM_CX, WILLIAM, WILLIAM_SH, **(w_kwargs or {}))
    draw_rabbit(d, MARY_CX, MARY, MARY_SH, **(m_kwargs or {}))
    return add_outline(im)

# -- Front view rabbit (facing camera) ----------------------------------------------

def draw_rabbit_front(d, cx, fur, fur_sh, body_dy=0):
    by = 38 + body_dy
    d.ellipse([cx - 11, by, cx + 11, by + 16], fill=fur)
    d.ellipse([cx - 11, by + 9, cx + 11, by + 16], fill=fur_sh)
    d.rectangle([cx - 9, by + 13, cx - 3, by + 19], fill=fur_sh)
    d.rectangle([cx + 1, by + 13, cx + 7, by + 19], fill=fur_sh)
    hy = by - 12
    d.ellipse([cx - 9, hy, cx + 9, hy + 14], fill=fur)
    d.rectangle([cx - 8, hy - 14, cx - 3, hy + 1], fill=fur)
    d.rectangle([cx + 3, hy - 14, cx + 8, hy + 1], fill=fur)
    d.rectangle([cx - 7, hy - 12, cx - 4, hy - 1], fill=PINK)
    d.rectangle([cx + 4, hy - 12, cx + 7, hy - 1], fill=PINK)
    d.ellipse([cx - 5, hy + 5, cx - 2, hy + 8], fill=INK)
    d.ellipse([cx + 2, hy + 5, cx + 5, hy + 8], fill=INK)

def f_front_pair(dy=0, leg_phase=0):
    im = tile(); d = ImageDraw.Draw(im)
    draw_rabbit_front(d, WILLIAM_CX, WILLIAM, WILLIAM_SH, body_dy=dy)
    draw_rabbit_front(d, MARY_CX, MARY, MARY_SH, body_dy=dy)
    return add_outline(im)

# -- Squeeze / lying poses -----------------------------------------------------------

def draw_rabbit_squeeze(d, cx, fur, fur_sh, dx=0):
    d.ellipse([cx - 16 + dx, 40, cx + 16 + dx, 54], fill=fur)
    d.ellipse([cx - 16 + dx, 47, cx + 16 + dx, 54], fill=fur_sh)
    d.ellipse([cx + 10 + dx, 38, cx + 24 + dx, 50], fill=fur)   # head poking forward
    d.rectangle([cx + 8 + dx, 30, cx + 14 + dx, 40], fill=fur)  # ear flattened back
    d.ellipse([cx + 18 + dx, 42, cx + 21 + dx, 45], fill=INK)

def draw_rabbit_lying(d, cx, fur, fur_sh, face_right=True):
    d.ellipse([cx - 14, 44, cx + 14, 58], fill=fur)
    d.ellipse([cx - 14, 51, cx + 14, 58], fill=fur_sh)
    if face_right:
        d.ellipse([cx + 6, 42, cx + 18, 52], fill=fur)
        d.rectangle([cx + 12, 44, cx + 22, 48], fill=fur)
        d.ellipse([cx + 9, 45, cx + 12, 48], fill=INK)
    else:
        d.ellipse([cx - 18, 42, cx - 6, 52], fill=fur)
        d.rectangle([cx - 22, 44, cx - 12, 48], fill=fur)
        d.ellipse([cx - 12, 45, cx - 9, 48], fill=INK)

# -- Animation generators --------------------------------------------------------

def anim_idle_pair():
    # Nose-twitch loop; William looks around, Mary is still
    head_dxs = [0, 1, 0, -1, 0, 1]
    return [f_pair(w_kwargs={"head_dx": dx}) for dx in head_dxs]

_HOP = [0, -3, 0, -3, 0, -3, 0, -3]

def anim_hop_down_pair():
    return [f_front_pair(dy=dy) for dy in _HOP]

def anim_hop_right_pair():
    frames = []
    for dy in _HOP:
        leg = 1 if dy == 0 else 0
        frames.append(f_pair(
            w_kwargs={"body_dy": dy, "leg_phase": leg},
            m_kwargs={"body_dy": dy, "leg_phase": leg},
        ))
    return frames

def anim_brace_hold_right_pair():
    # Both pressed against an object, pushing; feet dug in
    frames = []
    for i in range(6):
        strain = 1 if i % 2 else 0
        frames.append(f_pair(
            w_kwargs={"ear_mode": "back", "body_dy": strain},
            m_kwargs={"ear_mode": "back", "body_dy": strain},
        ))
    return frames

def anim_william_squeeze_gap():
    # William low-crawls sideways through a narrow gap; Mary waits behind
    frames = []
    for dx in (-6, -3, 0, 3, 6, 8):
        im = tile(); d = ImageDraw.Draw(im)
        draw_rabbit_squeeze(d, 12, WILLIAM, WILLIAM_SH, dx=dx)
        draw_rabbit(d, MARY_CX, MARY, MARY_SH, ear_mode="up")
        frames.append(add_outline(im))
    return frames

def anim_reunite():
    # William returns; nose-bump with Mary
    frames = []
    for i, dx in enumerate((0, 2, 4, 6, 6, 6)):
        im = tile(); d = ImageDraw.Draw(im)
        draw_rabbit(d, WILLIAM_CX + i, WILLIAM, WILLIAM_SH, head_dx=dx)
        draw_rabbit(d, MARY_CX, MARY, MARY_SH, head_dx=-dx)
        frames.append(add_outline(im))
    return frames

def anim_hurt_pair():
    # Both startle; ears flat
    return [
        f_pair(w_kwargs={"ear_mode": "flat", "eye_x": True}, m_kwargs={"ear_mode": "flat", "eye_x": True}),
        f_pair(w_kwargs={"ear_mode": "flat", "body_dy": -2}, m_kwargs={"ear_mode": "flat", "body_dy": -2}),
        f_pair(w_kwargs={"ear_mode": "flat", "eye_x": True}, m_kwargs={"ear_mode": "flat", "eye_x": True}),
        f_pair(w_kwargs={"ear_mode": "up"}, m_kwargs={"ear_mode": "up"}),
    ]

def anim_down_pair():
    # Both lie flat simultaneously
    frames = []
    for i in range(2):
        frames.append(f_pair(
            w_kwargs={"ear_mode": "flat", "body_dy": i, "eye_x": True},
            m_kwargs={"ear_mode": "flat", "body_dy": i, "eye_x": True},
        ))
    for _ in range(6):
        im = tile(); d = ImageDraw.Draw(im)
        draw_rabbit_lying(d, WILLIAM_CX, WILLIAM, WILLIAM_SH, face_right=True)
        draw_rabbit_lying(d, MARY_CX, MARY, MARY_SH, face_right=False)
        frames.append(add_outline(im))
    return frames

ANIMS = [
    ("idle_pair",            anim_idle_pair),
    ("hop_down_pair",        anim_hop_down_pair),
    ("hop_right_pair",       anim_hop_right_pair),
    ("brace_hold_right_pair", anim_brace_hold_right_pair),
    ("william_squeeze_gap",  anim_william_squeeze_gap),
    ("reunite",              anim_reunite),
    ("hurt_pair",            anim_hurt_pair),
    ("down_pair",            anim_down_pair),
]

if __name__ == "__main__":
    sheet = Image.new('RGBA', (T * 10, T * len(ANIMS)), TR)
    for row, (name, fn) in enumerate(ANIMS):
        for col, frame in enumerate(fn()):
            sheet.paste(frame, (col * T, row * T))

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, "assets", "art", "sprites", "william_and_mary.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(f"Saved 640x{T*len(ANIMS)} -> {out}")
    for n, f in ANIMS:
        print(f"  {n:<20} {len(f())} frames")
