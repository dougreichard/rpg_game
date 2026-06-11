#!/usr/bin/env python3
"""
Ethan sprite sheet — PIL procedural, 64x64 spec.
640 x 1088 px RGBA  (17 rows x 10 cols x 64x64).

Extended-palette / "Stranger Things: 1984"-style rebuild (DESIGN.md SS2.0,
sprites.md "Ethan"). Same animation structure and frame counts as the
original 32x32 generator, doubled onto the 64x64 canvas, plus:
  - extended-palette grey hoodie (#A8A8B8) w/ highlight + pocket shadow,
    dark-navy cargo pants (#2F4A99) w/ highlight, off-white sneakers w/
    sole shadow, dark hair (#18141A), warm skin w/ blush
  - dark-blue AR-glasses frames with cyan (#5ED6FF) lens glow + a brighter
    glow accent
  - device screen now pulses brighter cyan every 3rd idle frame (sprites.md:
    "screen pulses cyan every 3 frames") and goes dark on the final Down
    frame ("device screen goes dark at final frame")
  - Lizard summon (row 16) gains a small green lizard companion drawn on
    Ethan's arm for its final 3 frames ("small green lizard appears on arm
    (4-6)") — a detail v1 didn't have room for at 32x32

Proportions: head ~16x14 (lean/narrow), torso ~16x22, legs — same grid as
Quinn/Erin/Evan/Ben, doubled from the v1 32x32 coordinates.
"""
from PIL import Image, ImageDraw
import os

# -- Extended palette (DESIGN.md SS2.0 / sprites.md "Ethan -> Palette slots") --
INK          = ( 26,  26,  34, 255)  # ink-black: outline
HOODIE       = (168, 168, 184, 255)  # #A8A8B8 grey hoodie
HOODIE_HI    = (200, 200, 214, 255)  # hoodie highlight
HOODIE_SH    = (130, 130, 148, 255)  # hoodie shadow / pocket / hood
NAVY         = ( 47,  74, 153, 255)  # #2F4A99 navy cargo pants
NAVY_HI      = ( 75, 102, 181, 255)  # cargo highlight
SNEAKER      = (224, 224, 224, 255)  # off-white sneakers
SNEAKER_SH   = (180, 180, 190, 255)  # sneaker sole shadow
SKIN         = (242, 196, 155, 255)  # warm skin
SKIN_SH      = (217, 168, 124, 255)  # skin shadow / blush
HAIR         = ( 24,  20,  26, 255)  # #18141A dark hair
HAIR_HI      = ( 50,  44,  56, 255)  # hair highlight
GLASSES      = ( 32,  60, 120, 255)  # dark-blue AR-glasses frames
CYAN         = ( 94, 214, 255, 255)  # #5ED6FF device glow / glasses tint
CYAN_HI      = (180, 240, 255, 255)  # bright cyan glow / pulse
LIZARD       = ( 92, 168,  92, 255)  # lizard companion green
LIZARD_SH    = ( 64, 130,  68, 255)  # lizard shadow / eye spot
TR           = (  0,   0,   0,   0)

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
# Head:  y 4-22 (lean, narrow)
# Torso: y 22-44 (hoodie)
# Legs:  y 44-62 (navy cargo + sneakers)

def draw_hair_front(d):
    d.rectangle([26, 2, 38, 10], fill=HAIR)
    d.line([(28, 3), (36, 3)], fill=HAIR_HI)

def draw_hair_back(d):
    d.rectangle([26, 2, 38, 10], fill=HAIR)
    d.line([(28, 3), (36, 3)], fill=HAIR_HI)

def draw_hair_side(d):
    d.rectangle([28, 2, 42, 10], fill=HAIR)
    d.line([(30, 3), (40, 3)], fill=HAIR_HI)

