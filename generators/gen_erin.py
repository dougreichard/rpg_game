#!/usr/bin/env python3
"""
Erin sprite sheet — PIL procedural, 64x64 spec.
640 x 1088 px RGBA  (17 rows x 10 cols x 64x64).

Extended-palette / "Stranger Things: 1984"-style rebuild (DESIGN.md SS2.0,
sprites.md "Erin"). Same animation structure and frame counts as the
original 32x32 generator, doubled onto the 64x64 canvas, plus:
  - extended-palette colors (deep-green jacket w/ highlight ramp, auburn
    hair w/ highlight, light-tan skin w/ blush, flame-orange fingertip
    accent), see gem/erin.png for the fidelity target (visible hands,
    rounder face w/ eyebrows + blush, softer 2-3 step shading on the
    jacket/hair/sneakers)
  - a small Erin-orange accent stripe on the jacket sleeve (DESIGN.md SS2.1
    #E6591A)
  - a fuller back-of-head silhouette for walk_up/run_up (v1's back view was
    just a thin hair cap)

Proportions (per sprites.md "Style Guide"): head ~20px, torso ~20px,
legs ~24px out of 64 — same grid as Quinn.
"""
from PIL import Image, ImageDraw
import os

# -- Extended palette (DESIGN.md SS2.0 / sprites.md "Erin -> Palette slots") --
INK       = ( 26,  26,  34, 255)  # #1A1A22  ink-black: outline, jeans, zipper
JACKET    = ( 46, 125,  79, 255)  # #2E7D4F  deep-green jacket
JACKET_HI = ( 79, 176,  92, 255)  # #4FB05C  jacket highlight
JACKET_SH = ( 31,  86,  56, 255)  # jacket shadow band
JEAN_SH   = ( 42,  42,  56, 255)  # far-leg jean shadow (vs. INK near leg)
HAIR      = (156,  90,  46, 255)  # #9C5A2E  auburn hair
HAIR_HI   = (199, 138,  87, 255)  # auburn highlight streak
HAIR_SH   = (110,  61,  28, 255)  # auburn shadow / eyebrows
SKIN      = (242, 196, 155, 255)  # #F2C49B  light-tan skin
SKIN_SH   = (217, 168, 124, 255)  # skin shadow / blush
EYE_WHITE = (244, 240, 230, 255)  # #F4F0E6  eye whites
FLAME     = (255, 154,  60, 255)  # #FF9A3C  fingertip flame
FLAME_HI  = (255, 201,  77, 255)  # bright flame core
SOLE      = ( 29,  43,  83, 255)  # navy sneaker sole
SOLE_HI   = ( 60,  76, 130, 255)  # sneaker sole highlight
ACCENT    = (230,  89,  26, 255)  # #E6591A  Erin's signature orange (sleeve trim)
TR        = (  0,   0,   0,   0)

T = 64

# -- Primitives -----------------------------------------------------------------

def tile():
    return Image.new('RGBA', (T, T), TR)

def add_outline(im):
    """1-pixel ink-black border around the whole character silhouette."""
    px  = im.load()
    out = im.copy()
    opx = out.load()
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

# -- Body-part helpers (all coords are the v1 32x32 coords x2) ------------------

def draw_hair_front(d):
    d.rectangle([24, 0, 40, 6], fill=HAIR)    # top of head
    d.rectangle([22, 6, 42, 10], fill=HAIR)   # hair sides flare slightly
    d.rectangle([22, 12, 24, 14], fill=HAIR)  # strand left
    d.rectangle([40, 12, 42, 14], fill=HAIR)  # strand right
    d.line([(26, 1), (38, 1)], fill=HAIR_HI)  # highlight streak

def draw_hair_back(d):
    d.rectangle([24, 8, 40, 22], fill=HAIR)   # back of head (matches front head size)
    d.rectangle([22, 0, 42, 12], fill=HAIR)   # hair cap
    d.line([(26, 1), (38, 1)], fill=HAIR_HI)

def draw_hair_side(d):
    d.rectangle([26, 0, 44, 10], fill=HAIR)
    d.rectangle([44, 12, 46, 14], fill=HAIR)  # strand
    d.line([(28, 1), (42, 1)], fill=HAIR_HI)

