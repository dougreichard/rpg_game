#!/usr/bin/env python3
"""Batch PIL generator for all 12 overworld town NPC sprite sheets.

Each NPC shares the NPC_TOWN_ANIMS layout (SpriteLoader):
  row 0: idle          6 frames  640x64   8 fps  loop
  row 1: walk_right    8 frames  640x64  10 fps  loop
  row 2: walk_down     8 frames  640x64  10 fps  loop
  row 3: talk_closeup  6 frames  640x64   8 fps  loop  (character shifted up for portrait)

Canvas: 640x256 px RGBA.  Tile: 64x64.
"""
from PIL import Image, ImageDraw
from _sprite_common import (
    INK, TR, tile, add_outline, save_sheet,
    SKIN_PALE, SKIN_MED, SKIN_TAN,
    HAIR_BLACK, HAIR_BROWN, HAIR_AUBURN, HAIR_BLOND,
    NEUTRAL_DARK, NEUTRAL_GREY, NEUTRAL_LIGHT, NEUTRAL_OFFWH,
    CYAN, AMBER, RED,
)
from _sprite_npc_common import (
    biped_front, biped_back, biped_side,
    eyes_front, eyes_side, save_npc_sheet,
)

T = 64


# ── Shading helper ────────────────────────────────────────────────────────────

def _sh(color, frac=0.7):
    """Return a darkened (shadow) version of color."""
    r, g, b, a = color
    return (max(0, int(r * frac)), max(0, int(g * frac)), max(0, int(b * frac)), a)


# ── Hair style functions ──────────────────────────────────────────────────────
# Signature: hair_fn(d, hy, hx=32) — hx is the head left-x for side view.

def _hair_short(color):
    """Short hair covering the top of the head."""
    def fn(d, hy, hx=None):
        x = (hx if hx is not None else 23)
        d.rectangle([x, hy, x + 18, hy + 8], fill=color)
        d.rectangle([x, hy + 6, x + 3, hy + 14], fill=color)    # left sideburn
        d.rectangle([x + 15, hy + 6, x + 18, hy + 14], fill=color)  # right sideburn
    return fn


def _hair_sparse(color):
    """Sparse/receding hair — minimal coverage, mostly skin showing."""
    def fn(d, hy, hx=None):
        x = (hx if hx is not None else 23)
        d.rectangle([x, hy, x + 6, hy + 6], fill=color)
        d.rectangle([x + 12, hy, x + 18, hy + 6], fill=color)
    return fn


def _hair_tousled(color):
    """Tousled/unkempt short hair with irregular top edge."""
    def fn(d, hy, hx=None):
        x = (hx if hx is not None else 23)
        d.rectangle([x, hy, x + 18, hy + 9], fill=color)
        d.rectangle([x + 2, hy - 2, x + 8, hy + 2], fill=color)   # tuft left
        d.rectangle([x + 10, hy - 3, x + 16, hy + 1], fill=color)  # tuft right
        d.rectangle([x, hy + 6, x + 3, hy + 14], fill=color)
    return fn


def _hair_bun(color):
    """Neat bun on the crown of the head."""
    def fn(d, hy, hx=None):
        x = (hx if hx is not None else 23)
        # Base coverage
        d.rectangle([x, hy, x + 18, hy + 7], fill=color)
        # Bun shape at top-centre
        d.ellipse([x + 5, hy - 5, x + 13, hy + 3], fill=color)
    return fn


def _hair_two_buns(color):
    """Two buns — one each side of the crown (Penny's style)."""
    def fn(d, hy, hx=None):
        x = (hx if hx is not None else 23)
        d.rectangle([x, hy, x + 18, hy + 7], fill=color)
        d.ellipse([x, hy - 5, x + 8, hy + 3], fill=color)    # left bun
        d.ellipse([x + 10, hy - 5, x + 18, hy + 3], fill=color)   # right bun
    return fn


def _hair_ponytail(color):
    """Ponytail pulled to the back — visible as a tail on side view."""
    def fn(d, hy, hx=None):
        x = (hx if hx is not None else 23)
        d.rectangle([x, hy, x + 18, hy + 7], fill=color)
        # Ponytail band + tail (visible behind head)
        if hx is not None:
            # Side view — tail hangs behind the head
            d.rectangle([hx - 4, hy + 4, hx + 2, hy + 20], fill=color)
        else:
            # Front view — tail barely visible, just a tuft at back
            d.rectangle([x + 16, hy + 4, x + 20, hy + 16], fill=color)
    return fn


