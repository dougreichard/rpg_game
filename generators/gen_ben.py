#!/usr/bin/env python3
"""
Ben sprite sheet — PIL procedural, 64x64 spec.
640 x 1088 px RGBA  (17 rows x 10 cols x 64x64).

Extended-palette / "Stranger Things: 1984"-style rebuild (DESIGN.md SS2.0,
sprites.md "Ben"). Same animation structure and frame counts as the
original 32x32 generator, doubled onto the 64x64 canvas, plus:
  - extended-palette patchwork jacket (blue base #4D9CE6, green #4FB05C,
    red #E13B4A / #FF6B5C patches, plus a warm-brown panel), dark-grey
    trousers (#5C5C6E) w/ shadow, worn ankle boots, mid-brown hair (#9C5A2E)
    w/ highlight, light-tan skin w/ blush
  - keytar body recolored grey/black with glowing cyan (#5ED6FF) keys + a
    bright cyan glow highlight strip
  - eye-white + pupil + eyebrow detail on the face (front/side/closeup)
  - musical note glyphs (idle floats one up; Perfect Pitch shows several
    above his head; Perform scatters them around him) and concentric
    sound-wave rings for the AoE special, via small new draw_note/draw_rings
    helpers — literalizes sprites.md's "note glyph" / "sound-wave rings" cues
    that v1 didn't yet have room for at 32x32

Proportions: head ~16x14, torso ~22x22, legs wide stance — same grid as
Quinn/Erin/Evan, doubled from the v1 32x32 coordinates.
"""
from PIL import Image, ImageDraw
import os

# -- Extended palette (DESIGN.md SS2.0 / sprites.md "Ben -> Palette slots") --
INK          = ( 26,  26,  34, 255)  # ink-black: outline
HAIR         = (156,  90,  46, 255)  # #9C5A2E mid-brown hair
HAIR_HI      = (199, 138,  87, 255)  # hair highlight
HAIR_SH      = (110,  61,  28, 255)  # hair shadow / eyebrows
SKIN         = (242, 196, 155, 255)  # light-tan skin
SKIN_SH      = (217, 168, 124, 255)  # skin shadow / blush
EYE_WHITE    = (244, 240, 230, 255)  # eye whites
TROUSER      = ( 92,  92, 110, 255)  # #5C5C6E dark grey trousers
TROUSER_SH   = ( 68,  68,  82, 255)  # trouser shadow
BOOT         = ( 70,  47,  29, 255)  # worn ankle boots
BOOT_HI      = ( 95,  68,  46, 255)  # boot cuff highlight
PATCH_BLUE   = ( 77, 156, 230, 255)  # #4D9CE6 patch — base
PATCH_BLUE_SH= ( 47,  74, 153, 255)  # #2F4A99 patch
PATCH_GREEN  = ( 79, 176,  92, 255)  # #4FB05C patch
PATCH_RED    = (225,  59,  74, 255)  # #E13B4A patch
PATCH_RED_HI = (255, 107,  92, 255)  # #FF6B5C patch
PATCH_BROWN  = (156,  90,  46, 255)  # warm-brown patch panel
KEYTAR_BODY  = ( 60,  60,  68, 255)  # grey/black keytar body
KEYTAR_DK    = ( 38,  38,  46, 255)  # keytar strap / shadow
CYAN         = ( 94, 214, 255, 255)  # #5ED6FF glowing keys
CYAN_HI      = (180, 240, 255, 255)  # bright cyan glow
NOTE_COLOR   = (255, 230, 120, 255)  # musical note glyph
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

def draw_note(d, x, y):
    """Small floating musical-note glyph."""
    d.ellipse([x, y, x + 6, y + 6], fill=NOTE_COLOR)
    d.rectangle([x + 5, y - 10, x + 7, y + 3], fill=NOTE_COLOR)

def draw_rings(d, n):
    """Concentric sound-wave rings radiating from Ben's center."""
    for k in range(n):
        r = 14 + k * 8
        d.arc([32 - r, 32 - r, 32 + r, 32 + r], 0, 360, fill=CYAN_HI, width=2)

# -- Body-part helpers (all coords are the v1 32x32 coords x2) ------------------
# Head:  y 4-22
# Torso: y 22-44 (patchwork jacket)
# Legs:  y 44-62

def draw_hair_front(d):
    d.rectangle([24, 2, 40, 10], fill=HAIR)
    d.rectangle([22, 8, 24, 10], fill=HAIR)
    d.rectangle([40, 8, 42, 10], fill=HAIR)
    d.line([(26, 3), (38, 3)], fill=HAIR_HI)

