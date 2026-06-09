#!/usr/bin/env python3
"""
Quinn sprite sheet — v3, fixed proportions + ligne-claire coat depth.
320 × 544 px RGBA  (17 rows × 10 cols × 32×32).

Proportions per spec: head ~10px (y0-11), torso ~10px (y11-21), legs ~11px (y21-31).

Coordinate reference (front-facing, 32×32):
  y  0– 2  hat crown   x 12–20
  y  2– 4  hat brim    x  8–24  (16px wide)
  y  3–11  face        x 12–20
  y  7– 9  glasses     left 12–14, right 17–19
  y 11–12  collar      x 14–18
  y 11–21  coat body   trapezoid top=10–22, bottom=8–24
  y 12–22  arms        x 6–9 left,  x 23–26 right
  y 18     belt stripe
  y 21–27  legs        x 11–14 left, x 17–20 right
  y 26–31  boots       x 10–15 left, x 16–21 right
"""
from PIL import Image, ImageDraw
import os

# ── PICO-8 palette ────────────────────────────────────────────────────────────
BL = (  0,   0,   0, 255)   # black   coat / hat / outline
NV = ( 29,  43,  83, 255)   # navy    boots
GR = ( 95,  87,  79, 255)   # grey    belt / lapels
SL = (194, 195, 199, 255)   # silver  glasses frames
CR = (255, 241, 232, 255)   # cream   skin
OR = (255, 163,   0, 255)   # orange  wrench (brass)
DK = ( 18,  18,  22, 255)   # near-black  coat depth / back-arm shadow
TR = (  0,   0,   0,   0)   # transparent

T = 32

# ── Primitives ────────────────────────────────────────────────────────────────

def tile():
    return Image.new('RGBA', (T, T), TR)

def add_outline(im):
    """1-pixel black border around the whole character silhouette."""
    px  = im.load()
    out = im.copy()
    opx = out.load()
    for y in range(T):
        for x in range(T):
            if px[x, y][3] > 0:
                continue
            for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
                nx, ny = x+dx, y+dy
                if 0 <= nx < T and 0 <= ny < T and px[nx, ny][3] > 0:
                    opx[x, y] = BL
                    break
    return out

# ── Body-part helpers ─────────────────────────────────────────────────────────

def draw_hat(d, cx=16, tilt=0):
    d.rectangle([cx-4, tilt,   cx+4, tilt+2], fill=BL)  # crown (8px)
    d.rectangle([cx-8, tilt+2, cx+8, tilt+4], fill=BL)  # brim (16px)
    d.line([(cx-8, tilt+4), (cx+8, tilt+4)], fill=DK)   # brim underside

def draw_face_front(d, blink=False, expr="neutral"):
    d.rectangle([12, 4, 20, 11], fill=CR)                # head 8×7
    d.line([(12, 4), (20, 4)], fill=GR)                  # hairline hint
    if blink:
        d.line([(12, 8), (14, 8)], fill=GR)
        d.line([(17, 8), (19, 8)], fill=GR)
    else:
        d.rectangle([12, 7, 14, 9], fill=SL)             # left lens 3×2
        d.rectangle([17, 7, 19, 9], fill=SL)             # right lens 3×2
        d.point((13, 8), fill=BL)                        # pupils
        d.point((18, 8), fill=BL)
    d.line([(15, 8), (16, 8)], fill=BL)                  # nose bridge
    if   expr == "talk":  d.line([(14,10),(18,10)], fill=BL)
    elif expr == "laugh": d.arc([13, 9,19,12], 0, 180, fill=BL)
    elif expr == "hurt":  d.line([(14,10),(16,10)], fill=BL)  # small grimace

def draw_face_side(d):
    """Right-facing profile."""
    d.rectangle([16, 4, 22, 11], fill=CR)
    d.line([(16, 4), (22, 4)], fill=GR)                  # hairline
    d.rectangle([19, 7, 21,  9], fill=SL)
    d.point((20, 8), fill=BL)

