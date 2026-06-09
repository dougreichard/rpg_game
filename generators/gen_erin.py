#!/usr/bin/env python3
"""
Erin sprite sheet — PIL fallback.
320 × 544 px RGBA  (17 rows × 10 cols × 32×32).

Erin: teenage girl, lithe, quick. Dark-green jacket, black jeans, sneakers,
short red-auburn hair. Orange flame accent at fingertips in attack/special.
"""
from PIL import Image, ImageDraw
import os

# ── Palette ───────────────────────────────────────────────────────────────────
BL = (  0,   0,   0, 255)   # black   jeans / outline
GN = (  0, 135,  81, 255)   # dark green jacket
RD = (171,  82,  54, 255)   # auburn  hair
OR = (255, 163,   0, 255)   # orange  flame
CR = (255, 241, 232, 255)   # cream   skin
DK = ( 18,  18,  22, 255)   # near-black jacket shadow
NV = ( 29,  43,  83, 255)   # navy    sneaker sole
TR = (  0,   0,   0,   0)   # transparent

T = 32

# ── Proportions (same grid as Quinn v3) ──────────────────────────────────────
# Head:   y 2–11  (no hat — hair fills y0-3)
# Torso:  y 11–21 (jacket)
# Legs:   y 21–31 (jeans + sneakers)

def tile():
    return Image.new('RGBA', (T, T), TR)

def add_outline(im):
    px = im.load(); out = im.copy(); opx = out.load()
    for y in range(T):
        for x in range(T):
            if px[x, y][3] > 0: continue
            for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
                nx, ny = x+dx, y+dy
                if 0 <= nx < T and 0 <= ny < T and px[nx, ny][3] > 0:
                    opx[x, y] = BL; break
    return out

# ── Body parts ────────────────────────────────────────────────────────────────

def draw_hair_front(d):
    d.rectangle([12, 0, 20, 3], fill=RD)   # top of head
    d.rectangle([11, 3, 21, 5], fill=RD)   # hair sides flare slightly
    d.point((11, 6), fill=RD)              # strand left
    d.point((21, 6), fill=RD)              # strand right

def draw_hair_back(d):
    d.rectangle([11, 0, 21, 6], fill=RD)

def draw_hair_side(d):
    d.rectangle([13, 0, 22, 5], fill=RD)
    d.point((22, 6), fill=RD)

def draw_face_front(d, blink=False, expr="neutral"):
    d.rectangle([12, 4, 20, 11], fill=CR)
    if blink:
        d.line([(13, 8), (15, 8)], fill=BL)
        d.line([(17, 8), (19, 8)], fill=BL)
    else:
        d.rectangle([13, 7, 15, 9], fill=BL)   # eyes (no glasses)
        d.rectangle([17, 7, 19, 9], fill=BL)
        d.point((14, 8), fill=CR)               # eye highlight
        d.point((18, 8), fill=CR)
    if   expr == "talk":  d.arc([13, 9, 19, 12], 0, 180, fill=BL)
    elif expr == "smirk": d.line([(14,10),(18,10)], fill=BL); d.point((18,10), fill=BL)
    elif expr == "hurt":  d.line([(14,10),(16,10)], fill=BL)

def draw_face_side(d):
    d.rectangle([15, 4, 21, 11], fill=CR)
    d.rectangle([18, 7, 20,  9], fill=BL)
    d.point((19, 8), fill=CR)

def draw_jacket_front(d):
    d.polygon([(10,11),(22,11),(23,21),(9,21)], fill=GN)
    d.line([(10,11),(9,21)],  fill=DK)
    d.line([(22,11),(23,21)], fill=DK)
    d.rectangle([14,10,18,12], fill=GN)   # collar
    d.line([(16,11),(16,20)], fill=DK)    # zipper line

def draw_jacket_back(d):
    d.polygon([(10,11),(22,11),(23,21),(9,21)], fill=GN)
    d.line([(10,11),(9,21)], fill=DK)
    d.line([(22,11),(23,21)], fill=DK)

def draw_jacket_side(d):
    d.polygon([(13,11),(22,11),(23,21),(11,21)], fill=GN)
    d.line([(12,11),(11,21)], fill=DK)
    d.rectangle([12,12,13,20], fill=DK)