def _hair_updo(color):
    """Neat updo — hair swept up and pinned, formal appearance (Agnes)."""
    def fn(d, hy, hx=None):
        x = (hx if hx is not None else 23)
        d.rectangle([x, hy, x + 18, hy + 8], fill=color)
        # Swept-up mass at top — wider and higher than a bun
        d.rectangle([x + 2, hy - 4, x + 16, hy + 2], fill=color)
        d.rectangle([x + 4, hy - 6, x + 14, hy - 2], fill=color)
    return fn


def _hair_headscarf(hair_color, scarf_color):
    """Hair tucked under a fabric headscarf (Dottie)."""
    def fn(d, hy, hx=None):
        x = (hx if hx is not None else 23)
        # Underlying hair hint at neck
        d.rectangle([x + 1, hy + 14, x + 17, hy + 18], fill=hair_color)
        # Scarf covering the head
        d.rectangle([x, hy, x + 18, hy + 14], fill=scarf_color)
        # Scarf knot / fold at top
        d.ellipse([x + 4, hy - 3, x + 14, hy + 5], fill=_sh(scarf_color, 0.85))
    return fn


# ── Prop / accessory functions ────────────────────────────────────────────────
# Signature: accessory_fn(d, view, y) — view in ("front", "back", "side").

def _prop_glasses(frame_color):
    """Small round glasses (Moira — frames on nose)."""
    def fn(d, view, y):
        hy = 4 + y
        if view == "side":
            # Side — single lens visible
            d.ellipse([48, hy + 9, 54, hy + 15], outline=frame_color, width=1)
        else:
            # Front — two lenses
            d.ellipse([25, hy + 9, 31, hy + 15], outline=frame_color, width=1)
            d.ellipse([33, hy + 9, 39, hy + 15], outline=frame_color, width=1)
            d.line([(31, hy + 12), (33, hy + 12)], fill=frame_color, width=1)
    return fn


def _prop_beard(beard_color):
    """Beard on lower jaw (Otis, Ambrose)."""
    def fn(d, view, y):
        hy = 4 + y
        if view == "side":
            hx = 34
            d.rectangle([hx + 6, hy + 11, hx + 18, hy + 18], fill=beard_color)
        else:
            d.rectangle([24, hy + 11, 40, hy + 18], fill=beard_color)
    return fn


def _prop_pincushion(pin_color):
    """Pincushion bracelet on wrist (Penny) — small red dot on arm."""
    def fn(d, view, y):
        if view == "front":
            d.ellipse([44, 40 + y, 50, 46 + y], fill=pin_color)
        elif view == "side":
            d.ellipse([46, 40 + y, 52, 46 + y], fill=pin_color)
    return fn


def _prop_earphone(loop_color):
    """Cyan earphone loop on the side of the head (Clara)."""
    def fn(d, view, y):
        hy = 4 + y
        if view == "front":
            d.arc([19, hy + 4, 27, hy + 16], start=90, end=270, fill=loop_color, width=2)
        elif view == "side":
            hx = 34
            d.arc([hx + 14, hy + 3, hx + 22, hy + 13], start=270, end=90, fill=loop_color, width=2)
    return fn


def _prop_notebook(paper_color):
    """Rolled notebook tucked under the arm (Ambrose)."""
    def fn(d, view, y):
        if view == "front":
            d.rectangle([44, 30 + y, 56, 44 + y], fill=paper_color)
            d.line([(44, 35 + y), (56, 35 + y)], fill=_sh(paper_color, 0.75), width=1)
        elif view == "side":
            d.rectangle([46, 30 + y, 56, 42 + y], fill=paper_color)
    return fn


def _prop_sheet_music(paper_color):
    """Sheet music tucked under the arm (Agnes)."""
    def fn(d, view, y):
        if view == "front":
            d.rectangle([44, 28 + y, 58, 44 + y], fill=paper_color)
            for ly in (33, 37, 41):
                d.line([(46, ly + y), (56, ly + y)], fill=_sh(paper_color, 0.6), width=1)
        elif view == "side":
            d.rectangle([46, 28 + y, 56, 42 + y], fill=paper_color)
    return fn


def _prop_none():
    """No prop — returns a no-op function."""
    def fn(d, view, y):
        pass
    return fn


# ── Per-NPC definitions ───────────────────────────────────────────────────────

