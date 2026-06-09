#!/usr/bin/env python3
"""
Ben sprite sheet — PIL fallback.
320 × 544 px RGBA  (17 rows × 10 cols × 32×32).

Ben: teenage boy, medium build, patchwork jacket (multi-color patches), dark
trousers, ankle boots, messy brown hair. Keytar slung diagonally across body.
Bard/musician — animations should feel expressive and theatrical.
"""
from PIL import Image, ImageDraw
import os

# ── Palette ───────────────────────────────────────────────────────────────────
BL = (  0,   0,   0, 255)   # black    outline
BN = ( 95,  87,  79, 255)   # brown    hair / ankle boots
DK = ( 55,  50,  35, 255)   # dark     trousers / shadow
SK = (255, 204, 170, 255)   # skin
CY = (  0, 195, 199, 255)   # cyan     keytar keys
KY = ( 28,  28, 80, 255)    # keytar   body (dark navy)
# Patchwork patches — PICO-8 palette fragments
P1 = (255, 163,   0, 255)   # orange patch
P2 = (  0, 228,  54, 255)   # green patch
P3 = (255,   0,  77, 255)   # red patch
P4 = ( 29,  43,  83, 255)   # dark navy patch
P5 = (171, 82,  54, 255)    # warm brown patch
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

# ── Body parts ────────────────────────────────────────────────────────────────
# Head:  y 2–11
# Torso: y 11–22  (patchwork jacket)
# Legs:  y 22–31

_PATCHES_FRONT = [
    # (x0,y0,x1,y1,color) — torso patch layout
    (11,11,16,16, P1),   # orange left-chest
    (16,11,22,16, P2),   # green right-chest
    (11,16,16,22, P3),   # red left-belly
    (16,16,22,22, P4),   # navy right-belly
    (10,12,12,20, P5),   # left arm panel
    (21,12,23,20, P5),   # right arm panel
]

def draw_hair_front(d):
    d.rectangle([12, 1, 20, 5], fill=BN)
    d.point((11, 4), fill=BN)
    d.point((21, 4), fill=BN)

def draw_hair_back(d):
    d.rectangle([12, 1, 20, 6], fill=BN)
    d.point((11, 5), fill=BN); d.point((21, 5), fill=BN)

def draw_hair_side(d):
    d.rectangle([15, 1, 22, 6], fill=BN)
    d.point((14, 5), fill=BN)

def draw_face_front(d, expr="neutral"):
    d.rectangle([12, 4, 20, 11], fill=SK)
    d.rectangle([13, 7, 15,  9], fill=BL)    # left eye
    d.rectangle([17, 7, 19,  9], fill=BL)    # right eye
    d.point((14, 8), fill=SK); d.point((18, 8), fill=SK)
    if   expr == "sing":   d.arc([12,9,20,13], 0, 180, fill=BL)
    elif expr == "hype":   d.arc([12,9,20,12], 0, 180, fill=BL); d.line([(13,6),(15,7)], fill=BL)
    elif expr == "hurt":   d.line([(13,9),(19,9)], fill=BL)
    elif expr == "listen": d.rectangle([14,9,18,11], fill=BL)

def draw_face_side(d):
    d.rectangle([14, 4, 22, 11], fill=SK)
    d.rectangle([19, 7, 21,  9], fill=BL)
    d.point((20, 8), fill=SK)

def draw_torso_front(d):
    d.rectangle([11,11,22,22], fill=P4)   # base (dark navy)
    for x0,y0,x1,y1,col in _PATCHES_FRONT:
        d.rectangle([x0,y0,x1,y1], fill=col)
    # Patch seam lines
    d.line([(16,11),(16,22)], fill=BL)
    d.line([(11,16),(22,16)], fill=BL)

def draw_torso_back(d):
    d.rectangle([11,11,22,22], fill=P4)
    d.rectangle([11,11,17,16], fill=P2)
    d.rectangle([17,11,22,16], fill=P1)
    d.rectangle([11,16,17,22], fill=P5)
    d.rectangle([17,16,22,22], fill=P3)
    d.line([(17,11),(17,22)], fill=BL); d.line([(11,16),(22,16)], fill=BL)

