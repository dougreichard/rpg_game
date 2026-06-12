#!/usr/bin/env python3
"""Runner sprite sheet -- PIL procedural, 64x64 spec (sprites.md "Runner").
640 x 512 px RGBA (8 rows x 10 cols x 64x64), ENEMY_ANIMS row order:
walk(6) chase(8) windup(4) attack(3) recover(4) hurt(3) death(6) alert(5->padded).

Lean, fast, manic -- cyan tracksuit, white stripe, dark boots, no weapon,
dashes in and jabs/kicks. Single 3/4 facing-right pose; flip_h for left.
"""
from PIL import Image, ImageDraw
from _sprite_common import INK, TR, tile, add_outline, save_sheet

T = 64

TRACK      = ( 94, 214, 255, 255)  # #5ED6FF cyan tracksuit
TRACK_SH   = ( 60, 170, 210, 255)
STRIPE     = (244, 240, 230, 255)  # #F4F0E6 white stripe
BOOT       = ( 26,  26,  34, 255)  # #1A1A22 near-black boots
SKIN       = (242, 196, 155, 255)  # #F2C49B
SKIN_SH    = (210, 160, 118, 255)
HAIR       = ( 24,  20,  26, 255)  # #18141A


def f_runner(leg_phase=0, bob=0, head_tilt=0, lean=0, arm_fwd=0, kick=False,
             eyes_x=False, lying=False):
    """lean: extra x-offset applied to head/upper body for forward dash lean.
    arm_fwd: front arm raised forward (0=swing, 1=out, 2=punch). kick: foot
    out for attack frame."""
    im = tile(); d = ImageDraw.Draw(im)

    if lying:
        d.ellipse([6, 42, 50, 58], fill=TRACK)
        d.ellipse([6, 50, 50, 58], fill=TRACK_SH)
        d.rectangle([38, 40, 56, 52], fill=SKIN)
        d.rectangle([10, 38, 20, 50], fill=BOOT)
        d.rectangle([4, 36, 14, 44], fill=TRACK)
        d.line([(46, 42), (50, 46)], fill=INK, width=2)
        d.line([(50, 42), (46, 46)], fill=INK, width=2)
        return add_outline(im)

    y = bob

    # Boots / feet
    boff = 4 if leg_phase == 0 else 0
    d.rectangle([24, 52 + boff + y, 32, 62], fill=BOOT)
    d.rectangle([36, 52 + (4 - boff) + y, 44, 62], fill=BOOT)

    # Legs (thin, lean)
    if leg_phase == 0:
        d.rectangle([26, 44 + y, 32, 54 + y], fill=TRACK)
        d.rectangle([36, 46 + y, 42, 54 + y], fill=TRACK)
    elif leg_phase == 1:
        d.rectangle([26, 46 + y, 32, 54 + y], fill=TRACK)
        d.rectangle([36, 44 + y, 42, 54 + y], fill=TRACK)
    else:  # kick
        d.rectangle([22, 44 + y, 28, 56 + y], fill=TRACK)
        d.rectangle([36, 44 + y, 58, 52 + y], fill=TRACK)  # kicking leg out
        d.rectangle([54, 48 + y, 60, 54 + y], fill=BOOT)

    lx = lean

    # Back arm
    d.rectangle([16 + lx, 28 + y, 22 + lx, 40 + y], fill=TRACK_SH)

    # Torso / tracksuit -- slim
    d.rectangle([22 + lx, 26 + y, 44 + lx, 46 + y], fill=TRACK)
    d.rectangle([22 + lx, 38 + y, 44 + lx, 46 + y], fill=TRACK_SH)
    # White stripe down side
    d.rectangle([26 + lx, 26 + y, 28 + lx, 46 + y], fill=STRIPE)

    # Front arm
    if arm_fwd == 0:  # normal swing
        d.rectangle([42 + lx, 30 + y, 48 + lx, 44 + y], fill=SKIN)
    elif arm_fwd == 1:  # reaching forward / guard
        d.rectangle([44 + lx, 26 + y, 52 + lx, 36 + y], fill=SKIN)
    elif arm_fwd == 2:  # full punch forward
        d.rectangle([44 + lx, 24 + y, 58 + lx, 32 + y], fill=SKIN)

    # Head -- lean / elongated
    hy = 8 + y + head_tilt
    hx = lx
    d.rectangle([24 + hx, hy, 42 + hx, hy + 18], fill=SKIN)
    d.rectangle([24 + hx, hy + 10, 42 + hx, hy + 18], fill=SKIN_SH)
    d.rectangle([22 + hx, hy - 6, 44 + hx, hy + 4], fill=HAIR)
    if eyes_x:
        for ex in (27, 35):
            d.line([(ex + hx, hy + 8), (ex + 4 + hx, hy + 12)], fill=INK, width=2)
            d.line([(ex + 4 + hx, hy + 8), (ex + hx, hy + 12)], fill=INK, width=2)
    else:
        d.ellipse([26 + hx, hy + 8, 30 + hx, hy + 12], fill=INK)
        d.ellipse([34 + hx, hy + 8, 38 + hx, hy + 12], fill=INK)

    return add_outline(im)