def draw_hair_back(d):
    d.rectangle([24, 2, 40, 12], fill=HAIR)
    d.rectangle([22, 10, 24, 12], fill=HAIR)
    d.rectangle([40, 10, 42, 12], fill=HAIR)
    d.line([(26, 3), (38, 3)], fill=HAIR_HI)

def draw_hair_side(d):
    d.rectangle([30, 2, 44, 12], fill=HAIR)
    d.rectangle([28, 10, 30, 12], fill=HAIR)
    d.line([(32, 3), (42, 3)], fill=HAIR_HI)

def draw_face_front(d, expr="neutral"):
    d.rectangle([24, 8, 40, 22], fill=SKIN)
    d.line([(25, 12), (29, 11)], fill=HAIR_SH)           # left eyebrow
    d.line([(35, 11), (39, 12)], fill=HAIR_SH)           # right eyebrow
    d.rectangle([26, 14, 30, 18], fill=EYE_WHITE)
    d.rectangle([34, 14, 38, 18], fill=EYE_WHITE)
    d.rectangle([27, 15, 29, 17], fill=INK)              # left pupil
    d.rectangle([35, 15, 37, 17], fill=INK)              # right pupil
    d.ellipse([24, 17, 28, 20], fill=SKIN_SH)            # blush
    d.ellipse([36, 17, 40, 20], fill=SKIN_SH)
    if   expr == "sing":
        d.arc([24, 18, 40, 26], 0, 180, fill=INK, width=2)
    elif expr == "hype":
        d.arc([24, 18, 40, 24], 0, 180, fill=INK, width=2)
        d.line([(26, 12), (30, 14)], fill=INK, width=2)
    elif expr == "hurt":
        d.line([(26, 18), (38, 18)], fill=INK, width=2)
    elif expr == "listen":
        d.rectangle([28, 18, 36, 22], fill=INK)
    else:
        d.line([(28, 20), (36, 20)], fill=SKIN_SH)

def draw_face_side(d):
    d.rectangle([28, 8, 44, 22], fill=SKIN)
    d.line([(36, 11), (42, 11)], fill=HAIR_SH)           # eyebrow
    d.rectangle([38, 14, 42, 18], fill=EYE_WHITE)
    d.rectangle([39, 15, 41, 17], fill=INK)              # pupil
    d.ellipse([34, 17, 38, 20], fill=SKIN_SH)            # blush

_PATCHES_FRONT = [
    (22, 22, 32, 32, PATCH_RED_HI),   # bright red-orange patch
    (32, 22, 44, 32, PATCH_GREEN),    # green patch
    (22, 32, 32, 44, PATCH_RED),      # red patch
    (32, 32, 44, 44, PATCH_BLUE_SH),  # navy patch
    (20, 24, 24, 40, PATCH_BROWN),    # left arm panel
    (42, 24, 46, 40, PATCH_BROWN),    # right arm panel
]

def draw_torso_front(d):
    d.rectangle([22, 22, 44, 44], fill=PATCH_BLUE)       # base patch
    for x0, y0, x1, y1, col in _PATCHES_FRONT:
        d.rectangle([x0, y0, x1, y1], fill=col)
    d.line([(32, 22), (32, 44)], fill=INK, width=2)      # patch seam
    d.line([(22, 32), (44, 32)], fill=INK, width=2)

def draw_torso_back(d):
    d.rectangle([22, 22, 44, 44], fill=PATCH_BLUE)
    d.rectangle([22, 22, 34, 32], fill=PATCH_GREEN)
    d.rectangle([34, 22, 44, 32], fill=PATCH_RED_HI)
    d.rectangle([22, 32, 34, 44], fill=PATCH_BROWN)
    d.rectangle([34, 32, 44, 44], fill=PATCH_RED)
    d.line([(34, 22), (34, 44)], fill=INK, width=2)
    d.line([(22, 32), (44, 32)], fill=INK, width=2)

def draw_torso_side(d):
    d.rectangle([28, 22, 44, 44], fill=PATCH_BLUE)
    d.rectangle([28, 22, 36, 32], fill=PATCH_RED_HI)
    d.rectangle([28, 32, 36, 44], fill=PATCH_RED)
    d.line([(28, 32), (44, 32)], fill=INK, width=2)

