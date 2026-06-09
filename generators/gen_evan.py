#!/usr/bin/env python3
"""
Evan sprite sheet — PIL fallback.
320 × 544 px RGBA  (17 rows × 10 cols × 32×32).

Evan: teenage boy, BROAD/wide build (widest character). Olive t-shirt,
brown cargo shorts, hiking boots, warm skin. Fists only — no tool.
Frosty (small white dog) at feet in idle. Slowest but hits hardest.
"""
from PIL import Image, ImageDraw
import os

# ── Palette ───────────────────────────────────────────────────────────────────
BL = (  0,   0,   0, 255)   # black   outline
OL = (108, 121,  67, 255)   # olive   t-shirt
BN = ( 95,  87,  79, 255)   # brown   cargo shorts / boots
SK = (255, 204, 170, 255)   # warm    skin (arms, face, legs)
DK = ( 55,  50,  35, 255)   # dark    boot / shadow
WH = (255, 241, 232, 255)   # near-white  Frosty fur
TR = (  0,   0,   0,   0)   # transparent

T = 32

# ── Shared helpers ────────────────────────────────────────────────────────────

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

# ── Body parts — Evan is 2 px wider each side than Quinn ──────────────────────
# Head:   y 3–11  (no hat — short dark hair)
# Torso:  y 11–21 (t-shirt, wide shoulders x 8–24)
# Legs:   y 21–31 (shorts + boots, wide stance)

def draw_hair_front(d):
    d.rectangle([11, 1, 21, 4], fill=BN)   # short dark hair

def draw_hair_back(d):
    d.rectangle([10, 1, 22, 5], fill=BN)

def draw_hair_side(d):
    d.rectangle([13, 1, 22, 5], fill=BN)

def draw_face_front(d, expr="neutral"):
    d.rectangle([11, 4, 21, 11], fill=SK)   # wider head
    d.rectangle([12, 7, 14,  9], fill=BL)   # left eye
    d.rectangle([18, 7, 20,  9], fill=BL)   # right eye
    d.point((13, 8), fill=SK)
    d.point((19, 8), fill=SK)
    if   expr == "shout": d.arc([13,9,19,12], 0, 180, fill=BL)
    elif expr == "hurt":  d.line([(13,10),(19,10)], fill=BL)
    elif expr == "strain":d.line([(12,10),(20,10)], fill=BL); d.line([(15,9),(17,9)], fill=BL)

def draw_face_side(d):
    d.rectangle([14, 4, 22, 11], fill=SK)
    d.rectangle([19, 7, 21,  9], fill=BL)
    d.point((20, 8), fill=SK)

def draw_torso_front(d):
    # Wide t-shirt
    d.rectangle([8, 11, 24, 21], fill=OL)
    d.line([(8,11),(8,21)],  fill=DK)   # left shadow
    d.line([(24,11),(24,21)], fill=DK)  # right shadow

def draw_torso_back(d):
    d.rectangle([8, 11, 24, 21], fill=OL)
    d.line([(8,11),(8,21)],  fill=DK)
    d.line([(24,11),(24,21)], fill=DK)

def draw_torso_side(d):
    d.rectangle([12, 11, 22, 21], fill=OL)
    d.line([(12,11),(12,21)], fill=DK)

def draw_arms_front(d, ldy=0, rdy=0, wide=False, raised=False, strain=False):
    if wide:
        d.rectangle([ 1, 12,  8, 17], fill=SK)
        d.rectangle([24, 12, 31, 17], fill=SK)
    elif raised:
        d.rectangle([ 5, 11,  9, 21], fill=SK)
        d.rectangle([23,  6, 27, 16], fill=SK)
    else:
        ly0 = 11 + max(ldy, 0); ly1 = 21 + ldy
        ry0 = 11 + max(rdy, 0); ry1 = 21 + rdy
        d.rectangle([ 5, ly0,  9, ly1], fill=SK)
        d.rectangle([23, ry0, 27, ry1], fill=SK)