def draw_face_front(d, blink=False, expr="neutral"):
    d.rectangle([24, 8, 40, 22], fill=SKIN)              # head 16x14
    d.line([(25, 12), (29, 11)], fill=HAIR_SH)           # left eyebrow
    d.line([(35, 11), (39, 12)], fill=HAIR_SH)           # right eyebrow
    if blink:
        d.line([(26, 16), (30, 16)], fill=INK)
        d.line([(34, 16), (38, 16)], fill=INK)
    else:
        d.rectangle([26, 14, 30, 18], fill=EYE_WHITE)
        d.rectangle([34, 14, 38, 18], fill=EYE_WHITE)
        d.rectangle([27, 15, 29, 17], fill=INK)          # pupils
        d.rectangle([35, 15, 37, 17], fill=INK)
    d.line([(31, 17), (33, 17)], fill=SKIN_SH)           # nose hint
    d.ellipse([24, 17, 28, 20], fill=SKIN_SH)            # blush
    d.ellipse([36, 17, 40, 20], fill=SKIN_SH)
    if expr == "talk":
        d.rectangle([29, 19, 35, 21], fill=INK)
    elif expr == "smirk":
        d.line([(29, 20), (37, 20)], fill=INK, width=2)
        d.rectangle([36, 18, 38, 20], fill=INK)
    elif expr == "hurt":
        d.line([(29, 21), (33, 19)], fill=INK, width=2)
    else:
        d.line([(30, 20), (34, 20)], fill=INK)

def draw_face_side(d):
    """Right-facing profile."""
    d.rectangle([30, 8, 42, 22], fill=SKIN)
    d.line([(34, 11), (40, 11)], fill=HAIR_SH)           # eyebrow
    d.rectangle([36, 14, 40, 18], fill=EYE_WHITE)
    d.rectangle([37, 15, 39, 17], fill=INK)              # pupil
    d.ellipse([33, 17, 37, 20], fill=SKIN_SH)            # blush

def draw_jacket_front(d):
    d.polygon([(20, 22), (44, 22), (46, 42), (18, 42)], fill=JACKET)  # jacket body
    d.line([(20, 22), (18, 42)], fill=JACKET_SH)         # left shadow edge
    d.line([(44, 22), (46, 42)], fill=JACKET_SH)         # right shadow edge
    d.line([(38, 24), (38, 40)], fill=JACKET_HI)         # highlight
    d.rectangle([28, 20, 36, 24], fill=JACKET)           # collar
    d.line([(32, 22), (32, 40)], fill=INK, width=2)      # zipper line
    d.rectangle([20, 30, 22, 34], fill=ACCENT)           # signature orange sleeve trim
    d.rectangle([20, 40, 44, 42], fill=JACKET_SH)        # hem shadow

def draw_jacket_back(d):
    d.polygon([(20, 22), (44, 22), (46, 42), (18, 42)], fill=JACKET)
    d.line([(20, 22), (18, 42)], fill=JACKET_SH)
    d.line([(44, 22), (46, 42)], fill=JACKET_SH)
    d.line([(38, 24), (38, 40)], fill=JACKET_HI)
    d.rectangle([20, 40, 44, 42], fill=JACKET_SH)

def draw_jacket_side(d):
    d.polygon([(26, 22), (44, 22), (46, 42), (22, 42)], fill=JACKET)  # jacket profile
    d.line([(24, 22), (22, 42)], fill=JACKET_SH)         # near-side shadow
    d.rectangle([24, 24, 26, 40], fill=JACKET_SH)        # far sleeve sliver
    d.line([(40, 24), (40, 40)], fill=JACKET_HI)         # highlight

def draw_arms_front(d, ldy=0, rdy=0, wide=False, fire=False):
    if wide:
        d.rectangle([6, 26, 18, 32], fill=JACKET)
        d.rectangle([46, 26, 58, 32], fill=JACKET)
        d.rectangle([6, 26, 10, 32], fill=SKIN)          # left hand
        d.rectangle([54, 26, 58, 32], fill=SKIN)         # right hand
        if fire:
            d.rectangle([4, 26, 6, 30], fill=FLAME)
            d.rectangle([58, 26, 60, 30], fill=FLAME)
    else:
        ly0 = 24 + max(ldy, 0) * 2
        ly1 = 44 + ldy * 2
        ry0 = 24 + max(rdy, 0) * 2
        ry1 = 44 + rdy * 2
        d.rectangle([14, ly0, 20, ly1], fill=JACKET)
        d.rectangle([14, ly1 - 4, 20, ly1], fill=SKIN)   # left hand
        d.rectangle([44, ry0, 50, ry1], fill=JACKET)
        d.rectangle([44, ry1 - 4, 50, ry1], fill=SKIN)   # right hand
        if fire:
            d.rectangle([14, ly1, 18, ly1 + 2], fill=FLAME)
            d.rectangle([46, ry1, 50, ry1 + 2], fill=FLAME)

