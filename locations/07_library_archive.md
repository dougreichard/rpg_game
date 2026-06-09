# 7. The Public Library & Archive

**Script:** `scripts/levels/library_archive.gd`
**Entering duo:** Erin + Ethan
**Unlock condition:** TBD (mid-game)

---

## Current layout

Public reading room (west, enemies + hiding spot) → LibrarianDesk
StaticBody2D (seals the only passage) → Restricted Stacks (east, archive
terminal).

Erin's Special at the desk scales it down and fades it via `create_tween()`
("she packs up her desk and steps aside"), physically opening the stacks. ✓

---

## Improved floor plan

```
+------RESTRICTED STACKS---------+
|  [ARCHIVE TERMINAL]            |  ← Ethan's hack
|  [filing cabinet ×3]           |
|  [tall bookshelf ×2]           |
+------LibrarianDesk-door--------+
|       PUBLIC READING ROOM      |
|  [reading table ×3]            |
|  [short bookshelf ×2]          |
|  [card catalog cabinet]        |
|  [hiding spot]                 |
|  [enemies: Grunt + Sentry]     |
|  [loot] [loot]                 |
+-----+                 +--------+
      |      FOYER      |
      |  [Doorway]      |
      |  [spawn]        |
      +-----------------+
```

---

## Visual props to add

1. **Bookshelf** — `make_bookshelf_texture(w, h)` — vertical rectangles (spines) of varying widths/heights, alternating 3 muted colors, 1px dark gaps between. Short (40×24px) in reading room, tall (40×40px) in stacks. Collidable.
2. **Reading table** — `make_reading_table_texture(w, h)` — flat rectangle with 2 chair silhouettes each side and a thin lamp shape on top. Non-collidable.
3. **Card catalog cabinet** — `make_card_catalog_texture(w, h)` — 4×5 grid of small drawer rectangles with tiny handle dots. Dark wood.
4. **Filing cabinet** — `make_filing_cabinet_texture(w, h)` — tall narrow rectangle with 3 horizontal drawer lines + small handle dots. In stacks only.
5. **Archive terminal** — same shape as Recording Studio soundboard but taller and with cyan glow at top edge. Already implied by existing archive hack prop.

### Prop draw functions to request

```
"Add make_bookshelf_texture(w, h) to PlaceholderArt. Fill width with
vertical book spines of varying widths (6–10px), varying heights
(h*0.5 to h*0.9), cycling through 3 muted colors. 1px dark gap between
spines. Shelf base is a solid darker rectangle at the bottom."

"Add make_reading_table_texture(w, h) to PlaceholderArt. A flat table
rectangle with 4 simple chair silhouettes (small rectangles) on each
long side. A thin lamp rectangle at center."

"Add make_card_catalog_texture(w, h) to PlaceholderArt. A cabinet face
divided into a 4x5 grid of small drawer rectangles, each with a 1px
handle dot. Dark wood tone."
```

---

## Palette

```
FLOOR_BASE_COLOR   = Color(0.82, 0.78, 0.68)   # warm cream / parchment
FLOOR_ACCENT_COLOR = Color(0.65, 0.60, 0.50)   # aged oak
```

---

## Puzzles

- Erin presses Special at LibrarianDesk → steps aside (`library_card` item bypasses)
- Ethan presses Special at archive terminal → hacks it
- Both conditions + enemies cleared gate completion
- `library_card` loot box in reading room
- `skeleton_key` junk loot box in stacks (seems like it should open everything — it doesn't)

---

## Atmosphere notes

Bookshelves are the most important prop for this location — two short ones in
the reading room and two tall ones in the stacks immediately establish the
spatial vocabulary. Collidable bookshelves in the stacks create a light maze
feel matching the "slower, stealth-and-puzzle counterpoint" spec tone. The card
catalog in the reading room is a strong period detail (libraries had these before
digital archives) that also serves as visual cover for the hiding spot.
