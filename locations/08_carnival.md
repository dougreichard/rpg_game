# 8. The Carnival & Fairground

**Script:** `scripts/levels/carnival.gd`
**Entering duo:** Quinn + Erin
**Unlock condition:** TBD (mid-game)

---

## Current layout

Open midway (Doorway/spawn, enemies, broken ride prop) → BackstageGate
StaticBody2D (velvet curtain barrier) → backstage alcove (north, Doug poster
prop visible only after curtain rises).

Erin's talk-down at the gate raises the curtain via `create_tween()`
(upward slide + vertical scale-to-near-zero). Doug poster was always present,
hidden behind the opaque curtain until revealed. ✓

---

## Improved floor plan

```
+------BACKSTAGE----------+
|  [DOUG POSTER]          |  ← revealed when curtain rises
|  [costume rack]         |
|  [vanity mirror]        |
+------BackstageGate------+
|         MIDWAY          |
|  [ferris wheel arc]     |  ← partial circle, north wall band
|  [game booth ×2]        |
|  [bunting strings]      |  ← decorative triangles across top band
|  [broken RIDE]          |  ← Quinn's puzzle
|  [hiding spot]          |
|  [enemies]              |
|  [loot] [loot] [loot]   |
+------+          +-------+
       |   GATE   |
       | [Doorway]|
       | [spawn]  |
       +----------+
```

---

## Visual props to add

1. **Bunting string** — `_draw()` decoration: alternating colored triangles (8px base × 8px tall) across the top 12px of the room. Pure atmosphere, free with `draw_colored_polygon()`.
2. **Game booth** — `make_game_booth_texture(w, h)` — rectangular stall outline with a flat awning (contrasting color rectangle) at top. 40×40px × 2 on midway sides.
3. **Ferris wheel arc** — `_draw()`: partial circle arc at north wall (top quarter of a 64px radius wheel), 4 thin spoke lines to an off-screen center. Pure decoration.
4. **Costume rack** — `make_costume_rack_texture(w, h)` — horizontal bar with 4 hanger silhouettes (triangle + vertical line each). Backstage only.
5. **Vanity mirror** — `make_vanity_mirror_texture(w, h)` — oval outline with 6 small dot-bulbs evenly spaced around the perimeter. Backstage only.

### Prop draw functions to request

```
"Add make_game_booth_texture(w, h) to PlaceholderArt. A rectangular
booth stall outline with a contrasting-color awning rectangle at top,
and a horizontal counter bar 1/3 up from the bottom."

"Add bunting decoration to carnival.gd's _build_props() via _draw()
calls: alternating filled triangles (base w=8, h=8) strung across
y=8 to y=16, covering the full room width. Cycle 3 PICO-8 colors."

"Add make_costume_rack_texture(w, h) to PlaceholderArt. A horizontal
bar at top with 4 hanger silhouettes hanging from it — each hanger is
a small triangle (shoulder shape) with a thin vertical line below."
```

---

## Palette

```
FLOOR_BASE_COLOR   = Color(0.70, 0.65, 0.40)   # worn sawdust / dirt
FLOOR_ACCENT_COLOR = Color(0.85, 0.35, 0.25)   # carnival red
```

---

## Puzzles

- Quinn presses Special near broken ride → repairs it
- Erin presses Special at BackstageGate → curtain rises, reveals Doug poster (`backstage_pass` bypasses)
- Both conditions + enemies cleared gate completion
- `backstage_pass` loot box on midway (right side booth area)
- `ticket_erin` loot box in backstage alcove
- `ticket_stub_torn` junk loot box near gate entrance (looks like a ticket — it's from a different theater)

---

## Atmosphere notes

The bunting string across the top band is the cheapest-highest-impact decoration
for this location — a single `_draw()` loop of alternating colored triangles
immediately reads as a fairground. No new prop function needed. The ferris wheel
arc at the north wall adds the location's "landmark" silhouette visible from
across the midway. The game booths as collidable stalls give the wide midway
some routing structure for combat.
