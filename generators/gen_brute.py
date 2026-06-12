#!/usr/bin/env python3
"""Brute sprite sheet -- PIL procedural, 96x64 spec (sprites.md "Brute").
960 x 512 px RGBA (8 rows x 10 cols x 96x64), ENEMY_ANIMS row order:
walk(6) chase(8) windup(8) attack(4) recover(6) hurt(4) death(10) alert(4).

Massive, wide-body brawler -- dark magenta-red tank top, grey track pants,
warm skin. Overhead-slam attack with big fists (no weapon prop). Tile is
96x64 wide to accommodate the broad silhouette; displayed 48x32 on screen
via ENEMY_SPRITE_SCALE=0.5.
"""
from PIL import Image, ImageDraw
from _sprite_common import INK, TR, tile, add_outline, save_sheet

TW, TH = 96, 64

TANK       = (194,  82, 140, 255)  # #C2528C magenta-red tank top
TANK_SH    = (154,  60, 108, 255)
PANTS      = (168, 168, 184, 255)  # #A8A8B8 grey track pants
PANTS_SH   = (130, 130, 146, 255)
SKIN       = (217, 163, 110, 255)  # #D9A36E warm skin
SKIN_SH    = (184, 133,  87, 255)
HAIR       = ( 24,  20,  26, 255)  # #18141A


def f_brute(leg_phase=0, bob=0, head_tilt=0, arms="idle", eyes_x=False,
            fall=0, lying=False):
    """arms in {"idle","raise1","raise2","raise3","hold","slam","low"}."""
    im = tile(TW, TH); d = ImageDraw.Draw(im)

    if lying:
        d.ellipse([8, 36, 80, 62], fill=PANTS)
        d.ellipse([8, 52, 80, 62], fill=PANTS_SH)
        d.rectangle([62, 28, 86, 48], fill=SKIN)
        d.rectangle([4, 28, 22, 44], fill=SKIN)
        d.line([(70, 32), (76, 38)], fill=INK, width=2)
        d.line([(76, 32), (70, 38)], fill=INK, width=2)
        return add_outline(im, TW, TH)

    y = bob + fall

    # Legs -- thick
    if leg_phase == 0:
        d.rectangle([32, 44 + y, 44, 62], fill=PANTS)
        d.rectangle([52, 46 + y, 64, 62], fill=PANTS)
        d.rectangle([32, 56, 44, 62], fill=PANTS_SH)
        d.rectangle([52, 56, 64, 62], fill=PANTS_SH)
    elif leg_phase == 1:
        d.rectangle([32, 46 + y, 44, 62], fill=PANTS)
        d.rectangle([52, 44 + y, 64, 62], fill=PANTS)
        d.rectangle([32, 56, 44, 62], fill=PANTS_SH)
        d.rectangle([52, 56, 64, 62], fill=PANTS_SH)
    else:  # wide slam stance
        d.rectangle([24, 46 + y, 36, 62], fill=PANTS)
        d.rectangle([60, 46 + y, 72, 62], fill=PANTS)
        d.rectangle([24, 56, 36, 62], fill=PANTS_SH)
        d.rectangle([60, 56, 72, 62], fill=PANTS_SH)

    # Left arm (back) -- beefy
    d.rectangle([12, 22 + y, 26, 44 + y], fill=SKIN_SH)
    d.rectangle([10, 40 + y, 26, 48 + y], fill=SKIN_SH)  # fist

    # Torso -- wide trapezoid
    d.rectangle([18, 18 + y, 74, 46 + y], fill=TANK)
    d.rectangle([18, 36 + y, 74, 46 + y], fill=TANK_SH)
    # Tank-top straps
    d.rectangle([26, 18 + y, 36, 24 + y], fill=TANK)
    d.rectangle([56, 18 + y, 66, 24 + y], fill=TANK)
    # Chest / exposed shoulders
    d.rectangle([14, 18 + y, 22, 36 + y], fill=SKIN)
    d.rectangle([70, 18 + y, 78, 36 + y], fill=SKIN)

    # Right arm + fists depending on pose
    if arms == "idle":
        d.rectangle([70, 22 + y, 84, 44 + y], fill=SKIN)
        d.rectangle([72, 40 + y, 86, 50 + y], fill=SKIN_SH)
    elif arms == "raise1":
        d.rectangle([70, 14 + y, 84, 36 + y], fill=SKIN)
        d.rectangle([72, 8 + y, 86, 18 + y], fill=SKIN_SH)
        # also left arm rises
        d.rectangle([8, 14 + y, 22, 36 + y], fill=SKIN_SH)
        d.rectangle([6, 8 + y, 22, 18 + y], fill=SKIN_SH)
    elif arms == "raise2":
        d.rectangle([68, 8 + y, 82, 28 + y], fill=SKIN)
        d.rectangle([70, 2 + y, 84, 12 + y], fill=SKIN_SH)
        d.rectangle([10, 8 + y, 24, 28 + y], fill=SKIN_SH)
        d.rectangle([8, 2 + y, 24, 12 + y], fill=SKIN_SH)
    elif arms in ("raise3", "hold"):
        d.rectangle([66, 2 + y, 80, 22 + y], fill=SKIN)
        d.rectangle([68, -4 + y, 82, 6 + y], fill=SKIN_SH)
        d.rectangle([12, 2 + y, 26, 22 + y], fill=SKIN_SH)
        d.rectangle([10, -4 + y, 24, 6 + y], fill=SKIN_SH)
    elif arms == "slam":
        # Both fists crash down onto the ground in front.
        d.rectangle([50, 30 + y, 86, 52 + y], fill=SKIN)
        d.rectangle([8, 30 + y, 38, 52 + y], fill=SKIN_SH)
        d.rectangle([50, 48 + y, 86, 60 + y], fill=SKIN_SH)
    elif arms == "low":
        d.rectangle([70, 28 + y, 84, 48 + y], fill=SKIN)
        d.rectangle([72, 44 + y, 86, 54 + y], fill=SKIN_SH)

    # Head -- large, square jaw
    hy = 4 + y + head_tilt
    d.rectangle([30, hy, 62, hy + 22], fill=SKIN)
    d.rectangle([30, hy + 14, 62, hy + 22], fill=SKIN_SH)
    d.rectangle([28, hy - 8, 64, hy + 4], fill=HAIR)
    if eyes_x:
        for ex in (35, 47):
            d.line([(ex, hy + 8), (ex + 4, hy + 12)], fill=INK, width=2)
            d.line([(ex + 4, hy + 8), (ex, hy + 12)], fill=INK, width=2)
    else:
        d.ellipse([34, hy + 8, 40, hy + 14], fill=INK)
        d.ellipse([52, hy + 8, 58, hy + 14], fill=INK)

    return add_outline(im, TW, TH)


