# 2. The Old Parish Church

**Script:** `scripts/levels/old_parish_church.gd`
**Entering duo:** Quinn + Erin
**Unlock condition:** Complete Pipe Organ Works
**Unlocks:** Evan

---

## Current layout

Vestibule → nave (Quinn/Erin puzzle pillars on opposite walls) → hidden
organ loft behind secret wall at altar end. No enemies. ✓

---

## Improved floor plan

```
+-------+----+-------+
|SIDE   |    |SIDE   |  ← optional alcoves
|CHAPEL |    |ORGAN  |
|[loot] |    |[loft] |  ← SecretWall reveals organ loft
+---+   |    |  +----+
    |          |
    |   N A V E         |
    |                   |
    | [pew][pew][pew]   |  ← 3 rows each side of center aisle
    | [pew][pew][pew]   |
    |                   |
    |  [QUINN pillar]   |  ← west wall mid (BLUE)
    |          [ERIN pillar]  ← east wall mid (RED)
    |                   |
    |     [ALTAR]       |  ← north end
    |   [candles ×3]    |
    +--+----------+-----+
       | VESTIBULE |
       | [Doorway] |
       +-----------+
```

---

## Visual props to add (priority order)

1. **Pew** — `make_pew_texture(color, w, h)` — dark wood bench with back rail at top + leg detail at each end. 80×18px. Collidable.
2. **Altar** — `make_altar_texture(w, h)` — raised stone platform with cloth-draped table on top. 64×24px, collidable front face.
3. **Stained glass** — `make_stained_glass_texture(w, h, colors)` — 3×4 grid of colored panels separated by 1px black lead lines. East + west nave walls, 32×64px each. *Biggest single visual upgrade for this location.*
4. **Candle** — `make_candle_texture(lit: bool)` — thin white stub, warm flame tip when lit. 8×24px.
5. **Arch window** — `make_arch_window_texture(w, h, glass_color)` — pointed arch outline with colored glass fill. Nave north wall above altar.

### Prop draw functions to request

```
"Add make_pew_texture(color, w, h) to PlaceholderArt. A bench: filled
rectangle with a 2px back rail across the top and small leg rectangles
at each end. Dark wood tone."

"Add make_stained_glass_texture(w, h, colors) to PlaceholderArt. Divide
space into a 3x4 grid of colored rectangles separated by 1px black lead
lines. Cycle through the colors array for each cell."

"Add make_candle_texture(w, h, lit) to PlaceholderArt. Thin white
rectangle (wax body) with a small orange flame teardrop at top if lit=true."
```

---

## Palette

```
FLOOR_BASE_COLOR   = Color(0.60, 0.58, 0.52)   # cool limestone
FLOOR_ACCENT_COLOR = Color(0.75, 0.72, 0.60)   # candlelit stone
```

---

## Puzzles

- Quinn presses Special at BLUE pillar (west nave) — congregation trust
- Erin presses Special at RED pillar (east nave) — skeptic challenges deception
- Both required; pillars are ~440px apart so the player must physically cross the nave and swap
- `ticket_quinn` loot box in side chapel alcove
- `faded_photograph` loot box near vestibule (lore — short Uncle Doug dialogue on pickup)

---

## Atmosphere notes

Stained glass on east/west nave walls is the highest-impact single improvement
for this location. Even a simple 4-color geometric fill makes the room
unmistakably a church. Pew rows add physical obstacles that give the wide
nave a sense of space and make the 440px pillar-to-pillar crossing feel
deliberate. Candles at the altar (3× non-collidable) are a future hook for a
sequential candle-lighting puzzle (see `better_rooms.md` multi-puzzle section).
