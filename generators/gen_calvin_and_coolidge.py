#!/usr/bin/env python3
"""
Calvin & Coolidge sprite sheet — PIL procedural, 64x64 spec.
640 x 576 px RGBA  (9 rows x up-to-8 cols x 64x64, padded to 10 cols).

Calvin & Coolidge: a pair of large white Great Pyrenees, ALWAYS together —
every frame contains both. Calvin (heavier-set charger) on the left half of
the tile, Coolidge (leaner brace/pusher) on the right half. Heavy muscle —
see harbor_docks.gd's combat-charge summon and CLAUDE.md. New, 64x64 — no
v1 to migrate from.
"""
from PIL import Image, ImageDraw
import os

# -- Palette (sprites.md "Calvin & Coolidge -> Palette slots") --
INK   = ( 26,  26,  34, 255)  # #1A1A22 ink-black: outline, eyes, nose
FUR   = (244, 240, 230, 255)  # #F4F0E6 white main coat
MANE  = (168, 168, 184, 255)  # #A8A8B8 light grey mane depth shading
PINK  = (255, 156, 194, 255)  # #FF9CC2 tongue
TR    = (  0,   0,   0,   0)

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

CALVIN_CX = 14
COOLIDGE_CX = 42

# -- Side profile dog (facing right) ------------------------------------------------

def draw_dog(d, cx, body_dy=0, head_dx=0, leg_phase=0, mouth_open=False, eye_x=False,
              ears_back=False, lean=0, tail_dy=0):
    by = 36 + body_dy
    d.ellipse([cx - 14, by - 8, cx + 10, by + 6], fill=MANE)        # mane behind shoulders
    d.ellipse([cx - 16 + lean, by - 2 + tail_dy, cx - 8 + lean, by + 8 + tail_dy], fill=FUR)  # tail
    d.ellipse([cx - 12 + lean, by, cx + 12 + lean, by + 18], fill=FUR)
    d.ellipse([cx - 12 + lean, by + 10, cx + 12 + lean, by + 18], fill=MANE)
    lift = 3 if leg_phase else 0
    d.rectangle([cx - 9 + lean, by + 15, cx - 3 + lean, by + 21 - lift], fill=MANE)
    d.rectangle([cx + 1 + lean, by + 15, cx + 7 + lean, by + 21 - (0 if leg_phase else 3)], fill=MANE)
    hx = cx + 8 + head_dx + lean
    hy = by - 10
    d.ellipse([hx - 9, hy, hx + 9, hy + 14], fill=FUR)
    if ears_back:
        d.rectangle([hx - 10, hy - 6, hx - 2, hy - 1], fill=FUR)
        d.rectangle([hx + 2, hy - 6, hx + 10, hy - 1], fill=FUR)
    else:
        d.rectangle([hx - 9, hy - 8, hx - 3, hy + 1], fill=FUR)
        d.rectangle([hx + 3, hy - 8, hx + 9, hy + 1], fill=FUR)
    if eye_x:
        d.line([(hx + 1, hy + 3), (hx + 5, hy + 7)], fill=INK, width=1)
        d.line([(hx + 5, hy + 3), (hx + 1, hy + 7)], fill=INK, width=1)
    else:
        d.ellipse([hx + 2, hy + 4, hx + 5, hy + 7], fill=INK)
    d.ellipse([hx + 7, hy + 8, hx + 11, hy + 12], fill=INK)         # nose
    if mouth_open:
        d.rectangle([hx + 2, hy + 9, hx + 8, hy + 13], fill=PINK)

def f_pair(c_kwargs=None, k_kwargs=None):
    im = tile(); d = ImageDraw.Draw(im)
    draw_dog(d, CALVIN_CX, **(c_kwargs or {}))
    draw_dog(d, COOLIDGE_CX, **(k_kwargs or {}))
    return add_outline(im)

# -- Front view dog (facing camera) -------------------------------------------------

def draw_dog_front(d, cx, body_dy=0, leg_phase=0):
    by = 34 + body_dy
    d.ellipse([cx - 16, by - 6, cx + 16, by + 10], fill=MANE)
    d.ellipse([cx - 13, by, cx + 13, by + 18], fill=FUR)
    d.ellipse([cx - 13, by + 10, cx + 13, by + 18], fill=MANE)
    lift = 3 if leg_phase else 0
    d.rectangle([cx - 11, by + 15, cx - 5, by + 21 - lift], fill=MANE)
    d.rectangle([cx + 5, by + 15, cx + 11, by + 21 - (0 if leg_phase else 3)], fill=MANE)
    hy = by - 14
    d.ellipse([cx - 9, hy, cx + 9, hy + 14], fill=FUR)
    d.rectangle([cx - 9, hy - 7, cx - 2, hy + 1], fill=FUR)
    d.rectangle([cx + 2, hy - 7, cx + 9, hy + 1], fill=FUR)
    d.ellipse([cx - 6, hy + 5, cx - 3, hy + 8], fill=INK)
    d.ellipse([cx + 3, hy + 5, cx + 6, hy + 8], fill=INK)
    d.ellipse([cx - 2, hy + 9, cx + 2, hy + 13], fill=INK)

def f_front_pair(dy=0, leg_phase=0):
    im = tile(); d = ImageDraw.Draw(im)
    draw_dog_front(d, CALVIN_CX, body_dy=dy, leg_phase=leg_phase)
    draw_dog_front(d, COOLIDGE_CX, body_dy=dy, leg_phase=leg_phase)
    return add_outline(im)

# -- Lying pose -----------------------------------------------------------------------

