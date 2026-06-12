#!/usr/bin/env python3
"""Uncle Doug sprite sheet — PIL procedural.
640x256 px RGBA (4 rows x 10 cols x 64x64).
Row order matches NPC_UNCLE_DOUG_ANIMS in SpriteLoader:
  0 idle (6)  1 wave (8)  2 talk (6)  3 talk_closeup (8)
"""
from PIL import Image, ImageDraw
from _sprite_common import INK, TR, tile, add_outline, NEUTRAL_GREY, NEUTRAL_LIGHT
from _sprite_npc_common import biped_front, eyes_front, save_npc_sheet

T = 64

# -- Palette --
SHIRT    = (184, 196, 208, 255)   # pale blue-grey collared shirt
SHIRT_SH = (148, 160, 172, 255)
SLACKS   = (110, 110, 126, 255)   # grey slacks
SKIN     = (212, 160, 122, 255)   # warm medium
SKIN_SH  = (180, 128,  92, 255)
STUBBLE  = (158, 158, 140, 255)   # grey stubble beard
GLASS_FR = (140, 140, 140, 255)   # glasses on chain
CHAIN    = (210, 190, 110, 255)   # thin gold chain


def _hair_balding(d, hy, **kw):
    """Balding — small patch of grey at temples, bare crown."""
    d.rectangle([23, hy, 27, hy + 10], fill=STUBBLE)
    d.rectangle([37, hy, 41, hy + 10], fill=STUBBLE)


def _beard_glasses(d, view, y):
    hy = 4 + y
    # Stubble beard — short grey patch on lower jaw
    d.rectangle([25, hy + 11, 39, hy + 18], fill=STUBBLE)
    # Glasses on nose
    d.ellipse([25, hy + 7, 31, hy + 13], outline=GLASS_FR, width=1)
    d.ellipse([33, hy + 7, 39, hy + 13], outline=GLASS_FR, width=1)
    d.line([(31, hy + 10), (33, hy + 10)], fill=GLASS_FR)
    # Glasses chain — hangs from each side down toward chest
    if view == "front":
        d.line([(25, hy + 10), (18, hy + 18)], fill=CHAIN, width=1)
        d.line([(39, hy + 10), (46, hy + 18)], fill=CHAIN, width=1)


def _idle(i):
    """Adjusts glasses (arm raise at 2-3); nervous glance (head tilt alt frames)."""
    bobs  = [0, -1, 0, 0, -1, 0]
    arm_r = [0,  0, 6, 6,  0, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, SHIRT, SHIRT_SH, SLACKS,
                leg_phase=0, bob=bobs[i], arm_r_raise=arm_r[i],
                hair_fn=_hair_balding, accessory_fn=_beard_glasses)
    return add_outline(im)


def _wave(i):
    """Both arms waving — wide relieved smile across frames 4-8."""
    bobs   = [0, -2, -3, -2, -1, -2, -3, -2]
    arm_l  = [0,  4,  8, 10,  8,  4,  8, 10]
    arm_r  = [0,  4,  8, 10,  8,  4,  8, 10]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, SHIRT, SHIRT_SH, SLACKS,
                leg_phase=0, bob=bobs[i],
                arm_l_raise=arm_l[i], arm_r_raise=arm_r[i],
                hair_fn=_hair_balding, accessory_fn=_beard_glasses)
    # Smile — rosy crease below nose at frame 4+
    if i >= 3:
        d.rectangle([27, 4 + bobs[i] + 13, 37, 4 + bobs[i] + 15], fill=SKIN_SH)
    return add_outline(im)


def _talk(i):
    bobs  = [0, -1, 0, 0, -1, 0]
    arm_r = [0,  3, 5, 4,  2, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, SHIRT, SHIRT_SH, SLACKS,
                leg_phase=0, bob=bobs[i], arm_r_raise=arm_r[i],
                hair_fn=_hair_balding, accessory_fn=_beard_glasses)
    return add_outline(im)


def _talk_closeup(i):
    """Glasses slightly askew at frames 3-5; thankful warm expression throughout."""
    bobs = [-14, -15, -14, -14, -15, -14, -14, -14]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, SHIRT, SHIRT_SH, SLACKS,
                leg_phase=0, bob=bobs[i],
                hair_fn=_hair_balding, accessory_fn=_beard_glasses)
    # Glasses slightly tilted at frames 3-5 — redraw one lens off-axis
    if 3 <= i <= 5:
        hy = 4 + bobs[i]
        d.ellipse([25, hy + 6, 31, hy + 12], outline=GLASS_FR, width=1)
        d.ellipse([33, hy + 8, 39, hy + 14], outline=GLASS_FR, width=1)
    # Warm expression — slight smile hint
    hy = 4 + bobs[i]
    d.rectangle([28, hy + 13, 36, hy + 15], fill=SKIN_SH)
    return add_outline(im)


if __name__ == "__main__":
    anims = [
        ("idle",         [_idle(i)           for i in range(6)]),
        ("wave",         [_wave(i)           for i in range(8)]),
        ("talk",         [_talk(i)           for i in range(6)]),
        ("talk_closeup", [_talk_closeup(i)   for i in range(8)]),
    ]
    save_npc_sheet(anims, "uncle_doug")
