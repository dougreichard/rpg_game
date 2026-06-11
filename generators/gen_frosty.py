#!/usr/bin/env python3
"""
Frosty sprite sheet — PIL procedural, 64x64 spec.
640 x 704 px RGBA  (11 rows x 10 cols x 64x64).

Frosty: medium-small Schnoodle (Schnauzer/Poodle mix) — fluffy near-white
fur, blocky Schnauzer muzzle, pink tongue/inner ears, dark dot eyes/nose.
General-purpose combat companion (animal_companion.gd's CHARGE -> STRIKE ->
RETURN state machine — see CLAUDE.md). New, 64x64 — no v1 to migrate from.

Three base poses, each built from small rectangle/ellipse primitives in the
"Stranger Things: 1984" extended-palette style (DESIGN.md SS2.0): a side
profile (facing right — used for trot/gallop-right, charge, hurt, return),
a front view (facing the camera — trot/gallop-down), and a rear view
(trot/gallop-up).
"""
from PIL import Image, ImageDraw
import os

# -- Palette (sprites.md "Frosty -> Palette slots") --
INK    = ( 26,  26,  34, 255)  # #1A1A22 ink-black: outline, eyes, nose
FUR    = (244, 240, 230, 255)  # #F4F0E6 near-white fur
FUR_SH = (214, 210, 200, 255)  # fur shadow
PINK   = (255, 156, 194, 255)  # #FF9CC2 tongue / inner ears
TR     = (  0,   0,   0,   0)

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

# -- Side profile (facing right) --------------------------------------------------

def draw_tail_side(d, wag=0):
    d.rectangle([4, 20 + wag, 13, 34 + wag], fill=FUR)

def draw_body_side(d, bob=0):
    d.ellipse([10, 30 + bob, 50, 50 + bob], fill=FUR)
    d.ellipse([10, 42 + bob, 50, 50 + bob], fill=FUR_SH)

def draw_head_side(d, tilt=0, bob=0, mouth_open=False, eyes_x=False):
    hy = 16 + tilt + bob
    d.rectangle([42, hy, 60, hy + 20], fill=FUR)
    d.rectangle([54, hy + 10, 60, hy + 16], fill=FUR_SH)   # muzzle shading
    if eyes_x:
        d.line([(51, hy + 9), (56, hy + 14)], fill=INK, width=2)
        d.line([(56, hy + 9), (51, hy + 14)], fill=INK, width=2)
    else:
        d.ellipse([52, hy + 9, 56, hy + 13], fill=INK)
    d.ellipse([56, hy + 12, 60, hy + 16], fill=INK)        # nose
    if mouth_open:
        d.rectangle([50, hy + 16, 58, hy + 22], fill=PINK)

def draw_ear_side(d, tilt=0, bob=0):
    hy = 16 + tilt + bob
    d.rectangle([44, hy - 8, 54, hy + 2], fill=FUR)
    d.rectangle([46, hy - 6, 52, hy], fill=PINK)

def draw_legs_side(d, phase=0):
    if phase == 0:
        d.rectangle([16, 48, 22, 60], fill=FUR)
        d.rectangle([40, 48, 46, 60], fill=FUR)
        d.rectangle([24, 50, 30, 60], fill=FUR_SH)
        d.rectangle([34, 50, 40, 60], fill=FUR_SH)
    elif phase == 1:
        d.rectangle([24, 48, 30, 60], fill=FUR)
        d.rectangle([34, 48, 40, 60], fill=FUR)
        d.rectangle([16, 50, 22, 60], fill=FUR_SH)
        d.rectangle([40, 50, 46, 60], fill=FUR_SH)
    else:  # bound — all four legs tucked under the body
        d.rectangle([22, 46, 28, 54], fill=FUR_SH)
        d.rectangle([32, 46, 38, 54], fill=FUR_SH)

