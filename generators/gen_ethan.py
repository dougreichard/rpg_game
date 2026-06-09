#!/usr/bin/env python3
"""
Ethan sprite sheet — PIL fallback.
320 × 544 px RGBA  (17 rows × 10 cols × 32×32).

Ethan: teenage boy, wiry/lean build (thinnest character). Grey hoodie,
dark navy cargo pants, sneakers, short dark hair. Rectangular dark-blue
AR glasses. Cyan hacking device in hand. Fastest hands, tech-focused.
"""
from PIL import Image, ImageDraw
import os

# ── Palette ───────────────────────────────────────────────────────────────────
BL = (  0,   0,   0, 255)   # black    outline
GY = (155, 155, 155, 255)   # grey     hoodie
DGY= ( 90,  90,  90, 255)   # dark grey hoodie shadow
NV = ( 10,  30,  80, 255)   # navy     cargo pants
SN = (200, 190, 180, 255)   # sneaker  off-white
CY = (  0, 195, 199, 255)   # cyan     device / glasses glow
SK = (255, 204, 170, 255)   # skin
GB = ( 20,  60, 120, 255)   # glasses  dark-blue frames
DK = ( 55,  50,  35, 255)   # dark     shadow / boot sole
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
# Head:  y 2–11 (lean, narrow)
# Torso: y 11–22 (hoodie — narrow 12–20)
# Legs:  y 22–31 (navy cargo pants + sneakers)

def draw_hair_front(d):
    d.rectangle([13, 1, 19, 5], fill=DGY)  # short dark hair

def draw_hair_back(d):
    d.rectangle([13, 1, 19, 5], fill=DGY)

def draw_hair_side(d):
    d.rectangle([14, 1, 21, 5], fill=DGY)

def draw_face_front(d, expr="neutral"):
    d.rectangle([13, 4, 19, 11], fill=SK)
    # AR glasses — rectangular dark-blue frames with cyan inner
    d.rectangle([13, 6, 16,  9], fill=GB)
    d.rectangle([14, 7, 15,  8], fill=CY)   # left lens glow
    d.rectangle([16, 6, 19,  9], fill=GB)
    d.rectangle([17, 7, 18,  8], fill=CY)   # right lens glow
    if   expr == "focus":  d.line([(14,5),(18,5)], fill=DGY)
    elif expr == "grin":   d.arc([13,9,19,12], 0, 180, fill=BL)
    elif expr == "hurt":   d.line([(14,9),(18,9)], fill=BL)
    elif expr == "hack":   d.rectangle([14,5,18,6], fill=CY)  # scanning line

def draw_face_side(d):
    d.rectangle([14, 4, 22, 11], fill=SK)
    d.rectangle([17, 6, 21,  9], fill=GB)
    d.rectangle([18, 7, 20,  8], fill=CY)

def draw_torso_front(d):
    d.rectangle([12,11,20,22], fill=GY)
    d.line([(12,11),(12,22)], fill=DGY)
    d.line([(20,11),(20,22)], fill=DGY)
    # Hoodie front pocket
    d.rectangle([14,18,18,21], fill=DGY)

def draw_torso_back(d):
    d.rectangle([12,11,20,22], fill=GY)
    d.line([(12,11),(12,22)], fill=DGY)
    d.line([(20,11),(20,22)], fill=DGY)

def draw_torso_side(d):
    d.rectangle([13,11,21,22], fill=GY)
    d.line([(13,11),(13,22)], fill=DGY)

def draw_device(d, raised=False):
    """Cyan hacking device in right hand."""
    dy = -3 if raised else 0
    d.rectangle([19,16+dy,23,20+dy], fill=CY)
    d.point((20,17+dy), fill=BL)
    d.point((22,18+dy), fill=BL)

def draw_arms_front(d, ldy=0, rdy=0, wide=False, raise_right=False):
    if wide:
        d.rectangle([ 8,12,12,19], fill=SK)
        d.rectangle([20,12,24,19], fill=SK)
    elif raise_right:
        d.rectangle([ 9,11+ldy,13,21+ldy], fill=SK)
        d.rectangle([19, 8,23,18], fill=SK)
    else:
        d.rectangle([ 9,11+ldy,13,21+ldy], fill=SK)
        d.rectangle([19,11+rdy,23,21+rdy], fill=SK)

