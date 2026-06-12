#!/usr/bin/env python3
"""Sentry sprite sheet -- PIL procedural, 64x64 spec (sprites.md "Sentry").
640 x 512 px RGBA (8 rows x 10 cols x 64x64), ENEMY_ANIMS row order:
walk(6) chase(8) windup(6) attack(4) recover(4) hurt(4) death(8) alert(4).

Upright guard -- navy uniform, dark cap, orange ranged weapon (stun baton /
blaster), white gloves, white collar. Enemy FSM fires a Projectile on
STRIKE; the weapon-raise + muzzle-flash frames telegraph the shot. Single
3/4 facing-right pose; flip_h for left.
"""
from PIL import Image, ImageDraw
from _sprite_common import INK, TR, tile, add_outline, save_sheet

T = 64

UNIFORM    = ( 47,  74, 153, 255)  # #2F4A99 navy
UNIFORM_SH = ( 35,  56, 118, 255)
CAP        = ( 24,  20,  26, 255)  # #18141A near-black cap
WEAPON     = (255, 154,  60, 255)  # #FF9A3C orange baton / blaster
WEAPON_SH  = (200, 118,  40, 255)
GLOVE      = (244, 240, 230, 255)  # #F4F0E6 white gloves
SKIN       = (242, 196, 155, 255)  # #F2C49B
SKIN_SH    = (210, 160, 118, 255)
MUZZLE     = (255, 224, 102, 255)  # #FFE066 yellow muzzle flash


def f_sentry(leg_phase=0, bob=0, head_tilt=0, weapon_pose="holstered",
             muzzle_flash=False, eyes_x=False, lying=False):
    """weapon_pose in {"holstered","aim_low","aim_mid","aim_high","fired",
    "lowering"}."""
    im = tile(); d = ImageDraw.Draw(im)

    if lying:
        d.ellipse([ 8, 42, 54, 60], fill=UNIFORM)
        d.ellipse([ 8, 54, 54, 60], fill=UNIFORM_SH)
        d.rectangle([42, 38, 60, 52], fill=SKIN)
        d.rectangle([42, 38, 60, 46], fill=CAP)
        d.rectangle([ 4, 40, 14, 52], fill=WEAPON)
        d.line([(50, 42), (54, 46)], fill=INK, width=2)
        d.line([(54, 42), (50, 46)], fill=INK, width=2)
        return add_outline(im)

    y = bob

    # Boots
    d.rectangle([24, 54 + y, 32, 62], fill=INK)
    d.rectangle([34, 54 + y, 42, 62], fill=INK)

    # Legs -- upright
    if leg_phase == 0:
        d.rectangle([26, 44 + y, 32, 56 + y], fill=UNIFORM)
        d.rectangle([34, 46 + y, 40, 56 + y], fill=UNIFORM)
    elif leg_phase == 1:
        d.rectangle([26, 46 + y, 32, 56 + y], fill=UNIFORM)
        d.rectangle([34, 44 + y, 40, 56 + y], fill=UNIFORM)
    else:  # standing firm
        d.rectangle([26, 46 + y, 32, 56 + y], fill=UNIFORM)
        d.rectangle([34, 46 + y, 40, 56 + y], fill=UNIFORM)

    # Back arm
    d.rectangle([16, 28 + y, 22, 44 + y], fill=UNIFORM_SH)
    d.rectangle([14, 40 + y, 20, 48 + y], fill=GLOVE)

    # Torso / uniform -- upright, neat
    d.rectangle([20, 24 + y, 46, 46 + y], fill=UNIFORM)
    d.rectangle([20, 38 + y, 46, 46 + y], fill=UNIFORM_SH)
    # White collar
    d.rectangle([26, 24 + y, 40, 28 + y], fill=GLOVE)

    # Front arm + weapon
    if weapon_pose == "holstered":
        d.rectangle([44, 28 + y, 50, 44 + y], fill=UNIFORM)
        d.rectangle([44, 40 + y, 52, 50 + y], fill=GLOVE)
        d.rectangle([48, 44 + y, 54, 58 + y], fill=WEAPON)
        d.rectangle([48, 54 + y, 54, 58 + y], fill=WEAPON_SH)
    elif weapon_pose == "aim_low":
        d.rectangle([44, 30 + y, 50, 44 + y], fill=UNIFORM)
        d.rectangle([44, 38 + y, 52, 46 + y], fill=GLOVE)
        d.rectangle([50, 36 + y, 62, 42 + y], fill=WEAPON)
    elif weapon_pose == "aim_mid":
        d.rectangle([44, 26 + y, 50, 38 + y], fill=UNIFORM)
        d.rectangle([44, 28 + y, 52, 34 + y], fill=GLOVE)
        d.rectangle([50, 24 + y, 62, 30 + y], fill=WEAPON)
    elif weapon_pose == "aim_high":
        d.rectangle([42, 22 + y, 48, 34 + y], fill=UNIFORM)
        d.rectangle([42, 22 + y, 52, 28 + y], fill=GLOVE)
        d.rectangle([50, 18 + y, 62, 24 + y], fill=WEAPON)
        d.rectangle([58, 16 + y, 64, 22 + y], fill=WEAPON_SH)  # barrel tip
    elif weapon_pose == "fired":
        d.rectangle([42, 22 + y, 48, 34 + y], fill=UNIFORM)
        d.rectangle([42, 22 + y, 52, 28 + y], fill=GLOVE)
        d.rectangle([50, 18 + y, 62, 24 + y], fill=WEAPON)
        d.rectangle([58, 16 + y, 64, 22 + y], fill=WEAPON_SH)
        if muzzle_flash:
            # bright yellow burst at barrel tip
            d.ellipse([60, 12 + y, 72, 24 + y], fill=MUZZLE)
    elif weapon_pose == "lowering":
        d.rectangle([44, 26 + y, 50, 40 + y], fill=UNIFORM)
        d.rectangle([44, 36 + y, 52, 44 + y], fill=GLOVE)
        d.rectangle([50, 30 + y, 60, 36 + y], fill=WEAPON)

    # Head + cap
    hy = 8 + y + head_tilt
    d.rectangle([22, hy, 42, hy + 18], fill=SKIN)
    d.rectangle([22, hy + 10, 42, hy + 18], fill=SKIN_SH)
    d.rectangle([20, hy - 6, 44, hy + 4], fill=CAP)
    d.rectangle([18, hy + 2, 44, hy + 6], fill=CAP)  # peak
    if eyes_x:
        for ex in (26, 34):
            d.line([(ex, hy + 8), (ex + 4, hy + 12)], fill=INK, width=2)
            d.line([(ex + 4, hy + 8), (ex, hy + 12)], fill=INK, width=2)
    else:
        d.ellipse([26, hy + 8, 30, hy + 12], fill=INK)
        d.ellipse([34, hy + 8, 38, hy + 12], fill=INK)

    return add_outline(im)