def draw_torso_side(d):
    d.rectangle([14,11,22,22], fill=P4)
    d.rectangle([14,11,18,16], fill=P1)
    d.rectangle([14,16,18,22], fill=P3)
    d.line([(14,16),(22,16)], fill=BL)

def draw_keytar_front(d, raise_arm=False):
    """Keytar slung diagonally across body — front view."""
    ky_y = 10 if raise_arm else 13
    # Body
    d.rectangle([8, ky_y, 23, ky_y+5], fill=KY)
    # Keys strip
    d.rectangle([9, ky_y+3, 22, ky_y+5], fill=CY)
    # Strap
    d.line([(9, ky_y),(22, ky_y+6)], fill=DK)

def draw_keytar_side(d):
    d.rectangle([17,12,26,17], fill=KY)
    d.rectangle([18,15,26,17], fill=CY)

def draw_arms_front(d, ldy=0, rdy=0, wide=False, raise_left=False, raise_right=False):
    if wide:
        d.rectangle([ 5,12,11,18], fill=SK)
        d.rectangle([21,12,27,18], fill=SK)
    elif raise_left and raise_right:
        d.rectangle([ 8, 9,12,20], fill=SK)
        d.rectangle([20, 9,24,20], fill=SK)
    elif raise_left:
        d.rectangle([ 8, 9,12,20], fill=SK)
        d.rectangle([22,11+rdy,26,21+rdy], fill=SK)
    elif raise_right:
        d.rectangle([ 8,11+ldy,12,21+ldy], fill=SK)
        d.rectangle([20, 9,24,20], fill=SK)
    else:
        d.rectangle([ 8,11+ldy,12,21+ldy], fill=SK)
        d.rectangle([20,11+rdy,24,21+rdy], fill=SK)

def draw_arm_side(d, arm_dy=0):
    d.rectangle([22,11+arm_dy,26,21+arm_dy], fill=SK)

def draw_legs_front(d, phase=0, run=False, crouch=False):
    if crouch:
        d.rectangle([12,22,16,27], fill=DK)
        d.rectangle([16,22,20,27], fill=DK)
        d.rectangle([11,27,17,31], fill=BN)
        d.rectangle([16,27,21,31], fill=BN)
        return
    s = 3 if run else 2
    if   phase == 0: lx,rx,ld,rd = 12,17, 0, 0
    elif phase == 1: lx,rx,ld,rd = 11,18, s, 0
    elif phase == 2: lx,rx,ld,rd = 13,16, 0, s
    else:            lx,rx,ld,rd = 11,18, 0, 0
    d.rectangle([lx,   22, lx+3, 26+ld], fill=DK)
    d.rectangle([lx-1, 26+ld, lx+4, 31], fill=BN)
    d.rectangle([rx,   22, rx+3, 26+rd], fill=DK)
    d.rectangle([rx-1, 26+rd, rx+4, 31], fill=BN)

def draw_legs_side(d, phase=0, run=False):
    s = 3 if run else 2
    if phase in (0,2):
        d.rectangle([14,22,18,27], fill=DK)
        d.rectangle([17,22,21,27], fill=DK)
        d.rectangle([13,26,19,31], fill=BN)
        d.rectangle([16,26,22,30], fill=BN)
    elif phase == 1:
        d.rectangle([17,22,21,26+s], fill=DK)
        d.rectangle([13,22,17,26],   fill=DK)
        d.rectangle([16,25+s,23,31], fill=BN)
        d.rectangle([12,25,18,29],   fill=BN)
    else:
        d.rectangle([13,22,17,26+s], fill=DK)
        d.rectangle([17,22,21,26],   fill=DK)
        d.rectangle([12,25+s,18,31], fill=BN)
        d.rectangle([16,25,23,29],   fill=BN)

