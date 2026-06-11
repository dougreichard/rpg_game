#!/usr/bin/env python3
"""
Quinn sprite sheet — PIL procedural, 64x64 spec.
640 x 1088 px RGBA  (17 rows x 10 cols x 64x64).

Extended-palette / "Stranger Things: 1984"-style rebuild (DESIGN.md SS2.0,
sprites.md "Quinn"). Same animation structure and frame counts as the
original 32x32 generator, doubled onto the 64x64 canvas, plus:
  - extended-palette colors (ink-black / coat shading ramp / steel-grey
    lining / pale skin / amber wrench / light-grey glasses), see
    gem/quinn.png for the fidelity target (visible hands, rounder face w/
    eyebrows + blush, softer 2-3 step shading on the coat/hat/boots/wrench)
  - a small Quinn-blue accent trim on the collar (DESIGN.md SS2.1 #4D73D9)
  - an expanding "HA" shockwave ring on the special-ability frames

Proportions (per sprites.md "Style Guide"): head ~20px, torso ~20px,
legs ~24px out of 64.
"""
from PIL import Image, ImageDraw
import os

# -- Extended palette (DESIGN.md SS2.0 / sprites.md "Quinn -> Palette slots") --
INK     = ( 26,  26,  34, 255)   # #1A1A22  ink-black: outline, coat/hat base
COAT_MD = ( 46,  46,  58, 255)   # #2E2E3A  coat shadow band
COAT_HI = ( 92,  92, 110, 255)   # #5C5C6E  coat/hat highlight
LINING  = (110, 122, 134, 255)   # #6E7A86  steel-grey coat lining (lapels)
SKIN    = (255, 227, 199, 255)   # #FFE3C7  pale skin
SKIN_SH = (242, 196, 155, 255)   # #F2C49B  skin shadow / blush
HAIR    = ( 74,  46,  28, 255)   # #4A2E1C  dark brown hair (hairline/brows)
WRENCH  = (255, 201,  77, 255)   # #FFC94D  amber wrench
WRENCH_SH = (255, 154,  60, 255) # #FF9A3C  wrench shadow edge
GLASS   = (168, 168, 184, 255)   # #A8A8B8  light-grey glasses rim
LENS    = (244, 240, 230, 255)   # #F4F0E6  lens highlight
ACCENT  = ( 77, 115, 217, 255)   # #4D73D9  Quinn's signature blue (trim)
TR      = (  0,   0,   0,   0)

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

def draw_hat(d, cx=32, tilt=0):
    d.rectangle([cx - 8, tilt, cx + 8, tilt + 4], fill=INK)        # crown
    d.rectangle([cx - 6, tilt, cx + 6, tilt + 1], fill=COAT_HI)    # crown shine
    d.rectangle([cx - 16, tilt + 4, cx + 16, tilt + 8], fill=INK)  # brim
    d.rectangle([cx - 16, tilt + 8, cx + 16, tilt + 9], fill=COAT_MD)  # brim shadow

def draw_face_front(d, blink=False, expr="neutral"):
    d.rectangle([24, 8, 40, 22], fill=SKIN)              # head 16x14
    d.rectangle([24, 8, 40, 9], fill=HAIR)               # hairline
    d.line([(25, 12), (29, 11)], fill=HAIR)              # left eyebrow
    d.line([(35, 11), (39, 12)], fill=HAIR)              # right eyebrow
    if blink:
        d.line([(24, 16), (28, 16)], fill=INK)
        d.line([(36, 16), (40, 16)], fill=INK)
    else:
        d.rectangle([24, 14, 28, 18], fill=LENS, outline=GLASS)
        d.rectangle([36, 14, 40, 18], fill=LENS, outline=GLASS)
        d.line([(28, 15), (36, 15)], fill=GLASS)         # bridge
        d.rectangle([25, 15, 26, 16], fill=INK)          # pupils
        d.rectangle([37, 15, 38, 16], fill=INK)
    d.line([(31, 17), (33, 17)], fill=SKIN_SH)           # nose hint
    d.ellipse([24, 17, 28, 20], fill=SKIN_SH)            # blush
    d.ellipse([36, 17, 40, 20], fill=SKIN_SH)
    if expr == "talk":
        d.rectangle([29, 19, 35, 21], fill=INK)
    elif expr == "laugh":
        d.arc([28, 17, 36, 23], 0, 180, fill=INK, width=2)
    elif expr == "hurt":
        d.line([(29, 21), (33, 19)], fill=INK, width=2)
    else:
        d.line([(30, 20), (34, 20)], fill=INK)

