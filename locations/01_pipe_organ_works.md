# 1. Bellows & Sons Pipe Organ Works

**Script:** `scripts/levels/pipe_organ_works.gd`
**Entering duo:** Quinn + Erin (Erin is "on loan" from Mr. Bellows  --  see
"Erin's unlock" below; she is not yet part of the traveling roster on a new
game)
**Unlock condition:** Available from the start
**Unlocks:** Erin

---

## Current layout — IMPLEMENTED

Entry bay → hallway → main workshop floor + secret parts closet behind a
hidden lever wall, plus a Manager's Office reached through a doorway gap in
the entry bay's south wall. Multi-room with camera follow. ✓

```
+------------------------------------------+
|          PARTS CLOSET                    |  <- secret; lever reveals it
|  [gear loot]                             |
+-------SecretWall---------+               |
                           |               |
+------------------+  HALLWAY  +-----------+
|                  |           |
|   ENTRY BAY      |   MAIN WORKSHOP       |
|   [Doorway]      |   [overhead pipes]    |
|   [spawn]        |   [soot stain]        |
|   [pipe rack]    |   [ORGAN]             |
|                  |              [BELLOWS]|
+------+-----+-----+   [pipe loot][spoon]  |
       |     |         [hiding spot]       |
  +----+-----+----+----------------------- +
  | MANAGER'S OFFICE |
  | [desk] [Mr. Bellows] |
  +------------------+
```

Camera bounds: `(24,24)`–`(1352,656)`. `FLOOR_COLS = 43`, `FLOOR_ROWS = 20`.

---

## Erin's unlock — IMPLEMENTED ("on loan")

A new game starts with `GameManager.unlocked_characters = ["quinn"]` only —
Erin is not part of the traveling roster yet. Inside Pipe Organ Works,
however, both `Players/Quinn` and `Players/Erin` are spawned and playable from
the start exactly as before (zero Player/HUD/swap architecture changes):
narratively, Erin already works for Mr. Bellows and is "on loan" to help Quinn
get the organ working. `complete_location("pipe_organ_works")` (which already
appends `"erin"` to `unlocked_characters`) is the moment she's "officially"
recruited into the traveling duo. The overworld's `_spawn_duo()` doesn't spawn
a standby player at all while `unlocked_characters.size() <= 1` — `_swap_duo()`
and the per-frame follow/camera update already guarded with
`is_instance_valid(_standby_player)`, so no new guard code was needed.

---

## Manager's Office & the tuning key — IMPLEMENTED

`_build_office_wing()` removes `Walls/EntryBottom` (a single 320x16 span
shared via `SubResource` with `EntryTop`) and replaces it with two shorter
segments (`EntryBottomLeft`/`EntryBottomRight`) flanking a 96px doorway gap,
plus three new walls (`OfficeLeft`/`OfficeRight`/`OfficeBottom`) forming a
96x128 room below the entry bay. Runs before `_build_walls()`, which iterates
`$Walls.get_children()` generically and textures the new segments like every
other wall — no further `.tscn` edits needed.

Mr. Bellows (`MANAGER_POS = (200, 590)`, an `AnimatedSprite2D` using the
generic humanoid placeholder via `PlaceholderArt.make_player_frames`, same as
overworld town NPCs) waits at his desk (`DESK_POS = (200, 545)`, drawn with
`make_workbench_texture`). A level-local `DialogBoxScript` instance (the same
generic, reusable Control overworld_map.gd uses for NPC dialog) handles the
conversation, opened via `_talk_to_manager(char_name)` when either character
presses Special within `MANAGER_RADIUS` (64px):

- **Quinn, first visit** (`manager_met == false`): intro dialog — Mr. Bellows
  explains the workshop's state and mentions he's lost his tuning key, hinting
  Erin might be able to talk it out of him.
- **Erin, before the key is given** (`tuning_key_given == false`): takes
  priority over Quinn's branches — Erin's Fast Talk gets Mr. Bellows to hand
  over `tuning_key`, granted to Erin on dialog-close (`_on_manager_dialog_closed`,
  deferred like the town quest turn-in pattern — never granted mid-conversation).
- **Quinn, after meeting but before the key** (`manager_met && !tuning_key_given`):
  a short reminder line.
