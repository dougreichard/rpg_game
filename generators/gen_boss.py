#!/usr/bin/env python3
"""Boss (Clockwork Guardian) sprite sheet -- PIL procedural, 128x128 spec
(sprites.md "Boss"). 1280 x 1024 px RGBA (8 rows x 10 cols x 128x128),
ENEMY_ANIMS row order:
walk(6) chase(8) windup(6) attack(4) recover(4) hurt(4) death(8) alert(4).

AOE_TELEGRAPH plays "windup" and AOE_SLAM plays "attack" (per enemy.gd
lines 349-350) -- both modes share the same 8-row contract, no extra rows.
Iron-grey armour, gold gear accents, single large red eye, crown of gear
teeth. Displayed 64x64 on screen (ENEMY_SPRITE_SCALE=0.5) then scaled to
96x96 by enemy.gd's is_boss scale=Vector2(1.5,1.5).
"""
from PIL import Image, ImageDraw
from _sprite_common import INK, TR, tile, add_outline, save_sheet

TW, TH = 128, 128

IRON       = ( 92,  92, 110, 255)  # #5C5C6E
IRON_SH    = ( 60,  60,  76, 255)
IRON_LT    = (120, 120, 140, 255)
GOLD       = (255, 201,  77, 255)  # #FFC94D
GOLD_SH    = (200, 152,  50, 255)
EYE        = (225,  59,  74, 255)  # #E13B4A red glow
EYE_CORE   = (255, 107,  92, 255)  # #FF6B5C brighter core
RING       = (244, 240, 230, 255)  # #F4F0E6 ring highlight
DARK       = ( 46,  46,  58, 255)  # #2E2E3A dark joint / gap


