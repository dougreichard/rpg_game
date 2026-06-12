#!/usr/bin/env python3
"""Lena sprite sheet — Zip Line Park attendant.
Teal branded polo, dark pants, brown ponytail, clipboard.
5 rows x 10 cols x 64x64 px RGBA.
"""
from PIL import Image, ImageDraw
from _sprite_common import INK, TR, tile, add_outline
from _sprite_npc_common import biped_front, eyes_front, save_npc_sheet

T = 64

TEAL     = ( 40, 160, 150, 255)
TEAL_SH  = ( 25, 120, 112, 255)
PANTS    = ( 55,  55,  70, 255)
SKIN     = (230, 195, 170, 255)
HAIR_B   = ( 90,  62,  36, 255)
CLIP     = (230, 220, 200, 255)


def _hair(d, hy, **kw):
    d.rectangle([23, hy, 41, hy + 5], fill=HAIR_B)
    # Ponytail to the right side
    d.rectangle([39, hy + 5, 44, hy + 16], fill=HAIR_B)


def _acc(d, view, y):
    if view == "front":
        d.rectangle([46, 26 + y, 52, 40 + y], fill=CLIP)
        d.line([(47, 26 + y), (51, 26 + y)], fill=INK, width=1)


def _idle(i):
    bobs = [0, -1, -1, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, TEAL, TEAL_SH, PANTS, bob=bobs[i],
                arm_r_raise=2, hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _idle_alt(i):
    bobs  = [0, -1, -2, -1, 0, 0]
    arm_r = [2, 4, 6, 4, 2, 2]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, TEAL, TEAL_SH, PANTS, bob=bobs[i], arm_r_raise=arm_r[i],
                hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _talk(i):
    bobs  = [0, -1, 0, -1, -1, 0]
    arm_l = [0, 3, 5, 5, 3, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, TEAL, TEAL_SH, PANTS, bob=bobs[i], arm_l_raise=arm_l[i],
                arm_r_raise=2, hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _gesture(i):
    bobs  = [0, -1, -2, -1, 0, 0]
    arm_l = [0, 4, 7, 9, 7, 4]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, TEAL, TEAL_SH, PANTS, bob=bobs[i], arm_l_raise=arm_l[i],
                arm_r_raise=2, hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _surprise(i):
    bobs  = [0, -2, -3, -2]
    arm_l = [0, 5, 8, 5]
    arm_r = [2, 5, 6, 5]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, TEAL, TEAL_SH, PANTS, bob=bobs[i],
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
    save_npc_sheet(anims, "lena")