_WLK = [0, 1, 0, 1, 0, 1]
_WB  = [0, -1, 0, -1, 0, -1]
_CSE = [0, 1, 0, 1, 0, 1, 0, 1]
_CB  = [0, -1, 0, -1, 0, -1, 0, -1]


def anim_walk():
    return [f_sentry(leg_phase=_WLK[i], bob=_WB[i]) for i in range(6)]


def anim_chase():
    return [f_sentry(leg_phase=_CSE[i], bob=_CB[i], head_tilt=1,
                     weapon_pose="aim_low") for i in range(8)]


def anim_windup():
    # Raise weapon to fire position -- 6 frames, hold last two (aim_high).
    poses = ["aim_low", "aim_low", "aim_mid", "aim_high", "aim_high", "aim_high"]
    return [f_sentry(leg_phase=2, weapon_pose=poses[i], head_tilt=-1)
            for i in range(6)]


def anim_attack():
    # Fire: aim_high → muzzle flash frame 2 (per sprites.md) → recoil → lower.
    return [
        f_sentry(leg_phase=2, weapon_pose="aim_high", head_tilt=-1),
        f_sentry(leg_phase=2, weapon_pose="fired", muzzle_flash=True, head_tilt=-1),
        f_sentry(leg_phase=2, weapon_pose="aim_high", head_tilt=0),
        f_sentry(leg_phase=2, weapon_pose="lowering"),
    ]


def anim_recover():
    return [
        f_sentry(leg_phase=2, weapon_pose="lowering"),
        f_sentry(leg_phase=1, weapon_pose="holstered"),
        f_sentry(leg_phase=0, weapon_pose="holstered"),
        f_sentry(leg_phase=0, weapon_pose="holstered"),
    ]


def anim_hurt():
    return [
        f_sentry(leg_phase=1, bob=1, head_tilt=2, eyes_x=True, weapon_pose="lowering"),
        f_sentry(leg_phase=0, bob=2, head_tilt=3, eyes_x=True, weapon_pose="lowering"),
        f_sentry(leg_phase=1, bob=1, head_tilt=2, eyes_x=True, weapon_pose="holstered"),
        f_sentry(leg_phase=0, weapon_pose="holstered"),
    ]


def anim_death():
    frames = []
    frames.append(f_sentry(leg_phase=1, bob=1, head_tilt=2, eyes_x=True))
    frames.append(f_sentry(leg_phase=2, bob=4, head_tilt=4, eyes_x=True))
    for _ in range(6):
        frames.append(f_sentry(lying=True))
    return frames


def anim_alert():
    # Scanning sweep with weapon raised to aim_low.
    return [
        f_sentry(leg_phase=2, weapon_pose="aim_low", head_tilt=0),
        f_sentry(leg_phase=2, weapon_pose="aim_low", head_tilt=-2),
        f_sentry(leg_phase=2, weapon_pose="aim_mid", head_tilt=0),
        f_sentry(leg_phase=2, weapon_pose="aim_low", head_tilt=2),
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
    save_sheet([(name, fn()) for name, fn in ANIMS], T, T, "sentry.png")