def f_side(leg_phase=0, tail_wag=0, head_tilt=0, bob=0, mouth_open=False, eyes_x=False):
    im = tile(); d = ImageDraw.Draw(im)
    draw_tail_side(d, wag=tail_wag)
    draw_legs_side(d, phase=leg_phase)
    draw_body_side(d, bob=bob)
    draw_head_side(d, tilt=head_tilt, bob=bob, mouth_open=mouth_open, eyes_x=eyes_x)
    draw_ear_side(d, tilt=head_tilt, bob=bob)
    return add_outline(im)

# -- Front view (facing camera) ---------------------------------------------------

def draw_body_front(d, bob=0):
    d.ellipse([16, 32 + bob, 48, 52 + bob], fill=FUR)
    d.ellipse([16, 44 + bob, 48, 52 + bob], fill=FUR_SH)

def draw_head_front(d, bob=0, tongue=False, eyes_x=False):
    hy = 12 + bob
    d.rectangle([20, hy, 44, hy + 22], fill=FUR)
    d.rectangle([18, hy - 8, 28, hy + 2], fill=FUR)
    d.rectangle([20, hy - 6, 26, hy], fill=PINK)
    d.rectangle([36, hy - 8, 46, hy + 2], fill=FUR)
    d.rectangle([38, hy - 6, 44, hy], fill=PINK)
    if eyes_x:
        for ex in (24, 36):
            d.line([(ex, hy + 8), (ex + 4, hy + 12)], fill=INK, width=2)
            d.line([(ex + 4, hy + 8), (ex, hy + 12)], fill=INK, width=2)
    else:
        d.ellipse([24, hy + 8, 28, hy + 12], fill=INK)
        d.ellipse([36, hy + 8, 40, hy + 12], fill=INK)
    d.ellipse([30, hy + 14, 34, hy + 18], fill=INK)
    if tongue:
        d.rectangle([28, hy + 18, 36, hy + 24], fill=PINK)

def draw_legs_front(d, phase=0):
    xs = [18, 26, 34, 42]
    if phase == 0:
        ys = [50, 48, 48, 50]
    elif phase == 1:
        ys = [48, 50, 50, 48]
    else:
        ys = [46, 46, 46, 46]
    for x, y0 in zip(xs, ys):
        d.rectangle([x, y0, x + 6, 60], fill=FUR)

def f_front(leg_phase=0, bob=0, tongue=False, eyes_x=False):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs_front(d, phase=leg_phase)
    draw_body_front(d, bob=bob)
    draw_head_front(d, bob=bob, tongue=tongue, eyes_x=eyes_x)
    return add_outline(im)

# -- Rear view ----------------------------------------------------------------------

def draw_head_back(d, bob=0, tail_up=False):
    hy = 12 + bob
    d.rectangle([20, hy, 44, hy + 22], fill=FUR)
    d.rectangle([18, hy - 8, 28, hy + 2], fill=FUR)
    d.rectangle([36, hy - 8, 46, hy + 2], fill=FUR)
    if tail_up:
        d.rectangle([28, hy - 14, 36, hy - 4], fill=FUR)

def f_back(leg_phase=0, bob=0, tail_up=False):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs_front(d, phase=leg_phase)
    draw_body_front(d, bob=bob)
    draw_head_back(d, bob=bob, tail_up=tail_up)
    return add_outline(im)

# -- Animation generators --------------------------------------------------------

def anim_idle():
    # Tail wag (3-frame loop); head tilt at frame 5
    frames = []
    wags = [0, 2, 0]
    for i in range(6):
        wag = wags[i % 3]
        tilt = 3 if i == 5 else 0
        frames.append(f_side(tail_wag=wag, head_tilt=tilt))
    return frames

_TROT_PHASE  = [0, 1, 0, 1, 0, 1, 0, 1]
_TROT_BOB    = [0, -1, 0, -1, 0, -1, 0, -1]
_GALLOP_PHASE = [0, 2, 1, 2, 0, 2, 1, 2]
_GALLOP_BOB   = [0, -3, -1, -3, 0, -3, -1, -3]

def anim_trot_down():
    return [f_front(leg_phase=_TROT_PHASE[i], bob=_TROT_BOB[i]) for i in range(8)]

def anim_trot_up():
    return [f_back(leg_phase=_TROT_PHASE[i], bob=_TROT_BOB[i]) for i in range(8)]