def draw_arm_side(d, arm_dy=0, raise_for_device=False):
    if raise_for_device:
        d.rectangle([20, 8,24,19], fill=SK)
    else:
        d.rectangle([20,11+arm_dy,24,21+arm_dy], fill=SK)

def draw_legs_front(d, phase=0, run=False, crouch=False):
    if crouch:
        d.rectangle([13,22,16,27], fill=NV)
        d.rectangle([17,22,20,27], fill=NV)
        d.rectangle([12,27,18,31], fill=SN)
        d.rectangle([17,27,21,31], fill=SN)
        return
    s = 3 if run else 2
    if   phase == 0: lx,rx,ld,rd = 13,17, 0, 0
    elif phase == 1: lx,rx,ld,rd = 12,18, s, 0
    elif phase == 2: lx,rx,ld,rd = 14,16, 0, s
    else:            lx,rx,ld,rd = 12,18, 0, 0
    d.rectangle([lx,   22, lx+3, 26+ld], fill=NV)
    d.rectangle([lx-1, 26+ld, lx+4, 31], fill=SN)
    d.rectangle([rx,   22, rx+3, 26+rd], fill=NV)
    d.rectangle([rx-1, 26+rd, rx+4, 31], fill=SN)

def draw_legs_side(d, phase=0, run=False, crouch=False):
    s = 3 if run else 2
    if crouch:
        d.rectangle([14,22,17,26], fill=NV)
        d.rectangle([17,22,21,26], fill=DGY)
        d.rectangle([13,26,19,31], fill=SN)
        d.rectangle([17,26,22,30], fill=NV)
        return
    if phase in (0,2):
        d.rectangle([14,22,18,27], fill=NV)
        d.rectangle([17,22,21,27], fill=NV)
        d.rectangle([13,26,19,31], fill=SN)
        d.rectangle([16,26,22,30], fill=SN)
    elif phase == 1:
        d.rectangle([17,22,21,26+s], fill=NV)
        d.rectangle([13,22,17,26],   fill=NV)
        d.rectangle([16,25+s,22,31], fill=SN)
        d.rectangle([12,25,18,29],   fill=SN)
    else:
        d.rectangle([13,22,17,26+s], fill=NV)
        d.rectangle([17,22,21,26],   fill=NV)
        d.rectangle([12,25+s,18,31], fill=SN)
        d.rectangle([16,25,22,29],   fill=SN)

# ── Frame assemblers ──────────────────────────────────────────────────────────

def f_front(leg=0, ldy=0, rdy=0, expr="neutral", wide=False,
            raise_right=False, run=False, crouch=False, device=True):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs_front(d, phase=leg, run=run, crouch=crouch)
    draw_arms_front(d, ldy, rdy, wide=wide, raise_right=raise_right)
    draw_torso_front(d)
    if device: draw_device(d, raised=raise_right)
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

def f_side(leg=0, arm_dy=0, run=False, crouch=False, device=False, device_raised=False):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs_side(d, phase=leg, run=run, crouch=crouch)
    draw_torso_side(d)
    draw_arm_side(d, arm_dy, raise_for_device=device_raised)
    if device or device_raised:
        dy = -3 if device_raised else 0
        d.rectangle([20,16+dy,24,20+dy], fill=CY)
        d.point((21,17+dy), fill=BL)
    draw_hair_side(d)
    draw_face_side(d)
    return add_outline(im)

def f_closeup(expr="neutral"):
    im = tile(); d = ImageDraw.Draw(im)
    d.rectangle([8, 0, 24, 5], fill=DGY)
    d.rectangle([8, 4, 24,22], fill=SK)
    d.rectangle([8, 9,15,14],  fill=GB)
    d.rectangle([9,10,14,13],  fill=CY)
    d.rectangle([15,9,23,14],  fill=GB)
    d.rectangle([16,10,22,13], fill=CY)
    if   expr == "focus": d.line([(10,8),(22,8)], fill=DGY)
    elif expr == "grin":  d.arc([10,17,22,22], 0,180, fill=BL)
    elif expr == "hack":  d.rectangle([10,7,22,8], fill=CY)
    elif expr == "talk":  d.line([(11,18),(21,18)], fill=BL)
    d.rectangle([4,22,28,31], fill=GY)
    d.rectangle([4,22,16,27], fill=DGY)
    return add_outline(im)

