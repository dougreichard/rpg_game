#!/usr/bin/env python3
"""Viktor sprite sheet — Harbor & Docks harbourmaster.
Hi-vis orange vest, navy cap and pants, weathered skin, clipboard.
5 rows x 10 cols x 64x64 px RGBA.
"""
from PIL import Image, ImageDraw
from _sprite_common import INK, TR, tile, add_outline
from _sprite_npc_common import biped_front, eyes_front, save_npc_sheet

T = 64

VEST     = (245, 130,  35, 255)
VEST_SH  = (200, 100,  20, 255)
NAVY     = ( 30,  40,  80, 255)
NAVY_SH  = ( 18,  26,  55, 255)
SKIN     = (190, 150, 120, 255)
HAIR     = ( 80,  60,  40, 255)
CLIP     = (230, 220, 200, 255)


def _hair(d, hy, **kw):
    d.rectangle([23, hy, 41, hy + 5], fill=HAIR)
    d.rectangle([23, hy, 26, hy + 8], fill=NAVY)  # navy cap peak
    d.rectangle([22, hy - 2, 42, hy + 3], fill=NAVY)


def _acc(d, view, y):
    if view == "front":
        d.rectangle([46, 28 + y, 52, 42 + y], fill=CLIP)  # clipboard right arm
        d.line([(47, 28 + y), (51, 28 + y)], fill=INK, width=1)


def _idle(i):
    bobs = [0, -1, -1, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, VEST, VEST_SH, NAVY, bob=bobs[i],
                arm_r_raise=2, hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _idle_alt(i):
    bobs  = [0, -1, 0, 0, -1, 0]
    arm_r = [2, 5, 7, 5, 2, 2]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, VEST, VEST_SH, NAVY, bob=bobs[i], arm_r_raise=arm_r[i],
                hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _talk(i):
    bobs  = [0, -1, 0, -1, 0, 0]
    arm_l = [0, 3, 5, 5, 3, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, VEST, VEST_SH, NAVY, bob=bobs[i], arm_l_raise=arm_l[i],
                arm_r_raise=2, hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _gesture(i):
    bobs  = [0, -1, -1, 0, -1, 0]
    arm_l = [0, 3, 6, 8, 6, 3]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, VEST, VEST_SH, NAVY, bob=bobs[i], arm_l_raise=arm_l[i],
                arm_r_raise=2, hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _surprise(i):
    bobs  = [0, -2, -3, -2]
    arm_l = [0, 5, 8, 5]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, VEST, VEST_SH, NAVY, bob=bobs[i], arm_l_raise=arm_l[i],
                arm_r_raise=2, hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


if __name__ == "__main__":
    anims = [
        ("idle",         [_idle(i)     for i in range(4)]),
        ("idle_alt",     [_idle_alt(i) for i in range(6)]),
        ("talk_closeup", [_talk(i)     for i in range(6)]),
        ("gesture",      [_gesture(i)  for i in range(6)]),
        ("surprise",     [_surprise(i) for i in range(4)]),
    ]
    save_npc_sheet(anims, "viktor")