_LURCH = [0, 1, 0, 1, 0, 1]
_LBOB  = [0, -1, 0, -1, 0, -1]
_STOMP = [0, 1, 0, 1, 0, 1, 0, 1]
_SBOB  = [0, -2, 0, -2, 0, -2, 0, -2]


def anim_walk():
    return [f_brute(leg_phase=_LURCH[i], bob=_LBOB[i]) for i in range(6)]


def anim_chase():
    return [f_brute(leg_phase=_STOMP[i], bob=_SBOB[i], head_tilt=1,
                    arms="low") for i in range(8)]


def anim_windup():
    poses = ["raise1", "raise2", "raise3", "hold", "hold", "hold", "hold", "hold"]
    bobs  = [0, -1, -2, -2, -2, -1, -2, -1]
    return [f_brute(leg_phase=2, arms=poses[i], bob=bobs[i], head_tilt=-2)
            for i in range(8)]


def anim_attack():
    return [
        f_brute(leg_phase=2, arms="hold", head_tilt=-2, bob=-2),
        f_brute(leg_phase=2, arms="slam", head_tilt=3, bob=4),
        f_brute(leg_phase=2, arms="slam", head_tilt=3, bob=4),
        f_brute(leg_phase=2, arms="low",  head_tilt=0),
    ]


def anim_recover():
    return [
        f_brute(leg_phase=2, arms="low",  bob=2),
        f_brute(leg_phase=1, arms="idle", bob=1),
        f_brute(leg_phase=0, arms="idle"),
        f_brute(leg_phase=0, arms="idle"),
        f_brute(leg_phase=0, arms="idle"),
        f_brute(leg_phase=0, arms="idle"),
    ]


def anim_hurt():
    return [
        f_brute(leg_phase=1, head_tilt=2, bob=1, eyes_x=True),
        f_brute(leg_phase=0, head_tilt=3, bob=3, eyes_x=True),
        f_brute(leg_phase=1, head_tilt=2, bob=1, eyes_x=True),
        f_brute(leg_phase=0),
    ]


def anim_death():
    frames = []
    frames.append(f_brute(leg_phase=1, head_tilt=2, bob=1, eyes_x=True))
    frames.append(f_brute(leg_phase=2, head_tilt=4, bob=4, eyes_x=True))
    frames.append(f_brute(leg_phase=2, head_tilt=6, fall=8, eyes_x=True))
    for _ in range(7):
        frames.append(f_brute(lying=True))
    return frames


def anim_alert():
    return [
        f_brute(leg_phase=2, arms="idle", head_tilt=0),
        f_brute(leg_phase=2, arms="idle", head_tilt=-2),
        f_brute(leg_phase=2, arms="idle", head_tilt=0),
        f_brute(leg_phase=2, arms="idle", head_tilt=2),
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
    save_sheet([(name, fn()) for name, fn in ANIMS], TW, TH, "brute.png")