TOWN_NPCS = [
    {
        "name": "gus",
        "skin":     (200, 144, 106, 255),   # #C8906A
        "shirt":    (122,  99,  71, 255),   # #7A6347 faded brown work jacket
        "shirt_sh": ( 96,  76,  52, 255),
        "pants":    NEUTRAL_GREY,
        "hair_fn":  _hair_sparse(NEUTRAL_LIGHT),
        "acc_fn":   _prop_none(),
    },
    {
        "name": "moira",
        "skin":     (240, 212, 176, 255),   # #F0D4B0
        "shirt":    (110, 158, 150, 255),   # #6E9E96 teal cardigan
        "shirt_sh": ( 84, 126, 118, 255),
        "pants":    (140, 122, 106, 255),   # #8C7A6A grey-brown skirt
        "hair_fn":  _hair_bun((200, 200, 200, 255)),   # silver
        "acc_fn":   _prop_glasses(NEUTRAL_GREY),
    },
    {
        "name": "reggie",
        "skin":     (200, 154, 106, 255),   # #C89A6A
        "shirt":    (140,  74,  58, 255),   # #8C4A3A red-brown flannel
        "shirt_sh": (108,  56,  42, 255),
        "pants":    ( 74,  92, 140, 255),   # #4A5C8C faded indigo
        "hair_fn":  _hair_short(HAIR_BLACK),
        "acc_fn":   _prop_none(),
    },
    {
        "name": "fanny",
        "skin":     (232, 196, 154, 255),   # #E8C49A
        "shirt":    (200, 144, 122, 255),   # #C8907A dusty rose blouse
        "shirt_sh": (158, 110,  92, 255),
        "pants":    (140, 138,  92, 255),   # #8C8A5C muted olive skirt
        "hair_fn":  _hair_bun((140, 106,  74, 255)),   # warm brown
        "acc_fn":   _prop_none(),
    },
    {
        "name": "penny",
        "skin":     (212, 160, 122, 255),   # #D4A07A
        "shirt":    (224, 122, 106, 255),   # #E07A6A coral top
        "shirt_sh": (180,  92,  78, 255),
        "pants":    (232, 216, 176, 255),   # #E8D8B0 cream apron skirt
        "hair_fn":  _hair_two_buns(HAIR_BLACK),
        "acc_fn":   _prop_pincushion(RED),
    },
    {
        "name": "otis",
        "skin":     (168, 120,  80, 255),   # #A87850
        "shirt":    ( 47,  74, 153, 255),   # #2F4A99 navy sweater
        "shirt_sh": ( 36,  56, 118, 255),
        "pants":    (110, 122, 134, 255),   # #6E7A86 slate canvas trousers
        "hair_fn":  _hair_short(NEUTRAL_GREY),
        "acc_fn":   _prop_beard(NEUTRAL_GREY),
    },
    {
        "name": "wendell",
        "skin":     (232, 200, 160, 255),   # #E8C8A0
        "shirt":    (140, 158, 128, 255),   # #8C9E80 sage knit sweater
        "shirt_sh": (106, 122,  96, 255),
        "pants":    (158, 140, 122, 255),   # #9E8C7A taupe slacks
        "hair_fn":  _hair_short((110,  92,  74, 255)),   # mousy brown
        "acc_fn":   _prop_none(),
    },
    {
        "name": "clara",
        "skin":     (232, 200, 154, 255),   # #E8C89A
        "shirt":    (140, 154,  90, 255),   # #8C9A5A olive cargo vest
        "shirt_sh": (108, 120,  68, 255),
        "pants":    ( 58,  74, 122, 255),   # #3A4A7A dark indigo jeans
        "hair_fn":  _hair_ponytail(HAIR_BROWN),
        "acc_fn":   _prop_earphone(CYAN),
    },
    {
        "name": "ambrose",
        "skin":     (212, 148, 106, 255),   # #D4946A
        "shirt":    (140, 122,  80, 255),   # #8C7A50 tweed jacket
        "shirt_sh": (108,  92,  58, 255),
        "pants":    NEUTRAL_GREY,
        "hair_fn":  _hair_sparse((158, 158, 140, 255)),   # salt-and-pepper
        "acc_fn":   _prop_beard((158, 158, 140, 255)),
    },
    {
        "name": "dottie",
        "skin":     (212, 160, 122, 255),   # #D4A07A
        "shirt":    (200, 168,  58, 255),   # #C8A83A mustard layered top
        "shirt_sh": (158, 130,  42, 255),
        "pants":    ( 78, 158, 150, 255),   # #4E9E96 teal flowy skirt
        "hair_fn":  _hair_headscarf(HAIR_BLACK, (224, 122, 106, 255)),   # coral scarf
        "acc_fn":   _prop_none(),
    },
    {
        "name": "tobias",
        "skin":     (232, 206, 168, 255),   # #E8CEA8
        "shirt":    (122, 122, 140, 255),   # #7A7A8C rumpled grey jacket
        "shirt_sh": ( 94,  94, 108, 255),
        "pants":    (140, 122,  92, 255),   # #8C7A5C dusty dark tan
        "hair_fn":  _hair_tousled((92, 74, 54, 255)),   # brown tousled
        "acc_fn":   _prop_none(),
    },
    {
        "name": "agnes",
        "skin":     (240, 212, 176, 255),   # #F0D4B0
        "shirt":    (184, 168, 208, 255),   # #B8A8D0 lavender blouse
        "shirt_sh": (148, 132, 170, 255),
        "pants":    NEUTRAL_GREY,
        "hair_fn":  _hair_updo((216, 216, 216, 255)),   # white-silver
        "acc_fn":   _prop_sheet_music((240, 232, 200, 255)),
    },
]