- **Either, after the key is given**: a short "after" line.

The organ repair gate (`_has_organ_parts()`) now requires **both**
`brass_organ_pipe` (a workshop loot box, as before) **and** `tuning_key`
(from Mr. Bellows) — held by either Quinn or Erin.

`level_progress["pipe_organ_works"]` flags: `manager_met`, `tuning_key_given`
(alongside the existing `enemies_cleared`/`organ_repaired`/`secret_revealed`/
loot-open flags), restored in `_restore_progress()`.

`_process()` routes `ui_accept` to `_dialog_box.advance()` and returns early
while the dialog is open (mirrors `overworld_map.gd`'s dialog-open branch);
`_on_special_used()` returns immediately if the dialog is open.

---

## Goal banner — IMPLEMENTED

`_create_goal_banner()` builds a plain `CanvasLayer`/`Label` (`layer = 18`,
between `HintOverlay` at 15 and `ClearOverlay` at 20) showing:

> GOAL: Clear the workshop, find the organ's missing parts, and repair the
> pipe organ for Mr. Bellows.

across the top of the screen for `GOAL_DISPLAY_DURATION` (6s), then fades out
via `create_tween()` and `queue_free()`s itself. `_update_hint()` carries the
moment-to-moment objective afterward, now staged across four steps:

1. Enemies not cleared → "clear them out, check the crates"
2. Enemies cleared, no `brass_organ_pipe` yet → "find it in a crate, then
   repair the organ"
3. Have the pipe but `tuning_key_given == false` → "Erin: find Mr. Bellows'
   office and fast-talk the tuning key out of him"
4. Have both parts, organ not yet repaired → "approach the organ and press G"

---

## Visual props — IMPLEMENTED

All five generated at runtime via `PlaceholderArt`, no imported art (original-
IP guarantee intact):

1. **Pipe rack** (`make_pipe_rack_texture`, entry bay at `(80, 180)`) — 4
   freestanding vertical brass cylinders of varying height, anchored to the
   bottom of the bounding box.
2. **Bellows** (`make_bellows_texture`, main workshop at `(960, 440)`) — an
   80x40 copper panel with diagonal accordion-fold creases.
3. **Workbench / Mr. Bellows' desk** (`make_workbench_texture`, office at
   `DESK_POS = (200, 545)`) — a 64x32 tabletop with hammer/wrench/screwdriver
   silhouettes; doubles as the manager-dialog anchor prop.
4. **Overhead pipes** (`make_pipe_rack_texture`, main workshop at
   `(1000, 56)`, `rotation = PI`) — the same pipe-rack texture flipped so the
   pipes hang down from the workshop's top wall.
5. **Soot stain** (`make_soot_stain_texture`, main workshop at `(840, 45)`) —
   a 96x64 noisy-edged dark smudge straddling the top wall above the organ.

---

## Palette — as shipped

```
FLOOR_BASE_COLOR   = Color(0.32, 0.29, 0.27)   # warm soot grey-brown
FLOOR_ACCENT_COLOR = Color(0.6, 0.48, 0.22)    # brass/gold accent
```

---

## Puzzles — IMPLEMENTED

- Quinn presses Special near the organ → repairs it (requires **both**
  `brass_organ_pipe` *and* `tuning_key`, held by either Quinn or Erin —
  `_has_organ_parts()`)
- `brass_organ_pipe` functional loot box on main floor
- `tuning_key` — Erin fast-talks it out of Mr. Bellows in the new Manager's
  Office (see "Manager's Office & the tuning key" above)
- Secret lever in hallway wall → reveals parts closet
- `spare_clockwork_gear` loot box in parts closet (hidden until secret
  revealed)
- `bent_spoon` junk loot box on main floor

---

## Atmosphere notes

The organ remains the defining prop, now flanked by overhead pipes and a soot
stain that read as decades of organ exhaust staining the workshop ceiling. The
bellows and Mr. Bellows' desk/workbench fill in the "factory floor scattered
with parts" spec line; the pipe rack does the same for the entry bay. The
Manager's Office gives the location its first stationary NPC and dialog-driven
puzzle, and the goal banner + staged hints make the four-step "clear → find
the pipe → fast-talk the key → repair" loop explicit from the moment the duo
walks in.