def draw_keytar_front(d, raise_arm=False):
    """Keytar slung diagonally across body — front view."""
    ky_y = 20 if raise_arm else 26
    d.rectangle([16, ky_y, 46, ky_y + 10], fill=KEYTAR_BODY)
    d.rectangle([18, ky_y + 6, 44, ky_y + 10], fill=CYAN)
    d.rectangle([18, ky_y + 6, 44, ky_y + 8], fill=CYAN_HI)   # glow highlight
    d.line([(18, ky_y), (44, ky_y + 12)], fill=KEYTAR_DK, width=2)

def draw_keytar_side(d):
    d.rectangle([34, 24, 52, 34], fill=KEYTAR_BODY)
    d.rectangle([36, 30, 52, 34], fill=CYAN)
    d.rectangle([36, 30, 52, 32], fill=CYAN_HI)

def draw_arms_front(d, ldy=0, rdy=0, wide=False, raise_left=False, raise_right=False):
    if wide:
        d.rectangle([10, 24, 22, 36], fill=SKIN)
        d.rectangle([42, 24, 54, 36], fill=SKIN)
        d.rectangle([10, 32, 22, 36], fill=SKIN_SH)
        d.rectangle([42, 32, 54, 36], fill=SKIN_SH)
    elif raise_left and raise_right:
        d.rectangle([16, 18, 24, 40], fill=SKIN)
        d.rectangle([40, 18, 48, 40], fill=SKIN)
    elif raise_left:
        d.rectangle([16, 18, 24, 40], fill=SKIN)
        d.rectangle([44, 22 + rdy * 2, 52, 42 + rdy * 2], fill=SKIN)
    elif raise_right:
        d.rectangle([16, 22 + ldy * 2, 24, 42 + ldy * 2], fill=SKIN)
        d.rectangle([40, 18, 48, 40], fill=SKIN)
    else:
        ly0 = 22 + ldy * 2; ly1 = 42 + ldy * 2
        ry0 = 22 + rdy * 2; ry1 = 42 + rdy * 2
        d.rectangle([16, ly0, 24, ly1], fill=SKIN)
        d.rectangle([40, ry0, 48, ry1], fill=SKIN)
        d.rectangle([16, ly1 - 4, 24, ly1], fill=SKIN_SH)
        d.rectangle([40, ry1 - 4, 48, ry1], fill=SKIN_SH)

def draw_arm_side(d, arm_dy=0):
    y0 = 22 + arm_dy * 2
    y1 = 42 + arm_dy * 2
    d.rectangle([44, y0, 52, y1], fill=SKIN)
    d.rectangle([44, y1 - 4, 52, y1], fill=SKIN_SH)

def draw_legs_front(d, phase=0, run=False, crouch=False):
    if crouch:
        d.rectangle([24, 44, 32, 54], fill=TROUSER)
        d.rectangle([32, 44, 40, 54], fill=TROUSER)
        d.rectangle([22, 54, 34, 62], fill=BOOT)
        d.rectangle([32, 54, 42, 62], fill=BOOT)
        d.rectangle([22, 54, 34, 56], fill=BOOT_HI)
        d.rectangle([32, 54, 42, 56], fill=BOOT_HI)
        return
    s = 6 if run else 4
    if   phase == 0: lx, rx, ld, rd = 24, 34, 0, 0
    elif phase == 1: lx, rx, ld, rd = 22, 36, s, 0
    elif phase == 2: lx, rx, ld, rd = 26, 32, 0, s
    else:            lx, rx, ld, rd = 22, 36, 0, 0
    d.rectangle([lx, 44, lx + 6, 52 + ld], fill=TROUSER)
    d.rectangle([lx, 44, lx + 2, 52 + ld], fill=TROUSER_SH)
    d.rectangle([lx - 2, 52 + ld, lx + 8, 62], fill=BOOT)
    d.rectangle([lx - 2, 52 + ld, lx + 8, 54 + ld], fill=BOOT_HI)
    d.rectangle([rx, 44, rx + 6, 52 + rd], fill=TROUSER)
    d.rectangle([rx, 44, rx + 2, 52 + rd], fill=TROUSER_SH)
    d.rectangle([rx - 2, 52 + rd, rx + 8, 62], fill=BOOT)
    d.rectangle([rx - 2, 52 + rd, rx + 8, 54 + rd], fill=BOOT_HI)

