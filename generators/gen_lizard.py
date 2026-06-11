#!/usr/bin/env python3
"""
Lizard sprite sheet — PIL procedural, 64x64 spec.
640 x 448 px RGBA  (7 rows x up-to-8 cols x 64x64, padded to 10 cols).

Lizard: slim olive-green gecko/skink with darker stripe markings and a tiny
yellow eye, tail ~1.5x body length. Vertical-traversal scout — see
zip_line_park.gd / vr_escape_room.gd's CLIMB -> PERCH -> RETURN phase
machine and CLAUDE.md. New, 64x64 — no v1 to migrate from.

Two base poses: a horizontal "ground" pose (head right, tail trailing left
— idle/walk/flee) and a vertical "climb" pose (belly flat against a wall,
viewed from the side — climb/descend/perch/target_reached).
"""
from PIL import Image, ImageDraw
import os

# -- Palette (sprites.md "Lizard -> Palette slots") --
INK     = ( 26,  26,  34, 255)  # #1A1A22 ink-black: outline
OLIVE   = (156, 138,  78, 255)  # #9C8A4E olive-green
OLIVE_SH = (122, 108,  60, 255)  # darker olive shading
STRIPE  = ( 92,  92, 110, 255)  # #5C5C6E dark stripe markings
EYE     = (255, 224, 102, 255)  # #FFE066 tiny yellow eye
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

# -- Ground pose (horizontal, head right) --------------------------------------------

def draw_tail_ground(d, swing=0):
    d.polygon([(18, 32), (18, 40), (6, 38 + swing), (2, 35 + swing)], fill=OLIVE)
    d.polygon([(18, 36), (18, 40), (6, 38 + swing)], fill=OLIVE_SH)

def draw_body_ground(d):
    d.ellipse([16, 28, 44, 42], fill=OLIVE)
    d.ellipse([16, 35, 44, 42], fill=OLIVE_SH)
    for sx in (22, 28, 34):
        d.rectangle([sx, 29, sx + 2, 41], fill=STRIPE)

def draw_head_ground(d, tongue=False):
    d.ellipse([40, 26, 54, 38], fill=OLIVE)
    d.ellipse([48, 28, 52, 32], fill=EYE)
    if tongue:
        d.line([(54, 32), (60, 30)], fill=STRIPE, width=1)

def draw_legs_ground(d, phase=0):
    if phase == 0:
        d.rectangle([20, 40, 24, 46], fill=OLIVE_SH)
        d.rectangle([36, 40, 40, 46], fill=OLIVE_SH)
        d.rectangle([24, 38, 28, 44], fill=OLIVE)
        d.rectangle([32, 38, 36, 44], fill=OLIVE)
    else:
        d.rectangle([24, 40, 28, 46], fill=OLIVE_SH)
        d.rectangle([32, 40, 36, 46], fill=OLIVE_SH)
        d.rectangle([20, 38, 24, 44], fill=OLIVE)
        d.rectangle([36, 38, 40, 44], fill=OLIVE)

def f_ground(leg_phase=0, tongue=False, swing=0):
    im = tile(); d = ImageDraw.Draw(im)
    draw_tail_ground(d, swing=swing)
    draw_legs_ground(d, phase=leg_phase)
    draw_body_ground(d)
    draw_head_ground(d, tongue=tongue)
    return add_outline(im)

# -- Climb pose (vertical, belly flat on wall, side view) -----------------------------

def draw_body_climb(d):
    d.ellipse([26, 18, 38, 46], fill=OLIVE)
    d.ellipse([32, 18, 38, 46], fill=OLIVE_SH)
    for sy in (24, 30, 36):
        d.rectangle([27, sy, 37, sy + 2], fill=STRIPE)

def draw_head_climb(d, head_down=False, nod=0):
    if head_down:
        d.ellipse([26, 44 + nod, 38, 56 + nod], fill=OLIVE)
        d.ellipse([29, 50 + nod, 32, 53 + nod], fill=EYE)
    else:
        d.ellipse([26, 8 + nod, 38, 20 + nod], fill=OLIVE)
        d.ellipse([29, 11 + nod, 32, 14 + nod], fill=EYE)

