#!/usr/bin/env python3
"""
Evan sprite sheet — PIL procedural, 64x64 spec.
640 x 1088 px RGBA  (17 rows x 10 cols x 64x64).

Extended-palette / "Stranger Things: 1984"-style rebuild (DESIGN.md SS2.0,
sprites.md "Evan"). Same animation structure and frame counts as the
original 32x32 generator, doubled onto the 64x64 canvas, plus:
  - extended-palette colors (olive/khaki t-shirt w/ highlight+shadow bands,
    brown cargo shorts w/ highlight, worn boots w/ cuff highlight, warm skin
    w/ blush, dark-brown hair w/ highlight)
  - eye-white + pupil + eyebrow detail on the face (front/side/closeup),
    matching the Quinn/Erin rebuilds
  - Frosty (small white dog at Evan's feet in idle) gains a shaded underside

Proportions (per sprites.md "Style Guide", "Evan is 2px wider each side than
Quinn" doubled): head ~20x14, torso ~32x20, legs wide stance — broadest
silhouette of the five characters.
"""
from PIL import Image, ImageDraw
import os

# -- Extended palette (DESIGN.md SS2.0 / sprites.md "Evan -> Palette slots") --
INK       = ( 26,  26,  34, 255)  # ink-black: outline
OLIVE     = (156, 138,  78, 255)  # #9C8A4E olive/khaki t-shirt
OLIVE_HI  = (189, 174, 118, 255)  # olive highlight seam
OLIVE_SH  = (122, 107,  58, 255)  # olive shadow band
BROWN     = (110,  74,  46, 255)  # #6E4A2E brown cargo shorts
BROWN_HI  = (140, 100,  68, 255)  # cargo highlight
BOOT      = ( 70,  47,  29, 255)  # worn boot brown (#6E4A2E darkened)
BOOT_HI   = ( 95,  68,  46, 255)  # boot cuff highlight
SKIN      = (217, 163, 110, 255)  # #D9A36E warm skin
SKIN_SH   = (191, 138,  90, 255)  # skin shadow / blush
HAIR      = ( 92,  62,  38, 255)  # short dark-brown hair
HAIR_HI   = (122,  87,  56, 255)  # hair highlight
HAIR_SH   = ( 64,  42,  25, 255)  # hair shadow / eyebrows
EYE_WHITE = (244, 240, 230, 255)  # eye whites
FROSTY    = (250, 248, 245, 255)  # near-white Frosty fur
FROSTY_SH = (214, 210, 204, 255)  # Frosty fur shadow
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
# Head:   y 8-22  (no hat — short dark hair)
# Torso:  y 22-42 (t-shirt, wide shoulders x 16-48)
# Legs:   y 42-62 (shorts + boots, wide stance)

def draw_hair_front(d):
    d.rectangle([22, 2, 42, 8], fill=HAIR)    # short dark hair
    d.line([(24, 3), (38, 3)], fill=HAIR_HI)  # highlight streak

def draw_hair_back(d):
    d.rectangle([20, 2, 44, 10], fill=HAIR)
    d.line([(22, 3), (40, 3)], fill=HAIR_HI)

def draw_hair_side(d):
    d.rectangle([26, 2, 44, 10], fill=HAIR)
    d.line([(28, 3), (42, 3)], fill=HAIR_HI)

def draw_face_front(d, expr="neutral"):
    d.rectangle([22, 8, 42, 22], fill=SKIN)              # wide head
    d.line([(24, 12), (28, 11)], fill=HAIR_SH)           # left eyebrow
    d.line([(36, 11), (40, 12)], fill=HAIR_SH)           # right eyebrow
    d.rectangle([24, 14, 28, 18], fill=EYE_WHITE)        # left eye
    d.rectangle([36, 14, 40, 18], fill=EYE_WHITE)        # right eye
    d.rectangle([25, 15, 27, 17], fill=INK)              # left pupil
    d.rectangle([37, 15, 39, 17], fill=INK)              # right pupil
    d.ellipse([22, 17, 26, 20], fill=SKIN_SH)            # blush
    d.ellipse([38, 17, 42, 20], fill=SKIN_SH)
    if   expr == "shout":
        d.arc([26, 18, 38, 24], 0, 180, fill=INK, width=2)
    elif expr == "hurt":
        d.line([(26, 20), (38, 20)], fill=INK, width=2)
    elif expr == "strain":
        d.line([(24, 20), (40, 20)], fill=INK, width=2)
        d.line([(30, 18), (34, 18)], fill=INK, width=2)
    else:
        d.line([(28, 20), (36, 20)], fill=SKIN_SH)