def draw_arms_front(d, ldy=0, rdy=0, wide=False, fire=False):
    if wide:
        d.rectangle([ 3, 13,  9, 16], fill=GN)
        d.rectangle([23, 13, 29, 16], fill=GN)
        if fire:
            d.point(( 3, 13), fill=OR); d.point(( 3, 14), fill=OR)
            d.point((29, 13), fill=OR); d.point((29, 14), fill=OR)
    else:
        ly0 = 12 + max(ldy, 0); ly1 = 22 + ldy
        ry0 = 12 + max(rdy, 0); ry1 = 22 + rdy
        d.rectangle([ 7, ly0, 10, ly1], fill=GN)
        d.rectangle([22, ry0, 25, ry1], fill=GN)
        if fire:
            d.point(( 7, ly1), fill=OR); d.point(( 8, ly1), fill=OR)
            d.point((22, ry1), fill=OR); d.point((23, ry1), fill=OR)

def draw_arm_side(d, arm_dy=0, fire=False):
    y0 = 12 + max(arm_dy, 0); y1 = 22 + arm_dy
    d.rectangle([22, y0, 25, y1], fill=GN)
    if fire: d.point((22, y1), fill=OR); d.point((23, y1), fill=OR)

def draw_legs_front(d, phase=0, run=False, crouch=False):
    if crouch:
        # Low crouching stance
        d.rectangle([11, 21, 14, 25], fill=BL)
        d.rectangle([18, 21, 21, 25], fill=BL)
        d.rectangle([10, 24, 16, 28], fill=NV)
        d.rectangle([17, 24, 23, 28], fill=NV)
        return
    s = 3 if run else 2
    if   phase == 0: lx,rx,ld,rd = 11,17, 0, 0
    elif phase == 1: lx,rx,ld,rd = 10,18, s, 0
    elif phase == 2: lx,rx,ld,rd = 12,16, 0, s
    else:            lx,rx,ld,rd = 10,18, 0, 0
    d.rectangle([lx,   21, lx+3, 26+ld], fill=BL)
    d.rectangle([lx-1, 25+ld, lx+5, 30], fill=NV)
    d.rectangle([rx,   21, rx+3, 26+rd], fill=BL)
    d.rectangle([rx-1, 25+rd, rx+5, 30], fill=NV)

def draw_legs_side(d, phase=0, run=False, crouch=False):
    s = 4 if run else 2
    if crouch:
        d.rectangle([13,21,16,24], fill=BL)
        d.rectangle([17,21,20,24], fill=DK)
        d.rectangle([12,24,19,28], fill=NV)
        d.rectangle([16,24,22,27], fill=NV)
        return
    if phase in (0, 2):
        d.rectangle([15,21,18,27], fill=BL)
        d.rectangle([17,21,20,27], fill=DK)
        d.rectangle([13,26,20,30], fill=NV)
        d.rectangle([16,26,22,29], fill=NV)
    elif phase == 1:
        d.rectangle([17,21,20,26+s], fill=BL)
        d.rectangle([14,21,17,25], fill=DK)
        d.rectangle([16,25+s,22,30], fill=NV)
        d.rectangle([12,25,18,28], fill=NV)
    else:
        d.rectangle([14,21,17,26+s], fill=BL)
        d.rectangle([17,21,20,25], fill=DK)
        d.rectangle([12,25+s,18,30], fill=NV)
        d.rectangle([16,25,22,28], fill=NV)

# ── Frame assemblers ──────────────────────────────────────────────────────────

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
    d.rectangle([10, 0, 22, 4], fill=RD)    # hair top
    d.rectangle([ 7, 4, 25, 8], fill=RD)    # hair sides wide
    d.rectangle([ 9, 8, 23, 23], fill=CR)   # face
    if blink:
        d.line([( 9,14),(14,14)], fill=BL)
        d.line([(18,14),(23,14)], fill=BL)
    else:
        d.rectangle([ 9,12,14,16], fill=BL)
        d.rectangle([18,12,23,16], fill=BL)
        d.point((12,14), fill=CR)
        d.point((21,14), fill=CR)
    if   expr == "talk":  d.arc([13,18,21,22], 0, 180, fill=BL)
    elif expr == "smirk": d.line([(13,19),(21,19)], fill=BL); d.point((21,19), fill=BL)
    d.rectangle([5, 24, 27, 31], fill=GN)   # jacket collar
    d.line([(5,24),(4,31)], fill=DK)
    d.line([(27,24),(28,31)], fill=DK)
    return add_outline(im)

# ── Walk cycle ────────────────────────────────────────────────────────────────

_WL = [0, 1, 3, 2, 0, 1, 3, 2]
_WA = [0,-1, 0, 1, 0,-1, 0, 1]

# ── Animations ────────────────────────────────────────────────────────────────

def anim_idle():
    # Slight weight shift, subtle fire flicker on last 2 frames
    return [f_front(blink=(i==4), fire=(i>=4)) for i in range(6)]