def draw_arm_side(d, arm_dy=0):
    y0 = 11 + max(arm_dy, 0); y1 = 21 + arm_dy
    d.rectangle([22, y0, 26, y1], fill=SK)

def draw_legs_front(d, phase=0, run=False, crouch=False):
    if crouch:
        d.rectangle([ 9, 21, 14, 25], fill=BN)
        d.rectangle([18, 21, 23, 25], fill=BN)
        d.rectangle([ 8, 25, 16, 31], fill=DK)
        d.rectangle([16, 25, 24, 31], fill=DK)
        return
    s = 3 if run else 2
    if   phase == 0: lx,rx,ld,rd = 10,17,  0, 0
    elif phase == 1: lx,rx,ld,rd =  9,18,  s, 0
    elif phase == 2: lx,rx,ld,rd = 11,16,  0, s
    else:            lx,rx,ld,rd =  9,18,  0, 0
    # Shorts (BN) then boots (DK) — wide stance
    d.rectangle([lx,   21, lx+4, 25+ld], fill=BN)
    d.rectangle([lx-1, 25+ld, lx+5, 31], fill=DK)
    d.rectangle([rx,   21, rx+4, 25+rd], fill=BN)
    d.rectangle([rx-1, 25+rd, rx+5, 31], fill=DK)

def draw_legs_side(d, phase=0, run=False, crouch=False):
    s = 4 if run else 2
    if crouch:
        d.rectangle([13,21,17,25], fill=BN)
        d.rectangle([17,21,21,25], fill=DK)
        d.rectangle([12,25,19,31], fill=DK)
        d.rectangle([17,25,23,30], fill=DK)
        return
    if phase in (0, 2):
        d.rectangle([14,21,18,27], fill=BN)
        d.rectangle([17,21,21,27], fill=BN)
        d.rectangle([13,26,20,31], fill=DK)
        d.rectangle([16,26,23,30], fill=DK)
    elif phase == 1:
        d.rectangle([17,21,21,26+s], fill=BN)
        d.rectangle([13,21,17,25],   fill=BN)
        d.rectangle([16,25+s,23,31], fill=DK)
        d.rectangle([12,25,18,29],   fill=DK)
    else:
        d.rectangle([13,21,17,26+s], fill=BN)
        d.rectangle([17,21,21,25],   fill=BN)
        d.rectangle([12,25+s,18,31], fill=DK)
        d.rectangle([16,25,23,29],   fill=DK)

def draw_frosty(d):
    """Small white dog at Evan's feet — idle only."""
    d.rectangle([6, 26, 13, 30], fill=WH)   # body
    d.rectangle([6, 24, 9,  27], fill=WH)   # head
    d.rectangle([5, 29, 7,  31], fill=WH)   # front legs
    d.rectangle([11,29,13, 31], fill=WH)    # back legs
    d.point((7, 25), fill=BL)               # eye
    d.rectangle([13,26,16,27], fill=WH)     # tail up

# ── Frame assemblers ──────────────────────────────────────────────────────────

def f_front(leg=0, ldy=0, rdy=0, expr="neutral", wide=False,
            raised=False, run=False, crouch=False, frosty=False):
    im = tile(); d = ImageDraw.Draw(im)
    if frosty: draw_frosty(d)
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
    d.rectangle([ 7, 0, 25,  4], fill=BN)   # hair
    d.rectangle([ 7, 4, 25, 22], fill=SK)   # wide face
    d.rectangle([ 8,12,13, 16], fill=BL)    # left eye
    d.rectangle([19,12,24, 16], fill=BL)
    d.point((11,14), fill=SK); d.point((22,14), fill=SK)
    if   expr == "shout": d.arc([11,18,21,23], 0, 180, fill=BL)
    elif expr == "talk":  d.line([(11,19),(21,19)], fill=BL)
    d.rectangle([4, 23, 28, 31], fill=OL)   # t-shirt collar wide
    return add_outline(im)