def draw_face_side(d):
    d.rectangle([28, 8, 44, 22], fill=SKIN)
    d.line([(36, 11), (42, 11)], fill=HAIR_SH)           # eyebrow
    d.rectangle([38, 14, 42, 18], fill=EYE_WHITE)
    d.rectangle([39, 15, 41, 17], fill=INK)              # pupil
    d.ellipse([34, 17, 38, 20], fill=SKIN_SH)            # blush

def draw_torso_front(d):
    d.rectangle([16, 22, 48, 42], fill=OLIVE)
    d.rectangle([16, 22, 20, 42], fill=OLIVE_SH)         # left shadow band
    d.rectangle([44, 22, 48, 42], fill=OLIVE_SH)         # right shadow band
    d.line([(32, 24), (32, 40)], fill=OLIVE_HI, width=2) # center highlight seam
    d.rectangle([28, 20, 36, 24], fill=OLIVE)            # collar

def draw_torso_back(d):
    d.rectangle([16, 22, 48, 42], fill=OLIVE)
    d.rectangle([16, 22, 20, 42], fill=OLIVE_SH)
    d.rectangle([44, 22, 48, 42], fill=OLIVE_SH)
    d.line([(32, 24), (32, 40)], fill=OLIVE_HI, width=2)

def draw_torso_side(d):
    d.rectangle([24, 22, 44, 42], fill=OLIVE)
    d.rectangle([24, 22, 28, 42], fill=OLIVE_SH)
    d.line([(40, 24), (40, 40)], fill=OLIVE_HI, width=2)

def draw_arms_front(d, ldy=0, rdy=0, wide=False, raised=False):
    if wide:
        d.rectangle([2, 24, 16, 34], fill=SKIN)
        d.rectangle([48, 24, 62, 34], fill=SKIN)
        d.rectangle([2, 30, 16, 34], fill=SKIN_SH)
        d.rectangle([48, 30, 62, 34], fill=SKIN_SH)
    elif raised:
        d.rectangle([10, 22, 18, 42], fill=SKIN)
        d.rectangle([46, 12, 54, 32], fill=SKIN)
    else:
        ly0 = 22 + max(ldy, 0) * 2
        ly1 = 42 + ldy * 2
        ry0 = 22 + max(rdy, 0) * 2
        ry1 = 42 + rdy * 2
        d.rectangle([10, ly0, 18, ly1], fill=SKIN)
        d.rectangle([46, ry0, 54, ry1], fill=SKIN)
        d.rectangle([10, ly1 - 4, 18, ly1], fill=SKIN_SH)
        d.rectangle([46, ry1 - 4, 54, ry1], fill=SKIN_SH)

def draw_arm_side(d, arm_dy=0):
    y0 = 22 + max(arm_dy, 0) * 2
    y1 = 42 + arm_dy * 2
    d.rectangle([44, y0, 52, y1], fill=SKIN)
    d.rectangle([44, y1 - 4, 52, y1], fill=SKIN_SH)

