#!/usr/bin/env python3
"""Carnival Guard sprite sheet — PIL procedural.
640x256 px RGBA (4 rows x 10 cols x 64x64).
Row order matches NPC_GATEKEEPER_ANIMS in SpriteLoader:
  0 idle (6)  1 refuse (6)  2 step_aside (8)  3 talk_closeup (6)
"""
from PIL import Image, ImageDraw
from _sprite_common import INK, TR, tile, add_outline, NEUTRAL_DARK, AMBER
from _sprite_npc_common import biped_front, biped_side, eyes_front, save_npc_sheet

T = 64

# -- Palette --
JACKET    = (204,  51,  51, 255)   # red circus jacket
JACKET_SH = (158,  36,  36, 255)
BRAID     = (200, 168,  58, 255)   # gold braid trim
TROUSERS  = ( 30,  30,  42, 255)   # near-black trousers
CAP_COL   = (174,  36,  36, 255)   # flat cap (darker red)
SKIN      = (212, 160, 122, 255)   # medium warm
HAIR      = ( 92,  74,  54, 255)   # brown, barely visible under cap


def _hair_cap(d, hy, **kw):
    """Flat cap sitting on top of head."""
    # Cap brim
    d.rectangle([19, hy + 3, 45, hy + 7], fill=NEUTRAL_DARK)   # brim
    # Cap crown
    d.rectangle([22, hy - 3, 42, hy + 6], fill=CAP_COL)
    # Badge — small gold dot on front of cap
    d.ellipse([30, hy - 1, 34, hy + 3], fill=BRAID)


def _braid_acc(d, view, y):
    """Gold braid along jacket front."""
    if view == "front":
        d.line([(26, 22 + y), (26, 42 + y)], fill=BRAID, width=1)
        d.line([(38, 22 + y), (38, 42 + y)], fill=BRAID, width=1)
    elif view == "side":
        d.line([(22, 22 + y), (22, 42 + y)], fill=BRAID, width=1)


def _idle(i):
    """Arms crossed; slight weight shift between frames."""
    bobs   = [0, -1,  0,  0,  1,  0]
    leans  = [0,  0, -1,  1,  0,  0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, JACKET, JACKET_SH, TROUSERS,
                leg_phase=0, bob=bobs[i],
                hair_fn=_hair_cap, accessory_fn=_braid_acc)
    # Crossed arms overlay — horizontal stripes across torso
    d.rectangle([14, 30 + bobs[i], 50, 36 + bobs[i]], fill=JACKET_SH)
    return add_outline(im)


def _refuse(i):
    """Shakes head; one hand forward in stop gesture."""
    bobs  = [ 0, -1,  0,  1,  0, -1]
    arm_r = [ 0,  4,  8,  8,  4,  0]
    tilt  = [(i % 2) * 2 - 1 for i in range(6)]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, JACKET, JACKET_SH, TROUSERS,
                leg_phase=0, bob=bobs[i], arm_r_raise=arm_r[i],
                hair_fn=_hair_cap, accessory_fn=_braid_acc)
    # Head shake — redraw head shifted left/right
    t = tilt[i]
    d.rectangle([23 + t, 4 + bobs[i], 41 + t, 22 + bobs[i]], fill=SKIN)
    eyes_front(d, 4 + bobs[i], hx_offset=t)
    _hair_cap(d, 4 + bobs[i])
    return add_outline(im)


def _step_aside(i):
    """8 frames: surprised (0-1) → amused (2-4) → waves through and steps right (5-7)."""
    drifts = [0, 0, 0, 0, 2, 6, 14, 24]
    bobs   = [0, -2, -1, 0, 0, -1, 0, 0]
    arm_r  = [4,  6,  4, 2, 0,  0, 6, 6]   # wave at 6-7
    im = tile(); d = ImageDraw.Draw(im)
    base = tile(); db = ImageDraw.Draw(base)
    biped_front(db, SKIN, JACKET, JACKET_SH, TROUSERS,
                leg_phase=(1 if i >= 5 else 0), bob=bobs[i],
                arm_r_raise=arm_r[i],
                hair_fn=_hair_cap, accessory_fn=_braid_acc)
    base = add_outline(base)
    drift = drifts[i]
    im.paste(base, (drift, 0), base)
    return im


def _talk_closeup(i):
    """Skeptical then slightly warmer; cap badge prominent."""
    bobs = [-14, -14, -15, -14, -14, -14]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, JACKET, JACKET_SH, TROUSERS,
                leg_phase=0, bob=bobs[i],
                hair_fn=_hair_cap, accessory_fn=_braid_acc)
    # Skeptical brow at frame 0-3
    if i < 4:
        hy = 4 + bobs[i]
        d.line([(24, hy + 5), (30, hy + 4)], fill=INK, width=1)
    return add_outline(im)


if __name__ == "__main__":
    anims = [
        ("idle",         [_idle(i)          for i in range(6)]),
        ("refuse",       [_refuse(i)        for i in range(6)]),
        ("step_aside",   [_step_aside(i)    for i in range(8)]),
        ("talk_closeup", [_talk_closeup(i)  for i in range(6)]),
    ]
    save_npc_sheet(anims, "carnival_guard")
