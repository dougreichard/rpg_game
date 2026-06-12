"""Shared biped-drawing helpers for the five player-character sprite
generators. Provides three canonical views (front/back/side) as draw
functions that each character generator calls with its own palette and
optional accessory callbacks.

Coordinate system (64×64 tile, T=64):
  Head   y:4–22   (18 px)
  Torso  y:22–44  (22 px)
  Legs   y:44–62  (18 px, 2 px ground margin)

  Front/back — centered at x=32 (26 px torso, legs 22-30 / 34-42)
  Side       — head x:34-52, torso x:20-46, arms x:14-20 / 46-52
"""
from PIL import ImageDraw
from _sprite_common import INK, TR, WHITE, tile, add_outline, save_sheet
import os

T = 64
WHT = (255, 255, 255, 255)   # eye-white


# ── Eye helpers ───────────────────────────────────────────────────────────────

def eyes_front(d, hy, hx_offset=0, eyes_x=False):
    """4×4 white + 2×2 pupil, two eyes, for front/back view head at hy."""
    for ex in (24 + hx_offset, 34 + hx_offset):
        if eyes_x:
            d.line([(ex, hy+8), (ex+4, hy+12)], fill=INK, width=2)
            d.line([(ex+4, hy+8), (ex, hy+12)], fill=INK, width=2)
        else:
            d.rectangle([ex, hy+8, ex+4, hy+12], fill=WHT)
            d.rectangle([ex+1, hy+9, ex+3, hy+11], fill=INK)


def eyes_side(d, hy, hx=34, eyes_x=False):
    """Single 4×4 eye for side view."""
    if eyes_x:
        d.line([(hx+14, hy+8), (hx+18, hy+12)], fill=INK, width=2)
        d.line([(hx+18, hy+8), (hx+14, hy+12)], fill=INK, width=2)
    else:
        d.rectangle([hx+14, hy+8, hx+18, hy+12], fill=WHT)
        d.rectangle([hx+15, hy+9, hx+17, hy+11], fill=INK)


# ── Front view (walk_down, run_down, idle, etc.) ──────────────────────────────

def biped_front(d, skin, shirt, shirt_sh, pants, leg_phase=0, bob=0,
                arm_l_raise=0, arm_r_raise=0, eyes_x=False,
                hair_fn=None, accessory_fn=None):
    """Draw a front-facing (toward camera) humanoid onto draw context d.
    hair_fn(d, hy)  — called after head rect, draws hair/hat.
    accessory_fn(d) — called last, draws weapon/tool/prop."""
    y = bob

    # Legs
    if leg_phase == 0:
        d.rectangle([22, 44+y, 30, 62], fill=pants)
        d.rectangle([34, 46+y, 42, 62], fill=pants)
    else:
        d.rectangle([22, 46+y, 30, 62], fill=pants)
        d.rectangle([34, 44+y, 42, 62], fill=pants)

    # Back arm (left — partially behind torso)
    d.rectangle([13, 24+y-arm_l_raise, 19, 44+y], fill=shirt_sh)

    # Torso
    d.rectangle([19, 22+y, 45, 44+y], fill=shirt)
    d.rectangle([19, 36+y, 45, 44+y], fill=shirt_sh)

    # Front arm (right)
    d.rectangle([45, 24+y-arm_r_raise, 51, 44+y], fill=shirt)

    # Head
    hy = 4 + y
    d.rectangle([23, hy, 41, hy+18], fill=skin)
    d.rectangle([23, hy+12, 41, hy+18], fill=skin)  # jaw area (same, just marks extent)
    eyes_front(d, hy, eyes_x=eyes_x)

    if hair_fn:
        hair_fn(d, hy)
    if accessory_fn:
        accessory_fn(d, "front", y)


# ── Back view (walk_up, run_up) ───────────────────────────────────────────────