def draw_face_front(d, expr="neutral"):
    d.rectangle([26, 8, 38, 22], fill=SKIN)
    d.rectangle([28, 20, 36, 22], fill=SKIN_SH)          # chin shadow
    # AR glasses — rectangular dark-blue frames with cyan inner glow
    d.rectangle([26, 12, 32, 18], fill=GLASSES)
    d.rectangle([28, 14, 30, 16], fill=CYAN)
    d.rectangle([32, 12, 38, 18], fill=GLASSES)
    d.rectangle([34, 14, 36, 16], fill=CYAN)
    if   expr == "focus":
        d.line([(28, 10), (36, 10)], fill=HAIR_HI, width=2)
    elif expr == "grin":
        d.arc([26, 18, 38, 24], 0, 180, fill=INK, width=2)
    elif expr == "hurt":
        d.line([(28, 18), (36, 18)], fill=INK, width=2)
    elif expr == "hack":
        d.rectangle([28, 10, 36, 12], fill=CYAN_HI)      # scanning line

def draw_face_side(d):
    d.rectangle([28, 8, 44, 22], fill=SKIN)
    d.rectangle([34, 12, 42, 18], fill=GLASSES)
    d.rectangle([36, 14, 40, 16], fill=CYAN)
    d.ellipse([30, 18, 36, 22], fill=SKIN_SH)            # chin shadow

def draw_torso_front(d):
    d.rectangle([24, 22, 40, 44], fill=HOODIE)
    d.line([(24, 22), (24, 44)], fill=HOODIE_SH, width=2)
    d.line([(40, 22), (40, 44)], fill=HOODIE_SH, width=2)
    d.rectangle([26, 24, 38, 28], fill=HOODIE_HI)        # shoulder highlight
    d.rectangle([28, 36, 36, 42], fill=HOODIE_SH)        # front pocket

def draw_torso_back(d):
    d.rectangle([24, 22, 40, 44], fill=HOODIE)
    d.line([(24, 22), (24, 44)], fill=HOODIE_SH, width=2)
    d.line([(40, 22), (40, 44)], fill=HOODIE_SH, width=2)
    d.rectangle([28, 22, 36, 26], fill=HOODIE_SH)        # hood

def draw_torso_side(d):
    d.rectangle([26, 22, 42, 44], fill=HOODIE)
    d.line([(26, 22), (26, 44)], fill=HOODIE_SH, width=2)
    d.rectangle([28, 24, 38, 28], fill=HOODIE_HI)

def draw_device(d, raised=False, pulse=False):
    """Cyan hacking device in right hand."""
    dy = -6 if raised else 0
    glow = CYAN_HI if pulse else CYAN
    d.rectangle([38, 32 + dy, 46, 40 + dy], fill=glow)
    d.rectangle([39, 33 + dy, 45, 36 + dy], fill=CYAN_HI if not pulse else CYAN)
    d.rectangle([40, 37 + dy, 44, 39 + dy], fill=INK)

def draw_lizard_companion(d):
    """Small green lizard perched on Ethan's arm (Lizard summon row)."""
    d.ellipse([42, 26, 54, 34], fill=LIZARD)
    d.ellipse([46, 28, 50, 32], fill=LIZARD_SH)
    d.line([(54, 30), (60, 26)], fill=LIZARD, width=2)   # tail

def draw_arms_front(d, ldy=0, rdy=0, wide=False, raise_right=False):
    if wide:
        d.rectangle([16, 24, 24, 38], fill=SKIN)
        d.rectangle([40, 24, 48, 38], fill=SKIN)
        d.rectangle([16, 34, 24, 38], fill=SKIN_SH)
        d.rectangle([40, 34, 48, 38], fill=SKIN_SH)
    elif raise_right:
        ly0 = 22 + ldy * 2; ly1 = 42 + ldy * 2
        d.rectangle([18, ly0, 26, ly1], fill=SKIN)
        d.rectangle([18, ly1 - 4, 26, ly1], fill=SKIN_SH)
        d.rectangle([38, 16, 46, 36], fill=SKIN)
        d.rectangle([38, 16, 46, 20], fill=SKIN_SH)
    else:
        ly0 = 22 + ldy * 2; ly1 = 42 + ldy * 2
        ry0 = 22 + rdy * 2; ry1 = 42 + rdy * 2
        d.rectangle([18, ly0, 26, ly1], fill=SKIN)
        d.rectangle([38, ry0, 46, ry1], fill=SKIN)
        d.rectangle([18, ly1 - 4, 26, ly1], fill=SKIN_SH)
        d.rectangle([38, ry1 - 4, 46, ry1], fill=SKIN_SH)