def draw_dog_lying(d, cx, face_right=True):
    d.ellipse([cx - 20, 36, cx + 20, 50], fill=MANE)   # mane spread wide
    d.ellipse([cx - 16, 40, cx + 16, 58], fill=FUR)
    d.ellipse([cx - 16, 50, cx + 16, 58], fill=MANE)
    if face_right:
        d.ellipse([cx + 8, 38, cx + 24, 52], fill=FUR)
        d.ellipse([cx + 18, 43, cx + 22, 47], fill=INK)
    else:
        d.ellipse([cx - 24, 38, cx - 8, 52], fill=FUR)
        d.ellipse([cx - 22, 43, cx - 18, 47], fill=INK)

# -- Animation generators --------------------------------------------------------

def anim_idle_pair():
    # Both stand side by side; slow breath; tails sway
    tails = [0, 1, 0, -1, 0, 1]
    return [f_pair(c_kwargs={"tail_dy": t}, k_kwargs={"tail_dy": -t}) for t in tails]

_WALK = [0, -2, 0, -2, 0, -2, 0, -2]

def anim_walk_down_pair():
    return [f_front_pair(dy=_WALK[i], leg_phase=i % 2) for i in range(8)]

def anim_walk_right_pair():
    return [f_pair(
        c_kwargs={"body_dy": _WALK[i], "leg_phase": i % 2},
        k_kwargs={"body_dy": _WALK[i], "leg_phase": (i + 1) % 2},
    ) for i in range(8)]

def anim_calvin_charge():
    # Calvin sprints hard, shoulder-first slam; Coolidge follows behind
    leans = [2, 4, 6, 8, 4, 0]
    return [f_pair(
        c_kwargs={"lean": leans[i], "mouth_open": True, "leg_phase": i % 2},
        k_kwargs={"leg_phase": i % 2, "head_dx": -2},
    ) for i in range(6)]

def anim_coolidge_brace():
    # Coolidge plants wide, leans hard into a large object; Calvin flanks
    leans = [0, 2, 4, 5, 5, 4]
    return [f_pair(
        c_kwargs={"head_dx": 2, "tail_dy": 1 if i % 2 else 0},
        k_kwargs={"ears_back": True, "lean": leans[i], "body_dy": 1 if i % 2 else 0},
    ) for i in range(6)]

def anim_dual_charge_split():
    # Calvin breaks left, Coolidge breaks right simultaneously
    frames = []
    for i in range(8):
        cx_c = CALVIN_CX - i
        cx_k = COOLIDGE_CX + i
        im = tile(); d = ImageDraw.Draw(im)
        draw_dog(d, cx_c, mouth_open=True, leg_phase=i % 2, head_dx=-2)
        draw_dog(d, cx_k, mouth_open=True, leg_phase=(i + 1) % 2, head_dx=2)
        frames.append(add_outline(im))
    return frames

def anim_hurt_pair():
    # Both flinch; manes ripple
    return [
        f_pair(c_kwargs={"eye_x": True, "ears_back": True}, k_kwargs={"eye_x": True, "ears_back": True}),
        f_pair(c_kwargs={"body_dy": -2, "ears_back": True}, k_kwargs={"body_dy": -2, "ears_back": True}),
        f_pair(c_kwargs={"eye_x": True, "ears_back": True}, k_kwargs={"eye_x": True, "ears_back": True}),
        f_pair(),
    ]

def anim_down_pair():
    # Both lie flat; manes spread wide
    frames = []
    for i in range(2):
        frames.append(f_pair(
            c_kwargs={"eye_x": True, "body_dy": i, "ears_back": True},
            k_kwargs={"eye_x": True, "body_dy": i, "ears_back": True},
        ))
    for _ in range(6):
        im = tile(); d = ImageDraw.Draw(im)
        draw_dog_lying(d, CALVIN_CX, face_right=True)
        draw_dog_lying(d, COOLIDGE_CX, face_right=False)
        frames.append(add_outline(im))
    return frames

def anim_return():
    # Trot back side by side; tails up
    return [
        f_pair(c_kwargs={"leg_phase": 0, "tail_dy": -3}, k_kwargs={"leg_phase": 1, "tail_dy": -3}),
        f_pair(c_kwargs={"leg_phase": 1, "tail_dy": -4}, k_kwargs={"leg_phase": 0, "tail_dy": -4}),
        f_pair(c_kwargs={"leg_phase": 0, "tail_dy": -3}, k_kwargs={"leg_phase": 1, "tail_dy": -3}),
        f_pair(c_kwargs={"leg_phase": 1, "tail_dy": -4}, k_kwargs={"leg_phase": 0, "tail_dy": -4}),
        f_pair(c_kwargs={"leg_phase": 0, "tail_dy": -3}, k_kwargs={"leg_phase": 1, "tail_dy": -3}),
        f_pair(c_kwargs={"leg_phase": 1, "tail_dy": -4}, k_kwargs={"leg_phase": 0, "tail_dy": -4}),
    ]

ANIMS = [
    ("idle_pair",         anim_idle_pair),
    ("walk_down_pair",    anim_walk_down_pair),
    ("walk_right_pair",   anim_walk_right_pair),
    ("calvin_charge",     anim_calvin_charge),
    ("coolidge_brace",    anim_coolidge_brace),
    ("dual_charge_split", anim_dual_charge_split),
    ("hurt_pair",         anim_hurt_pair),
    ("down_pair",         anim_down_pair),
    ("return",            anim_return),
]

if __name__ == "__main__":
    sheet = Image.new('RGBA', (T * 10, T * len(ANIMS)), TR)
    for row, (name, fn) in enumerate(ANIMS):
        for col, frame in enumerate(fn()):
            sheet.paste(frame, (col * T, row * T))

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, "assets", "art", "sprites", "calvin_and_coolidge.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(f"Saved 640x{T*len(ANIMS)} -> {out}")
    for n, f in ANIMS:
        print(f"  {n:<20} {len(f())} frames")
