#!/usr/bin/env python3
"""Grunt sprite sheet -- PIL procedural, 64x64 spec (sprites.md "Grunt").
640 x 512 px RGBA (8 rows x 10 cols x 64x64), ENEMY_ANIMS row order:
walk(6) chase(8) windup(6) attack(4) recover(4) hurt(4) death(8) alert(4).

Stocky, anonymous thug -- dark grey jacket, navy trousers, red bandana
obscuring most of the face, blunt pipe weapon. Single 3/4 facing-right
pose per sprites.md ("no left-facing -- flip right in code"); Enemy FSM
plays the same animation regardless of horizontal direction and flips
sprite.flip_h for movement direction.
"""
from PIL import Image, ImageDraw
from _sprite_common import INK, TR, tile, add_outline, save_sheet

T = 64

# -- Palette (sprites.md "Grunt -> Palette") --
JACKET     = ( 92,  92, 110, 255)  # #5C5C6E
JACKET_SH  = ( 70,  70,  86, 255)
TROUSER    = ( 47,  74, 153, 255)  # #2F4A99
TROUSER_SH = ( 36,  58, 122, 255)
BANDANA    = (225,  59,  74, 255)  # #E13B4A
BANDANA_SH = (180,  46,  58, 255)
SKIN       = (217, 163, 110, 255)  # #D9A36E
SKIN_SH    = (184, 133,  87, 255)
PIPE       = (168, 168, 184, 255)  # #A8A8B8
PIPE_SH    = (130, 130, 146, 255)


def f_grunt(leg_phase=0, bob=0, head_tilt=0, arm_pose="idle", eyes_x=False,
            fall=0, lying=False):
    """One 64x64 frame. arm_pose in {"idle","raise1","raise2","raise3",
    "hold","swing","low"}. fall/lying drive the death sequence."""
    im = tile(); d = ImageDraw.Draw(im)

    if lying:
        # Flattened heap on the ground, head to the right.
        d.ellipse([8, 44, 52, 60], fill=JACKET)
        d.ellipse([8, 52, 52, 60], fill=JACKET_SH)
        d.rectangle([40, 42, 58, 54], fill=SKIN)
        d.rectangle([48, 46, 58, 54], fill=SKIN_SH)
        d.rectangle([38, 36, 56, 44], fill=BANDANA)
        d.line([(50, 46), (54, 50)], fill=INK, width=2)
        d.line([(54, 46), (50, 50)], fill=INK, width=2)
        d.rectangle([4, 40, 10, 56], fill=PIPE)  # dropped pipe
        return add_outline(im)

    y = bob + fall

    # Legs
    if leg_phase == 0:
        d.rectangle([24, 44 + y, 32, 60 + y], fill=TROUSER)
        d.rectangle([34, 46 + y, 42, 60 + y], fill=TROUSER)
        d.rectangle([24, 54 + y, 32, 60 + y], fill=TROUSER_SH)
        d.rectangle([34, 54 + y, 42, 60 + y], fill=TROUSER_SH)
    elif leg_phase == 1:
        d.rectangle([24, 46 + y, 32, 60 + y], fill=TROUSER)
        d.rectangle([34, 44 + y, 42, 60 + y], fill=TROUSER)
        d.rectangle([24, 54 + y, 32, 60 + y], fill=TROUSER_SH)
        d.rectangle([34, 54 + y, 42, 60 + y], fill=TROUSER_SH)
    else:  # braced / wide stance
        d.rectangle([20, 46 + y, 28, 60 + y], fill=TROUSER)
        d.rectangle([38, 46 + y, 46, 60 + y], fill=TROUSER)
        d.rectangle([20, 54 + y, 28, 60 + y], fill=TROUSER_SH)
        d.rectangle([38, 54 + y, 46, 60 + y], fill=TROUSER_SH)

    # Back arm (under torso) -- usually still
    d.rectangle([16, 30 + y, 22, 42 + y], fill=JACKET_SH)

    # Torso / jacket
    d.rectangle([18, 26 + y, 46, 46 + y], fill=JACKET)
    d.rectangle([18, 38 + y, 46, 46 + y], fill=JACKET_SH)

    # Weapon + front arm, behind-or-ahead depending on pose
    if arm_pose == "idle":
        d.rectangle([44, 30 + y, 50, 42 + y], fill=SKIN)
        d.rectangle([46, 40 + y, 52, 60 + y], fill=PIPE)
        d.rectangle([46, 54 + y, 52, 60 + y], fill=PIPE_SH)
    elif arm_pose == "raise1":
        d.rectangle([44, 26 + y, 50, 38 + y], fill=SKIN)
        d.rectangle([46, 14 + y, 52, 38 + y], fill=PIPE)
        d.rectangle([46, 14 + y, 52, 20 + y], fill=PIPE_SH)
    elif arm_pose == "raise2":
        d.rectangle([42, 20 + y, 48, 34 + y], fill=SKIN)
        d.rectangle([42, 4 + y, 50, 28 + y], fill=PIPE)
        d.rectangle([42, 4 + y, 50, 10 + y], fill=PIPE_SH)
    elif arm_pose in ("raise3", "hold"):
        d.rectangle([40, 16 + y, 46, 30 + y], fill=SKIN)
        d.rectangle([38, 0 + y, 46, 24 + y], fill=PIPE)
        d.rectangle([38, 0 + y, 46, 6 + y], fill=PIPE_SH)
        if arm_pose == "hold":
            # small shake on the held frames
            pass
    elif arm_pose == "swing":
        # Weapon swept low/forward across the body.
        d.rectangle([46, 36 + y, 60, 42 + y], fill=SKIN)
        d.rectangle([48, 40 + y, 64, 48 + y], fill=PIPE)
        d.rectangle([48, 44 + y, 64, 48 + y], fill=PIPE_SH)
    elif arm_pose == "low":
        d.rectangle([44, 34 + y, 50, 46 + y], fill=SKIN)
        d.rectangle([46, 44 + y, 52, 60 + y], fill=PIPE)
        d.rectangle([46, 54 + y, 52, 60 + y], fill=PIPE_SH)

    # Head + bandana
    hy = 8 + y + head_tilt
    d.rectangle([22, hy, 42, hy + 18], fill=SKIN)
    d.rectangle([22, hy + 10, 42, hy + 18], fill=SKIN_SH)
    d.rectangle([20, hy - 2, 44, hy + 8], fill=BANDANA)
    d.rectangle([20, hy + 4, 44, hy + 8], fill=BANDANA_SH)
    d.rectangle([40, hy - 2, 46, hy + 4], fill=BANDANA)  # knot tail
    # Eyes
    if eyes_x:
        for ex in (27, 35):
            d.line([(ex, hy + 10), (ex + 4, hy + 14)], fill=INK, width=2)
            d.line([(ex + 4, hy + 10), (ex, hy + 14)], fill=INK, width=2)
    else:
        d.ellipse([26, hy + 10, 30, hy + 14], fill=INK)
        d.ellipse([34, hy + 10, 38, hy + 14], fill=INK)

    return add_outline(im)