def draw_arm_side(d, arm_dy=0, raise_for_device=False):
    if raise_for_device:
        d.rectangle([40, 16, 48, 38], fill=SKIN)
        d.rectangle([40, 16, 48, 20], fill=SKIN_SH)
    else:
        y0 = 22 + arm_dy * 2; y1 = 42 + arm_dy * 2
        d.rectangle([40, y0, 48, y1], fill=SKIN)
        d.rectangle([40, y1 - 4, 48, y1], fill=SKIN_SH)

def draw_legs_front(d, phase=0, run=False, crouch=False):
    if crouch:
        d.rectangle([26, 44, 32, 54], fill=NAVY)
        d.rectangle([34, 44, 40, 54], fill=NAVY)
        d.rectangle([24, 54, 36, 62], fill=SNEAKER)
        d.rectangle([34, 54, 42, 62], fill=SNEAKER)
        d.rectangle([24, 54, 36, 56], fill=SNEAKER_SH)
        d.rectangle([34, 54, 42, 56], fill=SNEAKER_SH)
        return
    s = 6 if run else 4
    if   phase == 0: lx, rx, ld, rd = 26, 34, 0, 0
    elif phase == 1: lx, rx, ld, rd = 24, 36, s, 0
    elif phase == 2: lx, rx, ld, rd = 28, 32, 0, s
    else:            lx, rx, ld, rd = 24, 36, 0, 0
    d.rectangle([lx, 44, lx + 6, 52 + ld], fill=NAVY)
    d.rectangle([lx, 44, lx + 2, 52 + ld], fill=NAVY_HI)
    d.rectangle([lx - 2, 52 + ld, lx + 8, 62], fill=SNEAKER)
    d.rectangle([lx - 2, 58, lx + 8, 62], fill=SNEAKER_SH)
    d.rectangle([rx, 44, rx + 6, 52 + rd], fill=NAVY)
    d.rectangle([rx, 44, rx + 2, 52 + rd], fill=NAVY_HI)
    d.rectangle([rx - 2, 52 + rd, rx + 8, 62], fill=SNEAKER)
    d.rectangle([rx - 2, 58, rx + 8, 62], fill=SNEAKER_SH)

def draw_legs_side(d, phase=0, run=False, crouch=False):
    s = 6 if run else 4
    if crouch:
        d.rectangle([28, 44, 34, 52], fill=NAVY)
        d.rectangle([34, 44, 42, 52], fill=HOODIE_SH)
        d.rectangle([26, 52, 38, 62], fill=SNEAKER)
        d.rectangle([34, 52, 44, 60], fill=NAVY)
        return
    if phase in (0, 2):
        d.rectangle([28, 44, 36, 54], fill=NAVY)
        d.rectangle([34, 44, 42, 54], fill=NAVY)
        d.rectangle([26, 52, 38, 62], fill=SNEAKER)
        d.rectangle([32, 52, 44, 60], fill=SNEAKER)
        d.rectangle([26, 58, 38, 62], fill=SNEAKER_SH)
    elif phase == 1:
        d.rectangle([34, 44, 42, 52 + s], fill=NAVY)
        d.rectangle([26, 44, 34, 52],     fill=NAVY)
        d.rectangle([32, 50 + s, 46, 62], fill=SNEAKER)
        d.rectangle([24, 50, 36, 58],     fill=SNEAKER)
        d.rectangle([32, 56 + s, 46, 62], fill=SNEAKER_SH)
    else:
        d.rectangle([26, 44, 34, 52 + s], fill=NAVY)
        d.rectangle([34, 44, 42, 52],     fill=NAVY)
        d.rectangle([24, 50 + s, 36, 62], fill=SNEAKER)
        d.rectangle([32, 50, 46, 58],     fill=SNEAKER)
        d.rectangle([24, 56 + s, 36, 62], fill=SNEAKER_SH)

# -- Frame assemblers ------------------------------------------------------------

