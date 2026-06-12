#!/usr/bin/env python3
"""Father Aldric sprite sheet — PIL procedural.
640x320 px RGBA (5 rows x 10 cols x 64x64).
Row order matches NPC_ALDRIC_ANIMS in SpriteLoader:
  0 idle (6)  1 talk (6)  2 talk_pleased (8)  3 talk_amused (8)  4 talk_annoyed (6)
"""
from PIL import Image, ImageDraw
from _sprite_common import INK, TR, tile, add_outline
from _sprite_npc_common import biped_front, eyes_front, save_npc_sheet

T = 64

# -- Palette --
CASSOCK    = ( 46,  46,  58, 255)   # #2E2E3A near-black cassock
CASSOCK_SH = ( 30,  30,  40, 255)   # deeper shadow
COLLAR     = (244, 240, 230, 255)   # #F4F0E6 white collar
SKIN       = (212, 168, 122, 255)   # #D4A87A aged warm skin
SKIN_SH    = (180, 136,  96, 255)
HAIR       = (240, 238, 232, 255)   # #F0EEE8 white hair

# Small smile color (slightly rosier skin patch below nose)
SMILE_SH   = (224, 144, 108, 255)


def _hair(d, hy, **kw):
    """White hair, slightly receded at temples — round and a little full."""
    d.rectangle([23, hy, 41, hy + 8], fill=HAIR)
    d.rectangle([20, hy + 4, 24, hy + 14], fill=HAIR)   # left temple
    d.rectangle([40, hy + 4, 44, hy + 14], fill=HAIR)   # right temple


def _collar(d, view, y):
    """White clerical collar strip at neckline."""
    d.rectangle([27, 22 + y, 37, 26 + y], fill=COLLAR)


def _idle(i):
    bobs  = [0, -1, -1, 0, 0, -1]
    # Hands clasped — both arms slightly raised toward center
    arm_l = [2, 2, 3, 2, 2, 2]
    arm_r = [2, 3, 3, 2, 2, 2]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, CASSOCK, CASSOCK_SH, CASSOCK,
                leg_phase=0, bob=bobs[i],
                arm_l_raise=arm_l[i], arm_r_raise=arm_r[i],
                hair_fn=_hair, accessory_fn=_collar)
    return add_outline(im)


def _talk(i):
    bobs  = [0, -1, 0, 0, -1, 0]
    arm_r = [0, 3, 5, 5, 3, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, CASSOCK, CASSOCK_SH, CASSOCK,
                leg_phase=0, bob=bobs[i], arm_r_raise=arm_r[i],
                hair_fn=_hair, accessory_fn=_collar)
    return add_outline(im)


def _pleased(i):
    """Warm and welcoming — slight head bob, arm slightly raised, small smile hint."""
    bobs  = [-14, -15, -15, -14, -14, -15, -14, -14]
    arm_r = [  0,   0,   3,   4,   4,   3,   1,   0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, CASSOCK, CASSOCK_SH, CASSOCK,
                leg_phase=0, bob=bobs[i], arm_r_raise=arm_r[i],
                hair_fn=_hair, accessory_fn=_collar)
    # Warm smile at frames 5-8 — small rosy crease below mouth
    if i >= 4:
        d.rectangle([28, 4 + bobs[i] + 14, 36, 4 + bobs[i] + 16], fill=SMILE_SH)
    return add_outline(im)


def _amused(i):
    """Knowing half-smile — slight eyebrow raise, minimal movement."""
    bobs   = [-14, -14, -15, -14, -14, -15, -14, -14]
    leans  = [  0,   0,   1,   1,   0,   0,   0,   0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, CASSOCK, CASSOCK_SH, CASSOCK,
                leg_phase=0, bob=bobs[i],
                hair_fn=_hair, accessory_fn=_collar)
    # Raised eyebrow (small dark stroke above left eye)
    d.line([(25, 4 + bobs[i] + 5), (30, 4 + bobs[i] + 4)], fill=INK, width=1)
    return add_outline(im)


def _annoyed(i):
    """Pinched lips, no warm gestures, forward stillness."""
    bobs = [-14, -14, -14, -14, -14, -14]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, CASSOCK, CASSOCK_SH, CASSOCK,
                leg_phase=0, bob=bobs[i],
                hair_fn=_hair, accessory_fn=_collar)
    # Pressed / pinched lips — thin dark horizontal stroke
    d.line([(27, 4 + bobs[i] + 14), (37, 4 + bobs[i] + 14)], fill=INK, width=1)
    return add_outline(im)


if __name__ == "__main__":
    anims = [
        ("idle",         [_idle(i)    for i in range(6)]),
        ("talk",         [_talk(i)    for i in range(6)]),
        ("talk_pleased", [_pleased(i) for i in range(8)]),
        ("talk_amused",  [_amused(i)  for i in range(8)]),
        ("talk_annoyed", [_annoyed(i) for i in range(6)]),
    ]
    save_npc_sheet(anims, "father_aldric")
