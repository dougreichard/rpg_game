# 13. The Grand Marquee Cinema

**Script:** `scripts/levels/grand_marquee_cinema.gd`
**Entering duo:** Quinn + Ben (all five characters required to enter)
**Unlock condition:** Complete The Drop; all five movie tickets collected

---

## Current layout

Hub-and-wings — Lobby (south, Doorway/spawn) → Backstage hub (Boss guards
the aisle between wings) → Projection Booth (west, Quinn) + Balcony (north,
Ben's house organ elevated above the stage).

Unique: a cleared Doorway-exit routes to `ResultScreen.tscn` (endgame) rather
than the overworld. Entry is gated by `_has_all_tickets()` — all five character
movie tickets required. ✓

---

## Improved floor plan

```
+-----BALCONY--------------------+
|  [HOUSE ORGAN]                 |  ← Ben's puzzle (elevated, stage below)
|  [balcony railing]             |
+------+                +--------+
       |                |
+------BACKSTAGE/STAGE-----------+
|  [stage curtain]               |  ← deep red, gold fringe — decorative
|  [spotlight circles ×3]        |  ← pale floor decals
|  [BOSS spawn]                  |  ← holds the aisle between wings
|  [enemies]                     |
+---PROJ. BOOTH---+              |
|  [PROJECTOR]   |              |
|  [film reel]   |              |
|  [film can]    |              |
|  [loot] [loot] |
+----------------+
       |
+-----LOBBY---------------------+
|  [cinema seat rows ×4]        |  ← rows of seat shapes, theater red
|  [popcorn stand]              |
|  [ticket booth]               |
|  [Doorway]                    |
|  [spawn]                      |
+-------------------------------+
```

---

## Visual props to add

1. **Cinema seat row** — `make_seat_row_texture(w, h, n_seats)` — N upright seat shapes (rectangle with curved back) in a row. Theater red. 4 rows in lobby. Collidable — they route combat through the aisles.
2. **Stage curtain** — `make_stage_curtain_texture(w, h)` — tall wide rectangle, deep red (`Color(0.7,0.1,0.1)`), gold fringe strip at bottom (dashed `Color(0.8,0.65,0.1)` band). Decorative `Sprite2D` behind combat area, `z_index = -1`.
3. **Spotlight circle** — `_draw()`: 3 pale yellow filled circles (`Color(1,0.95,0.6,0.2)`) on stage floor at fixed positions. Pure atmosphere, free.
4. **Projector** — `make_projector_texture(w, h)` — boxy rectangle with a lens cone (triangle) extending forward. In projection booth.
5. **Film reel** — `make_film_reel_texture(r)` — two overlapping circles in dark grey (reel flanges) with a small center hub circle. On projector prop.
6. **Popcorn stand** — `make_popcorn_stand_texture(w, h)` — red/white vertical stripes (alternating 4px bands) on a tall rectangle with a wider base. Lobby prop.
7. **Ticket booth** — `make_ticket_booth_texture(w, h)` — rectangle with a small arched window cutout + horizontal counter bar. Lobby south side.
8. **Balcony railing** — `_draw()` horizontal line along the balcony's south edge (facing the stage below). 3px, gold tone. Free.

### Prop draw functions to request

```
"Add make_seat_row_texture(w, h, n_seats) to PlaceholderArt. Draw n_seats
theater seats side-by-side: each seat is a rectangle body with a slightly
wider back-rest rectangle at top. Theater red with darker armrest lines."

"Add make_stage_curtain_texture(w, h) to PlaceholderArt. A deep red
rectangle with a gold dashed fringe band at the bottom 6px. Optionally
add vertical fold lines every 8px in a slightly darker red."

"Add make_projector_texture(w, h) to PlaceholderArt. A boxy rectangle
(the projector body) with a narrow triangle (lens cone) extending from
its front face. Dark metal grey with a small circular lens highlight."

"Add make_popcorn_stand_texture(w, h) to PlaceholderArt. Alternating
red/white vertical stripes (4px each), slightly wider base rectangle.
A small awning triangle at the top."
```

---

## Palette

```
FLOOR_BASE_COLOR   = Color(0.25, 0.08, 0.08)   # deep theater red carpet
FLOOR_ACCENT_COLOR = Color(0.45, 0.35, 0.10)   # gold foyer trim
```

---

## Puzzles

- **Entry gate:** `_has_all_tickets()` — all five character movie tickets required
- Boss + Grunts must be cleared before either wing's puzzle can be completed
- Quinn presses Special at projector → repairs it (requires `film_reel` item)
- Ben presses Special at house organ → plays it
- All three conditions gate completion → Uncle Doug found in projection booth → endgame trigger
- `film_reel` functional loot box in lobby (required for projector repair)
- (5th ticket collected at The Drop — see `12_the_drop.md`)

---

## Atmosphere notes

The collidable seat rows in the lobby are both visual and mechanical — they
funnel the player through aisles and make the lobby feel like a real theater
space rather than an open rectangle. The stage curtain (`z_index = -1`, purely
decorative) combined with spotlight circles on the stage floor establishes
the performance space for the balcony standoff. The projector booth is the
narrative payoff: Uncle Doug is found inside, so the booth should feel
deliberately cramped and secretive — film cans on the floor, the projector
as the centerpiece, a single bare-bulb light (small warm circle `_draw()`).

This is the final location and the emotional climax of the game. Every visual
detail here should feel earned — the red carpet, the gold trim, the spotlights.