def f_front(leg=0, ldy=0, rdy=0, expr="neutral", wide=False,
            raise_right=False, run=False, crouch=False, device=True,
            pulse=False, show_lizard=False):
    im = tile(); d = ImageDraw.Draw(im)
    draw_legs_front(d, phase=leg, run=run, crouch=crouch)
    draw_arms_front(d, ldy, rdy, wide=wide, raise_right=raise_right)
    draw_torso_front(d)
    if device:
        draw_device(d, raised=raise_right, pulse=pulse)
    if show_lizard:
        draw_lizard_companion(d)
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
        dy = -6 if device_raised else 0
        d.rectangle([40, 32 + dy, 48, 40 + dy], fill=CYAN)
        d.rectangle([41, 33 + dy, 47, 36 + dy], fill=CYAN_HI)
        d.rectangle([42, 37 + dy, 46, 39 + dy], fill=INK)
    draw_hair_side(d)
    draw_face_side(d)
    return add_outline(im)

def f_closeup(expr="neutral"):
    im = tile(); d = ImageDraw.Draw(im)
    d.rectangle([16, 0, 48, 10], fill=HAIR)
    d.line([(20, 2), (44, 2)], fill=HAIR_HI)
    d.rectangle([16, 8, 48, 44], fill=SKIN)
    d.rectangle([16, 18, 30, 28], fill=GLASSES)
    d.rectangle([18, 20, 28, 26], fill=CYAN)
    d.rectangle([30, 18, 46, 28], fill=GLASSES)
    d.rectangle([32, 20, 44, 26], fill=CYAN)
    if   expr == "focus":
        d.line([(20, 16), (44, 16)], fill=HAIR_HI, width=2)
    elif expr == "grin":
        d.arc([20, 34, 44, 44], 0, 180, fill=INK, width=2)
    elif expr == "hack":
        d.rectangle([20, 14, 44, 16], fill=CYAN_HI)
    elif expr == "talk":
        d.line([(22, 36), (42, 36)], fill=INK, width=2)
    d.rectangle([8, 44, 56, 62], fill=HOODIE)
    d.rectangle([8, 44, 32, 54], fill=HOODIE_SH)
    return add_outline(im)

# -- Walk cycle -------------------------------------------------------------------

_WL = [0, 1, 3, 2, 0, 1, 3, 2]
_WA = [0, -1, 0, 1, 0, -1, 0, 1]

# -- Animation generators -----------------------------------------------------------

def anim_idle():
    # Glances at device; screen pulses brighter cyan every 3rd frame
    return [f_front(device=True, pulse=(i % 3 == 2)) for i in range(6)]

def anim_walk_down():
    return [f_front(leg=_WL[i], ldy=_WA[i], rdy=-_WA[i]) for i in range(8)]

def anim_walk_up():
    return [f_back(leg=_WL[i], ldy=_WA[i], rdy=-_WA[i]) for i in range(8)]

def anim_walk_right():
    return [f_side(leg=_WL[i], arm_dy=_WA[i]) for i in range(8)]

def anim_run_down():
    return [f_front(leg=_WL[i], ldy=_WA[i] * 2, rdy=-_WA[i] * 2, run=True, device=False) for i in range(8)]

def anim_run_up():
    return [f_back(leg=_WL[i], ldy=_WA[i] * 2, rdy=-_WA[i] * 2, run=True) for i in range(8)]

def anim_run_right():
    return [f_side(leg=_WL[i], arm_dy=_WA[i] * 2, run=True) for i in range(8)]

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
    exprs = ["focus", "focus", "hack", "hack", "hack", "focus", "grin", "neutral"]
    raise_r = [True, True, True, True, True, True, False, False]
    return [f_front(raise_right=raise_r[i], expr=exprs[i], pulse=(exprs[i] == "hack")) for i in range(8)]

def anim_panel_interact():
    # Row 9 — panel interact (6 frames) — crouch + device extended
    return [
        f_front(crouch=True, expr="focus"),
        f_front(crouch=True, raise_right=True, expr="hack", pulse=True),
        f_front(crouch=True, raise_right=True, expr="hack", pulse=True),
        f_front(crouch=True, raise_right=True, expr="focus"),
        f_front(crouch=True, expr="grin"),
        f_front(expr="grin"),
    ]

def anim_talk():
    exprs = ["neutral", "talk", "focus", "grin", "neutral", "neutral"]
    raise_r = [False, True, False, False, False, False]
    return [f_front(raise_right=raise_r[i], expr=exprs[i]) for i in range(6)]