def biped_back(d, shirt, shirt_sh, pants, leg_phase=0, bob=0,
               hair_fn=None, accessory_fn=None):
    """Draw a back-facing (away from camera) humanoid."""
    y = bob

    # Legs
    if leg_phase == 0:
        d.rectangle([22, 44+y, 30, 62], fill=pants)
        d.rectangle([34, 46+y, 42, 62], fill=pants)
    else:
        d.rectangle([22, 46+y, 30, 62], fill=pants)
        d.rectangle([34, 44+y, 42, 62], fill=pants)

    # Arms
    d.rectangle([13, 24+y, 19, 44+y], fill=shirt_sh)
    d.rectangle([45, 24+y, 51, 44+y], fill=shirt)

    # Torso (back — slightly darker)
    d.rectangle([19, 22+y, 45, 44+y], fill=shirt_sh)
    d.rectangle([19, 22+y, 45, 30+y], fill=shirt)  # upper back lighter

    # Head (back of head — just a colored mass, hair fills it)
    hy = 4 + y
    d.rectangle([23, hy, 41, hy+18], fill=shirt)   # placeholder; hair_fn covers it

    if hair_fn:
        hair_fn(d, hy)
    if accessory_fn:
        accessory_fn(d, "back", y)


# ── Side view (walk_right, run_right, attack, hurt, etc.) ─────────────────────

def biped_side(d, skin, shirt, shirt_sh, pants, leg_phase=0, bob=0,
               head_tilt=0, arm_f_raise=0, lean=0, eyes_x=False,
               hair_fn=None, accessory_fn=None):
    """Draw a right-facing side-view humanoid.
    arm_f_raise: positive = front arm raised upward (for weapon attack).
    lean: x offset applied to head/upper body (forward lunge)."""
    y = bob
    lx = lean

    # Back leg
    if leg_phase == 0:
        d.rectangle([24, 44+y, 32, 62], fill=pants)
    else:
        d.rectangle([26, 44+y, 34, 62], fill=pants)

    # Back arm (behind torso)
    d.rectangle([14+lx, 24+y, 20+lx, 44+y], fill=shirt_sh)

    # Torso
    d.rectangle([20+lx, 22+y, 46+lx, 44+y], fill=shirt)
    d.rectangle([20+lx, 36+y, 46+lx, 44+y], fill=shirt_sh)

    # Front leg
    if leg_phase == 0:
        d.rectangle([34, 44+y, 42, 62], fill=pants)
    else:
        d.rectangle([32, 44+y, 40, 62], fill=pants)

    # Front arm (in front of torso)
    arm_top = 24 + y - arm_f_raise
    d.rectangle([46+lx, arm_top, 52+lx, 44+y], fill=shirt)

    # Head
    hx = 34 + lx
    hy = 4 + y + head_tilt
    d.rectangle([hx, hy, hx+18, hy+18], fill=skin)
    d.rectangle([hx+12, hy+12, hx+18, hy+18], fill=skin)  # jaw
    eyes_side(d, hy, hx=hx, eyes_x=eyes_x)

    if hair_fn:
        hair_fn(d, hy, hx=hx)
    if accessory_fn:
        accessory_fn(d, "side", y)


# ── Lying-flat helper (shared death/down pose) ────────────────────────────────

def biped_lying(d, skin, shirt, shirt_sh, pants, hair_fn=None):
    """Character lying face-down / crumpled on ground."""
    d.ellipse([10, 44, 54, 60], fill=shirt)
    d.ellipse([10, 52, 54, 60], fill=shirt_sh)
    # Head to the right
    d.rectangle([44, 38, 60, 54], fill=skin)
    d.line([(50, 42), (56, 48)], fill=INK, width=2)
    d.line([(56, 42), (50, 48)], fill=INK, width=2)
    # Legs spread left
    d.rectangle([ 6, 44, 16, 56], fill=pants)
    d.rectangle([14, 48, 24, 58], fill=pants)
    if hair_fn:
        hair_fn(d, 38)


# ── Sheet save wrapper ────────────────────────────────────────────────────────

def save_player_sheet(anims, char_name):
    """anims: list of (anim_name, frame_list). Pads each row to 10 cols.
    Saves to assets/art/sprites/<char_name>.png."""
    return save_sheet(anims, T, T, f"{char_name}.png")