def draw_face_side(d):
    """Right-facing profile."""
    d.rectangle([32, 8, 44, 22], fill=SKIN)
    d.rectangle([32, 8, 44, 9], fill=HAIR)               # hairline
    d.line([(34, 11), (40, 11)], fill=HAIR)              # eyebrow
    d.rectangle([38, 14, 42, 18], fill=LENS, outline=GLASS)
    d.rectangle([39, 15, 40, 16], fill=INK)              # pupil
    d.ellipse([33, 17, 37, 20], fill=SKIN_SH)            # blush

def draw_arms_front(d, ldy=0, rdy=0, wide=False, raised=False):
    if wide:
        d.rectangle([4, 28, 18, 34], fill=INK)
        d.rectangle([46, 28, 60, 34], fill=INK)
        d.rectangle([4, 28, 8, 34], fill=SKIN)           # left hand
        d.rectangle([56, 28, 60, 34], fill=SKIN)         # right hand
    elif raised:
        d.rectangle([12, 24, 18, 44], fill=INK)          # left: normal hang
        d.rectangle([12, 40, 18, 44], fill=SKIN)         # left hand
        d.rectangle([46, 14, 52, 34], fill=INK)          # right: raised
        d.rectangle([46, 14, 52, 18], fill=SKIN)         # right hand (raised)
    else:
        ly0 = 24 + max(ldy, 0) * 2
        ly1 = 44 + ldy * 2
        ry0 = 24 + max(rdy, 0) * 2
        ry1 = 44 + rdy * 2
        d.rectangle([12, ly0, 18, ly1], fill=INK)
        d.rectangle([12, ly1 - 4, 18, ly1], fill=SKIN)   # left hand
        d.rectangle([46, ry0, 52, ry1], fill=INK)
        d.rectangle([46, ry1 - 4, 52, ry1], fill=SKIN)   # right hand

def draw_coat_front(d):
    d.polygon([(20, 22), (44, 22), (48, 42), (16, 42)], fill=INK)   # coat body
    d.polygon([(20, 22), (22, 22), (18, 42), (16, 42)], fill=COAT_MD)  # left shadow
    d.polygon([(42, 22), (44, 22), (48, 42), (46, 42)], fill=COAT_MD)  # right shadow
    d.line([(32, 24), (32, 40)], fill=COAT_HI)                      # center highlight
    d.polygon([(28, 22), (32, 22), (26, 32)], fill=LINING)          # left lapel
    d.polygon([(36, 22), (32, 22), (38, 32)], fill=LINING)          # right lapel
    d.rectangle([20, 36, 44, 37], fill=COAT_MD)                     # belt
    d.rectangle([28, 20, 36, 24], fill=INK)                         # collar
    d.line([(28, 23), (36, 23)], fill=ACCENT)                       # accent trim

def draw_coat_back(d):
    d.polygon([(20, 22), (44, 22), (48, 42), (16, 42)], fill=INK)
    d.polygon([(20, 22), (22, 22), (18, 42), (16, 42)], fill=COAT_MD)
    d.polygon([(42, 22), (44, 22), (48, 42), (46, 42)], fill=COAT_MD)
    d.line([(32, 24), (32, 40)], fill=COAT_HI)
    d.rectangle([20, 36, 44, 37], fill=COAT_MD)

def draw_coat_side(d, reaching=False):
    d.polygon([(26, 22), (44, 22), (46, 42), (22, 42)], fill=INK)   # coat profile
    d.polygon([(24, 22), (26, 22), (22, 42), (20, 42)], fill=COAT_MD)  # far shadow
    d.rectangle([26, 36, 44, 37], fill=COAT_MD)                     # belt
    d.rectangle([24, 24, 26, 40], fill=COAT_MD)                     # far arm sliver
    if reaching:
        d.rectangle([44, 22, 52, 30], fill=INK)
        d.rectangle([50, 26, 60, 32], fill=INK)

def draw_near_arm_side(d, arm_dy=0):
    y0 = 24 + max(arm_dy, 0) * 2
    y1 = 44 + arm_dy * 2
    d.rectangle([44, y0, 50, y1], fill=INK)
    d.rectangle([44, y1 - 4, 50, y1], fill=SKIN)         # near hand