def draw_tail_climb(d, head_down=False, swing=0, curl=False):
    if curl:
        d.arc([20 + swing, 40, 36 + swing, 56], 0, 270, fill=OLIVE_SH, width=4)
        return
    if head_down:
        d.polygon([(28, 18), (36, 18), (34 + swing, 6), (30 + swing, 4)], fill=OLIVE)
    else:
        d.polygon([(28, 46), (36, 46), (34 + swing, 58), (30 + swing, 60)], fill=OLIVE)

def draw_legs_climb(d, phase=0):
    if phase == 0:
        d.rectangle([18, 22, 26, 26], fill=OLIVE_SH)
        d.rectangle([38, 22, 46, 26], fill=OLIVE)
        d.rectangle([18, 38, 26, 42], fill=OLIVE)
        d.rectangle([38, 38, 46, 42], fill=OLIVE_SH)
    else:
        d.rectangle([18, 22, 26, 26], fill=OLIVE)
        d.rectangle([38, 22, 46, 26], fill=OLIVE_SH)
        d.rectangle([18, 38, 26, 42], fill=OLIVE_SH)
        d.rectangle([38, 38, 46, 42], fill=OLIVE)

def f_climb(leg_phase=0, swing=0, head_down=False, curl=False, nod=0):
    im = tile(); d = ImageDraw.Draw(im)
    draw_tail_climb(d, head_down=head_down, swing=swing, curl=curl)
    draw_legs_climb(d, phase=leg_phase)
    draw_body_climb(d)
    draw_head_climb(d, head_down=head_down, nod=nod)
    return add_outline(im)

# -- Animation generators --------------------------------------------------------

def anim_idle():
    # Tongue flick; toe-pads pressed flat
    return [
        f_ground(leg_phase=0),
        f_ground(leg_phase=0, tongue=True),
        f_ground(leg_phase=0),
        f_ground(leg_phase=0, swing=1),
    ]

def anim_walk_right_ground():
    phases = [0, 1, 0, 1, 0, 1]
    swings = [0, 1, 0, -1, 0, 1]
    return [f_ground(leg_phase=phases[i], swing=swings[i]) for i in range(6)]

_CLIMB_PHASE = [0, 1, 0, 1, 0, 1, 0, 1]
_CLIMB_SWING = [-2, 2, -2, 2, -2, 2, -2, 2]

def anim_climb_upward():
    return [f_climb(leg_phase=_CLIMB_PHASE[i], swing=_CLIMB_SWING[i], head_down=False) for i in range(8)]

def anim_perch_hold():
    return [f_climb(leg_phase=0, curl=True, head_down=False, nod=(1 if i % 2 else 0)) for i in range(4)]

def anim_target_reached():
    # Tail flick, head nod — success signal to Ethan
    return [
        f_climb(curl=True, head_down=False),
        f_climb(curl=True, head_down=False, swing=3),
        f_climb(curl=True, head_down=False, nod=2),
        f_climb(curl=True, head_down=False),
    ]

def anim_descend():
    return [f_climb(leg_phase=_CLIMB_PHASE[i], swing=_CLIMB_SWING[i], head_down=True) for i in range(8)]

def anim_flee_scatter():
    return [f_ground(leg_phase=i % 2, swing=(2 if i % 2 else -2)) for i in range(4)]

ANIMS = [
    ("idle",             anim_idle),
    ("walk_right_ground", anim_walk_right_ground),
    ("climb_upward",     anim_climb_upward),
    ("perch_hold",       anim_perch_hold),
    ("target_reached",   anim_target_reached),
    ("descend",          anim_descend),
    ("flee_scatter",     anim_flee_scatter),
]

if __name__ == "__main__":
    sheet = Image.new('RGBA', (T * 10, T * len(ANIMS)), TR)
    for row, (name, fn) in enumerate(ANIMS):
        for col, frame in enumerate(fn()):
            sheet.paste(frame, (col * T, row * T))

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, "assets", "art", "sprites", "lizard.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(f"Saved 640x{T*len(ANIMS)} -> {out}")
    for n, f in ANIMS:
        print(f"  {n:<18} {len(f())} frames")