# ── Walk cycle ────────────────────────────────────────────────────────────────
_WL = [0, 1, 3, 2, 0, 1, 3, 2]
_WA = [0,-1, 0, 1, 0,-1, 0, 1]

# ── Animations ────────────────────────────────────────────────────────────────

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
    return [f_front(leg=_WL[i], ldy=_WA[i]*2, rdy=-_WA[i]*2, run=True) for i in range(8)]

def anim_run_up():
    return [f_back(leg=_WL[i], ldy=_WA[i]*2, rdy=-_WA[i]*2, run=True) for i in range(8)]

def anim_run_right():
    return [f_side(leg=_WL[i], arm_dy=_WA[i]*2, run=True) for i in range(8)]

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
    exprs = ["neutral","neutral","shout","shout","shout","neutral","neutral","neutral"]
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
    exprs = ["neutral","shout","neutral","talk","neutral","neutral"]
    wide  = [False, True, False, False, False, False]
    return [f_front(wide=wide[i], expr=exprs[i]) for i in range(6)]

def anim_talk_closeup():
    exprs = ["neutral","talk","shout","talk","neutral","talk","neutral","neutral"]
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
            d.rectangle([ 2,11, 10,15], fill=OL)
            d.rectangle([ 4,14, 28,20], fill=OL)
            d.rectangle([ 4,14, 10,20], fill=SK)
            d.rectangle([ 3,19, 20,23], fill=BN)
            d.rectangle([19,20, 28,23], fill=DK)
            frames.append(add_outline(im))
        else:
            im = tile(); d = ImageDraw.Draw(im)
            fy = min(10 + (i-3)*3, 19)
            d.rectangle([ 1,fy,    8, fy+3], fill=BN)
            d.rectangle([ 2,fy+3, 30, fy+8], fill=OL)
            d.rectangle([ 2,fy+3,  8, fy+8], fill=SK)
            d.rectangle([22,fy+4, 30, fy+8], fill=DK)
            frames.append(add_outline(im))
    return frames

def anim_revive():
    down = anim_down()
    return [down[9], down[7], down[5], down[3],
            f_side(crouch=True), f_side(leg=1), f_front(), f_front()]

def anim_dash():
    frames = []
    for i in range(5):
        im = tile(); d = ImageDraw.Draw(im)
        lean = i
        draw_legs_side(d, phase=1, run=True)
        d.rectangle([12+lean,11, 22+lean,21], fill=OL)
        d.line([(12+lean,11),(12+lean,21)], fill=DK)
        d.rectangle([22+lean,11,27+lean,18], fill=SK)
        d.rectangle([11,12,12,20], fill=DK)
        draw_hair_side(d)
        d.rectangle([14+lean,4,22+lean,11], fill=SK)
        d.rectangle([19+lean,7,21+lean, 9], fill=BL)
        frames.append(add_outline(im))
    return frames

def anim_brace():
    # Wide stance, arms spread bracing — "Hold" animation
    frames = []
    for i in range(6):
        sway = [0,1,0,-1,0,1][i]
        im = tile(); d = ImageDraw.Draw(im)
        draw_legs_front(d, phase=0)
        draw_arms_front(d, ldy=0, rdy=0, wide=True)
        draw_torso_front(d)
        draw_hair_front(d)
        draw_face_front(d, expr="strain")
        frames.append(add_outline(im))
    return frames

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
    sheet = Image.new('RGBA', (T*10, T*len(ANIMS)), (0,0,0,0))
    for row, (name, fn) in enumerate(ANIMS):
        for col, frame in enumerate(fn()):
            sheet.paste(frame, (col*T, row*T))
    out = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                       "assets", "art", "sprites", "evan.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(f"Saved 320x{T*len(ANIMS)} -> {out}")
    for n, f in ANIMS: print(f"  {n:<16} {len(f())} frames")