def draw_wrench(d, raised=False, strike=False, side=False):
    if raised:
        d.rectangle([46, 10, 50, 26], fill=WRENCH)
        d.rectangle([42, 8, 50, 14], fill=WRENCH)
        d.line([(46, 10), (46, 26)], fill=WRENCH_SH)
    elif strike:
        d.rectangle([48, 26, 62, 30], fill=WRENCH)
        d.rectangle([48, 22, 54, 30], fill=WRENCH)
        d.line([(48, 22), (48, 30)], fill=WRENCH_SH)
    elif side:
        d.rectangle([42, 34, 46, 46], fill=WRENCH)
        d.rectangle([40, 32, 46, 38], fill=WRENCH)
        d.line([(42, 34), (42, 46)], fill=WRENCH_SH)
    else:
        d.rectangle([48, 34, 52, 46], fill=WRENCH)
        d.rectangle([44, 32, 52, 38], fill=WRENCH)
        d.line([(48, 34), (48, 46)], fill=WRENCH_SH)

def draw_legs_front(d, phase=0, run=False):
    s = 8 if run else 4
    if   phase == 0: lx, rx, ld, rd = 22, 34, 0, 0
    elif phase == 1: lx, rx, ld, rd = 20, 36, s, 0
    elif phase == 2: lx, rx, ld, rd = 24, 32, 0, s
    else:            lx, rx, ld, rd = 20, 36, 0, 0
    # trouser legs y=42-52, boots y=50-62
    d.rectangle([lx, 42, lx + 6, 52 + ld], fill=INK)
    d.rectangle([lx - 2, 50 + ld, lx + 10, 62], fill=INK)         # boot
    d.rectangle([lx - 2, 50 + ld, lx + 10, 52 + ld], fill=COAT_HI)  # boot cuff shine
    d.rectangle([rx, 42, rx + 6, 52 + rd], fill=INK)
    d.rectangle([rx - 2, 50 + rd, rx + 10, 62], fill=INK)
    d.rectangle([rx - 2, 50 + rd, rx + 10, 52 + rd], fill=COAT_HI)

def draw_legs_side(d, phase=0, run=False, crouch=False):
    s = 8 if run else 4
    if crouch:
        d.rectangle([28, 42, 34, 50], fill=INK)
        d.rectangle([36, 42, 42, 50], fill=COAT_MD)
        d.rectangle([24, 50, 40, 62], fill=INK)
        d.rectangle([34, 50, 46, 60], fill=INK)
        return
    if phase in (0, 2):
        d.rectangle([30, 42, 36, 54], fill=INK)
        d.rectangle([34, 42, 40, 54], fill=COAT_MD)
        d.rectangle([26, 52, 40, 62], fill=INK)
        d.rectangle([32, 52, 44, 60], fill=INK)
    elif phase == 1:
        d.rectangle([34, 42, 40, 52 + s], fill=INK)
        d.rectangle([28, 42, 34, 50], fill=COAT_MD)
        d.rectangle([32, 50 + s, 44, 62], fill=INK)
        d.rectangle([24, 50, 36, 58], fill=INK)
    else:
        d.rectangle([28, 42, 34, 52 + s], fill=INK)
        d.rectangle([34, 42, 40, 50], fill=COAT_MD)
        d.rectangle([24, 50 + s, 36, 62], fill=INK)
        d.rectangle([32, 50, 44, 58], fill=INK)

# -- Frame assemblers ------------------------------------------------------------

def f_front(leg=0, ldy=0, rdy=0, blink=False, expr="neutral",
             wide=False, raised=False, strike=False, ripple=0):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs_front(d, phase=leg)
    draw_arms_front(d, ldy, rdy, wide=wide, raised=raised)
    draw_coat_front(d)
    if   raised: draw_wrench(d, raised=True)
    elif strike: draw_wrench(d, strike=True)
    else:        draw_wrench(d)
    draw_hat(d)
    draw_face_front(d, blink=blink, expr=expr)
    if ripple > 0:
        d.ellipse([32 - ripple, 32 - ripple, 32 + ripple, 32 + ripple],
                  outline=ACCENT, width=2)
    return add_outline(im)

def f_back(leg=0, ldy=0, rdy=0, run=False):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs_front(d, phase=leg, run=run)
    draw_arms_front(d, ldy, rdy)
    draw_coat_back(d)
    draw_hat(d)
    d.rectangle([24, 8, 40, 22], fill=INK)            # back of head
    d.line([(28, 9), (36, 9)], fill=COAT_HI)          # hair shine
    return add_outline(im)

