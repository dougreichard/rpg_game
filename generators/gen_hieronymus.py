#!/usr/bin/env python3
"""Hieronymus sprite sheet — Clocktower clockmaker.
Warm grey coat, brass-gold trim, silver hair, wire-rimmed glasses.
5 rows x 10 cols x 64x64 px RGBA.
"""
from PIL import Image, ImageDraw
from _sprite_common import INK, TR, tile, add_outline
from _sprite_npc_common import biped_front, eyes_front, save_npc_sheet

T = 64

COAT     = (112, 100,  88, 255)
COAT_SH  = ( 80,  70,  62, 255)
GOLD     = (180, 140,  50, 255)
SKIN     = (224, 190, 158, 255)
HAIR     = (220, 218, 212, 255)  # silver-white
PANTS    = ( 86,  76,  68, 255)


def _hair(d, hy, **kw):
    d.rectangle([20, hy, 44, hy + 6], fill=HAIR)
    d.rectangle([20, hy + 6, 25, hy + 14], fill=HAIR)
    d.rectangle([39, hy + 6, 44, hy + 14], fill=HAIR)


def _glasses(d, hy):
    d.rectangle([23, hy + 8, 29, hy + 13], outline=GOLD, width=1)
    d.rectangle([35, hy + 8, 41, hy + 13], outline=GOLD, width=1)
    d.line([(29, hy + 10), (35, hy + 10)], fill=GOLD, width=1)


def _acc(d, view, y):
    _glasses(d, 4 + y)
    if view == "front":
        d.rectangle([28, 36 + y, 32, 44 + y], fill=GOLD)  # pocket-watch chain


def _idle(i):
    bobs = [0, -1, -1, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, COAT, COAT_SH, PANTS, bob=bobs[i],
                hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _idle_alt(i):
    bobs   = [0, -1, 0, 0, -1, 0]
    arm_r  = [0, 0, 4, 6, 4, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, COAT, COAT_SH, PANTS, bob=bobs[i], arm_r_raise=arm_r[i],
                hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _talk(i):
    bobs  = [0, -1, 0, -1, 0, 0]
    arm_r = [0, 3, 5, 5, 3, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, COAT, COAT_SH, PANTS, bob=bobs[i], arm_r_raise=arm_r[i],
                hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _gesture(i):
    bobs  = [0, -1, -1, 0, -1, 0]
    arm_l = [0, 2, 4, 6, 4, 2]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, COAT, COAT_SH, PANTS, bob=bobs[i], arm_l_raise=arm_l[i],
                hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _surprise(i):
    bobs  = [0, -2, -3, -2]
    arm_l = [0, 4, 6, 4]
    arm_r = [0, 4, 6, 4]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, COAT, COAT_SH, PANTS, bob=bobs[i],
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
    save_npc_sheet(anims, "hieronymus")
