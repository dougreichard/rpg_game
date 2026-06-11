## Gemini prompt template — per-location floor tileset

This is a **reusable template** for generating a floor tileset for any one of
the 13 locations (each location currently gets its 2-tile floor procedurally
from `PlaceholderArt.make_level_tileset(base, accent)`). Run this prompt once
per location, substituting that location's `BASE`/`ACCENT` colors and name
from the table below.

---

Generate a pixel-art floor tileset, in a clean modern pixel-art style similar
to *Stranger Things: 1984*'s character-swap art (vibrant, lightly shaded,
confident outlines — not flat 8-bit). This sheet is **opaque** — every tile
should be fully painted edge-to-edge (no transparency, no green-screen
needed).

**Canvas:** 64 x 32 px, divided into a strict grid of 32x32 px tiles, 2
columns x 1 row. Both tiles must **tile seamlessly** with themselves and with
each other when repeated edge-to-edge in any direction (this floor is laid
out as a checkerboard-ish alternating pattern across the whole room).

**Subject:** A dungeon/room floor for **<LOCATION NAME>**, evoking that
location's identity: <LOCATION IDENTITY>.

**Palette:** Base color `<BASE HEX>`, accent color `<ACCENT HEX>`, plus the
extended palette (DESIGN.md §2.0) for incidental detail. Use 2-3 step
highlight/shadow shading, no dithering.

**Tiles (left to right):**
1. **Plain floor tile** — a beveled stone/floor square in the base color
   `<BASE HEX>`, with a subtle highlight along the top/left edges and a
   subtle shadow along the bottom/right edges (a soft inset-panel look)
2. **Accent floor tile** — the same beveled floor square in the base color
   `<BASE HEX>`, but with a small decorative diamond-shaped inlay in the
   accent color `<ACCENT HEX>` centered in the tile

**Save to:** `assets/art/tiles/floor_<location_id>.png`

---

### Per-location substitutions

| Location | `<location_id>` | `<LOCATION IDENTITY>` | `<BASE HEX>` | `<ACCENT HEX>` |
|---|---|---|---|---|
| Bellows & Sons Pipe Organ Works | `pipe_organ_works` | warm workshop wood/brass | `#524A45` | `#997A38` |
| The Old Parish Church | `old_parish_church` | cool stone + candlelight | `#999489` | `#BFB899` |
| Iron & Strings Gym | `iron_strings_gym` | industrial grey + iron-red | `#474242` | `#9E4D42` |
| The Recording Studio | `recording_studio` | warm acoustic-foam tones | `#52453D` | `#8C664D` |
| The Clocktower | `clocktower` | aged brass/gear tones | `#524D45` | `#9E8447` |
| The Harbor & Docks | `harbor_docks` | cool dock grey/sea green | `#474F54` | `#738C80` |
| The Public Library & Archive | `library` | warm wood/parchment | `#574D40` | `#947A52` |
| The Carnival & Fairground | `carnival` | midway purple + marquee gold | `#574A54` | `#C78C3D` |
| The Underground Tunnels | `underground` | dark earthy tones | `#333330` | `#615947` |
| Zip Line Park | `zip_line` | outdoor green + rope-tan | `#45543F` | `#8C8047` |
| VR Escape Room (base) | `vr_room` | cyber-blue + glitch-cyan | `#364052` | `#4DA6B3` |
| VR Escape Room — Stage Alpha overlay | `vr_room_alpha` | "medieval" amber/stone | `#57452B` | `#9E8047` |
| VR Escape Room — Stage Beta overlay | `vr_room_beta` | "underwater" teal/aqua | `#23525C` | `#4DA39E` |
| The Drop | `the_drop` | dusty landing-zone tan | `#5C594D` | `#946652` |
| The Grand Marquee Cinema | `grand_marquee` | theater red + gold | `#4D3638` | `#B88C47` |

(Hex values converted from each location's `FLOOR_BASE_COLOR`/
`FLOOR_ACCENT_COLOR` floats in DESIGN.md §2.3.)