# ── Frame builders ────────────────────────────────────────────────────────────

def _make_idle_frame(npc, frame_idx):
    """Front-facing idle — 6 frames with gentle bob."""
    bobs = [0, -1, -1, 0, 1, 1]
    bob = bobs[frame_idx % len(bobs)]
    im = tile()
    d = ImageDraw.Draw(im)
    biped_front(d, npc["skin"], npc["shirt"], npc["shirt_sh"], npc["pants"],
                leg_phase=0, bob=bob,
                hair_fn=npc["hair_fn"], accessory_fn=npc["acc_fn"])
    return add_outline(im)


def _make_walk_right_frame(npc, frame_idx):
    """Side-facing walk — 8 frames, legs alternate."""
    bobs = [0, -1, -2, -1, 0, -1, -2, -1]
    phases = [0, 0, 1, 1, 0, 0, 1, 1]
    bob = bobs[frame_idx % 8]
    phase = phases[frame_idx % 8]
    im = tile()
    d = ImageDraw.Draw(im)
    biped_side(d, npc["skin"], npc["shirt"], npc["shirt_sh"], npc["pants"],
               leg_phase=phase, bob=bob,
               hair_fn=npc["hair_fn"], accessory_fn=npc["acc_fn"])
    return add_outline(im)


def _make_walk_down_frame(npc, frame_idx):
    """Front-facing walk toward camera — 8 frames, legs alternate."""
    bobs = [0, -1, -2, -1, 0, -1, -2, -1]
    phases = [0, 0, 1, 1, 0, 0, 1, 1]
    bob = bobs[frame_idx % 8]
    phase = phases[frame_idx % 8]
    im = tile()
    d = ImageDraw.Draw(im)
    biped_front(d, npc["skin"], npc["shirt"], npc["shirt_sh"], npc["pants"],
                leg_phase=phase, bob=bob,
                hair_fn=npc["hair_fn"], accessory_fn=npc["acc_fn"])
    return add_outline(im)


def _make_talk_closeup_frame(npc, frame_idx):
    """Portrait-style talking frame — character shifted up 16px so face
    fills more of the tile.  Slight arm-raise alternates for gesture."""
    bobs = [-16, -17, -17, -16, -16, -17]
    arm_raises = [0, 0, 4, 4, 0, 0]
    bob = bobs[frame_idx % 6]
    arm_r = arm_raises[frame_idx % 6]
    im = tile()
    d = ImageDraw.Draw(im)
    biped_front(d, npc["skin"], npc["shirt"], npc["shirt_sh"], npc["pants"],
                leg_phase=0, bob=bob, arm_r_raise=arm_r,
                hair_fn=npc["hair_fn"], accessory_fn=npc["acc_fn"])
    return add_outline(im)


# ── Main ──────────────────────────────────────────────────────────────────────

def generate_npc(npc):
    idle_frames  = [_make_idle_frame(npc, i)        for i in range(6)]
    walk_r       = [_make_walk_right_frame(npc, i)  for i in range(8)]
    walk_d       = [_make_walk_down_frame(npc, i)   for i in range(8)]
    talk         = [_make_talk_closeup_frame(npc, i) for i in range(6)]
    anims = [
        ("idle",         idle_frames),
        ("walk_right",   walk_r),
        ("walk_down",    walk_d),
        ("talk_closeup", talk),
    ]
    save_npc_sheet(anims, npc["name"])


if __name__ == "__main__":
    for npc in TOWN_NPCS:
        generate_npc(npc)