def draw_arm_side(d, arm_dy=0, fire=False):
    y0 = 24 + max(arm_dy, 0) * 2
    y1 = 44 + arm_dy * 2
    d.rectangle([44, y0, 50, y1], fill=JACKET)
    d.rectangle([44, y1 - 4, 50, y1], fill=SKIN)         # near hand
    if fire:
        d.rectangle([44, y1, 50, y1 + 2], fill=FLAME)
        d.rectangle([46, y1 - 2, 50, y1], fill=FLAME_HI)  # bright core near hand

def draw_legs_front(d, phase=0, run=False, crouch=False):
    if crouch:
        d.rectangle([22, 42, 28, 50], fill=INK)
        d.rectangle([36, 42, 42, 50], fill=INK)
        d.rectangle([20, 48, 32, 56], fill=SOLE)
        d.rectangle([34, 48, 46, 56], fill=SOLE)
        return
    s = 6 if run else 4
    if   phase == 0: lx, rx, ld, rd = 22, 34, 0, 0
    elif phase == 1: lx, rx, ld, rd = 20, 36, s, 0
    elif phase == 2: lx, rx, ld, rd = 24, 32, 0, s
    else:            lx, rx, ld, rd = 20, 36, 0, 0
    d.rectangle([lx, 42, lx + 6, 52 + ld], fill=INK)
    d.rectangle([lx - 2, 50 + ld, lx + 10, 60], fill=SOLE)
    d.rectangle([lx - 2, 50 + ld, lx + 10, 52 + ld], fill=SOLE_HI)  # sole cuff shine
    d.rectangle([rx, 42, rx + 6, 52 + rd], fill=INK)
    d.rectangle([rx - 2, 50 + rd, rx + 10, 60], fill=SOLE)
    d.rectangle([rx - 2, 50 + rd, rx + 10, 52 + rd], fill=SOLE_HI)

def draw_legs_side(d, phase=0, run=False, crouch=False):
    s = 8 if run else 4
    if crouch:
        d.rectangle([26, 42, 32, 48], fill=INK)
        d.rectangle([34, 42, 40, 48], fill=JEAN_SH)
        d.rectangle([24, 48, 38, 56], fill=SOLE)
        d.rectangle([32, 48, 44, 54], fill=SOLE)
        return
    if phase in (0, 2):
        d.rectangle([30, 42, 36, 54], fill=INK)
        d.rectangle([34, 42, 40, 54], fill=JEAN_SH)
        d.rectangle([26, 52, 40, 60], fill=SOLE)
        d.rectangle([32, 52, 44, 58], fill=SOLE)
    elif phase == 1:
        d.rectangle([34, 42, 40, 52 + s], fill=INK)
        d.rectangle([28, 42, 34, 50], fill=JEAN_SH)
        d.rectangle([32, 50 + s, 44, 60], fill=SOLE)
        d.rectangle([24, 50, 36, 56], fill=SOLE)
    else:
        d.rectangle([28, 42, 34, 52 + s], fill=INK)
        d.rectangle([34, 42, 40, 50], fill=JEAN_SH)
        d.rectangle([24, 50 + s, 36, 60], fill=SOLE)
        d.rectangle([32, 50, 44, 56], fill=SOLE)

# -- Frame assemblers ------------------------------------------------------------

def f_front(leg=0, ldy=0, rdy=0, blink=False, expr="neutral",
             wide=False, run=False, fire=False, crouch=False):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs_front(d, phase=leg, run=run, crouch=crouch)
    draw_arms_front(d, ldy, rdy, wide=wide, fire=fire)
    draw_jacket_front(d)
    draw_hair_front(d)
    draw_face_front(d, blink=blink, expr=expr)
    return add_outline(im)

def f_back(leg=0, ldy=0, rdy=0, run=False):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs_front(d, phase=leg, run=run)
    draw_arms_front(d, ldy, rdy)
    draw_jacket_back(d)
    draw_hair_back(d)
    return add_outline(im)

def f_side(leg=0, arm_dy=0, run=False, crouch=False, fire=False):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs_side(d, phase=leg, run=run, crouch=crouch)
    draw_jacket_side(d)
    draw_arm_side(d, arm_dy, fire=fire)
    draw_hair_side(d)
    draw_face_side(d)
    return add_outline(im)