def anim_talk_closeup():
    exprs = ["neutral", "focus", "hack", "grin", "focus", "talk", "neutral", "neutral"]
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
            d.rectangle([6, 24, 20, 34], fill=HOODIE)
            d.rectangle([8, 32, 52, 42], fill=HOODIE)
            d.rectangle([8, 32, 22, 42], fill=SKIN)
            d.rectangle([6, 40, 44, 48], fill=NAVY)
            d.rectangle([42, 40, 54, 48], fill=SNEAKER)
            d.rectangle([40, 34, 48, 40], fill=CYAN)        # device on floor
            frames.append(add_outline(im))
        else:
            im = tile(); d = ImageDraw.Draw(im)
            fy = min(22 + (i - 3) * 6, 36)
            d.rectangle([2, fy, 16, fy + 6], fill=HAIR)
            d.rectangle([4, fy + 6, 56, fy + 16], fill=HOODIE)
            d.rectangle([4, fy + 6, 16, fy + 16], fill=SKIN)
            # device screen — goes dark on the final frame
            device_color = HOODIE_SH if i == 9 else CYAN
            d.rectangle([32, fy + 8, 44, fy + 14], fill=device_color)
            frames.append(add_outline(im))
    return frames

def anim_revive():
    down = anim_down()
    return [down[9], down[7], down[5], down[3],
            f_side(leg=0, arm_dy=-2), f_side(leg=1), f_front(), f_front()]

def anim_dash():
    frames = []
    for i in range(5):
        lean = i * 2
        im = tile(); d = ImageDraw.Draw(im)
        draw_legs_side(d, phase=1, run=True)
        d.rectangle([26 + lean, 22, 42 + lean, 44], fill=HOODIE)
        d.line([(26 + lean, 22), (26 + lean, 44)], fill=HOODIE_SH, width=2)
        draw_arm_side(d, arm_dy=-2)
        d.rectangle([40 + lean, 24, 48 + lean, 34], fill=CYAN)
        draw_hair_side(d)
        d.rectangle([28 + lean, 8, 44 + lean, 22], fill=SKIN)
        d.rectangle([34 + lean, 12, 42 + lean, 18], fill=GLASSES)
        d.rectangle([36 + lean, 14, 40 + lean, 16], fill=CYAN)
        frames.append(add_outline(im))
    return frames

def anim_lizard_summon():
    # Row 16 — holds device up, beeps (frames 1-3); small green lizard
    # appears on his arm for the final 3 frames (4-6)
    exprs = ["focus", "focus", "hack", "hack", "grin", "neutral"]
    raise_r = [False, True, True, True, False, False]
    show_lizard = [False, False, False, True, True, True]
    return [f_front(crouch=(i < 3), raise_right=raise_r[i], expr=exprs[i],
                     pulse=(exprs[i] == "hack"), show_lizard=show_lizard[i]) for i in range(6)]

ANIMS = [
    ("idle",           anim_idle),
    ("walk_down",      anim_walk_down),
    ("walk_up",        anim_walk_up),
    ("walk_right",     anim_walk_right),
    ("run_down",       anim_run_down),
    ("run_up",         anim_run_up),
    ("run_right",      anim_run_right),
    ("attack",         anim_attack),
    ("special",        anim_special),
    ("panel_interact", anim_panel_interact),
    ("talk",           anim_talk),
    ("talk_closeup",   anim_talk_closeup),
    ("hurt",           anim_hurt),
    ("down",           anim_down),
    ("revive",         anim_revive),
    ("dash",           anim_dash),
    ("lizard_summon",  anim_lizard_summon),
]

if __name__ == "__main__":
    sheet = Image.new('RGBA', (T * 10, T * len(ANIMS)), TR)
    for row, (name, fn) in enumerate(ANIMS):
        for col, frame in enumerate(fn()):
            sheet.paste(frame, (col * T, row * T))

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, "assets", "art", "sprites", "ethan.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(f"Saved 640x{T*len(ANIMS)} -> {out}")
    for n, f in ANIMS:
        print(f"  {n:<16} {len(f())} frames")
