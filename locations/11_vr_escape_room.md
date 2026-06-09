# 11. VR Escape Room

**Script:** `scripts/levels/vr_escape_room.gd`
**Entering duo:** Quinn + Ethan
**Unlock condition:** TBD (late mid-game)

---

## Current layout

Boot Chamber (cyber-blue, Doorway/spawn/enemies) → Corridor 1 → Stage Alpha
("medieval" glitch, warm amber, Quinn's physics-glitch repair) → Corridor 2
→ Stage Beta ("underwater" glitch, teal-aqua, Ethan's system console).

Each stage has its own `TileMap` palette layer painted on top of the base
floor via `_paint_stage_floor()`. Crossing a corridor threshold visibly
recolors the floor. ✓

---

## Improved floor plan

```
+-----STAGE BETA (underwater)--+
|  [SYSTEM CONSOLE]            |  ← Ethan's hack
|  [fish silhouette ×3]        |  ← floating in teal background
|  [bubble column ×2]          |
+------CORRIDOR 2--------------+
                               |
+-----STAGE ALPHA (medieval)---+
|  [PHYSICS GLITCH prop]       |  ← Quinn's repair
|  [castle gate frame]         |
|  [stone pillar ×2]           |
+------CORRIDOR 1--------------+
                               |
+-----BOOT CHAMBER-------------+
|  [cyber grid overlay]        |  ← cyan grid lines in _draw()
|  [spawn grid marker]         |
|  [Doorway]                   |
|  [spawn]                     |
|  [enemies]                   |
|  [hiding spot]               |
|  [loot] [loot]               |
+------------------------------+
```

---

## Visual props to add

1. **Boot Chamber grid** — `_draw()` cyan grid lines (1px, every 8px, alpha=0.25) over the entire Boot Chamber floor area. Classic VR/cyber aesthetic. Free.
2. **Spawn marker** — `_draw()` cyan circle at player spawn position (radius 16px, alpha=0.4, `NO_FILL`). Suggests a VR "spawn point" indicator.
3. **Castle gate frame** — `make_castle_gate_texture(w, h)` — two stone-grey vertical columns with a horizontal portcullis bar between them, crenellation teeth at top. Stage Alpha backdrop.
4. **Stone pillar** — `make_stone_pillar_texture(w, h)` — narrow rectangle with a wider capital (top rectangle). Two in Stage Alpha. Collidable.
5. **Fish silhouette** — `make_fish_texture(w, h)` — simple ellipse body + triangle tail. 3× scattered in Stage Beta. Non-collidable, pure decoration.
6. **Bubble column** — `_draw()` column of 4 ascending circles (radii 3→6px, spaced 12px apart) in Stage Beta. Suggests underwater. Free.
7. **Glitch offset** — in Stage Alpha's `_draw()`, draw the physics-glitch prop rectangle one more time at +3px offset in a contrasting color, alpha=0.5. Simulates a corrupted render.

### Prop draw functions to request

```
"Add make_castle_gate_texture(w, h) to PlaceholderArt. Two stone-grey
vertical column rectangles with a horizontal bar connecting them at 2/3
height. Crenellation: 4 small rectangles on top of each column."

"Add make_fish_texture(w, h) to PlaceholderArt. An ellipse body with
a triangle tail fin at the left end. Simple single-color silhouette.
Use a slightly lighter teal than the Stage Beta floor."

"In vr_escape_room.gd's _draw(), add a cyber grid over the Boot Chamber
zone: draw horizontal and vertical lines every 8px within the boot
chamber bounds, in Color(0,0.8,0.8,0.25)."
```

---

## Palette

```
# Boot Chamber
FLOOR_BASE_COLOR   = Color(0.10, 0.15, 0.35)   # cyber midnight blue
# Stage Alpha (painted on top via _paint_stage_floor)
STAGE_ALPHA_BASE   = Color(0.55, 0.40, 0.20)   # warm medieval amber
STAGE_ALPHA_ACCENT = Color(0.70, 0.55, 0.30)   # lighter sandstone
# Stage Beta
STAGE_BETA_BASE    = Color(0.10, 0.45, 0.55)   # underwater teal
STAGE_BETA_ACCENT  = Color(0.15, 0.60, 0.65)   # lighter aqua
```

---

## Puzzles

- Quinn presses Special at physics-glitch prop → repairs it (`vr_override_chip` instant-clears)
- Ethan presses Special at system console → hacks it
- Both conditions + enemies cleared gate completion
- `vr_override_chip` loot box in Boot Chamber
- `bies_charm` loot box in Boot Chamber (+10% starting Bies charge)

---

## Atmosphere notes

The Boot Chamber cyber grid is the highest-impact free change — `_draw()` cyan
lines on the floor immediately establishes the VR setting before the player
even moves. The glitch-offset effect on Stage Alpha's prop (a second draw of
the same rectangle at +3px offset) is a clever way to make "corrupted VR
physics" visually legible without any new system. The fish + bubble columns in
Stage Beta require the `make_fish_texture()` function but the columns are free
`_draw()` calls — together they make the "underwater" theme land at a glance
rather than relying solely on the teal palette.