def draw_legs_side(d, phase=0, run=False):
    s = 6 if run else 4
    if phase in (0, 2):
        d.rectangle([28, 44, 36, 54], fill=TROUSER)
        d.rectangle([34, 44, 42, 54], fill=TROUSER)
        d.rectangle([26, 52, 38, 62], fill=BOOT)
        d.rectangle([32, 52, 44, 60], fill=BOOT)
        d.rectangle([26, 52, 38, 54], fill=BOOT_HI)
    elif phase == 1:
        d.rectangle([34, 44, 42, 52 + s], fill=TROUSER)
        d.rectangle([26, 44, 34, 52],     fill=TROUSER)
        d.rectangle([32, 50 + s, 46, 62], fill=BOOT)
        d.rectangle([24, 50, 36, 58],     fill=BOOT)
        d.rectangle([32, 50 + s, 46, 52 + s], fill=BOOT_HI)
    else:
        d.rectangle([26, 44, 34, 52 + s], fill=TROUSER)
        d.rectangle([34, 44, 42, 52],     fill=TROUSER)
        d.rectangle([24, 50 + s, 36, 62], fill=BOOT)
        d.rectangle([32, 50, 46, 58],     fill=BOOT)
        d.rectangle([24, 50 + s, 36, 52 + s], fill=BOOT_HI)

# -- Frame assemblers ------------------------------------------------------------

def f_front(leg=0, ldy=0, rdy=0, expr="neutral", wide=False,
             raise_left=False, raise_right=False, run=False, crouch=False,
             keytar=True, note_y=None, rings=0, extra_notes=None):
    im = tile(); d = ImageDraw.Draw(im)
    if rings:
        draw_rings(d, rings)
    draw_legs_front(d, phase=leg, run=run, crouch=crouch)
    draw_arms_front(d, ldy, rdy, wide=wide, raise_left=raise_left, raise_right=raise_right)
    draw_torso_front(d)
    if keytar:
        draw_keytar_front(d)
    draw_hair_front(d)
    draw_face_front(d, expr=expr)
    if note_y is not None:
        draw_note(d, 46, note_y)
    if extra_notes:
        for nx, ny in extra_notes:
            draw_note(d, nx, ny)
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
    if keytar:
        draw_keytar_side(d)
    draw_hair_side(d)
    draw_face_side(d)
    return add_outline(im)

def f_closeup(expr="neutral"):
    im = tile(); d = ImageDraw.Draw(im)
    d.rectangle([16, 0, 48, 10], fill=HAIR)              # hair top
    d.rectangle([14, 8, 16, 10], fill=HAIR)              # left tuft
    d.rectangle([48, 8, 50, 10], fill=HAIR)              # right tuft
    d.line([(20, 2), (44, 2)], fill=HAIR_HI)             # highlight streak
    d.rectangle([16, 8, 48, 44], fill=SKIN)              # face
    d.line([(18, 18), (28, 16)], fill=HAIR_SH)           # eyebrows
    d.line([(36, 16), (46, 18)], fill=HAIR_SH)
    d.rectangle([18, 22, 28, 30], fill=EYE_WHITE)        # left eye
    d.rectangle([36, 22, 46, 30], fill=EYE_WHITE)
    d.rectangle([21, 24, 25, 28], fill=INK)              # left pupil
    d.rectangle([39, 24, 43, 28], fill=INK)              # right pupil
    d.ellipse([16, 32, 24, 38], fill=SKIN_SH)            # blush
    d.ellipse([40, 32, 48, 38], fill=SKIN_SH)
    if   expr == "sing":
        d.arc([20, 34, 44, 46], 0, 180, fill=INK, width=2)
    elif expr == "hype":
        d.arc([20, 34, 44, 42], 0, 180, fill=INK, width=2)
        d.line([(22, 18), (28, 22)], fill=INK, width=2)
    elif expr == "talk":
        d.line([(22, 38), (42, 38)], fill=INK, width=2)
    else:
        d.line([(24, 40), (40, 40)], fill=SKIN_SH, width=2)
    d.rectangle([8, 44, 56, 62], fill=PATCH_BLUE)        # jacket collar
    d.rectangle([8, 44, 32, 54], fill=PATCH_GREEN)
    d.rectangle([32, 44, 56, 54], fill=PATCH_RED_HI)
    return add_outline(im)

# -- Walk cycle -------------------------------------------------------------------

_WL = [0, 1, 3, 2, 0, 1, 3, 2]
_WA = [0, -1, 0, 1, 0, -1, 0, 1]

# -- Animation generators -----------------------------------------------------------

def anim_idle():
    # Finger tap; small note glyph floats upward in the last 4 frames
    return [f_front(note_y=(20 - (i - 2) * 4) if i >= 2 else None) for i in range(6)]

def anim_walk_down():
    return [f_front(leg=_WL[i], ldy=_WA[i], rdy=-_WA[i]) for i in range(8)]

def anim_walk_up():
    return [f_back(leg=_WL[i], ldy=_WA[i], rdy=-_WA[i]) for i in range(8)]

