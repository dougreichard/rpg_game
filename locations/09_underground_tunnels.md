# 9. The Underground Tunnels

**Script:** `scripts/levels/underground_tunnels.gd`
**Entering duo:** Evan + Ethan
**Unlock condition:** TBD (mid-game)

---

## Current layout

Y/T-shaped tunnel network — south entry corridor (Doorway/spawn) → central
junction chamber (hiding spot, patrolling enemy) → west tunnel dead-end
(Evan's rubble) + east tunnel dead-end (Ethan's multi-step hatch).

Ethan's hatch is the project's first multi-step effort gate: 3 pips, each
press fills one, only the third completes the hack. Partial progress persists
across exits (`hatch_progress` int stored via `set_level_flag`). Twinkle's
bark distraction also implemented here. ✓

---

## Improved floor plan

```
+--WEST TUNNEL--+   +--EAST TUNNEL---+
|               |   |                |
|   [RUBBLE]    |   |  [HATCH]       |
|   (Evan)      |   |  pip pip pip   |  ← 3-press gate
|               |   |  (Ethan)       |
+-------+   +---+   +---+   +--------+
        |   |           |   |
        | JUNCTION CHAMBER  |
        |  [hiding spot] |
        |  [pipe cluster]|
        |  [puddle]      |
        |  [enemies]     |
        +------+---------+
               |
       +-------+--------+
       | ENTRY CORRIDOR  |
       |  [warning strip]|
       |  [Doorway]      |
       |  [spawn]        |
       +-----------------+
```

---

## Visual props to add

1. **Pipe cluster** — `make_pipe_cluster_texture(w, h)` — 3–4 overlapping circles/ovals of varying sizes at junction walls. Utility-pipe grey. Non-collidable.
2. **Rusty hatch** — `make_hatch_texture(r)` — circular cover with a cross-brace pattern and bolts at cardinal points. Replace current rectangle prop.
3. **Rubble pile** — `make_rubble_texture(w, h)` — irregular cluster of grey angular shapes (jagged polygon fragments). Replaces current rectangle prop.
4. **Warning stripe** — `_draw()` diagonal black/yellow stripes (8px alternating bands) on tunnel walls near the hatch and rubble. Classic hazard marking.
5. **Puddle** — flat teal ellipse at floor level in junction. `z_index = -1`, non-collidable.
6. **Dim lantern** — small warm circle glow (`draw_circle()`, warm yellow, alpha 0.15) around a wall hook in each tunnel. Suggests darkness without a real lighting system.

### Prop draw functions to request

```
"Add make_pipe_cluster_texture(w, h) to PlaceholderArt. Draw 3–4
overlapping ellipses of varying sizes in utility grey, with 1px dark
outlines. Intended as a wall-mounted pipe junction."

"Add make_hatch_texture(diameter) to PlaceholderArt. A circle with
a cross-brace (two perpendicular lines dividing it into quarters)
and small square bolt shapes at N/S/E/W positions. Rusty brown."

"Add make_rubble_texture(w, h) to PlaceholderArt. An irregular heap
of angular fragments — draw 6–8 small filled polygons (3–5 vertices
each) overlapping in a pile, in stone grey tones."
```

---

## Palette

```
FLOOR_BASE_COLOR   = Color(0.18, 0.16, 0.14)   # dark earthy
FLOOR_ACCENT_COLOR = Color(0.28, 0.24, 0.20)   # worn stone
```

---

## Puzzles

- Evan presses Special near rubble → clears it (Twinkle distraction when used away from rubble)
- Ethan presses Special at hatch 3× → multi-step hack (`security_badge` pre-fills 1 pip on entry)
- `rusty_key` opens shortcut door (consume on use, immediate overworld exit)
- `rusty_key` loot box in west tunnel near rubble
- `security_badge` loot box in east tunnel near hatch
- `pocket_lantern` loot box in junction chamber (reveals hidden loot boxes in dark areas — future mechanic)

---

## Atmosphere notes

This location is the darkest visually — the palette is intentionally low-contrast.
The warning stripes on walls near hazards are a quick `_draw()` pattern (diagonal
lines, no new function) that immediately telegraphs danger. The hatch and rubble
upgrades from rectangles to their actual shapes (circle + pile) are the most
impactful prop changes; everything else is atmosphere layered on top. The dim
lantern glow circles are a zero-cost `draw_circle()` with low alpha that gesture
toward a lighting system without needing one.