# ── Frame assemblers ──────────────────────────────────────────────────────────

def f_front(leg=0, ldy=0, rdy=0, expr="neutral", wide=False,
            raise_left=False, raise_right=False, run=False, crouch=False,
            keytar=True):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs_front(d, phase=leg, run=run, crouch=crouch)
    draw_arms_front(d, ldy, rdy, wide=wide, raise_left=raise_left, raise_right=raise_right)
    draw_torso_front(d)
    if keytar: draw_keytar_front(d)
    draw_hair_front(d)
    draw_face_front(d, expr=expr)
    return add_outline(im)

def f_back(leg=0, ldy=0, rdy=0, run=False):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs_front(d, phase=leg, run=run)
    draw_arms_front(d, ldy, rdy)
    draw_torso_back(d)
    draw_keytar_front(d)
    draw_hair_back(d)
    return add_outline(im)

def f_side(leg=0, arm_dy=0, run=False, keytar=True):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs_side(d, phase=leg, run=run)
    draw_torso_side(d)
    draw_arm_side(d, arm_dy)
    if keytar: draw_keytar_side(d)
    draw_hair_side(d)
    draw_face_side(d)
    return add_outline(im)

def f_closeup(expr="neutral"):
    im = tile(); d = ImageDraw.Draw(im)
    d.rectangle([ 8, 0, 24, 5], fill=BN)
    d.point((7,4), fill=BN); d.point((25,4), fill=BN)
    d.rectangle([ 8, 4, 24, 22], fill=SK)
    d.rectangle([ 9,11,14, 15], fill=BL)
    d.rectangle([18,11,23, 15], fill=BL)
    d.point((11,13), fill=SK); d.point((21,13), fill=SK)
    if   expr == "sing":  d.arc([10,17,22,22], 0, 180, fill=BL)
    elif expr == "hype":  d.arc([10,17,22,21], 0, 180, fill=BL); d.line([(11,10),(14,12)], fill=BL)
    elif expr == "talk":  d.line([(11,18),(21,18)], fill=BL)
    d.rectangle([4, 22, 28, 31], fill=P4)
    d.rectangle([4, 22, 16, 27], fill=P1)
    d.rectangle([16,22, 28, 27], fill=P2)
    return add_outline(im)

# ── Walk cycle ────────────────────────────────────────────────────────────────
_WL = [0,1,3,2,0,1,3,2]
_WA = [0,-1,0,1,0,-1,0,1]

# ── Animations ────────────────────────────────────────────────────────────────

def anim_idle():
    return [f_front(keytar=True) for _ in range(6)]

def anim_walk_down():
    return [f_front(leg=_WL[i], ldy=_WA[i], rdy=-_WA[i]) for i in range(8)]

def anim_walk_up():
    return [f_back(leg=_WL[i], ldy=_WA[i], rdy=-_WA[i]) for i in range(8)]

def anim_walk_right():
    return [f_side(leg=_WL[i], arm_dy=_WA[i]) for i in range(8)]

def anim_run_down():
    return [f_front(leg=_WL[i], ldy=_WA[i]*2, rdy=-_WA[i]*2, run=True) for i in range(8)]

def anim_run_up():
    return [f_back(leg=_WL[i], ldy=_WA[i]*2, rdy=-_WA[i]*2, run=True) for i in range(8)]

def anim_run_right():
    return [f_side(leg=_WL[i], arm_dy=_WA[i]*2, run=True) for i in range(8)]

def anim_attack():
    # Keytar swing — wide sweep
    return [
        f_front(),
        f_side(),
        f_front(raise_left=True, expr="hype"),
        f_front(wide=True, expr="hype"),
        f_front(raise_right=True, expr="hype"),
        f_front(),
    ]

def anim_special():
    # Perfect pitch listen — hand to ear, eyes closed, 8 frames
    exprs = ["listen","listen","listen","listen","sing","sing","neutral","neutral"]
    raise_l = [True,True,True,True,False,False,False,False]
    return [f_front(raise_left=raise_l[i], expr=exprs[i]) for i in range(8)]

