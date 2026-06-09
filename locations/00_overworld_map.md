# 0. The Overworld Map

**Script:** `scripts/overworld/overworld_map.gd`
**Scene:** `scenes/overworld/OverworldMap.tscn`
**Entering duo:** n/a (hub — duo is whichever pair is currently active/standby)
**Unlock condition:** n/a (always available after the title screen)
**Unlocks:** Access to all 13 locations as their unlock conditions are met

---

## Current layout

A single 1280×720 `Node2D` with no `TileMap` and no player character. The
playable map occupies the top 1280×608px; a `CanvasLayer` UI panel (title,
subtitle, info panel, hint) fills the bottom 608–720px band. Everything is
drawn programmatically in `_draw()`:

- Flat grass-green base rectangle + a few lighter "mow stripe" rectangles
- Three hardcoded park-zone rectangles and a harbor water rectangle (with
  drawn wave lines)
- **Roads** are straight diagonal `draw_line()` segments connecting each
  pair in `CONNECTIONS` directly between `LOCS[idx]["pos"]` points, with
  small circles at intersections
- **Buildings** are single-color rectangles per location
  (`_building_color`/`_building_half`), each with a hand-drawn icon
  (`_draw_icon`) — gear, arch, dumbbell, note, clock, anchor, book, star,
  tunnel, zipline, hex, chevron, film
- A handful of simple tree shapes (`_draw_trees`/`_draw_tree`)
- Navigation is **cursor-based**: `_cursor_idx` selects a location,
  `ui_left`/`ui_right`/`move_left`/`move_right` cycle through `LOCS`, a
  pulsing ring (`_draw_cursor_ring`) marks the selection, and
  `ui_accept`/`attack` calls `_launch()` — there is no player-controlled
  character on this screen at all

This works, but it's visually flat compared to the 13 location interiors,
which all now have `TileMap` floors, brick-textured walls, and a duo that
walks around. The overworld is the odd one out.

---

## Improved floor plan

Grid: **40 cols × 19 rows** at 32px tiles = 1280×608px (matches the existing
playable area exactly; the UI CanvasLayer band below is untouched).

```
col:      0    5    10   15   20   25   30   35   40
row 0   +-------------------------------------------+
row 1   |              [GRAND MARQUEE]               |
row 2   |  17-21, rows 0-3 (5x4, film icon)          |
row 3   |        [THE DROP]      [VR ROOM]           |
row 4   |        8-11,rows3-5     24-27,rows3-5      |
row 5   |        [LIBRARY]                [CARNIVAL] |
row 6   |        12-15,rows4-6            25-29,r6-9 |
row 7   |                          [CLOCKTOWER]      |
row 8   |                          19-21,rows4-7     |
row 9   |                                  [ZIPLINE] |
row 10  |                                  30-33,r8-10
row 11  |  [OLD PARISH]    [IRON GYM]                |
row 12  |  9-12,rows12-14  15-18,r11-13               |
row 13  |                            [RECORDING STD] |
row 14  |                            21-24,rows12-14 |
row 15  |  [PIPE ORGAN]      [UNDERGROUND]   [HARBOR]|
row 16  |  3-6,rows15-17     20-23,r15-17    27-31,r14-16
row 17  |                                             |
row 18  +-------------------------------------------+
```

(Approximate — see "Building footprints" below for exact tile rects. The
sketch above is for relative orientation, not pixel-precise.)

### Building footprints (top-left tile, size in tiles)

| Location | Anchor (col,row) | Size (cols×rows) | Terrain row (building tiles) |
|---|---|---|---|
| 1. Pipe Organ Works | (3,15) | 4×3 | 1 = WORKSHOP |
| 2. Old Parish Church | (9,12) | 4×3 | 0 = STONE |
| 3. Iron & Strings Gym | (15,11) | 4×3 | 1 = WORKSHOP |
| 4. Recording Studio | (21,12) | 4×3 | 2 = WOOD |
| 5. Clocktower | (19,4) | 3×4 | 0 = STONE |
| 6. Harbor & Docks | (27,14) | 5×3 | 5 = DOCK |
| 7. Library & Archive | (12,4) | 4×3 | 0 = STONE |
| 8. Carnival & Fairground | (25,6) | 5×4 | 2 = WOOD |
| 9. Underground Tunnels | (20,15) | 4×3 | 4 = TUNNEL |
| 10. Zip Line Park | (30,8) | 4×3 | 3 = OUTDOOR (col 5/8, distinct from grass) |
| 11. VR Escape Room | (24,3) | 4×3 | 7 = CYBER |
| 12. The Drop | (8,3) | 4×3 | 3 = OUTDOOR (col 5/8, distinct from grass) |
| 13. Grand Marquee Cinema | (17,0) | 5×4 | 6 = CARPET |

All 13 footprints fit within the 40×19 grid with no overlaps.

---

## Visual props / systems to add