# ── Walk cycle ────────────────────────────────────────────────────────────────
_WL = [0,1,3,2,0,1,3,2]
_WA = [0,-1,0,1,0,-1,0,1]

# ── Animations ────────────────────────────────────────────────────────────────

def anim_idle():
    return [f_front(device=True) for _ in range(6)]

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
    # Quick device jab / electric burst
    return [
        f_front(),
        f_side(),
        f_side(device_raised=True),
        f_side(device_raised=True),
        f_side(),
        f_front(),
    ]

def anim_special():
    # Hack panel — lean in with device raised, scanning motion
    exprs = ["focus","focus","hack","hack","hack","focus","grin","neutral"]
    raise_r = [True,True,True,True,True,True,False,False]
    return [f_front(raise_right=raise_r[i], expr=exprs[i]) for i in range(8)]

def anim_panel_interact():
    # Row 9 — panel interact (6 frames) — crouch + device extended
    return [
        f_front(crouch=True, expr="focus"),
        f_front(crouch=True, raise_right=True, expr="hack"),
        f_front(crouch=True, raise_right=True, expr="hack"),
        f_front(crouch=True, raise_right=True, expr="focus"),
        f_front(crouch=True, expr="grin"),
        f_front(expr="grin"),
    ]

def anim_talk():
    exprs = ["neutral","talk","focus","grin","neutral","neutral"]
    raise_r = [False, True, False, False, False, False]
    return [f_front(raise_right=raise_r[i], expr=exprs[i]) for i in range(6)]

def anim_talk_closeup():
    exprs = ["neutral","focus","hack","grin","focus","talk","neutral","neutral"]
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
            d.rectangle([3,12,10,17], fill=GY)
            d.rectangle([4,16,26,21], fill=GY)
            d.rectangle([4,16,11,21], fill=SK)
            d.rectangle([3,20,22,24], fill=NV)
            d.rectangle([21,20,27,24], fill=SN)
            d.rectangle([20,17,24,20], fill=CY)  # device on floor
            frames.append(add_outline(im))
        else:
            im = tile(); d = ImageDraw.Draw(im)
            fy = min(11+(i-3)*3, 18)
            d.rectangle([1,fy,  8,fy+3], fill=DGY)
            d.rectangle([2,fy+3,28,fy+8], fill=GY)
            d.rectangle([2,fy+3, 8,fy+8], fill=SK)
            d.rectangle([16,fy+4,22,fy+7], fill=CY)
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
        d.rectangle([13+lean,11,21+lean,22], fill=GY)
        d.line([(13+lean,11),(13+lean,22)], fill=DGY)
        draw_arm_side(d, arm_dy=-2)
        d.rectangle([20+lean,12,24+lean,17], fill=CY)
        draw_hair_side(d)
        d.rectangle([14+lean,4,22+lean,11], fill=SK)
        d.rectangle([17+lean,6,21+lean, 9], fill=GB)
        d.rectangle([18+lean,7,20+lean, 8], fill=CY)
        frames.append(add_outline(im))
    return frames

def anim_lizard_summon():
    # Row 16 — lizard companion summon (6 frames) — crouch, extend device up
    exprs = ["focus","focus","hack","hack","grin","neutral"]
    raise_r = [False, True, True, True, False, False]
    return [f_front(crouch=(i<3), raise_right=raise_r[i], expr=exprs[i]) for i in range(6)]

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
    ("panel_interact",anim_panel_interact),
    ("talk",          anim_talk),
    ("talk_closeup",  anim_talk_closeup),
    ("hurt",          anim_hurt),
    ("down",          anim_down),
    ("revive",        anim_revive),
    ("dash",          anim_dash),
    ("lizard_summon", anim_lizard_summon),
]

if __name__ == "__main__":
    sheet = Image.new('RGBA', (T*10, T*len(ANIMS)), (0,0,0,0))
    for row, (name, fn) in enumerate(ANIMS):
        for col, frame in enumerate(fn()):
            sheet.paste(frame, (col*T, row*T))
    out = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                       "assets", "art", "sprites", "ethan.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(f"Saved 320x{T*len(ANIMS)} -> {out}")
    for n, f in ANIMS: print(f"  {n:<16} {len(f())} frames")