def draw_arms_front(d, ldy=0, rdy=0, wide=False, raised=False):
    if wide:
        d.rectangle([ 2, 14,  9, 17], fill=BL)
        d.rectangle([23, 14, 30, 17], fill=BL)
    elif raised:
        d.rectangle([ 6, 12,  9, 22], fill=BL)   # left: normal hang
        d.rectangle([23,  7, 26, 17], fill=BL)   # right: raised
    else:
        ly0 = 12 + max(ldy, 0);  ly1 = 22 + ldy
        ry0 = 12 + max(rdy, 0);  ry1 = 22 + rdy
        d.rectangle([ 6, ly0,  9, ly1], fill=BL)
        d.rectangle([23, ry0, 26, ry1], fill=BL)

def draw_coat_front(d):
    d.polygon([(10,11),(22,11),(24,21),(8,21)], fill=BL)  # coat body
    # ligne-claire depth: one-pixel DK band on each coat edge
    d.line([(10,11),(9,21)],  fill=DK)   # left edge shadow
    d.line([(22,11),(23,21)], fill=DK)   # right edge shadow
    d.polygon([(14,11),(16,11),(13,16)], fill=GR)          # left lapel
    d.polygon([(18,11),(16,11),(19,16)], fill=GR)          # right lapel
    d.line([(10,18),(22,18)], fill=GR)                     # belt
    d.rectangle([14,10,18,12], fill=BL)                    # collar

def draw_coat_back(d):
    d.polygon([(10,11),(22,11),(24,21),(8,21)], fill=BL)
    d.line([(10,11),(9,21)],  fill=DK)
    d.line([(22,11),(23,21)], fill=DK)
    d.line([(10,18),(22,18)], fill=GR)

def draw_coat_side(d, reaching=False):
    d.polygon([(13,11),(22,11),(23,21),(11,21)], fill=BL)  # coat profile
    d.line([(12,11),(11,21)], fill=DK)                     # far edge shadow
    d.line([(13,18),(22,18)], fill=GR)
    d.rectangle([12,12,13,20], fill=DK)                    # far arm sliver
    if reaching:
        d.rectangle([22,11,26,15], fill=BL)
        d.rectangle([25,13,30,16], fill=BL)

def draw_near_arm_side(d, arm_dy=0):
    y0 = 12 + max(arm_dy, 0)
    y1 = 22 + arm_dy
    d.rectangle([22, y0, 25, y1], fill=BL)

def draw_wrench(d, raised=False, strike=False, side=False):
    if raised:
        d.rectangle([23,  5, 25, 13], fill=OR)
        d.rectangle([21,  4, 25,  7], fill=OR)
    elif strike:
        d.rectangle([24, 13, 31, 15], fill=OR)
        d.rectangle([24, 11, 27, 15], fill=OR)
    elif side:
        d.rectangle([21, 17, 23, 23], fill=OR)
        d.rectangle([20, 16, 23, 19], fill=OR)
    else:
        d.rectangle([24, 17, 26, 23], fill=OR)
        d.rectangle([22, 16, 26, 19], fill=OR)

def draw_legs_front(d, phase=0, run=False):
    s = 3 if run else 2
    if   phase == 0: lx,rx,ld,rd = 11,17, 0, 0
    elif phase == 1: lx,rx,ld,rd = 10,18, s, 0
    elif phase == 2: lx,rx,ld,rd = 12,16, 0, s
    else:            lx,rx,ld,rd = 10,18, 0, 0
    # trouser legs y=21-27, boots y=26-31
    d.rectangle([lx,   21,    lx+3, 26+ld], fill=BL)
    d.rectangle([lx-1, 25+ld, lx+5, 31],   fill=NV)   # boot
    d.rectangle([rx,   21,    rx+3, 26+rd], fill=BL)
    d.rectangle([rx-1, 25+rd, rx+5, 31],   fill=NV)   # boot