def f_side(leg=0, arm_dy=0, run=False, crouch=False, reaching=False,
           raised=False, strike=False):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs_side(d, phase=leg, run=run, crouch=crouch)
    draw_coat_side(d, reaching=reaching)
    if not reaching:
        draw_near_arm_side(d, arm_dy)
    if   raised: draw_wrench(d, raised=True)
    elif strike: draw_wrench(d, strike=True)
    else:        draw_wrench(d, side=True)
    draw_hat(d)
    draw_face_side(d)
    return add_outline(im)

def f_closeup(blink=False, expr="neutral"):
    im = tile(); d = ImageDraw.Draw(im)
    d.rectangle([16, 0, 46, 8], fill=INK)              # hat crown
    d.rectangle([12, 0, 42, 2], fill=COAT_HI)          # crown shine
    d.rectangle([2, 8, 60, 14], fill=INK)              # hat brim
    d.rectangle([2, 14, 60, 15], fill=COAT_MD)         # brim shadow
    d.rectangle([16, 14, 46, 44], fill=SKIN)           # face
    d.rectangle([16, 14, 46, 16], fill=HAIR)           # hairline
    d.line([(18, 22), (26, 21)], fill=HAIR)            # eyebrows
    d.line([(36, 21), (44, 22)], fill=HAIR)
    if blink:
        d.line([(16, 28), (26, 28)], fill=INK)
        d.line([(36, 28), (46, 28)], fill=INK)
    else:
        d.rectangle([16, 24, 26, 32], fill=LENS, outline=GLASS)
        d.rectangle([36, 24, 46, 32], fill=LENS, outline=GLASS)
        d.line([(26, 27), (36, 27)], fill=GLASS)
        d.rectangle([20, 27, 22, 29], fill=INK)
        d.rectangle([40, 27, 42, 29], fill=INK)
    d.ellipse([16, 32, 22, 38], fill=SKIN_SH)          # blush
    d.ellipse([40, 32, 46, 38], fill=SKIN_SH)
    if expr == "talk":
        d.arc([24, 36, 38, 44], 0, 180, fill=INK, width=2)
    elif expr == "laugh":
        d.arc([20, 36, 42, 46], 0, 180, fill=INK, width=2)
    else:
        d.line([(28, 40), (34, 40)], fill=INK, width=2)
    d.rectangle([8, 46, 54, 62], fill=INK)             # coat collar
    d.line([(8, 46), (6, 62)], fill=COAT_MD)
    d.line([(54, 46), (56, 62)], fill=COAT_MD)
    d.line([(28, 58), (34, 58)], fill=ACCENT)          # accent trim
    return add_outline(im)

# -- Animation generators ---------------------------------------------------------

_WL = [0, 1, 3, 2, 0, 1, 3, 2]       # leg phases, 8-frame walk cycle
_WA = [0, -1, 0, 1, 0, -1, 0, 1]     # arm counter-swing dy

def anim_idle():
    return [f_front(blink=(i == 4)) for i in range(6)]

def anim_walk_down():
    return [f_front(leg=_WL[i], ldy=_WA[i], rdy=-_WA[i]) for i in range(8)]

def anim_walk_up():
    return [f_back(leg=_WL[i], ldy=_WA[i], rdy=-_WA[i]) for i in range(8)]

def anim_walk_right():
    return [f_side(leg=_WL[i], arm_dy=_WA[i]) for i in range(8)]

def anim_run_down():
    return [f_front(leg=_WL[i], ldy=_WA[i] * 2, rdy=-_WA[i] * 2) for i in range(8)]

def anim_run_up():
    return [f_back(leg=_WL[i], ldy=_WA[i] * 2, rdy=-_WA[i] * 2, run=True)
            for i in range(8)]

def anim_run_right():
    return [f_side(leg=_WL[i], arm_dy=_WA[i] * 2, run=True) for i in range(8)]

def anim_attack():
    return [
        f_front(),
        f_side(),
        f_side(raised=True),
        f_side(raised=True),
        f_side(strike=True),
        f_front(),
    ]

def anim_special():
    wide    = [False, False, True, True, True, True, False, False]
    exprs   = ["neutral", "neutral", "laugh", "laugh", "laugh", "laugh", "talk", "neutral"]
    ripples = [0, 0, 0, 0, 14, 22, 30, 38]
    return [f_front(wide=wide[i], expr=exprs[i], ripple=ripples[i]) for i in range(8)]

def anim_talk():
    rdys  = [0, -1, 0, 1, -1, 0]
    exprs = ["neutral", "talk", "neutral", "talk", "neutral", "neutral"]
    return [f_front(rdy=rdys[i], expr=exprs[i]) for i in range(6)]