def f_closeup(blink=False, expr="neutral"):
    im = tile(); d = ImageDraw.Draw(im)
    d.rectangle([20, 0, 44, 8], fill=HAIR)               # hair top
    d.rectangle([14, 8, 50, 16], fill=HAIR)              # hair sides wide
    d.line([(24, 2), (40, 2)], fill=HAIR_HI)             # highlight streak
    d.rectangle([18, 16, 46, 46], fill=SKIN)             # face
    d.line([(20, 22), (28, 21)], fill=HAIR_SH)           # eyebrows
    d.line([(36, 21), (44, 22)], fill=HAIR_SH)
    if blink:
        d.line([(18, 28), (28, 28)], fill=INK)
        d.line([(36, 28), (46, 28)], fill=INK)
    else:
        d.rectangle([18, 24, 28, 32], fill=EYE_WHITE)
        d.rectangle([36, 24, 46, 32], fill=EYE_WHITE)
        d.rectangle([21, 26, 25, 30], fill=INK)
        d.rectangle([39, 26, 43, 30], fill=INK)
    d.ellipse([18, 32, 24, 38], fill=SKIN_SH)            # blush
    d.ellipse([40, 32, 46, 38], fill=SKIN_SH)
    if expr == "talk":
        d.arc([26, 36, 42, 44], 0, 180, fill=INK, width=2)
    elif expr == "smirk":
        d.line([(26, 38), (42, 38)], fill=INK, width=2)
        d.rectangle([41, 36, 44, 38], fill=INK)
    else:
        d.line([(28, 40), (36, 40)], fill=INK, width=2)
    d.rectangle([10, 48, 54, 62], fill=JACKET)           # jacket collar
    d.line([(10, 48), (8, 62)], fill=JACKET_SH)
    d.line([(54, 48), (56, 62)], fill=JACKET_SH)
    d.rectangle([28, 58, 36, 60], fill=ACCENT)           # signature orange trim
    return add_outline(im)

# -- Walk cycle -------------------------------------------------------------------

_WL = [0, 1, 3, 2, 0, 1, 3, 2]
_WA = [0, -1, 0, 1, 0, -1, 0, 1]

# -- Animation generators -----------------------------------------------------------

def anim_idle():
    # Slight weight shift, subtle fire flicker on last 2 frames
    return [f_front(blink=(i == 4), fire=(i >= 4)) for i in range(6)]

def anim_walk_down():
    return [f_front(leg=_WL[i], ldy=_WA[i], rdy=-_WA[i]) for i in range(8)]

def anim_walk_up():
    return [f_back(leg=_WL[i], ldy=_WA[i], rdy=-_WA[i]) for i in range(8)]

def anim_walk_right():
    return [f_side(leg=_WL[i], arm_dy=_WA[i]) for i in range(8)]

def anim_run_down():
    # Erin runs faster — bigger arm/leg swings
    return [f_front(leg=_WL[i], ldy=_WA[i] * 3, rdy=-_WA[i] * 3, run=True) for i in range(8)]

def anim_run_up():
    return [f_back(leg=_WL[i], ldy=_WA[i] * 3, rdy=-_WA[i] * 3, run=True) for i in range(8)]

def anim_run_right():
    return [f_side(leg=_WL[i], arm_dy=_WA[i] * 3, run=True) for i in range(8)]

def anim_attack():
    # Fire jab: wind-up, ignite, strike burst, fade
    return [
        f_side(),
        f_side(arm_dy=-2, fire=True),
        f_side(arm_dy=-3, fire=True),
        f_side(arm_dy=-1, fire=True),
        f_side(fire=False),
        f_front(),
    ]

def anim_special():
    # Fast Talk — rapid gestures, leaning
    exprs = ["neutral", "talk", "smirk", "talk", "smirk", "talk", "neutral", "neutral"]
    wide  = [False, True, True, True, True, True, False, False]
    return [f_front(wide=wide[i], expr=exprs[i]) for i in range(8)]

def anim_stealth():
    # Crouch tiptoe — reduced height
    return [f_front(leg=_WL[i], ldy=_WA[i], rdy=-_WA[i], crouch=True) for i in range(6)]

def anim_talk():
    rdys  = [0, -1, 0, 1, -1, 0]
    exprs = ["neutral", "talk", "smirk", "talk", "neutral", "neutral"]
    return [f_front(rdy=rdys[i], expr=exprs[i]) for i in range(6)]

def anim_talk_closeup():
    blinks = [False, False, False, False, False, False, True, False]
    exprs  = ["neutral", "talk", "smirk", "talk", "smirk", "neutral", "neutral", "talk"]
    return [f_closeup(blink=blinks[i], expr=exprs[i]) for i in range(8)]

