# 1. Bellows & Sons Pipe Organ Works

**Script:** `scripts/levels/pipe_organ_works.gd`
**Entering duo:** Quinn + Erin
**Unlock condition:** Available from the start
**Unlocks:** Erin

---

## Current layout

Entry bay → hallway → main workshop floor + secret parts closet behind a
hidden lever wall. Multi-room with camera follow. ✓

---

## Improved floor plan

```
+------------------------------------------+
|          PARTS CLOSET                    |  ← secret; lever reveals it
|  [gear loot]                             |
+-------SecretWall---------+               |
                           |               |
+------------------+  HALLWAY  +-----------+
|                  |           |
|   ENTRY BAY      |   MAIN WORKSHOP       |
|   [Doorway]      |                       |
|   [spawn]        |   [ORGAN]  [BELLOWS]  |
|                  |                       |
|   [pipe rack]    |   [workbench]         |
|                  |   [loot] [loot]       |
+------------------+-----------+-----------+
```

---

## Visual props to add

1. **Pipe rack** — tall vertical cylinders in a row (varying heights 8–24px), warm brass/copper tone
2. **Bellows** — wide accordion-shaped prop (horizontal zigzag outline), warm copper
3. **Workbench** — horizontal surface with small tool silhouettes on top
4. **Overhead pipes** — thin horizontal lines crossing the ceiling band (pure decoration)
5. **Soot stain** — irregular dark smudge ellipse on walls near the organ

### Prop draw functions to request

```
"Add make_pipe_rack_texture(w, h, n_pipes) to PlaceholderArt. Draw n_pipes
vertical rectangles of varying height, evenly spaced, in a warm brass color."

"Add make_bellows_texture(w, h) to PlaceholderArt. Draw a horizontal zigzag
shape (accordion) in copper tone with a darker border."

"Add make_workbench_texture(w, h) to PlaceholderArt. Flat rectangle with
3–4 small tool silhouettes (wrench, hammer outlines) drawn on top."
```

---

## Palette

```
FLOOR_BASE_COLOR   = Color(0.28, 0.20, 0.16)   # warm soot brown
FLOOR_ACCENT_COLOR = Color(0.45, 0.30, 0.18)   # brick red accent
```

---

## Puzzles

- Quinn presses Special near organ → repairs it (requires `brass_organ_pipe` item)
- Secret lever in hallway wall → reveals parts closet
- `spare_clockwork_gear` loot box in parts closet (hidden until secret revealed)
- `bent_spoon` junk loot box on main floor
- `brass_organ_pipe` functional loot box on main floor

---

## Atmosphere notes

The defining prop is the organ itself — already implemented as a colored
rectangle. The biggest single visual upgrade would be adding pipe details:
a row of vertical cylinders of varying heights behind the keyboard console.
The workbench and bellows fill in the "factory floor scattered with parts"
spec line. Overhead pipe lines are free (just `_draw()` lines) and
immediately read as an industrial interior.
