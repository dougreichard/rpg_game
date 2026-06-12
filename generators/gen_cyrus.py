#!/usr/bin/env python3
"""Cyrus sprite sheet — Underground Tunnels maintenance worker.
Faded blue coveralls, yellow hard hat, tool belt, wiry build.
5 rows x 10 cols x 64x64 px RGBA.
"""
from PIL import Image, ImageDraw
from _sprite_common import INK, TR, tile, add_outline
from _sprite_npc_common import biped_front, eyes_front, save_npc_sheet

T = 64

CVRLL    = ( 80, 100, 140, 255)
CVRLL_SH = ( 55,  75, 110, 255)
HAT_Y    = (220, 185,  35, 255)
HAT_SH   = (170, 140,  20, 255)
SKIN     = (200, 165, 135, 255)
HAIR     = ( 60,  50,  40, 255)
BELT     = (110,  80,  40, 255)


def _hair(d, hy, **kw):
    d.rectangle([22, hy - 4, 42, hy + 2], fill=HAT_Y)
    d.rectangle([20, hy + 1, 44, hy + 5], fill=HAT_SH)  # brim


def _acc(d, view, y):
    if view == "front":
        d.rectangle([19, 40 + y, 45, 44 + y], fill=BELT)  # tool belt


def _idle(i):
    bobs = [0, -1, -1, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, CVRLL, CVRLL_SH, CVRLL, bob=bobs[i],
                hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _idle_alt(i):
    bobs  = [0, -1, 0, -1, 0, 0]
    arm_r = [0, 3, 5, 3, 1, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, CVRLL, CVRLL_SH, CVRLL, bob=bobs[i], arm_r_raise=arm_r[i],
                hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _talk(i):
    bobs  = [0, -1, 0, -1, 0, 0]
    arm_l = [0, 2, 4, 4, 2, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, CVRLL, CVRLL_SH, CVRLL, bob=bobs[i], arm_l_raise=arm_l[i],
                hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _gesture(i):
    bobs  = [0, -1, -1, 0, -1, 0]
    arm_r = [0, 3, 6, 8, 6, 3]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, CVRLL, CVRLL_SH, CVRLL, bob=bobs[i], arm_r_raise=arm_r[i],
                hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _surprise(i):
    bobs  = [0, -2, -3, -2]
    arm_l = [0, 5, 8, 5]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, CVRLL, CVRLL_SH, CVRLL, bob=bobs[i], arm_l_raise=arm_l[i],
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
    save_npc_sheet(anims, "cyrus")