# -- Animations --------------------------------------------------------

_WALK_PHASE = [0, 1, 0, 1, 0, 1]
_WALK_BOB   = [0, -1, 0, -1, 0, -1]


def anim_walk():
    return [f_grunt(leg_phase=_WALK_PHASE[i], bob=_WALK_BOB[i]) for i in range(6)]


_CHASE_PHASE = [0, 1, 0, 1, 0, 1, 0, 1]
_CHASE_BOB   = [0, -2, 0, -2, 0, -2, 0, -2]


def anim_chase():
    return [f_grunt(leg_phase=_CHASE_PHASE[i], bob=_CHASE_BOB[i], head_tilt=1,
                     arm_pose="low") for i in range(8)]


def anim_windup():
    # 6 frames: raise progressively, hold the last two (sprites.md: "hold
    # frames 5-6").
    poses = ["raise1", "raise2", "raise3", "hold", "hold", "hold"]
    return [f_grunt(leg_phase=2, arm_pose=p, head_tilt=-1) for p in poses]


def anim_attack():
    return [
        f_grunt(leg_phase=2, arm_pose="hold", head_tilt=-1),
        f_grunt(leg_phase=2, arm_pose="swing", head_tilt=1, bob=1),
        f_grunt(leg_phase=2, arm_pose="swing", head_tilt=1, bob=1),
        f_grunt(leg_phase=2, arm_pose="low", head_tilt=0),
    ]


def anim_recover():
    return [
        f_grunt(leg_phase=2, arm_pose="low"),
        f_grunt(leg_phase=1, arm_pose="idle"),
        f_grunt(leg_phase=0, arm_pose="idle"),
        f_grunt(leg_phase=0, arm_pose="idle", bob=0),
    ]


def anim_hurt():
    return [
        f_grunt(leg_phase=1, head_tilt=2, eyes_x=True, bob=1),
        f_grunt(leg_phase=0, head_tilt=3, eyes_x=True, bob=2),
        f_grunt(leg_phase=1, head_tilt=2, eyes_x=True, bob=1),
        f_grunt(leg_phase=0, head_tilt=0, bob=0),
    ]


def anim_death():
    frames = []
    frames.append(f_grunt(leg_phase=1, head_tilt=2, eyes_x=True, bob=1))
    frames.append(f_grunt(leg_phase=2, head_tilt=4, eyes_x=True, fall=6))
    for _ in range(6):
        frames.append(f_grunt(lying=True))
    return frames


def anim_alert():
    return [
        f_grunt(leg_phase=2, head_tilt=0, arm_pose="idle"),
        f_grunt(leg_phase=2, head_tilt=-2, arm_pose="idle"),
        f_grunt(leg_phase=2, head_tilt=0, arm_pose="idle"),
        f_grunt(leg_phase=2, head_tilt=2, arm_pose="idle"),
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
    save_sheet([(name, fn()) for name, fn in ANIMS], T, T, "grunt.png")