_TROT = [0, 1, 0, 1, 0, 1]
_BOB  = [0, -1, 0, -1, 0, -1]
_SPRINT = [0, 1, 0, 1, 0, 1, 0, 1]
_SBOB   = [0, -2, -1, -2, 0, -2, -1, -2]


def anim_walk():
    return [f_runner(leg_phase=_TROT[i], bob=_BOB[i]) for i in range(6)]


def anim_chase():
    return [f_runner(leg_phase=_SPRINT[i], bob=_SBOB[i], lean=3, head_tilt=2,
                     arm_fwd=1) for i in range(8)]


def anim_windup():
    # Short sharp crouch before jab/kick -- padded to 6 frames to match
    # ENEMY_ANIMS windup count (SpriteLoader slices exactly that many).
    return [
        f_runner(leg_phase=0, bob=0, arm_fwd=0),
        f_runner(leg_phase=0, bob=2, arm_fwd=1, head_tilt=1),
        f_runner(leg_phase=0, bob=2, arm_fwd=1, head_tilt=1),
        f_runner(leg_phase=2, bob=2, arm_fwd=1, head_tilt=1),
        f_runner(leg_phase=2, bob=2, arm_fwd=1, head_tilt=1),
        f_runner(leg_phase=2, bob=2, arm_fwd=1, head_tilt=1),
    ]


def anim_attack():
    # 4 frames: lunge / jab / jab-hold / pullback (ENEMY_ANIMS attack=4).
    return [
        f_runner(leg_phase=2, bob=1, arm_fwd=2, lean=4, head_tilt=2),
        f_runner(leg_phase=2, bob=1, arm_fwd=2, lean=4, head_tilt=2),
        f_runner(leg_phase=2, bob=1, arm_fwd=2, lean=3, head_tilt=2),
        f_runner(leg_phase=1, bob=0, arm_fwd=0),
    ]


def anim_recover():
    return [
        f_runner(leg_phase=1, bob=0, arm_fwd=1),
        f_runner(leg_phase=0, bob=0, arm_fwd=0),
        f_runner(leg_phase=0, bob=0),
        f_runner(leg_phase=0, bob=-1),
    ]


def anim_hurt():
    # Padded to 4 frames to match ENEMY_ANIMS hurt count.
    return [
        f_runner(leg_phase=1, bob=2, head_tilt=2, eyes_x=True),
        f_runner(leg_phase=0, bob=3, head_tilt=3, eyes_x=True),
        f_runner(leg_phase=0, bob=1, eyes_x=True),
        f_runner(leg_phase=0, bob=0),
    ]


def anim_death():
    # Padded to 8 frames to match ENEMY_ANIMS death count.
    frames = []
    frames.append(f_runner(leg_phase=1, bob=2, head_tilt=2, eyes_x=True))
    frames.append(f_runner(leg_phase=2, bob=6, head_tilt=4, eyes_x=True))
    for _ in range(6):
        frames.append(f_runner(lying=True))
    return frames


def anim_alert():
    # Bouncing on toes, head snapping side to side.
    return [
        f_runner(leg_phase=0, bob=0, head_tilt=0),
        f_runner(leg_phase=1, bob=-1, head_tilt=-2),
        f_runner(leg_phase=0, bob=0, head_tilt=0),
        f_runner(leg_phase=1, bob=-1, head_tilt=2),
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
    save_sheet([(name, fn()) for name, fn in ANIMS], T, T, "runner.png")