def draw_legs_side(d, phase=0, run=False, crouch=False):
    s = 4 if run else 2
    if crouch:
        d.rectangle([14,21,17,25], fill=BL)
        d.rectangle([18,21,21,25], fill=DK)
        d.rectangle([12,25,20,31], fill=NV)
        d.rectangle([17,25,23,30], fill=NV)
        return
    if phase in (0, 2):
        d.rectangle([15,21,18,27], fill=BL)
        d.rectangle([17,21,20,27], fill=DK)
        d.rectangle([13,26,20,31], fill=NV)
        d.rectangle([16,26,22,30], fill=NV)
    elif phase == 1:
        d.rectangle([17,21,20,26+s], fill=BL)
        d.rectangle([14,21,17,25],   fill=DK)
        d.rectangle([16,25+s,22,31], fill=NV)
        d.rectangle([12,25,18,29],   fill=NV)
    else:
        d.rectangle([14,21,17,26+s], fill=BL)
        d.rectangle([17,21,20,25],   fill=DK)
        d.rectangle([12,25+s,18,31], fill=NV)
        d.rectangle([16,25,22,29],   fill=NV)

# ── Frame assemblers ──────────────────────────────────────────────────────────

def f_front(leg=0, ldy=0, rdy=0, blink=False, expr="neutral",
            wide=False, raised=False, strike=False):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs_front(d, phase=leg)
    draw_arms_front(d, ldy, rdy, wide=wide, raised=raised)
    draw_coat_front(d)
    if   raised: draw_wrench(d, raised=True)
    elif strike: draw_wrench(d, strike=True)
    else:        draw_wrench(d)
    draw_hat(d)
    draw_face_front(d, blink=blink, expr=expr)
    return add_outline(im)

def f_back(leg=0, ldy=0, rdy=0, run=False):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs_front(d, phase=leg, run=run)
    draw_arms_front(d, ldy, rdy)
    draw_coat_back(d)
    draw_hat(d)
    d.rectangle([12, 4, 20, 11], fill=BL)   # back of head
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
    d.rectangle([ 8, 0, 23,  4], fill=BL)    # hat crown
    d.rectangle([ 1, 4, 30,  7], fill=BL)    # hat brim
    d.line([(1,7),(30,7)], fill=DK)
    d.rectangle([ 8, 7, 23, 22], fill=CR)    # face
    d.line([( 8, 8),(23, 8)], fill=GR)        # hairline
    if blink:
        d.line([( 8,14),(13,14)], fill=GR)
        d.line([(18,14),(23,14)], fill=GR)
    else:
        d.rectangle([ 8,12,13,16], fill=SL)
        d.rectangle([18,12,23,16], fill=SL)
        d.point((11,14), fill=BL)
        d.point((21,14), fill=BL)
    d.line([(15,14),(16,14)], fill=BL)
    if   expr == "talk":  d.arc([12,18,20,22], 0, 180, fill=BL)
    elif expr == "laugh": d.arc([10,18,22,23], 0, 180, fill=BL)
    d.rectangle([4, 23, 27, 31], fill=BL)    # coat collar
    d.line([(4,23),(3,31)], fill=DK)
    d.line([(27,23),(28,31)], fill=DK)
    return add_outline(im)

# ── Animation generators ──────────────────────────────────────────────────────

_WL = [0, 1, 3, 2, 0, 1, 3, 2]       # leg phases, 8-frame walk cycle
_WA = [0,-1, 0, 1, 0,-1, 0, 1]       # arm counter-swing dy

def anim_idle():
    return [f_front(blink=(i==4)) for i in range(6)]

def anim_walk_down():
    return [f_front(leg=_WL[i], ldy=_WA[i], rdy=-_WA[i]) for i in range(8)]

def anim_walk_up():
    return [f_back(leg=_WL[i], ldy=_WA[i], rdy=-_WA[i]) for i in range(8)]

def anim_walk_right():
    return [f_side(leg=_WL[i], arm_dy=_WA[i]) for i in range(8)]

