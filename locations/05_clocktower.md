# 5. The Clocktower

**Script:** `scripts/levels/clocktower.gd`
**Entering duo:** Quinn + Ben
**Unlock condition:** All five characters unlocked

---

## Current layout

Vertical shaft — landing (ground floor) → gear floor (middle) →
belfry (top). Stairwell gaps connect floors. Boss spawns in the upper
stairwell gap ("the clockwork guardian holds the stairs"). ✓

Camera bounding box is unusually tall (352×592) so the climb reveals
itself floor by floor as the camera pans up the shaft.

---

## Improved floor plan

```
+--------BELFRY---------+
|  [BELL ×4]            |  ← hanging bell shapes, Ben's puzzle
|  [clock face]         |  ← north wall, decorative
|                       |
+---+    gap    +-------+
    |  STAIR   |         ← Boss spawns here (holds the stairs)
    +----------+
+---+    gap    +-------+
    |  STAIR   |
+--------GEAR FLOOR-----+
|  [GEAR large]         |  ← Quinn's puzzle prop
|  [GEAR small]         |  ← interlocking second gear
|  [PENDULUM]           |  ← animated swing via _draw()
|  [enemies]            |
|  [hiding spot]        |
|  [loot] [loot]        |
+---+    gap    +-------+
    |  STAIR   |
+-----------LANDING-----+
|  [Doorway]            |
|  [spawn]              |
+-----------------------+
```

---

## Visual props to add

1. **Gear** — `make_gear_texture(r, n_teeth)` — circle with evenly-spaced rectangular teeth around perimeter. Two gears: large (40px diameter) + small (24px diameter), positioned to interlock.
2. **Pendulum** — animated via `_draw()`: a vertical line + disc at bottom, angle offset by `sin(Time.get_ticks_msec() / 800.0) * 0.4` radians each frame. Call `queue_redraw()` from `_process`.
3. **Bell** — `make_bell_texture(w, h)` — rounded arch shape, wider at bottom than top. Four across belfry north wall.
4. **Clock face** — `make_clock_face_texture(r)` — circle with 12 tick marks + two hands (hour at 10, minute at 2 for a permanent "dramatic" time). North belfry wall.
5. **Stone arch** — thin arch outline on stairwell openings (decorative, above each gap).

### Prop draw functions to request

```
"Add make_gear_texture(diameter, n_teeth) to PlaceholderArt. A circle with
n_teeth evenly-spaced rectangular teeth (width 4px, height 6px) protruding
from the perimeter. Stone grey with a darker center hole circle."

"Add make_bell_texture(w, h) to PlaceholderArt. A bell shape: wide flat
top, curving out and back in to a flared rim at the bottom. Brass/golden tone."

"Add make_clock_face_texture(diameter) to PlaceholderArt. Circle outline,
12 tick marks at even intervals, two hands (clock frozen at 10:10)."
```

---

## Palette

```
FLOOR_BASE_COLOR   = Color(0.35, 0.33, 0.28)   # aged stone
FLOOR_ACCENT_COLOR = Color(0.55, 0.50, 0.35)   # warm sandstone
```

---

## Puzzles

- Boss + enemies cleared before belfry is reachable (Boss physically blocks the gap)
- Quinn presses Special near large gear → repairs mechanism (`spare_clockwork_gear` speeds it up)
- Ben presses Special near bells → plays correct tonal sequence (`sheet_music_page` or `tuning_fork` helps)
- Both conditions + enemies cleared gate completion
- `sheet_music_page` loot box on landing
- `tuning_fork` loot box on gear floor

---

## Atmosphere notes

The animated pendulum is the standout visual for this location — it's already
`_draw()` based, so adding a `sin()` oscillation to the pendulum arm is a few
lines and immediately makes the room feel alive. The interlocking gears (large
+ small at slightly different positions) reinforce "mechanical puzzle" without
needing any new asset beyond the draw function. The clock face on the belfry
north wall ties the exterior landmark (visible on the overworld) to the interior.
