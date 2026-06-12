#!/usr/bin/env python3
"""Librarian sprite sheet — PIL procedural.
640x256 px RGBA (4 rows x 10 cols x 64x64).
Row order matches NPC_GATEKEEPER_ANIMS in SpriteLoader:
  0 idle (6)  1 refuse (6)  2 step_aside (8)  3 talk_closeup (6)
"""
from PIL import Image, ImageDraw
from _sprite_common import INK, TR, tile, add_outline, NEUTRAL_GREY
from _sprite_npc_common import biped_front, biped_seated, eyes_front, save_npc_sheet

T = 64

# -- Palette --
CARDIGAN    = (122, 140, 154, 255)   # grey-blue cardigan
CARDIGAN_SH = ( 94, 110, 122, 255)
SHIRT       = (232, 224, 208, 255)   # off-white shirt under cardigan
SKIRT       = ( 92,  92, 110, 255)   # dark grey pencil skirt
SKIN        = (212, 168, 122, 255)   # medium warm
HAIR        = ( 40,  30,  20, 255)   # dark brown / near-black
GLASS_FR    = (140, 140, 140, 255)   # thin round frames on nose
BOOK        = ( 68,  90, 110, 255)   # dark blue-grey hardcover stamp book


def _hair_bun(d, hy, **kw):
    """Tight bun at the back/crown."""
    d.rectangle([23, hy, 41, hy + 7], fill=HAIR)
    d.ellipse([29, hy - 4, 37, hy + 4], fill=HAIR)   # bun knot


def _glasses(d, view, y):
    hy = 4 + y
    d.ellipse([25, hy + 9, 31, hy + 15], outline=GLASS_FR, width=1)
    d.ellipse([33, hy + 9, 39, hy + 15], outline=GLASS_FR, width=1)
    d.line([(31, hy + 12), (33, hy + 12)], fill=GLASS_FR)


def _book_acc(d, view, y):
    _glasses(d, view, y)
    # Stamp book held under left arm
    if view in ("front", "seated"):
        d.rectangle([10, 28 + y, 22, 44 + y], fill=BOOK)
        d.line([(10, 36 + y), (22, 36 + y)], fill=INK, width=1)


def _idle(i):
    """Seated at desk — stamps books; glasses gleam."""
    bobs  = [0, -1, -1,  0,  0, -1]
    leans = [0,  1,  1, -1, -1,  0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_seated(d, SKIN, CARDIGAN, CARDIGAN_SH, SKIRT,
                 bob=bobs[i], lean=leans[i], arm_desk=True,
                 hair_fn=_hair_bun, accessory_fn=_book_acc)
    return add_outline(im)


def _refuse(i):
    """Shakes head firmly; right hand out as stop gesture."""
    bobs    = [ 0, -1,  0,  1,  0, -1]
    arm_r   = [ 0,  0,  8,  8,  4,  0]
    leans   = [ 0,  0,  0,  1,  0,  0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, CARDIGAN, CARDIGAN_SH, SKIRT,
                leg_phase=0, bob=bobs[i], arm_r_raise=arm_r[i],
                hair_fn=_hair_bun, accessory_fn=_book_acc)
    # Head-shake: alternate left/right lean via small offset
    tilt = (i % 2) * 2 - 1
    d.rectangle([23 + tilt, 4 + bobs[i], 41 + tilt, 22 + bobs[i]], fill=SKIN)
    eyes_front(d, 4 + bobs[i], hx_offset=tilt)
    _hair_bun(d, 4 + bobs[i])
    _glasses(d, "front", bobs[i])
    return add_outline(im)


def _step_aside(i):
    """8 frames: surprised (1-2), packs up (3-4), steps right out of frame (5-8)."""
    # Lateral drift: character moves right across frames
    drifts = [0, 0, 2, 4, 8, 14, 22, 32]
    bobs   = [0, -1, 0, 0, -1, -1, 0, 0]
    arm_r  = [0, 4, 4, 0, 0, 0, 0, 0]
    im = tile(); d = ImageDraw.Draw(im)
    drift = drifts[i]
    # Build the frame at normal position then shift by pasting onto an offset
    base = tile()
    db = ImageDraw.Draw(base)
    biped_front(db, SKIN, CARDIGAN, CARDIGAN_SH, SKIRT,
                leg_phase=(i % 2), bob=bobs[i], arm_r_raise=arm_r[i],
                hair_fn=_hair_bun, accessory_fn=_book_acc)
    base = add_outline(base)
    im.paste(base, (drift, 0), base)
    return im


def _talk_closeup(i):
    """Closeup — expression shifts from severe to slightly softened."""
    bobs = [-14, -14, -15, -14, -14, -14]
    im = tile(); d = ImageDraw.Draw(im)
    biped_front(d, SKIN, CARDIGAN, CARDIGAN_SH, SKIRT,
                leg_phase=0, bob=bobs[i],
                hair_fn=_hair_bun, accessory_fn=_glasses)
    # Slight frown at frame 0-2, neutral by 4-5
    if i < 3:
        d.line([(26, 4 + bobs[i] + 14), (32, 4 + bobs[i] + 13)], fill=INK, width=1)
        d.line([(32, 4 + bobs[i] + 14), (38, 4 + bobs[i] + 13)], fill=INK, width=1)
    return add_outline(im)


if __name__ == "__main__":
    anims = [
        ("idle",         [_idle(i)          for i in range(6)]),
        ("refuse",       [_refuse(i)        for i in range(6)]),
        ("step_aside",   [_step_aside(i)    for i in range(8)]),
        ("talk_closeup", [_talk_closeup(i)  for i in range(6)]),
    ]
    save_npc_sheet(anims, "librarian")