def anim_walk_down():
    return [f_front(leg=_WL[i], ldy=_WA[i], rdy=-_WA[i]) for i in range(8)]

def anim_walk_up():
    return [f_back(leg=_WL[i], ldy=_WA[i], rdy=-_WA[i]) for i in range(8)]

def anim_walk_right():
    return [f_side(leg=_WL[i], arm_dy=_WA[i]) for i in range(8)]

def anim_run_down():
    # Erin runs faster — bigger arm/leg swings
    return [f_front(leg=_WL[i], ldy=_WA[i]*3, rdy=-_WA[i]*3, run=True) for i in range(8)]

def anim_run_up():
    return [f_back(leg=_WL[i], ldy=_WA[i]*3, rdy=-_WA[i]*3, run=True) for i in range(8)]

def anim_run_right():
    return [f_side(leg=_WL[i], arm_dy=_WA[i]*3, run=True) for i in range(8)]

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
    exprs = ["neutral","talk","smirk","talk","smirk","talk","neutral","neutral"]
    wide  = [False, True, True, True, True, True, False, False]
    return [f_front(wide=wide[i], expr=exprs[i]) for i in range(8)]

def anim_stealth():
    # Crouch tiptoe — reduced height
    return [f_front(leg=_WL[i], ldy=_WA[i], rdy=-_WA[i], crouch=True) for i in range(6)]

def anim_talk():
    rdys  = [0,-1, 0, 1,-1, 0]
    exprs = ["neutral","talk","smirk","talk","neutral","neutral"]
    return [f_front(rdy=rdys[i], expr=exprs[i]) for i in range(6)]

def anim_talk_closeup():
    blinks = [False,False,False,False,False,False,True,False]
    exprs  = ["neutral","talk","smirk","talk","smirk","neutral","neutral","talk"]
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
            d.rectangle([ 3,12,  9,15], fill=GN)
            d.rectangle([ 4,14, 28,19], fill=GN)
            d.rectangle([ 4,14,  9,19], fill=CR)
            d.rectangle([20,14, 28,17], fill=RD)   # hair visible
            d.rectangle([ 3,18, 20,22], fill=BL)
            d.rectangle([18,19, 28,22], fill=NV)
            frames.append(add_outline(im))
        else:
            im = tile(); d = ImageDraw.Draw(im)
            fy = min(11 + (i-3)*3, 20)
            d.rectangle([ 1,fy,    7, fy+3], fill=RD)   # hair
            d.rectangle([ 2,fy+3, 29, fy+8], fill=GN)
            d.rectangle([ 2,fy+3,  7, fy+8], fill=CR)
            d.rectangle([23,fy+4, 29, fy+8], fill=NV)
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
        lean = i
        draw_legs_side(d, phase=1, run=True)
        d.polygon([(13+lean,13),(22+lean,13),(23+lean,22),(11+lean,22)], fill=GN)
        d.line([(13+lean,13),(12+lean,22)], fill=DK)
        d.line([(22+lean,13),(23+lean,22)], fill=DK)
        d.rectangle([22+lean,13,26+lean,17], fill=GN)
        d.rectangle([12,13,13,21], fill=DK)
        draw_hair_side(d)
        d.rectangle([15+lean,5,21+lean,11], fill=CR)
        draw_face_side(d)
        frames.append(add_outline(im))
    return frames

def anim_hide():
    # Ducking down, silhouette shrinks each frame
    frames = []
    for i in range(6):
        shrink = i * 2
        im = tile(); d = ImageDraw.Draw(im)
        top = 4 + shrink
        d.rectangle([12, top, 20, top+5], fill=RD)  # hair shrinks
        d.rectangle([11+shrink//2, top+4, 21-shrink//2, top+9], fill=CR)  # face
        d.rectangle([10+shrink//2, top+9, 22-shrink//2, top+16], fill=GN) # jacket
        d.rectangle([10+shrink//2, top+15, 22-shrink//2, 31], fill=BL)    # jeans
        frames.append(add_outline(im))
    return frames

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
    sheet = Image.new('RGBA', (T*10, T*len(ANIMS)), TR)
    for row, (name, fn) in enumerate(ANIMS):
        for col, frame in enumerate(fn()):
            sheet.paste(frame, (col*T, row*T))

    out = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                       "assets", "art", "sprites", "erin.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(f"Saved 320x{T*len(ANIMS)} -> {out}")
    for _, (n, f) in enumerate(ANIMS):
        print(f"  {n:<16} {len(f())} frames")