1. **3-layer `TileMap`** built once in `_build_floor()`, using the existing
   `PlaceholderArt.make_hb_tileset()` (8×12 atlas, already used by all 13
   location interiors):
   - **Layer 0 — Grass:** OUTDOOR row (3), lush grass (col 4) as the base
     fill across all 40×19 cells, with sparse-tuft (col 2) cells scattered
     on a period for texture — same "checkerboard-ish two-tone" approach as
     the location floors.
   - **Layer 1 — Roads:** STONE row (0), plain ashlar (col 0), painted along
     orthogonal L-shaped routes between each pair of connected locations'
     "door" tile (bottom-center of each footprint).
   - **Layer 2 — Buildings:** each location's footprint filled with its
     terrain row from the table above. Because roads are on layer 1 and
     buildings on layer 2 (drawn after/above), any road tile that happens to
     run under a building footprint is simply covered — no collision-avoiding
     routing logic needed.
2. **Orthogonal road routing** — for each pair in `CONNECTIONS`, route an
   L-shaped path: horizontal run from doorA to `(doorB.x, doorA.y)`, then
   vertical run to doorB (or vice versa, whichever keeps the bend on open
   grass). Replaces the current diagonal `draw_line()` roads entirely.
3. **Player-controlled duo** — the overworld gains an `AnimatedSprite2D`
   pair using `PlaceholderArt.make_player_frames(sprite_color, character_name)`,
   one for the active character (player-controlled, WASD/`move_*`) and one
   for the standby (follows at a short delay, mirroring in-level standby
   behavior). The pair sourced the same way a level resolves its entering
   duo: `GameManager.pending_level_duo` if set, else the first two of
   `GameManager.unlocked_characters`. Spawns near the title-screen "home"
   building (Pipe Organ Works, the first unlocked location).
4. **NPC wander AI** — 3–5 small `AnimatedSprite2D` NPCs (neutral palette
   colors via `PlaceholderArt.make_player_frames`) using a lightweight
   wander script (`scripts/overworld/town_npc.gd`, no `class_name` — the
   established `preload()` + untyped-`var` pattern, see
   `[[feedback-godot-technical]]`): pick a random nearby road tile, walk to
   it, pause, repeat. Keeps the town feeling lived-in.
5. **Camera follow** — `Camera2D` follows the active character within the
   1280×608 bounding box (same `position_smoothing_enabled` pattern as the
   13 levels) — though since the whole map already fits in one screen at
   `zoom = (1,1)`, this is mostly about keeping the duo visually centered if
   the map is later made larger than one screen.
6. **Building "enter" prompt replacing cursor navigation** — walking the
   active character within a small radius of a building's door tile shows a
   prompt (reusing the existing info-panel/hint label); pressing
   `ui_accept`/`attack` there calls `_launch()` for that location (only if
   its unlock condition is met — locked buildings show a "locked" hint
   instead). `_cursor_idx`-based left/right cycling is removed entirely.

### Functions / systems to request when implementing

```
"In overworld_map.gd, replace the diagonal draw_line() roads with a TileMap
roads layer. For each pair in CONNECTIONS, compute an L-shaped tile path
between the two locations' door tiles (bottom-center of each footprint) and
set_cell() plain-ashlar (row 0, col 0) tiles along it on layer 1."

"Add scripts/overworld/town_npc.gd (Node2D, no class_name, preload pattern).
Wander AI: pick a random point within WANDER_RADIUS of a home tile, walk
there at a slow speed using an AnimatedSprite2D from
PlaceholderArt.make_player_frames(), pause PAUSE_DURATION, repeat."

"In overworld_map.gd, spawn the active/standby duo as AnimatedSprite2D pairs
using PlaceholderArt.make_player_frames(sprite_color, character_name), driven
by move_* inputs for the active character and a short-delay follow for
standby — mirroring the in-level player/standby relationship."
```

---

## Palette

Reuses `PlaceholderArt.make_hb_tileset()` — no new tileset needed:

```
Grass (layer 0):    row 3 (OUTDOOR), col 4 = lush grass, col 2 = sparse tufts
Roads (layer 1):    row 0 (STONE),   col 0 = plain ashlar
Buildings (layer 2): per-location terrain row, see footprint table above
```

---

## Gameplay changes

- Cursor-based `_cursor_idx` left/right navigation → **walk to a building's
  door tile and press interact/attack to launch it**
- Locked locations: walking up to them shows a "locked — complete X first"
  hint instead of allowing entry (mirrors the existing
  `LOCS[idx]["requires"]` check, just triggered by proximity instead of
  cursor selection)
- The active/standby duo shown matches `GameManager`'s current state, so the
  characters the player sees walking around the overworld are the same pair
  they'll enter the next location with — `preferred_active`/swap input still
  works here exactly as in a level
- NPCs are purely cosmetic (no dialogue/quest hooks in this pass) — they
  exist to make the town feel populated

---

## Atmosphere notes

The overworld is the player's "home base" between levels, and right now it
reads as a schematic map rather than a place. Giving it the same
`TileMap`-floor + brick-wall-style treatment as the 13 interiors — plus a
walking duo and a few wandering townsfolk — makes it feel like the first
"location" rather than a menu. Orthogonal roads connecting building doors
(rather than arbitrary diagonals between icon centers) read as an actual
street grid, reinforcing the "town" framing. Keep the existing per-location
icons (`_draw_icon`) as a final visual flourish on top of each building
footprint — they're a low-cost way to keep each building immediately
recognizable at a glance even before the player walks up to it.
