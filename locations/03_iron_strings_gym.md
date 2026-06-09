# 3. Iron & Strings Gym

**Script:** `scripts/levels/iron_strings_gym.gd`
**Entering duo:** Quinn + Evan
**Unlock condition:** Complete Old Parish Church
**Unlocks:** Ben

---

## Current layout

Locker room (Doorway/spawn) → main gym floor (enemies, hiding spot) →
Ben's cage alcove (north, barbell StaticBody2D blocks the doorway). ✓

The barbell is a real `StaticBody2D` collider — Evan's Special disables it
and slides it aside via `create_tween()`.

---

## Improved floor plan

```
+--BEN'S CAGE ALCOVE--+
|  [BEN prop]         |
|  [bench press]      |
+----BARBELL-door-----+
|                     |
|     GYM FLOOR       |
|  [boxing bag]       |
|  [weight rack]      |
|  [floor mat]        |
|  [enemies]          |
|  [hiding spot]      |
|  [loot] [loot]      |
+-----+               |
| LOCKER ROOM         |
| [lockers row]       |
| [Doorway]           |
| [spawn]             |
+---------------------+
```

---

## Visual props to add

1. **Punching bag** — `make_punching_bag_texture(w, h)` — elongated oval with a chain hook at top. Warm leather brown. Hanging from ceiling band.
2. **Weight rack** — `make_weight_rack_texture(w, h)` — horizontal bar with 3 disc shapes stacked at each end. Iron grey.
3. **Floor mat** — darker rectangle tile area covering the ring zone. Non-collidable. Draw as a second `TileMap` layer (same pattern as VR Escape Room stage floors).
4. **Locker row** — `make_locker_row_texture(w, h, n)` — N tall narrow rectangles with a horizontal handle line each. Metal grey.
5. **Bench press bench** — flat padded rectangle with a short rack frame above it. In cage alcove beside Ben prop.

### Prop draw functions to request

```
"Add make_punching_bag_texture(w, h) to PlaceholderArt. An elongated
oval shape in warm leather brown with a small chain-link rectangle at
top and horizontal wrap lines across the bag body."

"Add make_weight_rack_texture(w, h) to PlaceholderArt. A horizontal
bar with disc shapes (thin rectangles) stacked at each end in iron grey."

"Add make_locker_row_texture(w, h, n_lockers) to PlaceholderArt.
N vertical rectangles side-by-side, each with a small horizontal
handle rectangle. Metal grey with darker borders between lockers."
```

---

## Palette

```
FLOOR_BASE_COLOR   = Color(0.25, 0.25, 0.28)   # concrete grey
FLOOR_ACCENT_COLOR = Color(0.45, 0.20, 0.18)   # iron red mat squares
```

---

## Puzzles

- Evan presses Special near barbell → slides it aside, opens cage doorway
- `ticket_ben` loot box in cage alcove (near Ben prop — found where he's freed)
- `animal_treat` loot box on gym floor

---

## Atmosphere notes

The cage alcove is the emotional payoff of this room — Ben is visibly trapped
there. Adding a bench press and cage-bar details on the alcove's south face
(vertical lines over the blocked doorway before the barbell is cleared)
reinforces the "locked away" feeling. The floor mat as a darker `TileMap`
layer in the ring area is a low-effort visual anchor that makes the gym
read as a gym even from a distance.
