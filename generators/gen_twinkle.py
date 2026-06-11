#!/usr/bin/env python3
"""
Twinkle sprite sheet — PIL procedural, 64x64 spec.
640 x 576 px RGBA  (9 rows x up-to-8 cols x 64x64, padded to 10 cols).

Twinkle: tiny Pomeranian — cream fluffy fur, oversized round head, tiny
cloudy (blind) eyes, an ivory snaggle tooth always poking out, ridiculously
short legs, tiny pink tongue. Sound-puzzle aggravator — her bark distraction
is implemented in underground_tunnels.gd via twinkle_companion.gd (see
CLAUDE.md). New, 64x64 — no v1 to migrate from.
"""
from PIL import Image, ImageDraw
import os

# -- Palette (sprites.md "Twinkle -> Palette slots") --
INK     = ( 26,  26,  34, 255)  # #1A1A22 ink-black: outline, nose
FUR     = (244, 240, 230, 255)  # #F4F0E6 cream fur
FUR_SH  = (214, 210, 200, 255)  # fur shadow
PINK    = (255, 156, 194, 255)  # #FF9CC2 tongue
CLOUDY  = (200, 200, 210, 255)  # tiny cloudy/blind eyes
SNAGGLE = (255, 252, 240, 255)  # ivory snaggle tooth
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

# -- Shared parts ------------------------------------------------------------------

def draw_tail(d, up=False):
    if up:
        d.ellipse([6, 8, 18, 28], fill=FUR)
        d.ellipse([6, 8, 12, 18], fill=FUR_SH)
    else:
        d.ellipse([4, 26, 16, 42], fill=FUR)
        d.ellipse([4, 34, 16, 42], fill=FUR_SH)

def draw_legs(d, phase=0):
    # ridiculously short legs — 4px tall
    xs = [20, 28, 36, 44]
    for i, x in enumerate(xs):
        y0 = 52 if (i + phase) % 2 == 0 else 53
        d.rectangle([x, y0, x + 4, 56], fill=FUR)

def draw_body(d, dy=0):
    d.ellipse([14, 32 + dy, 50, 54 + dy], fill=FUR)
    d.ellipse([14, 46 + dy, 50, 54 + dy], fill=FUR_SH)

def draw_rings(d, n, cx=42, cy=16):
    for i in range(n):
        r = 6 + i * 5
        d.arc([cx - r, cy - r, cx + r, cy + r], 0, 360, fill=CLOUDY, width=2)

# -- Side profile (facing right) --------------------------------------------------

def draw_head_side(d, dy=0, dx=0, mouth_open=False, turn_away=False):
    hx = 34 + dx
    hy = 12 + dy
    d.ellipse([hx, hy, hx + 28, hy + 28], fill=FUR)
    d.ellipse([hx + 14, hy + 14, hx + 28, hy + 28], fill=FUR_SH)
    d.ellipse([hx + 2, hy - 4, hx + 10, hy + 6], fill=FUR)
    d.ellipse([hx + 18, hy - 4, hx + 26, hy + 6], fill=FUR)
    if not turn_away:
        d.ellipse([hx + 8, hy + 8, hx + 13, hy + 13], fill=CLOUDY)
        d.ellipse([hx + 16, hy + 8, hx + 21, hy + 13], fill=CLOUDY)
        d.ellipse([hx + 22, hy + 14, hx + 26, hy + 18], fill=INK)
        d.polygon([(hx + 18, hy + 20), (hx + 22, hy + 20), (hx + 20, hy + 26)], fill=SNAGGLE)
        if mouth_open:
            d.ellipse([hx + 13, hy + 17, hx + 24, hy + 26], fill=PINK)

def f_side(leg_phase=0, dx=0, mouth_open=False, tail_up=False, dy=0, turn_away=False, body_dy=0):
    im = tile(); d = ImageDraw.Draw(im)
    draw_tail(d, up=tail_up)
    draw_legs(d, phase=leg_phase)
    draw_body(d, dy=body_dy)
    draw_head_side(d, dy=dy, dx=dx, mouth_open=mouth_open, turn_away=turn_away)
    return add_outline(im)

# -- Front view (facing camera) ---------------------------------------------------

def draw_head_front(d, dx=0):
    hx = 18 + dx
    d.ellipse([hx, 10, hx + 28, 38], fill=FUR)
    d.ellipse([hx + 14, 24, hx + 28, 38], fill=FUR_SH)
    d.ellipse([hx + 1, 4, hx + 9, 14], fill=FUR)
    d.ellipse([hx + 19, 4, hx + 27, 14], fill=FUR)
    d.ellipse([hx + 6, 18, hx + 11, 23], fill=CLOUDY)
    d.ellipse([hx + 17, 18, hx + 22, 23], fill=CLOUDY)
    d.ellipse([hx + 12, 24, hx + 16, 28], fill=INK)
    d.polygon([(hx + 13, 28), (hx + 17, 28), (hx + 15, 34)], fill=SNAGGLE)