def anim_perfect_pitch():
    # Row 9 — intense listening then eureka reveal (6 frames)
    exprs = ["listen","listen","listen","listen","hype","sing"]
    raise_l = [True,True,True,True,False,False]
    return [f_front(raise_left=raise_l[i], expr=exprs[i]) for i in range(6)]

def anim_talk():
    exprs = ["neutral","sing","hype","sing","neutral","neutral"]
    wide  = [False, True, False, True, False, False]
    return [f_front(wide=wide[i], expr=exprs[i]) for i in range(6)]

def anim_talk_closeup():
    exprs = ["neutral","talk","hype","sing","hype","talk","neutral","neutral"]
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
            d.rectangle([3,12,10,17], fill=P4)
            d.rectangle([4,16,26,21], fill=P4)
            d.rectangle([4,16,11,21], fill=SK)
            d.rectangle([3,20,22,24], fill=DK)
            d.rectangle([21,20,27,24], fill=BN)
            frames.append(add_outline(im))
        else:
            im = tile(); d = ImageDraw.Draw(im)
            fy = min(11+(i-3)*3, 18)
            d.rectangle([1,fy,   8,fy+3], fill=BN)
            d.rectangle([2,fy+3,28,fy+8], fill=P4)
            d.rectangle([2,fy+3, 8,fy+8], fill=SK)
            # keytar lying beside
            d.rectangle([16,fy+5,26,fy+8], fill=KY)
            frames.append(add_outline(im))
    return frames

def anim_revive():
    down = anim_down()
    return [down[9], down[7], down[5], down[3],
            f_side(leg=0, arm_dy=-2), f_side(leg=1), f_front(), f_front()]

def anim_dash():
    frames = []
    for i in range(5):
        im = tile(); d = ImageDraw.Draw(im)
        lean = i
        draw_legs_side(d, phase=1, run=True)
        d.rectangle([13+lean,11,22+lean,22], fill=P4)
        d.rectangle([13+lean,11,17+lean,16], fill=P1)
        draw_arm_side(d, arm_dy=-3)
        draw_keytar_side(d)
        draw_hair_side(d)
        d.rectangle([14+lean,4,22+lean,11], fill=SK)
        d.rectangle([19+lean,7,21+lean, 9], fill=BL)
        frames.append(add_outline(im))
    return frames

def anim_perform():
    # Row 16 — theatrical crowd-address performance (8 frames)
    exprs = ["neutral","hype","sing","hype","sing","hype","sing","neutral"]
    wide  = [False, True, False, True, False, True, False, False]
    return [f_front(wide=wide[i], expr=exprs[i]) for i in range(8)]

ANIMS = [
    ("idle",          anim_idle),
    ("walk_down",     anim_walk_down),
    ("walk_up",       anim_walk_up),
    ("walk_right",    anim_walk_right),
    ("run_down",      anim_run_down),
    ("run_up",        anim_run_up),
    ("run_right",     anim_run_right),
    ("attack",        anim_attack),
    ("special",       anim_special),
    ("perfect_pitch", anim_perfect_pitch),
    ("talk",          anim_talk),
    ("talk_closeup",  anim_talk_closeup),
    ("hurt",          anim_hurt),
    ("down",          anim_down),
    ("revive",        anim_revive),
    ("dash",          anim_dash),
    ("perform",       anim_perform),
]

if __name__ == "__main__":
    sheet = Image.new('RGBA', (T*10, T*len(ANIMS)), (0,0,0,0))
    for row, (name, fn) in enumerate(ANIMS):
        for col, frame in enumerate(fn()):
            sheet.paste(frame, (col*T, row*T))
    out = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                       "assets", "art", "sprites", "ben.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(f"Saved 320x{T*len(ANIMS)} -> {out}")
    for n, f in ANIMS: print(f"  {n:<16} {len(f())} frames")
