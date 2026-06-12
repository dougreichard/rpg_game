"""Shared biped-drawing helpers for NPC sprite generators.

Unlike _sprite_player_common.py (a reference/scaffold), this module is
actively imported by all NPC generators (gen_npc_town.py and the 5
level-NPC generators). Provides four views: front, back, side, and
seated (for desk-bound NPCs like Mr. Bellows and the Librarian).

Coordinate system (64x64 tile, T=64) — same proportions as players:
  Head   y:4–22   (18 px)
  Torso  y:22–44  (22 px)
  Legs   y:44–62  (18 px, 2 px ground margin)

  Front/back — centered at x=32
  Side       — head hx=34, torso x:20-46
  Seated     — torso only; legs hidden below desk line (~y:44)

Body shape differences between NPCs (stocky, portly, round) come from
clothing-rect widths and accessory choices, not skeleton changes.
"""
from PIL import Image, ImageDraw
from _sprite_common import (
    INK, TR, tile, add_outline, save_sheet,
    SKIN_PALE, SKIN_MED, SKIN_TAN,
    HAIR_BLACK, HAIR_BROWN, HAIR_AUBURN, HAIR_BLOND,
    NEUTRAL_DARK, NEUTRAL_GREY, NEUTRAL_LIGHT, NEUTRAL_OFFWH, WHITE,
)
import os

T   = 64
WHT = (255, 255, 255, 255)


# ── Eye helpers ───────────────────────────────────────────────────────────────

def eyes_front(d, hy, hx_offset=0):
    """4×4 white + 2×2 pupil, two eyes, front-facing."""
    for ex in (24 + hx_offset, 34 + hx_offset):
        d.rectangle([ex, hy + 8, ex + 4, hy + 12], fill=WHT)
        d.rectangle([ex + 1, hy + 9, ex + 3, hy + 11], fill=INK)


def eyes_side(d, hy, hx=34):
    """Single 4×4 eye, side-facing."""
    d.rectangle([hx + 14, hy + 8, hx + 18, hy + 12], fill=WHT)
    d.rectangle([hx + 15, hy + 9, hx + 17, hy + 11], fill=INK)


# ── Front view ────────────────────────────────────────────────────────────────

def biped_front(d, skin, shirt, shirt_sh, pants, leg_phase=0, bob=0,
                arm_l_raise=0, arm_r_raise=0,
                hair_fn=None, accessory_fn=None):
    """Front-facing (toward camera) humanoid.

    leg_phase 0/1 alternates which leg leads for walk cycles.
    hair_fn(d, hy)       — draws hair/hat/collar after head rect.
    accessory_fn(d, y)   — draws prop/item last.
    """
    y = bob

    # Legs
    if leg_phase == 0:
        d.rectangle([22, 44 + y, 30, 62], fill=pants)
        d.rectangle([34, 46 + y, 42, 62], fill=pants)
    else:
        d.rectangle([22, 46 + y, 30, 62], fill=pants)
        d.rectangle([34, 44 + y, 42, 62], fill=pants)

    # Back arm (partially behind torso)
    d.rectangle([13, 24 + y - arm_l_raise, 19, 44 + y], fill=shirt_sh)

    # Torso
    d.rectangle([19, 22 + y, 45, 44 + y], fill=shirt)
    d.rectangle([19, 36 + y, 45, 44 + y], fill=shirt_sh)

    # Front arm
    d.rectangle([45, 24 + y - arm_r_raise, 51, 44 + y], fill=shirt)

    # Head
    hy = 4 + y
    d.rectangle([23, hy, 41, hy + 18], fill=skin)
    eyes_front(d, hy)

    if hair_fn:
        hair_fn(d, hy)
    if accessory_fn:
        accessory_fn(d, "front", y)


# ── Back view ─────────────────────────────────────────────────────────────────

def biped_back(d, shirt, shirt_sh, pants, leg_phase=0, bob=0,
               hair_fn=None, accessory_fn=None):
    """Back-facing (away from camera) humanoid."""
    y = bob

    # Legs
    if leg_phase == 0:
        d.rectangle([22, 44 + y, 30, 62], fill=pants)
        d.rectangle([34, 46 + y, 42, 62], fill=pants)
    else:
        d.rectangle([22, 46 + y, 30, 62], fill=pants)
        d.rectangle([34, 44 + y, 42, 62], fill=pants)

    # Arms
    d.rectangle([13, 24 + y, 19, 44 + y], fill=shirt_sh)
    d.rectangle([45, 24 + y, 51, 44 + y], fill=shirt)

    # Torso (back — slightly darker on lower half)
    d.rectangle([19, 22 + y, 45, 44 + y], fill=shirt_sh)
    d.rectangle([19, 22 + y, 45, 30 + y], fill=shirt)

    # Head (back — hair_fn covers it)
    hy = 4 + y
    d.rectangle([23, hy, 41, hy + 18], fill=shirt)

    if hair_fn:
        hair_fn(d, hy)
    if accessory_fn:
        accessory_fn(d, "back", y)


