#!/usr/bin/env python3
"""Cecil sprite sheet — Grand Marquee Cinema chief usher.
Scarlet military jacket, gold buttons/trim, pillbox hat, black trousers, torch.
5 rows x 10 cols x 64x64 px RGBA.
"""
from PIL import Image, ImageDraw
from _sprite_common import INK, TR, tile, add_outline
from _sprite_npc_common import biped_front, eyes_front, save_npc_sheet

T = 64

JACKET   = (185,  28,  35, 255)   # scarlet red
JACKET_SH= (120,  16,  22, 255)   # shadow
GOLD     = (195, 158,  42, 255)   # buttons, hat band, epaulette trim
PANTS    = ( 28,  28,  40, 255)   # near-black trousers
SKIN     = (215, 180, 148, 255)
HAIR     = ( 45,  35,  28, 255)   # dark hair
TORCH    = (205, 190, 115, 255)   # usher's flashlight body


def _hair(d, hy, **kw):
    # Pillbox hat: flat scarlet crown + wide gold band/brim
    d.rectangle([23, hy - 4, 41, hy + 1], fill=JACKET)    # crown
    d.rectangle([21, hy + 1, 43, hy + 6], fill=GOLD)       # gold band / brim


def _epaulettes(d, y):
    # Small shoulder decoration on both sides
    d.rectangle([18, 22 + y, 22, 25 + y], fill=GOLD)
    d.rectangle([42, 22 + y, 46, 25 + y], fill=GOLD)


def _acc(d, view, y):
    if view == "front":
        _epaulettes(d, y)
        # Three gold buttons down jacket centre
        d.ellipse([29, 26 + y, 32, 29 + y], fill=GOLD)
        d.ellipse([29, 31 + y, 32, 34 + y], fill=GOLD)
        d.ellipse([29, 36 + y, 32, 39 + y], fill=GOLD)
        # Torch carried in the right hand (arm slightly raised)
        d.rectangle([45, 32 + y, 48, 44 + y], fill=TORCH)
        d.rectangle([44, 28 + y, 49, 33 + y], fill=GOLD)  # torch head/lens


def _idle(i):
    bobs = [0, -1, -1, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, JACKET, JACKET_SH, PANTS, bob=bobs[i],
                arm_r_raise=2, hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _idle_alt(i):
    bobs  = [0, -1, 0, -1, 0, 0]
    arm_r = [2, 4, 6, 4, 2, 2]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, JACKET, JACKET_SH, PANTS, bob=bobs[i], arm_r_raise=arm_r[i],
                hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _talk(i):
    bobs  = [0, -1, 0, -1, 0, 0]
    arm_l = [0, 3, 5, 5, 3, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, JACKET, JACKET_SH, PANTS, bob=bobs[i], arm_l_raise=arm_l[i],
                arm_r_raise=2, hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _gesture(i):
    bobs  = [0, -1, -1, 0, -1, 0]
    arm_l = [0, 4, 7, 9, 7, 4]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, JACKET, JACKET_SH, PANTS, bob=bobs[i], arm_l_raise=arm_l[i],
                arm_r_raise=2, hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _surprise(i):
    bobs  = [0, -2, -3, -2]
    arm_l = [0, 5, 8, 5]
    arm_r = [2, 5, 7, 5]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, JACKET, JACKET_SH, PANTS, bob=bobs[i],
                arm_l_raise=arm_l[i], arm_r_raise=arm_r[i],
                hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


if __name__ == "__main__":
    anims = [
        ("idle",         [_idle(i)     for i in range(4)]),
        ("idle_alt",     [_idle_alt(i) for i in range(6)]),
        ("talk_closeup", [_talk(i)     for i in range(6)]),
        ("gesture",      [_gesture(i)  for i in range(6)]),
        ("surprise",     [_surprise(i) for i in range(4)]),
    ]
    save_npc_sheet(anims, "usher")