def anim_talk_closeup():
    blinks = [False, False, False, False, False, False, True, False]
    exprs  = ["neutral", "talk", "talk", "neutral", "talk", "neutral", "neutral", "laugh"]
    return [f_closeup(blink=blinks[i], expr=exprs[i]) for i in range(8)]

def anim_hurt():
    return [f_front(expr="hurt"), f_side(), f_side(leg=1), f_front()]

def anim_down():
    frames = []
    for i in range(10):
        if i <= 1:
            frames.append(f_front(expr="hurt"))
        elif i <= 3:
            im = tile(); d = ImageDraw.Draw(im)
            d.rectangle([4, 24, 16, 30], fill=INK)
            d.rectangle([8, 28, 56, 38], fill=INK)
            d.rectangle([8, 28, 18, 38], fill=SKIN)
            d.rectangle([6, 36, 40, 44], fill=INK)
            d.rectangle([36, 38, 56, 44], fill=INK)
            frames.append(add_outline(im))
        else:
            im = tile(); d = ImageDraw.Draw(im)
            fy = min(22 + (i - 3) * 6, 40)
            d.rectangle([2, fy, 14, fy + 6], fill=INK)
            d.rectangle([4, fy + 6, 58, fy + 16], fill=INK)
            d.rectangle([4, fy + 6, 14, fy + 16], fill=SKIN)
            d.rectangle([46, fy + 8, 58, fy + 16], fill=INK)
            frames.append(add_outline(im))
    return frames

def anim_revive():
    down = anim_down()
    return [down[9], down[7], down[5], down[3],
            f_side(), f_side(leg=1), f_front(), f_front()]

def anim_dash():
    frames = []
    for i in range(5):
        im = tile(); d = ImageDraw.Draw(im)
        lean = i * 2
        draw_legs_side(d, phase=1, run=True)
        d.polygon([(26 + lean, 22), (44 + lean, 22), (46 + lean, 42), (22 + lean, 42)], fill=INK)
        d.polygon([(24 + lean, 22), (26 + lean, 22), (22 + lean, 42), (20 + lean, 42)], fill=COAT_MD)
        d.rectangle([26 + lean, 36, 44 + lean, 37], fill=COAT_MD)   # belt
        d.rectangle([24, 24, 26, 40], fill=COAT_MD)                 # far arm sliver
        d.rectangle([44 + lean, 22, 52 + lean, 32], fill=INK)       # forward arm
        draw_wrench(d, side=True)
        draw_hat(d, cx=32 + lean, tilt=(i // 2) * 2)
        d.rectangle([32 + lean, 8, 44 + lean, 22], fill=SKIN)
        d.rectangle([32 + lean, 8, 44 + lean, 9], fill=HAIR)
        d.rectangle([38 + lean, 14, 42 + lean, 18], fill=LENS, outline=GLASS)
        d.rectangle([39 + lean, 15, 40 + lean, 16], fill=INK)
        frames.append(add_outline(im))
    return frames

def anim_interact():
    frames = []
    for i in range(8):
        im = tile(); d = ImageDraw.Draw(im)
        draw_legs_side(d, crouch=True)
        draw_coat_side(d)
        draw_near_arm_side(d, arm_dy=0)
        wy = 34 + (i % 2) * 2
        d.rectangle([40, wy, 44, wy + 10], fill=WRENCH)
        d.rectangle([36, wy - 2, 44, wy + 4], fill=WRENCH)
        d.line([(40, wy), (40, wy + 10)], fill=WRENCH_SH)
        draw_hat(d)
        draw_face_side(d)
        frames.append(add_outline(im))
    return frames

def anim_doorway():
    return [
        f_front(),
        f_side(),
        f_side(leg=1, reaching=True),
        f_side(leg=3, reaching=True),
        f_side(leg=2),
        f_front(),
    ]

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
    ("talk",         anim_talk),
    ("talk_closeup", anim_talk_closeup),
    ("hurt",         anim_hurt),
    ("down",         anim_down),
    ("revive",       anim_revive),
    ("dash",         anim_dash),
    ("interact",     anim_interact),
    ("doorway",      anim_doorway),
]

if __name__ == "__main__":
    sheet = Image.new('RGBA', (T * 10, T * len(ANIMS)), TR)
    for row, (name, fn) in enumerate(ANIMS):
        for col, frame in enumerate(fn()):
            sheet.paste(frame, (col * T, row * T))

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, "assets", "art", "sprites", "quinn.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(f"Saved 640x{T*len(ANIMS)} -> {out}")
    for n, f in ANIMS:
        print(f"  {n:<16} {len(f())} frames")