def anim_hurt():
    return [f_front(expr="hurt"), f_side(leg=1), f_side(), f_front()]

def anim_down():
    frames = []
    for i in range(10):
        if i <= 1:
            frames.append(f_front(expr="hurt"))
        elif i <= 3:
            im = tile(); d = ImageDraw.Draw(im)
            d.rectangle([6, 24, 18, 30], fill=JACKET)
            d.rectangle([8, 28, 56, 38], fill=JACKET)
            d.rectangle([8, 28, 18, 38], fill=SKIN)
            d.rectangle([40, 28, 56, 34], fill=HAIR)   # hair visible
            d.rectangle([6, 36, 40, 44], fill=INK)
            d.rectangle([36, 38, 56, 44], fill=SOLE)
            frames.append(add_outline(im))
        else:
            im = tile(); d = ImageDraw.Draw(im)
            fy = min(22 + (i - 3) * 6, 40)
            d.rectangle([2, fy, 14, fy + 6], fill=HAIR)        # hair
            d.rectangle([4, fy + 6, 58, fy + 16], fill=JACKET)
            d.rectangle([4, fy + 6, 14, fy + 16], fill=SKIN)
            d.rectangle([46, fy + 8, 58, fy + 16], fill=SOLE)
            frames.append(add_outline(im))
    return frames

def anim_revive():
    down = anim_down()
    return [down[9], down[7], down[5], down[3],
            f_side(crouch=True), f_side(leg=1), f_front(), f_front()]

def anim_dash():
    # Erin's dash is lower to ground than Quinn
    frames = []
    for i in range(5):
        im = tile(); d = ImageDraw.Draw(im)
        lean = i * 2
        draw_legs_side(d, phase=1, run=True)
        d.polygon([(26 + lean, 26), (44 + lean, 26), (46 + lean, 44), (22 + lean, 44)], fill=JACKET)
        d.line([(26 + lean, 26), (24 + lean, 44)], fill=JACKET_SH)
        d.line([(44 + lean, 26), (46 + lean, 44)], fill=JACKET_SH)
        d.rectangle([44 + lean, 26, 52 + lean, 34], fill=JACKET)  # forward arm
        d.rectangle([24, 26, 26, 42], fill=JACKET_SH)             # far arm sliver
        draw_hair_side(d)
        d.rectangle([30 + lean, 10, 42 + lean, 22], fill=SKIN)
        draw_face_side(d)
        frames.append(add_outline(im))
    return frames

def anim_hide():
    # Ducking down, silhouette shrinks each frame
    frames = []
    for i in range(6):
        shrink = i * 4
        im = tile(); d = ImageDraw.Draw(im)
        top = 8 + shrink
        d.rectangle([24, top, 40, top + 10], fill=HAIR)   # hair shrinks
        d.rectangle([22 + shrink // 2, top + 8, 42 - shrink // 2, top + 18], fill=SKIN)  # face
        d.rectangle([20 + shrink // 2, top + 18, 44 - shrink // 2, top + 32], fill=JACKET)  # jacket
        d.rectangle([20 + shrink // 2, top + 30, 44 - shrink // 2, 62], fill=INK)  # jeans
        frames.append(add_outline(im))
    return frames

# -- Sheet assembly ----------------------------------------------------------------

ANIMS = [
    ("idle",         anim_idle),
    ("walk_down",    anim_walk_down),
    ("walk_up",      anim_walk_up),
    ("walk_right",   anim_walk_right),
    ("run_down",     anim_run_down),
    ("run_up",       anim_run_up),
    ("run_right",    anim_run_right),
    ("attack",       anim_attack),
    ("special",      anim_special),
    ("stealth",      anim_stealth),
    ("talk",         anim_talk),
    ("talk_closeup", anim_talk_closeup),
    ("hurt",         anim_hurt),
    ("down",         anim_down),
    ("revive",       anim_revive),
    ("dash",         anim_dash),
    ("hide",         anim_hide),
]

if __name__ == "__main__":
    sheet = Image.new('RGBA', (T * 10, T * len(ANIMS)), TR)
    for row, (name, fn) in enumerate(ANIMS):
        for col, frame in enumerate(fn()):
            sheet.paste(frame, (col * T, row * T))

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, "assets", "art", "sprites", "erin.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(f"Saved 640x{T*len(ANIMS)} -> {out}")
    for n, f in ANIMS:
        print(f"  {n:<16} {len(f())} frames")
