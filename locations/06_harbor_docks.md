# 6. The Harbor & Docks

**Script:** `scripts/levels/harbor_docks.gd`
**Entering duo:** Quinn + Evan
**Unlock condition:** All five characters unlocked (mid-game, opens alongside Clocktower)

---

## Current layout

Entry pier (west, Doorway/spawn) → container-maze yard (MazeCrateA/B as
collidable routing obstacles) → crane platform alcove (north, Container
StaticBody2D seals the doorway).

Evan's Special hoists the container up and away with a swinging rotation
via a parallel `create_tween()`. Calvin & Coolidge combat-assist summon
lives in the yard alongside the enemies. ✓

---

## Improved floor plan

```
+--CRANE PLATFORM-------+
|  [crane arm]          |  ← diagonal line to east wall top corner
|  [winch drum]         |
|  [crane controls]     |
+----CONTAINER-door-----+
|       CONTAINER YARD  |
|  [MazeCrate A]        |  ← collidable routing obstacles
|  [MazeCrate B]        |
|                       |
|  [Calvin/Coolidge     |
|   spawn zone]         |
|  [hiding spot]        |
|  [enemies]            |
|  [loot] [loot] [loot] |
+-----+                 |
| PIER                  |
| [bollard ×3]          |
| [chain line]          |
| [water strip]         |
| [Doorway]             |
| [spawn]               |
+-----------------------+
```

---

## Visual props to add

1. **Crane arm** — diagonal thick line from crane platform center to east wall top corner. Iron grey. Drawn in `_draw()` or as a rotated `Sprite2D`.
2. **Winch drum** — `make_winch_texture(w, h)` — cylindrical drum (rectangle with arc caps) with a thin cable line wrapping around it.
3. **Bollard** — `make_bollard_texture(w, h)` — short rounded post, wider at base. 3× along pier south edge. Non-collidable.
4. **Chain** — dashed/dotted horizontal line connecting pier bollards. Pure `_draw()` decoration.
5. **Water strip** — 16px-tall teal rectangle at pier south edge, `z_index = -1`. Pure atmosphere.
6. **Cargo stencil** — add dot-matrix text ("HB IMPORT", "FRAGILE") to the existing MazeCrate face texture.

### Prop draw functions to request

```
"Add make_winch_texture(w, h) to PlaceholderArt. A squat cylinder shape
(rectangle with semicircle caps) with a thin cable line wrapped around
the drum. Iron grey."

"Add make_bollard_texture(w, h) to PlaceholderArt. A short rounded post:
wider rectangle base, narrower rectangle shaft, rounded cap at top. Dark iron."

"Add a water_strip Sprite2D to harbor_docks.gd's _build_props() — a
16px-tall teal rectangle at y=320 (pier south edge), full room width,
z_index = -1. Use PlaceholderArt.make_flat_color_texture(Color(0.1,0.5,0.6),
room_width, 16)."
```

---

## Palette

```
FLOOR_BASE_COLOR   = Color(0.35, 0.35, 0.30)   # weathered concrete
FLOOR_ACCENT_COLOR = Color(0.22, 0.30, 0.40)   # wet dock blue-grey
```

---

## Puzzles

- Evan presses Special near Container → hoists it (Calvin & Coolidge alt route for combat distraction)
- `crowbar` item bypasses the container gate directly (alternate route without C&C)
- `crowbar` loot box in yard
- `crane_crank_handle` loot box on crane platform
- `faded_treasure_map` junk loot box on pier

---

## Atmosphere notes

The water strip at the pier's south edge is the single cheapest visual win for
this location — a 16px teal rectangle behind everything immediately establishes
"we're at a dock" without any new prop system. The crane arm diagonal and
winch drum on the crane platform complete the scene. The MazeCrates already
read as cargo — adding a stenciled text pattern to their face texture is a
small tweak to `make_gate_texture` (or a wrapper) that makes them feel like
real freight.