def f_front(leg_phase=0, dx=0):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs(d, phase=leg_phase)
    d.ellipse([16, 34, 48, 54], fill=FUR)
    d.ellipse([16, 46, 48, 54], fill=FUR_SH)
    draw_head_front(d, dx=dx)
    return add_outline(im)

# -- Animation generators --------------------------------------------------------

def anim_idle():
    # tiny wobble; snaggle tooth + cloudy eyes always visible
    wobbles = [0, 1, 0, -1, 0, 1]
    return [f_side(dx=w) for w in wobbles]

_TROT_PHASE = [0, 1, 0, 1, 0, 1]

def anim_trot_down():
    return [f_front(leg_phase=_TROT_PHASE[i], dx=(1 if i % 2 else -1)) for i in range(6)]

def anim_trot_right():
    return [f_side(leg_phase=_TROT_PHASE[i], dy=(-1 if i % 2 else 0)) for i in range(6)]

def anim_return_trot():
    # same as trot_right but the loader flips horizontally for the way home
    return anim_trot_right()

def anim_bark_distract():
    frames = []
    for i in range(8):
        bounce = -3 if i % 2 == 0 else 0
        rings = (i // 2) + 1 if i % 2 == 1 else 0
        im = tile(); d = ImageDraw.Draw(im)
        draw_tail(d, up=False)
        draw_legs(d, phase=i % 2)
        draw_body(d, dy=bounce)
        draw_head_side(d, dy=bounce, mouth_open=True)
        if rings:
            draw_rings(d, min(rings, 3))
        frames.append(add_outline(im))
    return frames

def anim_hurt():
    return [
        f_side(leg_phase=1, dx=2, dy=-2, turn_away=False),
        f_side(leg_phase=0, dx=-1, dy=1, mouth_open=True),
        f_side(leg_phase=1, dx=2, dy=-2),
        f_side(leg_phase=0),
    ]

def f_flop(leg_up=True):
    im = tile(); d = ImageDraw.Draw(im)
    d.ellipse([8, 38, 52, 58], fill=FUR)
    d.ellipse([8, 50, 52, 58], fill=FUR_SH)
    d.ellipse([40, 26, 64, 50], fill=FUR)
    d.ellipse([52, 38, 64, 50], fill=FUR_SH)
    d.ellipse([46, 32, 51, 37], fill=CLOUDY)
    d.polygon([(48, 38), (52, 38), (50, 44)], fill=SNAGGLE)
    if leg_up:
        d.rectangle([24, 24, 28, 38], fill=FUR)  # one tiny leg points up
    return add_outline(im)

def anim_down():
    frames = [
        f_side(leg_phase=1, dy=2, dx=1),
        f_flop(leg_up=False),
    ]
    for _ in range(4):
        frames.append(f_flop(leg_up=True))
    return frames

def anim_sniff():
    return [
        f_side(leg_phase=0, tail_up=True, dy=8),
        f_side(leg_phase=1, tail_up=True, dy=9),
        f_side(leg_phase=0, tail_up=True, dy=8),
        f_side(leg_phase=1, tail_up=True, dy=9),
    ]

def anim_annoyed():
    return [
        f_side(turn_away=True, dx=0),
        f_side(turn_away=True, dx=2),
        f_side(turn_away=True, dx=0),
        f_side(turn_away=True, dx=2),
    ]

ANIMS = [
    ("idle",          anim_idle),
    ("trot_down",     anim_trot_down),
    ("trot_right",    anim_trot_right),
    ("bark_distract", anim_bark_distract),
    ("return_trot",   anim_return_trot),
    ("hurt",          anim_hurt),
    ("down",          anim_down),
    ("sniff",         anim_sniff),
    ("annoyed",       anim_annoyed),
]

if __name__ == "__main__":
    sheet = Image.new('RGBA', (T * 10, T * len(ANIMS)), TR)
    for row, (name, fn) in enumerate(ANIMS):
        for col, frame in enumerate(fn()):
            sheet.paste(frame, (col * T, row * T))

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, "assets", "art", "sprites", "twinkle.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(f"Saved 640x{T*len(ANIMS)} -> {out}")
    for n, f in ANIMS:
        print(f"  {n:<16} {len(f())} frames")