def draw_legs_front(d, phase=0, run=False, crouch=False):
    if crouch:
        d.rectangle([18, 42, 28, 50], fill=BROWN)
        d.rectangle([36, 42, 46, 50], fill=BROWN)
        d.rectangle([16, 50, 32, 62], fill=BOOT)
        d.rectangle([32, 50, 48, 62], fill=BOOT)
        d.rectangle([16, 50, 32, 52], fill=BOOT_HI)
        d.rectangle([32, 50, 48, 52], fill=BOOT_HI)
        return
    s = 6 if run else 4
    if   phase == 0: lx, rx, ld, rd = 20, 34, 0, 0
    elif phase == 1: lx, rx, ld, rd = 18, 36, s, 0
    elif phase == 2: lx, rx, ld, rd = 22, 32, 0, s
    else:            lx, rx, ld, rd = 18, 36, 0, 0
    d.rectangle([lx, 42, lx + 8, 50 + ld], fill=BROWN)
    d.rectangle([lx, 42, lx + 2, 50 + ld], fill=BROWN_HI)
    d.rectangle([lx - 2, 50 + ld, lx + 10, 62], fill=BOOT)
    d.rectangle([lx - 2, 50 + ld, lx + 10, 52 + ld], fill=BOOT_HI)
    d.rectangle([rx, 42, rx + 8, 50 + rd], fill=BROWN)
    d.rectangle([rx, 42, rx + 2, 50 + rd], fill=BROWN_HI)
    d.rectangle([rx - 2, 50 + rd, rx + 10, 62], fill=BOOT)
    d.rectangle([rx - 2, 50 + rd, rx + 10, 52 + rd], fill=BOOT_HI)

def draw_legs_side(d, phase=0, run=False, crouch=False):
    s = 8 if run else 4
    if crouch:
        d.rectangle([26, 42, 34, 50], fill=BROWN)
        d.rectangle([34, 42, 42, 50], fill=BOOT)
        d.rectangle([24, 50, 38, 62], fill=BOOT)
        d.rectangle([34, 50, 46, 60], fill=BOOT)
        d.rectangle([24, 50, 38, 52], fill=BOOT_HI)
        return
    if phase in (0, 2):
        d.rectangle([28, 42, 36, 54], fill=BROWN)
        d.rectangle([34, 42, 42, 54], fill=BROWN)
        d.rectangle([26, 52, 40, 62], fill=BOOT)
        d.rectangle([32, 52, 46, 60], fill=BOOT)
        d.rectangle([26, 52, 40, 54], fill=BOOT_HI)
    elif phase == 1:
        d.rectangle([34, 42, 42, 52 + s], fill=BROWN)
        d.rectangle([26, 42, 34, 50],     fill=BROWN)
        d.rectangle([32, 50 + s, 46, 62], fill=BOOT)
        d.rectangle([24, 50, 36, 58],     fill=BOOT)
        d.rectangle([32, 50 + s, 46, 52 + s], fill=BOOT_HI)
    else:
        d.rectangle([26, 42, 34, 52 + s], fill=BROWN)
        d.rectangle([34, 42, 42, 50],     fill=BROWN)
        d.rectangle([24, 50 + s, 36, 62], fill=BOOT)
        d.rectangle([32, 50, 46, 58],     fill=BOOT)
        d.rectangle([24, 50 + s, 36, 52 + s], fill=BOOT_HI)

def draw_frosty(d):
    """Small white dog at Evan's feet — idle only."""
    d.rectangle([12, 52, 26, 60], fill=FROSTY)   # body
    d.rectangle([12, 48, 18, 54], fill=FROSTY)   # head
    d.rectangle([10, 58, 14, 62], fill=FROSTY)   # front legs
    d.rectangle([22, 58, 26, 62], fill=FROSTY)   # back legs
    d.rectangle([12, 56, 26, 60], fill=FROSTY_SH)  # belly shadow
    d.rectangle([14, 50, 16, 52], fill=INK)      # eye
    d.rectangle([26, 52, 32, 54], fill=FROSTY)   # tail up

# -- Frame assemblers ------------------------------------------------------------

def f_front(leg=0, ldy=0, rdy=0, expr="neutral", wide=False,
             raised=False, run=False, crouch=False, frosty=False):
    im = tile(); d = ImageDraw.Draw(im)
    if frosty:
        draw_frosty(d)
    draw_legs_front(d, phase=leg, run=run, crouch=crouch)
    draw_arms_front(d, ldy, rdy, wide=wide, raised=raised)
    draw_torso_front(d)
    draw_hair_front(d)
    draw_face_front(d, expr=expr)
    return add_outline(im)