# ── Side view ─────────────────────────────────────────────────────────────────

def biped_side(d, skin, shirt, shirt_sh, pants, leg_phase=0, bob=0,
               head_tilt=0, arm_f_raise=0, lean=0,
               hair_fn=None, accessory_fn=None):
    """Right-facing side view.

    arm_f_raise: positive = front arm raised upward.
    lean: x offset on head/upper body (forward lunge).
    """
    y = bob
    lx = lean

    # Back leg
    if leg_phase == 0:
        d.rectangle([24, 44 + y, 32, 62], fill=pants)
    else:
        d.rectangle([26, 44 + y, 34, 62], fill=pants)

    # Back arm (behind torso)
    d.rectangle([14 + lx, 24 + y, 20 + lx, 44 + y], fill=shirt_sh)

    # Torso
    d.rectangle([20 + lx, 22 + y, 46 + lx, 44 + y], fill=shirt)
    d.rectangle([20 + lx, 36 + y, 46 + lx, 44 + y], fill=shirt_sh)

    # Front leg
    if leg_phase == 0:
        d.rectangle([34, 44 + y, 42, 62], fill=pants)
    else:
        d.rectangle([32, 44 + y, 40, 62], fill=pants)

    # Front arm
    arm_top = 24 + y - arm_f_raise
    d.rectangle([46 + lx, arm_top, 52 + lx, 44 + y], fill=shirt)

    # Head
    hx = 34 + lx
    hy = 4 + y + head_tilt
    d.rectangle([hx, hy, hx + 18, hy + 18], fill=skin)
    d.rectangle([hx + 12, hy + 12, hx + 18, hy + 18], fill=skin)  # jaw
    eyes_side(d, hy, hx=hx)

    if hair_fn:
        hair_fn(d, hy, hx=hx)
    if accessory_fn:
        accessory_fn(d, "side", y)


# ── Seated view ───────────────────────────────────────────────────────────────

def biped_seated(d, skin, shirt, shirt_sh, pants, bob=0, lean=0,
                 arm_desk=True, hair_fn=None, accessory_fn=None):
    """Front-facing seated humanoid (desk/table position).

    Torso and head are visible above the desk line (~y:44); legs are
    drawn faintly at y:44-62 as a seated suggestion (mostly hidden by
    the desk drawn by the calling generator).

    arm_desk: if True, arms rest on a horizontal desk surface at y:40-46
              (forearms forward). If False, arms hang at sides (talking).
    lean: small x offset on head (leans forward to read).
    """
    y = bob
    lx = lean

    # Faint legs (chair/seated suggestion — mostly hidden by desk prop)
    d.rectangle([22, 44 + y, 30, 58], fill=pants)
    d.rectangle([34, 44 + y, 42, 58], fill=pants)

    # Torso
    d.rectangle([19, 22 + y, 45, 44 + y], fill=shirt)
    d.rectangle([19, 36 + y, 45, 44 + y], fill=shirt_sh)

    if arm_desk:
        # Forearms resting on desk surface
        d.rectangle([10, 38 + y, 22, 46 + y], fill=shirt_sh)   # left forearm
        d.rectangle([42, 38 + y, 54, 46 + y], fill=shirt)      # right forearm
    else:
        # Arms at sides (talking / gesturing)
        d.rectangle([13, 24 + y, 19, 44 + y], fill=shirt_sh)
        d.rectangle([45, 24 + y, 51, 44 + y], fill=shirt)

    # Head
    hy = 4 + y
    hx_off = lx
    d.rectangle([23 + hx_off, hy, 41 + hx_off, hy + 18], fill=skin)
    eyes_front(d, hy, hx_offset=hx_off)

    if hair_fn:
        hair_fn(d, hy)
    if accessory_fn:
        accessory_fn(d, "seated", y)


# ── Sheet save wrapper ────────────────────────────────────────────────────────

def save_npc_sheet(anims, npc_name):
    """anims: list of (anim_name, frame_list). Pads each row to 10 cols.
    Saves to assets/art/sprites/<npc_name>.png."""
    save_sheet(anims, T, T, f"{npc_name}.png")
