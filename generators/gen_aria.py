#!/usr/bin/env python3
"""ARIA sprite sheet — VR Escape Room AI guide.
Electric blue body, white panels, glitch-red flickers.
Digital avatar — no organic hair, geometric scan-lines, flickering.
5 rows x 10 cols x 64x64 px RGBA.
"""
from PIL import Image, ImageDraw
from _sprite_common import INK, TR, tile, add_outline
from _sprite_npc_common import biped_front, eyes_front, save_npc_sheet
import random

T = 64

BODY     = ( 30, 100, 220, 255)
BODY_SH  = ( 18,  65, 155, 255)
PANEL    = (210, 230, 255, 255)
GLITCH   = (220,  30,  50, 255)
SKINTONE = (140, 190, 250, 255)  # blue-tinted "skin"
SCAN     = ( 60, 120, 200, 100)


def _no_hair(d, hy, **kw):
    # Geometric head-frame — panels instead of hair
    d.rectangle([22, hy, 28, hy + 4], fill=PANEL)
    d.rectangle([36, hy, 42, hy + 4], fill=PANEL)


def _scanlines(d, y, glitch=False):
    for sy in range(4 + y, 62, 4):
        d.line([(19, sy), (45, sy)], fill=SCAN, width=1)
    if glitch:
        gx = 16 + (hash(str(y)) % 12)
        d.rectangle([gx, 20 + y, gx + 8, 24 + y], fill=GLITCH)


def _acc(d, view, y):
    _scanlines(d, y)


def _acc_glitch(d, view, y):
    _scanlines(d, y, glitch=True)


def _idle(i):
    bobs = [0, -1, -1, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKINTONE, BODY, BODY_SH, BODY, bob=bobs[i],
                hair_fn=_no_hair, accessory_fn=_acc)
    return add_outline(im)


def _idle_alt(i):
    bobs = [0, -1, 0, -1, 0, 0]
    glitch_frames = {1, 3}
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKINTONE, BODY, BODY_SH, BODY, bob=bobs[i],
                hair_fn=_no_hair,
                accessory_fn=_acc_glitch if i in glitch_frames else _acc)
    return add_outline(im)


def _talk(i):
    bobs  = [0, -1, 0, -1, 0, 0]
    arm_r = [0, 3, 5, 5, 3, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKINTONE, BODY, BODY_SH, BODY, bob=bobs[i], arm_r_raise=arm_r[i],
                hair_fn=_no_hair, accessory_fn=_acc)
    return add_outline(im)


def _gesture(i):
    bobs  = [0, -1, -1, 0, -1, 0]
    arm_l = [0, 4, 7, 9, 7, 4]
    glitch_f = {2}
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKINTONE, BODY, BODY_SH, BODY, bob=bobs[i], arm_l_raise=arm_l[i],
                hair_fn=_no_hair,
                accessory_fn=_acc_glitch if i in glitch_f else _acc)
    return add_outline(im)


def _surprise(i):
    bobs  = [0, -2, -3, -2]
    arm_l = [0, 5, 8, 5]
    arm_r = [0, 5, 8, 5]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKINTONE, BODY, BODY_SH, BODY, bob=bobs[i],
                arm_l_raise=arm_l[i], arm_r_raise=arm_r[i],
                hair_fn=_no_hair, accessory_fn=_acc_glitch)
    return add_outline(im)


if __name__ == "__main__":
    anims = [
        ("idle",         [_idle(i)     for i in range(4)]),
        ("idle_alt",     [_idle_alt(i) for i in range(6)]),
        ("talk_closeup", [_talk(i)     for i in range(6)]),
        ("gesture",      [_gesture(i)  for i in range(6)]),
        ("surprise",     [_surprise(i) for i in range(4)]),
    ]
    save_npc_sheet(anims, "aria")