def f_back(leg=0, ldy=0, rdy=0, run=False):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs_front(d, phase=leg, run=run)
    draw_arms_front(d, ldy, rdy)
    draw_torso_back(d)
    draw_hair_back(d)
    return add_outline(im)

def f_side(leg=0, arm_dy=0, run=False, crouch=False):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs_side(d, phase=leg, run=run, crouch=crouch)
    draw_torso_side(d)
    draw_arm_side(d, arm_dy)
    draw_hair_side(d)
    draw_face_side(d)
    return add_outline(im)

def f_closeup(expr="neutral"):
    im = tile(); d = ImageDraw.Draw(im)
    d.rectangle([14, 0, 50, 8], fill=HAIR)               # hair top
    d.line([(18, 2), (46, 2)], fill=HAIR_HI)             # highlight streak
    d.rectangle([14, 8, 50, 44], fill=SKIN)              # wide face
    d.line([(18, 16), (28, 14)], fill=HAIR_SH)           # eyebrows
    d.line([(36, 14), (46, 16)], fill=HAIR_SH)
    d.rectangle([18, 20, 28, 28], fill=EYE_WHITE)        # left eye
    d.rectangle([36, 20, 46, 28], fill=EYE_WHITE)
    d.rectangle([21, 22, 25, 26], fill=INK)              # left pupil
    d.rectangle([39, 22, 43, 26], fill=INK)              # right pupil
    d.ellipse([16, 30, 24, 36], fill=SKIN_SH)            # blush
    d.ellipse([40, 30, 48, 36], fill=SKIN_SH)
    if   expr == "shout":
        d.arc([22, 36, 42, 46], 0, 180, fill=INK, width=2)
    elif expr == "talk":
        d.line([(22, 38), (42, 38)], fill=INK, width=2)
    else:
        d.line([(24, 38), (40, 38)], fill=SKIN_SH, width=2)
    d.rectangle([8, 46, 56, 62], fill=OLIVE)             # wide t-shirt collar
    d.rectangle([8, 46, 56, 50], fill=OLIVE_HI)          # collar highlight
    return add_outline(im)

# -- Walk cycle -------------------------------------------------------------------

_WL = [0, 1, 3, 2, 0, 1, 3, 2]
_WA = [0, -1, 0, 1, 0, -1, 0, 1]

# -- Animation generators -----------------------------------------------------------

def anim_idle():
    return [f_front(frosty=(i < 4)) for i in range(6)]

def anim_walk_down():
    return [f_front(leg=_WL[i], ldy=_WA[i], rdy=-_WA[i]) for i in range(8)]

def anim_walk_up():
    return [f_back(leg=_WL[i], ldy=_WA[i], rdy=-_WA[i]) for i in range(8)]

def anim_walk_right():
    return [f_side(leg=_WL[i], arm_dy=_WA[i]) for i in range(8)]

def anim_run_down():
    # Evan runs heavy — less arm swing than Erin
    return [f_front(leg=_WL[i], ldy=_WA[i] * 2, rdy=-_WA[i] * 2, run=True) for i in range(8)]

def anim_run_up():
    return [f_back(leg=_WL[i], ldy=_WA[i] * 2, rdy=-_WA[i] * 2, run=True) for i in range(8)]

def anim_run_right():
    return [f_side(leg=_WL[i], arm_dy=_WA[i] * 2, run=True) for i in range(8)]

def anim_attack():
    # Straight punch — fist extends past tile edge
    return [
        f_front(),
        f_side(),
        f_side(arm_dy=-3),
        f_side(arm_dy=-4),   # fist fully extended
        f_side(arm_dy=-2),
        f_front(),
    ]

def anim_special():
    # Two-finger whistle then pointing gesture
    exprs = ["neutral", "neutral", "shout", "shout", "shout", "neutral", "neutral", "neutral"]
    wide  = [False, False, True, True, False, False, False, False]
    return [f_front(wide=wide[i], expr=exprs[i]) for i in range(8)]