def anim_trot_right():
    return [f_side(leg_phase=_TROT_PHASE[i], bob=_TROT_BOB[i], tail_wag=1) for i in range(8)]

def anim_gallop_down():
    return [f_front(leg_phase=_GALLOP_PHASE[i], bob=_GALLOP_BOB[i], tongue=True) for i in range(8)]

def anim_gallop_up():
    return [f_back(leg_phase=_GALLOP_PHASE[i], bob=_GALLOP_BOB[i], tail_up=True) for i in range(8)]

def anim_gallop_right():
    return [f_side(leg_phase=_GALLOP_PHASE[i], bob=_GALLOP_BOB[i], tail_wag=2, mouth_open=True) for i in range(8)]

def anim_charge():
    # Low sprint (1-3), head-down ram (4), bounce back (5-6)
    frames = []
    for i in range(3):
        frames.append(f_side(leg_phase=_GALLOP_PHASE[i], bob=2, head_tilt=2, mouth_open=True))
    frames.append(f_side(leg_phase=2, bob=4, head_tilt=6))           # ram — head down low
    frames.append(f_side(leg_phase=1, bob=-2, head_tilt=-2))          # bounce back
    frames.append(f_side(leg_phase=0, bob=0, head_tilt=0))
    return frames

def anim_hurt():
    return [
        f_side(leg_phase=1, head_tilt=2, eyes_x=True),
        f_side(leg_phase=0, head_tilt=-2, eyes_x=True, mouth_open=True),
        f_side(leg_phase=1, head_tilt=2, eyes_x=True),
        f_side(leg_phase=0, head_tilt=0),
    ]

def f_lying():
    im = tile(); d = ImageDraw.Draw(im)
    d.ellipse([6, 42, 56, 60], fill=FUR)
    d.ellipse([6, 52, 56, 60], fill=FUR_SH)
    d.rectangle([46, 38, 62, 52], fill=FUR)             # head lying on side
    d.line([(54, 43), (58, 43)], fill=INK, width=2)     # closed eye
    d.ellipse([58, 44, 62, 48], fill=INK)               # nose
    d.rectangle([2, 46, 10, 52], fill=FUR)              # tail flat, stopped
    return add_outline(im)

def anim_down():
    frames = []
    frames.append(f_side(leg_phase=1, head_tilt=2, eyes_x=True))
    frames.append(f_side(leg_phase=0, head_tilt=4, eyes_x=True, bob=2))
    for _ in range(6):
        frames.append(f_lying())
    return frames

def anim_return():
    # Happy trot, tail held high
    return [
        f_side(leg_phase=0, tail_wag=-3, mouth_open=True),
        f_side(leg_phase=1, tail_wag=-2, mouth_open=True),
        f_side(leg_phase=0, tail_wag=-3, mouth_open=True),
        f_side(leg_phase=1, tail_wag=-2, mouth_open=True),
        f_side(leg_phase=0, tail_wag=-3, mouth_open=True),
        f_side(leg_phase=1, tail_wag=-2, mouth_open=True),
    ]

ANIMS = [
    ("idle",          anim_idle),
    ("trot_down",     anim_trot_down),
    ("trot_up",       anim_trot_up),
    ("trot_right",    anim_trot_right),
    ("gallop_down",   anim_gallop_down),
    ("gallop_up",     anim_gallop_up),
    ("gallop_right",  anim_gallop_right),
    ("charge",        anim_charge),
    ("hurt",          anim_hurt),
    ("down",          anim_down),
    ("return",        anim_return),
]

if __name__ == "__main__":
    sheet = Image.new('RGBA', (T * 10, T * len(ANIMS)), TR)
    for row, (name, fn) in enumerate(ANIMS):
        for col, frame in enumerate(fn()):
            sheet.paste(frame, (col * T, row * T))

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, "assets", "art", "sprites", "frosty.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(f"Saved 640x{T*len(ANIMS)} -> {out}")
    for n, f in ANIMS:
        print(f"  {n:<16} {len(f())} frames")