def f_boss(leg_phase=0, bob=0, head_tilt=0, arms="idle", eye_glow=False,
           eyes_x=False, charge_level=0, fall=0, lying=False):
    """arms in {"idle","raise1","raise2","raise3","hold","slam","low"}.
    charge_level 0-3 controls how much gold charge glow rings appear (for
    windup/hold phases). eye_glow adds an extra bright corona around the eye.
    """
    im = tile(TW, TH); d = ImageDraw.Draw(im)

    if lying:
        # Collapsed heap -- torso flat, gear-crown tilted.
        d.ellipse([16, 76, 110, 116], fill=IRON)
        d.ellipse([16, 96, 110, 116], fill=IRON_SH)
        # Left arm sprawled
        d.rectangle([ 4, 70,  28,  94], fill=IRON_SH)
        # Right arm sprawled
        d.rectangle([100, 70, 124,  94], fill=IRON_SH)
        # Head tilted on side
        d.rectangle([80, 54, 114, 84], fill=IRON)
        # Crown teeth flat
        for gx in (84, 92, 100, 108):
            d.rectangle([gx, 48, gx + 6, 56], fill=GOLD)
        # X eye
        d.line([(90, 58), (98, 66)], fill=INK, width=3)
        d.line([(98, 58), (90, 66)], fill=INK, width=3)
        # Gold gear on torso
        d.ellipse([44, 78, 68, 102], fill=GOLD_SH)
        d.ellipse([50, 84, 62,  96], fill=DARK)
        return add_outline(im, TW, TH)

    y = bob + fall

    # Leg cylinders -- heavy armoured
    if leg_phase == 0:
        d.rectangle([34, 88 + y, 54, 122 + y], fill=IRON)
        d.rectangle([34, 108 + y, 54, 122 + y], fill=IRON_SH)
        d.rectangle([74, 90 + y, 94, 122 + y], fill=IRON)
        d.rectangle([74, 108 + y, 94, 122 + y], fill=IRON_SH)
    elif leg_phase == 1:
        d.rectangle([34, 90 + y, 54, 122 + y], fill=IRON)
        d.rectangle([34, 108 + y, 54, 122 + y], fill=IRON_SH)
        d.rectangle([74, 88 + y, 94, 122 + y], fill=IRON)
        d.rectangle([74, 108 + y, 94, 122 + y], fill=IRON_SH)
    else:  # wide braced
        d.rectangle([24, 90 + y, 44, 122 + y], fill=IRON)
        d.rectangle([24, 108 + y, 44, 122 + y], fill=IRON_SH)
        d.rectangle([84, 90 + y, 104, 122 + y], fill=IRON)
        d.rectangle([84, 108 + y, 104, 122 + y], fill=IRON_SH)

    # Left arm (back)
    left_arm_y = 48
    d.rectangle([ 6, left_arm_y + y, 30, left_arm_y + 44 + y], fill=IRON_SH)
    d.rectangle([ 6, left_arm_y + 36 + y, 30, left_arm_y + 50 + y], fill=IRON_SH)  # fist

    # Torso -- wide
    d.rectangle([26, 44 + y, 102, 90 + y], fill=IRON)
    d.rectangle([26, 74 + y, 102, 90 + y], fill=IRON_SH)
    # Gold gear badge center-chest
    cx, cy = 64, 68 + y
    d.ellipse([cx - 14, cy - 14, cx + 14, cy + 14], fill=GOLD_SH)
    d.ellipse([cx -  8, cy -  8, cx +  8, cy +  8], fill=DARK)
    for angle_idx in range(8):
        import math
        ang = math.radians(angle_idx * 45)
        gx = int(cx + 16 * math.cos(ang)) - 3
        gy = int(cy + 16 * math.sin(ang)) - 3
        d.rectangle([gx, gy, gx + 6, gy + 6], fill=GOLD)
    # Shoulder plates
    d.rectangle([ 6, 44 + y, 28, 62 + y], fill=IRON_LT)
    d.rectangle([100, 44 + y, 122, 62 + y], fill=IRON_LT)

    # Right arm + fists
    if arms == "idle":
        d.rectangle([98, 48 + y, 122, 92 + y], fill=IRON)
        d.rectangle([98, 80 + y, 124, 96 + y], fill=IRON_SH)
    elif arms == "raise1":
        d.rectangle([96, 36 + y, 120, 72 + y], fill=IRON)
        d.rectangle([96, 28 + y, 120, 44 + y], fill=IRON_SH)
        d.rectangle([ 6, 36 + y,  30, 72 + y], fill=IRON_SH)
        d.rectangle([ 6, 28 + y,  30, 44 + y], fill=IRON_SH)
    elif arms == "raise2":
        d.rectangle([94, 20 + y, 118, 56 + y], fill=IRON)
        d.rectangle([94, 10 + y, 118, 26 + y], fill=IRON_SH)
        d.rectangle([ 8, 20 + y,  32, 56 + y], fill=IRON_SH)
        d.rectangle([ 8, 10 + y,  32, 26 + y], fill=IRON_SH)
    elif arms in ("raise3", "hold"):
        d.rectangle([90,  8 + y, 114, 44 + y], fill=IRON)
        d.rectangle([90,  0 + y, 114, 12 + y], fill=IRON_SH)
        d.rectangle([12,  8 + y,  36, 44 + y], fill=IRON_SH)
        d.rectangle([12,  0 + y,  36, 12 + y], fill=IRON_SH)
        if charge_level > 0:
            for r in range(charge_level):
                ri = 20 + r * 12
                d.ellipse([64 - ri, 48 + y - ri, 64 + ri, 48 + y + ri], outline=GOLD, width=2)
    elif arms == "slam":
        # Both fists crash downward.
        d.rectangle([92, 68 + y, 124, 100 + y], fill=IRON)
        d.rectangle([ 4, 68 + y,  36, 100 + y], fill=IRON_SH)
        d.rectangle([92, 94 + y, 124, 108 + y], fill=IRON_SH)
    elif arms == "low":
        d.rectangle([98, 60 + y, 122, 96 + y], fill=IRON)
        d.rectangle([98, 88 + y, 122, 104 + y], fill=IRON_SH)

    # Head -- square, armoured visor
    hy = 6 + y + head_tilt
    d.rectangle([32, hy, 96, hy + 40], fill=IRON)
    d.rectangle([32, hy + 28, 96, hy + 40], fill=IRON_SH)
    # Visor band
    d.rectangle([28, hy + 12, 100, hy + 28], fill=DARK)
    # Crown gear teeth
    for gx in (34, 46, 58, 70, 82):
        d.rectangle([gx, hy - 12, gx + 8, hy + 2], fill=IRON_LT)
        d.rectangle([gx + 1, hy - 14, gx + 7, hy - 8], fill=GOLD)

    # The Eye
    ex, ey = 64, hy + 20
    d.ellipse([ex - 10, ey - 10, ex + 10, ey + 10], fill=EYE)
    d.ellipse([ex -  5, ey -  5, ex +  5, ey +  5], fill=EYE_CORE)
    if eye_glow:
        d.ellipse([ex - 14, ey - 14, ex + 14, ey + 14], outline=EYE, width=2)
    if eyes_x:
        d.line([(ex - 8, ey - 8), (ex + 8, ey + 8)], fill=INK, width=3)
        d.line([(ex + 8, ey - 8), (ex - 8, ey + 8)], fill=INK, width=3)

    # Gold trim stripe on helmet base
    d.rectangle([32, hy + 36, 96, hy + 40], fill=GOLD_SH)

    return add_outline(im, TW, TH)


