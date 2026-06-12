#!/usr/bin/env python3
"""Rio sprite sheet — The Drop ground-crew defector.
Olive flight jacket, worn tan vest, dark brown hair, radio clipped to vest.
5 rows x 10 cols x 64x64 px RGBA.
"""
from PIL import Image, ImageDraw
from _sprite_common import INK, TR, tile, add_outline
from _sprite_npc_common import biped_front, eyes_front, save_npc_sheet

T = 64

JACKET   = ( 80, 100,  50, 255)
JACKET_SH= ( 58,  74,  34, 255)
VEST     = (185, 160, 110, 255)  # worn tan
VEST_SH  = (150, 128,  85, 255)
SKIN     = (195, 158, 125, 255)
HAIR     = ( 70,  48,  30, 255)  # dark brown
RADIO    = ( 55,  60,  70, 255)  # dark radio unit
RADIO_L  = (120, 200, 100, 255)  # indicator light


def _hair(d, hy, **kw):
    d.rectangle([22, hy, 42, hy + 7], fill=HAIR)
    d.rectangle([22, hy + 7, 25, hy + 12], fill=HAIR)  # left sideburn
    d.rectangle([39, hy + 7, 42, hy + 12], fill=HAIR)  # right sideburn


def _acc(d, view, y):
    if view == "front":
        # Radio clipped to vest, left chest
        d.rectangle([19, 28 + y, 25, 36 + y], fill=RADIO)
        d.rectangle([20, 28 + y, 21, 29 + y], fill=RADIO_L)  # indicator


def _idle(i):
    bobs = [0, -1, -1, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, JACKET, JACKET_SH, JACKET, bob=bobs[i],
                hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _idle_alt(i):
    bobs  = [0, -1, 0, -1, 0, 0]
    arm_r = [0, 2, 4, 2, 0, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, JACKET, JACKET_SH, JACKET, bob=bobs[i], arm_r_raise=arm_r[i],
                hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _talk(i):
    bobs  = [0, -1, 0, -1, 0, 0]
    arm_l = [0, 3, 5, 5, 3, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, JACKET, JACKET_SH, JACKET, bob=bobs[i], arm_l_raise=arm_l[i],
                hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _gesture(i):
    bobs  = [0, -1, -1, 0, -1, 0]
    arm_r = [0, 4, 7, 9, 7, 4]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, JACKET, JACKET_SH, JACKET, bob=bobs[i], arm_r_raise=arm_r[i],
                hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _surprise(i):
    bobs  = [0, -2, -3, -2]
    arm_l = [0, 5, 8, 5]
    arm_r = [0, 5, 8, 5]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, JACKET, JACKET_SH, JACKET, bob=bobs[i],
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
    save_npc_sheet(anims, "rio")