def anim_run_down():
    return [f_front(leg=_WL[i], ldy=_WA[i]*2, rdy=-_WA[i]*2) for i in range(8)]

def anim_run_up():
    return [f_back(leg=_WL[i], ldy=_WA[i]*2, rdy=-_WA[i]*2, run=True)
            for i in range(8)]

def anim_run_right():
    return [f_side(leg=_WL[i], arm_dy=_WA[i]*2, run=True) for i in range(8)]

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
    wide  = [False,False,True,True,True,True,False,False]
    exprs = ["neutral","neutral","laugh","laugh","laugh","laugh","talk","neutral"]
    return [f_front(wide=wide[i], expr=exprs[i]) for i in range(8)]

def anim_talk():
    rdys  = [0,-1,0,1,-1,0]
    exprs = ["neutral","talk","neutral","talk","neutral","neutral"]
    return [f_front(rdy=rdys[i], expr=exprs[i]) for i in range(6)]

def anim_talk_closeup():
    blinks = [False,False,False,False,False,False,True,False]
    exprs  = ["neutral","talk","talk","neutral","talk","neutral","neutral","laugh"]
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
            d.rectangle([ 2,12,  8,15], fill=BL)
            d.rectangle([ 4,14, 28,19], fill=BL)
            d.rectangle([ 4,14,  9,19], fill=CR)
            d.rectangle([ 3,18, 20,22], fill=BL)
            d.rectangle([18,19, 28,22], fill=NV)
            frames.append(add_outline(im))
        else:
            im = tile(); d = ImageDraw.Draw(im)
            fy = min(11 + (i-3)*3, 20)
            d.rectangle([ 1,fy,    7, fy+3], fill=BL)
            d.rectangle([ 2,fy+3, 29, fy+8], fill=BL)
            d.rectangle([ 2,fy+3,  7, fy+8], fill=CR)
            d.rectangle([23,fy+4, 29, fy+8], fill=NV)
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
        lean = i
        draw_legs_side(d, phase=1, run=True)
        d.polygon([(13+lean,11),(22+lean,11),(23+lean,21),(11+lean,21)], fill=BL)
        d.line([(13+lean,18),(22+lean,18)], fill=GR)
        d.line([(13+lean,11),(12+lean,21)], fill=DK)
        d.line([(22+lean,11),(23+lean,21)], fill=DK)
        d.rectangle([22+lean,11, 26+lean,16], fill=BL)
        d.rectangle([12,12,13,20], fill=DK)
        draw_wrench(d, side=True)
        draw_hat(d, cx=16+lean, tilt=lean//2)
        d.rectangle([16+lean,4, 22+lean,11], fill=CR)
        d.line([(16+lean,4),(22+lean,4)], fill=GR)
        d.rectangle([19+lean,7, 21+lean, 9], fill=SL)
        d.point((20+lean,8), fill=BL)
        frames.append(add_outline(im))
    return frames

def anim_interact():
    frames = []
    for i in range(8):
        im = tile(); d = ImageDraw.Draw(im)
        draw_legs_side(d, crouch=True)
        draw_coat_side(d)
        draw_near_arm_side(d, arm_dy=0)
        wy = 17 + (i % 2)
        d.rectangle([20,wy,   22, wy+5], fill=OR)
        d.rectangle([18,wy-1, 22, wy+2], fill=OR)
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

# ── Sheet assembly ────────────────────────────────────────────────────────────

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
    sheet = Image.new('RGBA', (T*10, T*len(ANIMS)), TR)
    for row, (name, fn) in enumerate(ANIMS):
        for col, frame in enumerate(fn()):
            sheet.paste(frame, (col*T, row*T))

    out = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                       "assets", "art", "sprites", "quinn.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(f"Saved 320x{T*len(ANIMS)} -> {out}")
    for _, (n, f) in enumerate(ANIMS):
        print(f"  {n:<16} {len(f())} frames")
