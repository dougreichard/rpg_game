# 12. The Drop

**Script:** `scripts/levels/the_drop.gd`
**Entering duo:** Evan + Ethan
**Unlock condition:** Late-game, after a credible lead on Uncle Doug's location

---

## Current layout

Touchdown Clearing (Doorway/spawn, enemies, wreckage) → Corridor →
Snag Grove (chute release tangled in branches).

Wreckage sits at the clearing's only exit north — physically gates the
corridor. Clearing it (directly via Evan's Special, or via William & Mary
bracing both flanks simultaneously) opens the path. ✓

---

## Improved floor plan

```
+------SNAG GROVE---------------+
|  [CHUTE RELEASE]              |  ← Ethan's hack (tangled lines above)
|  [tree branch ×3]             |  ← horizontal thick lines, ceiling band
|  [parachute fabric]           |  ← crumpled shape, off-white
|  [tangled cord lines]         |  ← thin spaghetti lines in ceiling
+------CORRIDOR------------------+
                                 |
+------TOUCHDOWN CLEARING--------+
|  [WRECKAGE]                   |  ← Evan's chokepoint (or William & Mary)
|  [impact crater]              |  ← behind wreckage, radial cracks
|  [scattered gear]             |  ← dots+lines radiating from wreckage
|  [parachute panel]            |  ← partial chute visible on floor
|  [hiding spot]                |
|  [enemies]                    |
|  [loot] [loot]                |
|  [Doorway]                    |
|  [spawn]                      |
+-------------------------------+
```

---

## Visual props to add

1. **Impact crater** — `make_crater_texture(r)` — ellipse outline with 6–8 radial crack lines extending out from center. Behind the wreckage prop. Ground grey.
2. **Parachute fabric** — `make_parachute_texture(w, h)` — large crumpled irregular polygon, off-white (Color(0.95, 0.92, 0.85)). Two instances: one partial on clearing floor (partial), one full in Snag Grove near chute release.
3. **Tree branch** — `make_branch_texture(w, h)` — horizontal thick rectangle (trunk) with 2–3 short diagonal rectangles (branches) extending up/down from it. In Snag Grove ceiling band. 3× at varying widths.
4. **Tangled cord** — `_draw()` in Snag Grove zone: 5–6 thin lines from ceiling band down to various x positions, with slight bends (quadratic-like zigzag via intermediate points). Simulates parachute cords caught in branches. Free.
5. **Scattered gear** — `_draw()` in clearing: 8–10 small dots and short line segments radiating from the wreckage center position. Debris field. Free.

### Prop draw functions to request

```
"Add make_crater_texture(w, h) to PlaceholderArt. An ellipse outline
with 6 radial crack lines extending from the center to the ellipse
edge and slightly beyond. Ground-grey tones."

"Add make_parachute_texture(w, h) to PlaceholderArt. An irregular
crumpled polygon shape — use 8–10 vertices offset from a rectangle
base by random-ish amounts — in off-white (Color(0.95, 0.92, 0.85))
with light fold-line detail."

"In the_drop.gd's _draw(), add scattered debris around LANDING_POS:
draw 10 small filled circles (radius 1–2px) and short lines (4–8px)
at random angles within a 40px radius. Stone-grey tone."
```

---

## Palette

```
FLOOR_BASE_COLOR   = Color(0.25, 0.35, 0.20)   # scrubby outdoor ground
FLOOR_ACCENT_COLOR = Color(0.40, 0.55, 0.28)   # dry grass
```

---

## Puzzles

- Evan presses Special near wreckage → clears it directly (opens corridor)
- William & Mary alternate route: Evan's Special away from wreckage → both companions must reach flanking points simultaneously to free it
- Ethan presses Special at chute release → hacks it
- All three conditions (clearing cleared + chute hacked + enemies cleared) gate completion
- `rabbits_foot_keychain` junk loot box in clearing (Evan assumes it'll help with William & Mary — it doesn't)
- `ticket_evan` loot box in Snag Grove

---

## Atmosphere notes

The impact crater behind the wreckage is the emotional anchor of this room —
it makes "they jumped from an airship and landed here" physically legible. The
scattered gear `_draw()` debris field around the crater radiates outward
from the impact point, reinforcing the crash-landing narrative. Tangled cord
lines in the Snag Grove ceiling complete the parachute-caught-in-trees image.
All three debris effects are `_draw()` calls — free, no new functions needed.
The parachute fabric shapes are the only new `PlaceholderArt` function required.