def anim_walk_right():
    return [f_side(leg=_WL[i], arm_dy=_WA[i]) for i in range(8)]

def anim_run_down():
    return [f_front(leg=_WL[i], ldy=_WA[i] * 2, rdy=-_WA[i] * 2, run=True) for i in range(8)]

def anim_run_up():
    return [f_back(leg=_WL[i], ldy=_WA[i] * 2, rdy=-_WA[i] * 2, run=True) for i in range(8)]

def anim_run_right():
    return [f_side(leg=_WL[i], arm_dy=_WA[i] * 2, run=True) for i in range(8)]

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
    # AoE musical wave — planted stance, concentric sound-wave rings
    # radiate outward on frames 4-8
    exprs = ["listen", "listen", "listen", "listen", "sing", "sing", "neutral", "neutral"]
    raise_l = [True, True, True, True, False, False, False, False]
    rings = [0, 0, 0, 1, 2, 3, 2, 1]
    return [f_front(raise_left=raise_l[i], expr=exprs[i], rings=rings[i]) for i in range(8)]

def anim_perfect_pitch():
    # Row 9 — intense listening then eureka reveal; note glyphs appear above head
    exprs = ["listen", "listen", "listen", "listen", "hype", "sing"]
    raise_l = [True, True, True, True, False, False]
    note_y  = [None, 16, 12, 8, 4, 0]
    return [f_front(raise_left=raise_l[i], expr=exprs[i], note_y=note_y[i]) for i in range(6)]

def anim_talk():
    exprs = ["neutral", "sing", "hype", "sing", "neutral", "neutral"]
    wide  = [False, True, False, True, False, False]
    return [f_front(wide=wide[i], expr=exprs[i]) for i in range(6)]

def anim_talk_closeup():
    exprs = ["neutral", "talk", "hype", "sing", "hype", "talk", "neutral", "neutral"]
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
            d.rectangle([6, 24, 20, 34], fill=PATCH_BLUE)
            d.rectangle([8, 32, 52, 42], fill=PATCH_BLUE)
            d.rectangle([8, 32, 22, 42], fill=SKIN)
            d.rectangle([6, 40, 44, 48], fill=TROUSER)
            d.rectangle([42, 40, 54, 48], fill=BOOT)
            frames.append(add_outline(im))
        else:
            im = tile(); d = ImageDraw.Draw(im)
            fy = min(22 + (i - 3) * 6, 36)
            d.rectangle([2, fy, 16, fy + 6], fill=HAIR)
            d.rectangle([4, fy + 6, 56, fy + 16], fill=PATCH_BLUE)
            d.rectangle([4, fy + 6, 16, fy + 16], fill=SKIN)
            # keytar lying beside
            d.rectangle([32, fy + 10, 52, fy + 16], fill=KEYTAR_BODY)
            d.rectangle([34, fy + 12, 50, fy + 16], fill=CYAN)
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
        d.rectangle([26 + lean, 22, 44 + lean, 44], fill=PATCH_BLUE)
        d.rectangle([26 + lean, 22, 34 + lean, 32], fill=PATCH_RED_HI)
        draw_arm_side(d, arm_dy=-3)
        draw_keytar_side(d)
        draw_hair_side(d)
        d.rectangle([28 + lean, 8, 44 + lean, 22], fill=SKIN)
        d.rectangle([38 + lean, 14, 42 + lean, 18], fill=INK)
        frames.append(add_outline(im))
    return frames

def anim_perform():
    # Row 16 — theatrical crowd-address performance; note glyphs everywhere
    exprs = ["neutral", "hype", "sing", "hype", "sing", "hype", "sing", "neutral"]
    wide  = [False, True, False, True, False, True, False, False]
    notes = [
        [],
        [(8, 6)],
        [(50, 4)],
        [(8, 6), (50, 4)],
        [(50, 10), (4, 14)],
        [(8, 2), (52, 8)],
        [(4, 10), (50, 14), (28, 0)],
        [(28, 4)],
    ]
    return [f_front(wide=wide[i], expr=exprs[i], extra_notes=notes[i]) for i in range(8)]

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
    sheet = Image.new('RGBA', (T * 10, T * len(ANIMS)), TR)
    for row, (name, fn) in enumerate(ANIMS):
        for col, frame in enumerate(fn()):
            sheet.paste(frame, (col * T, row * T))

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, "assets", "art", "sprites", "ben.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(f"Saved 640x{T*len(ANIMS)} -> {out}")
    for n, f in ANIMS:
        print(f"  {n:<16} {len(f())} frames")
