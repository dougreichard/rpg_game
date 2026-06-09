# Hunkle Bunkle — Location Design Reference

Each file below covers one location: improved floor plan ASCII, visual props to
add, palette, puzzle summary, and improvement ideas.

Use as a briefing document when asking Claude to improve a location. Follow the
pattern from `better_rooms.md`: agree on the floor plan first, add prop draw
functions one at a time, then place them in the scene script.

## Locations

| # | File | Script | Entering Duo |
|---|------|--------|--------------|
| 0 | [00_overworld_map.md](00_overworld_map.md) | `overworld_map.gd` | n/a (hub) |
| 1 | [01_pipe_organ_works.md](01_pipe_organ_works.md) | `pipe_organ_works.gd` | Quinn + Erin |
| 2 | [02_old_parish_church.md](02_old_parish_church.md) | `old_parish_church.gd` | Quinn + Erin |
| 3 | [03_iron_strings_gym.md](03_iron_strings_gym.md) | `iron_strings_gym.gd` | Quinn + Evan |
| 4 | [04_recording_studio.md](04_recording_studio.md) | `recording_studio.gd` | Quinn + Ben |
| 5 | [05_clocktower.md](05_clocktower.md) | `clocktower.gd` | Quinn + Ben |
| 6 | [06_harbor_docks.md](06_harbor_docks.md) | `harbor_docks.gd` | Quinn + Evan |
| 7 | [07_library_archive.md](07_library_archive.md) | `library_archive.gd` | Erin + Ethan |
| 8 | [08_carnival.md](08_carnival.md) | `carnival.gd` | Quinn + Erin |
| 9 | [09_underground_tunnels.md](09_underground_tunnels.md) | `underground_tunnels.gd` | Evan + Ethan |
| 10 | [10_zip_line_park.md](10_zip_line_park.md) | `zip_line_park.gd` | Ethan + Ben |
| 11 | [11_vr_escape_room.md](11_vr_escape_room.md) | `vr_escape_room.gd` | Quinn + Ethan |
| 12 | [12_the_drop.md](12_the_drop.md) | `the_drop.gd` | Evan + Ethan |
| 13 | [13_grand_marquee_cinema.md](13_grand_marquee_cinema.md) | `grand_marquee_cinema.gd` | Quinn + Ben |

## Shared improvement strategy

Follow this order for any location:

1. **Floor plan** — agree on the ASCII layout before any code
2. **One prop draw function** — add to `PlaceholderArt` alone
3. **Place the prop** — call from `_build_props()` in the level script
4. **Puzzle hookup** — only after props are visually correct
5. **ComfyUI overlay** — generate atmospheric background panels last, drop in as `Sprite2D` with `z_index = -1`

Prompts that work:
```
"Add make_bookshelf_texture(w, h) to PlaceholderArt.
Vertical rectangles of varying width/height (book spines), alternating
3 muted PICO-8 colors, separated by 1px dark gaps. No new files."

"In library_archive.gd, add _build_props() after _build_walls(). Place
two collidable bookshelves at [pos1, pos2] using PlaceholderArt.make_bookshelf_texture().
Use the same StaticBody2D + CollisionShape2D pattern as the LibrarianDesk."
```