_WLK = [0, 1, 0, 1, 0, 1]
_WB  = [0, -1, 0, -1, 0, -1]
_CSE = [0, 1, 0, 1, 0, 1, 0, 1]
_CB  = [0, -2, 0, -2, 0, -2, 0, -2]


def anim_walk():
    return [f_boss(leg_phase=_WLK[i], bob=_WB[i]) for i in range(6)]


def anim_chase():
    return [f_boss(leg_phase=_CSE[i], bob=_CB[i], arms="low", eye_glow=True)
            for i in range(8)]


def anim_windup():
    # Used for BOTH melee windup AND AoE telegraph (enemy.gd line 349).
    # Charge levels 1-3 add visible gold energy rings as the hold progresses.
    entries = [
        ("raise1", 0, 0), ("raise2", 0, -1), ("raise3", 1, -2),
        ("hold", 2, -2),  ("hold", 3, -2),   ("hold", 3, -2),
    ]
    return [f_boss(leg_phase=2, arms=a, charge_level=c, bob=b,
                   head_tilt=-2, eye_glow=True) for a, c, b in entries]


def anim_attack():
    # Used for BOTH melee strike AND AoE slam (enemy.gd line 350).
    return [
        f_boss(leg_phase=2, arms="hold", charge_level=3, bob=-2,
               head_tilt=-2, eye_glow=True),
        f_boss(leg_phase=2, arms="slam",  bob=6, head_tilt=4, eye_glow=True),
        f_boss(leg_phase=2, arms="slam",  bob=6, head_tilt=4),
        f_boss(leg_phase=2, arms="low",   bob=0),
    ]


def anim_recover():
    return [
        f_boss(leg_phase=2, arms="low",  bob=2),
        f_boss(leg_phase=1, arms="idle", bob=1),
        f_boss(leg_phase=0, arms="idle"),
        f_boss(leg_phase=0, arms="idle"),
    ]


def anim_hurt():
    return [
        f_boss(leg_phase=1, bob=2, head_tilt=2, eyes_x=True),
        f_boss(leg_phase=0, bob=4, head_tilt=4, eyes_x=True),
        f_boss(leg_phase=1, bob=2, head_tilt=2, eyes_x=True),
        f_boss(leg_phase=0),
    ]


def anim_death():
    frames = []
    frames.append(f_boss(leg_phase=1, bob=2, head_tilt=2, eyes_x=True))
    frames.append(f_boss(leg_phase=2, bob=6, head_tilt=4, fall=4, eyes_x=True))
    frames.append(f_boss(leg_phase=2, fall=12, head_tilt=6, eyes_x=True))
    for _ in range(5):
        frames.append(f_boss(lying=True))
    return frames


def anim_alert():
    # Slow sweep -- eye glow pulses, head turns.
    return [
        f_boss(leg_phase=2, arms="idle", head_tilt=0, eye_glow=False),
        f_boss(leg_phase=2, arms="idle", head_tilt=-3, eye_glow=True),
        f_boss(leg_phase=2, arms="idle", head_tilt=0, eye_glow=False),
        f_boss(leg_phase=2, arms="idle", head_tilt=3, eye_glow=True),
    ]


ANIMS = [
    ("walk",    anim_walk),
    ("chase",   anim_chase),
    ("windup",  anim_windup),
    ("attack",  anim_attack),
    ("recover", anim_recover),
    ("hurt",    anim_hurt),
    ("death",   anim_death),
    ("alert",   anim_alert),
]

if __name__ == "__main__":
    save_sheet([(name, fn()) for name, fn in ANIMS], TW, TH, "boss.png")
