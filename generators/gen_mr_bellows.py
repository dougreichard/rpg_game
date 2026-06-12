#!/usr/bin/env python3
"""Mr. Bellows sprite sheet — PIL procedural.
640x320 px RGBA (5 rows x 10 cols x 64x64).
Row order matches NPC_MR_BELLOWS_ANIMS in SpriteLoader:
  0 idle (6)  1 talk (6)  2 talk_closeup (8)  3 relieved (6)  4 hand_over_item (4)
"""
from PIL import Image, ImageDraw
from _sprite_common import INK, TR, tile, add_outline, NEUTRAL_GREY, NEUTRAL_LIGHT
from _sprite_npc_common import biped_seated, eyes_front, save_npc_sheet

T = 64

# -- Palette --
APRON    = (200, 168, 122, 255)   # #C8A87A faded tan apron
APRON_SH = (160, 132,  92, 255)
SHIRT    = (240, 232, 208, 255)   # #F0E8D0 off-white shirt
SHIRT_SH = (210, 200, 175, 255)
TROUSERS = ( 92,  92, 110, 255)   # #5C5C6E dark grey
SKIN     = (217, 163, 110, 255)   # #D9A36E warm ruddy skin
MOUSTACH = (140, 140, 140, 255)   # #8C8C8C salt-and-pepper
GLASS_FR = ( 58,  58,  74, 255)   # #3A3A4A dark glasses frame
LENS     = (220, 216, 206, 255)   # #DCDAR lens highlight
KEY      = (200, 168,  58, 255)   # tuning key (amber/brass)


def _hair(d, hy, **kw):
    """Thinning hair — patch at temples, mostly skin."""
    d.rectangle([23, hy, 29, hy + 8], fill=MOUSTACH)
    d.rectangle([35, hy, 41, hy + 8], fill=MOUSTACH)


def _moustache(d, y):
    hy = 4 + y
    d.rectangle([27, hy + 11, 37, hy + 14], fill=MOUSTACH)


def _glasses(d, y):
    hy = 4 + y
    d.ellipse([25, hy + 8, 31, hy + 14], outline=GLASS_FR, width=1)
    d.ellipse([33, hy + 8, 39, hy + 14], outline=GLASS_FR, width=1)
    d.line([(31, hy + 11), (33, hy + 11)], fill=GLASS_FR)


def _key_on_belt(d, y):
    """Small brass key clipped to apron front."""
    d.rectangle([40, 38 + y, 44, 44 + y], fill=KEY)
    d.ellipse([40, 34 + y, 44, 38 + y], outline=KEY, width=1)


def _acc(d, view, y):
    _glasses(d, y)
    _moustache(d, y)
    _key_on_belt(d, y)


def _acc_no_key(d, view, y):
    _glasses(d, y)
    _moustache(d, y)


# -- Frame builders --

def _idle(i):
    bobs  = [0, -1, -1, 0, 0, -1]
    leans = [0,  0,  1, 1, 0,  0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_seated(d, SKIN, APRON, APRON_SH, TROUSERS,
                 bob=bobs[i], lean=leans[i], arm_desk=True,
                 hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _talk(i):
    bobs = [0, -1, -1, 0, 1, 0]
    arm_r = [0, 3, 6, 6, 3, 0]
    im = tile(); d = ImageDraw.Draw(im)
    biped_seated(d, SKIN, APRON, APRON_SH, TROUSERS,
                 bob=bobs[i], arm_desk=False,
                 hair_fn=_hair, accessory_fn=_acc)
    return add_outline(im)


def _talk_closeup(i):
    """Shifted up 14px for portrait feel; frame 4-5 hands move to pockets."""
    bobs = [-14, -15, -15, -14, -14, -15, -14, -14]
    pat  = i in (3, 4)   # patting pockets at frame 3-4
    im = tile(); d = ImageDraw.Draw(im)
    biped_seated(d, SKIN, APRON, APRON_SH, TROUSERS,
                 bob=bobs[i], lean=1, arm_desk=(not pat),
                 hair_fn=_hair, accessory_fn=_acc)
    if pat:
        # Hands patting upper apron
        d.rectangle([22, 22 + bobs[i], 28, 28 + bobs[i]], fill=SKIN)
        d.rectangle([36, 22 + bobs[i], 42, 28 + bobs[i]], fill=SKIN)
    return add_outline(im)


def _relieved(i):
    """Leans back — lean negative to recline slightly."""
    bobs  = [ 0,  0, -1, -1,  0,  0]
    leans = [-2, -2, -3, -3, -2, -1]
    im = tile(); d = ImageDraw.Draw(im)
    biped_seated(d, SKIN, APRON, APRON_SH, TROUSERS,
                 bob=bobs[i], lean=leans[i], arm_desk=False,
                 hair_fn=_hair, accessory_fn=_acc_no_key)
    return add_outline(im)


def _hand_over(i):
    """4 frames: arms extend toward viewer, key appears on desk."""
    extends = [0, 3, 6, 8]
    im = tile(); d = ImageDraw.Draw(im)
    ext = extends[i]
    biped_seated(d, SKIN, APRON, APRON_SH, TROUSERS,
                 bob=0, lean=extends[i] // 3, arm_desk=True,
                 hair_fn=_hair, accessory_fn=_acc_no_key)
    # Key on desk surface (appears fully in frame 2+)
    if i >= 1:
        d.rectangle([30, 42, 34, 48], fill=KEY)
        d.ellipse([29, 38, 35, 44], outline=KEY, width=1)
    return add_outline(im)


# -- Generate --
if __name__ == "__main__":
    anims = [
        ("idle",           [_idle(i)          for i in range(6)]),
        ("talk",           [_talk(i)          for i in range(6)]),
        ("talk_closeup",   [_talk_closeup(i)  for i in range(8)]),
        ("relieved",       [_relieved(i)      for i in range(6)]),
        ("hand_over_item", [_hand_over(i)     for i in range(4)]),
    ]
    save_npc_sheet(anims, "mr_bellows")