def anim_lift():
    # Crouch and grab (1-3), heave upward (4-6), release (7-8)
    frames = []
    for i in range(8):
        if i <= 2:
            frames.append(f_front(crouch=True, expr="strain"))
        elif i <= 5:
            frames.append(f_front(raised=True, expr="strain"))
        else:
            frames.append(f_front(expr="neutral"))
    return frames

def anim_talk():
    exprs = ["neutral", "shout", "neutral", "talk", "neutral", "neutral"]
    wide  = [False, True, False, False, False, False]
    return [f_front(wide=wide[i], expr=exprs[i]) for i in range(6)]

def anim_talk_closeup():
    exprs = ["neutral", "talk", "shout", "talk", "neutral", "talk", "neutral", "neutral"]
    return [f_closeup(expr=exprs[i]) for i in range(8)]

def anim_hurt():
    return [f_front(expr="hurt"), f_side(leg=1), f_side(), f_front()]

def anim_down():
    frames = []
    for i in range(10):
        if i <= 1:
            frames.append(f_front(expr="hurt"))
        elif i <= 3:
            im = tile(); d = ImageDraw.Draw(im)
            d.rectangle([4, 22, 20, 30], fill=OLIVE)
            d.rectangle([8, 28, 56, 40], fill=OLIVE)
            d.rectangle([8, 28, 20, 40], fill=SKIN)
            d.rectangle([6, 38, 40, 46], fill=BROWN)
            d.rectangle([38, 40, 56, 46], fill=BOOT)
            frames.append(add_outline(im))
        else:
            im = tile(); d = ImageDraw.Draw(im)
            fy = min(20 + (i - 3) * 6, 38)
            d.rectangle([2, fy, 16, fy + 6], fill=BROWN)
            d.rectangle([4, fy + 6, 60, fy + 16], fill=OLIVE)
            d.rectangle([4, fy + 6, 16, fy + 16], fill=SKIN)
            d.rectangle([44, fy + 8, 60, fy + 16], fill=BOOT)
            frames.append(add_outline(im))
    return frames

def anim_revive():
    down = anim_down()
    return [down[9], down[7], down[5], down[3],
            f_side(crouch=True), f_side(leg=1), f_front(), f_front()]

def anim_dash():
    frames = []
    for i in range(5):
        lean = i * 2
        im = tile(); d = ImageDraw.Draw(im)
        draw_legs_side(d, phase=1, run=True)
        d.rectangle([24 + lean, 22, 44 + lean, 42], fill=OLIVE)
        d.line([(24 + lean, 22), (24 + lean, 42)], fill=OLIVE_SH, width=2)
        d.rectangle([44 + lean, 22, 54 + lean, 36], fill=SKIN)
        d.rectangle([22, 24, 24, 40], fill=BOOT)
        draw_hair_side(d)
        d.rectangle([28 + lean, 8, 44 + lean, 22], fill=SKIN)
        d.rectangle([38 + lean, 14, 42 + lean, 18], fill=INK)
        frames.append(add_outline(im))
    return frames

def anim_brace():
    # Wide stance, arms spread bracing — "Hold" animation
    return [f_front(wide=True, expr="strain") for _ in range(6)]

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
    ("lift",         anim_lift),
    ("talk",         anim_talk),
    ("talk_closeup", anim_talk_closeup),
    ("hurt",         anim_hurt),
    ("down",         anim_down),
    ("revive",       anim_revive),
    ("dash",         anim_dash),
    ("brace",        anim_brace),
]

if __name__ == "__main__":
    sheet = Image.new('RGBA', (T * 10, T * len(ANIMS)), TR)
    for row, (name, fn) in enumerate(ANIMS):
        for col, frame in enumerate(fn()):
            sheet.paste(frame, (col * T, row * T))

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, "assets", "art", "sprites", "evan.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(f"Saved 640x{T*len(ANIMS)} -> {out}")
    for n, f in ANIMS:
        print(f"  {n:<16} {len(f())} frames")
