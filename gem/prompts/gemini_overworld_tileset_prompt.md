## Gemini prompt — Overworld tileset (`hb_tiles.png`)

Generate a pixel-art tileset sheet, in a clean modern pixel-art style similar
to *Stranger Things: 1984*'s character-swap art (vibrant, lightly shaded,
confident outlines — not flat 8-bit). This sheet is **opaque** — every tile
should be fully painted edge-to-edge (no transparency, no green-screen
needed).

**Canvas:** 384 x 256 px, divided into a strict grid of 32x32 px tiles, 12
columns x 8 rows. This is the master overworld `TileMap` source — it's
2x-upscaled at runtime, and every tile must **tile seamlessly** with its
neighbors (no visible seams when repeated edge-to-edge in any direction).

**Subject:** Eight distinct terrain/material types — one per row — used to
build the town overworld map (building interiors, roads, grass, etc.). Each
row should provide several seamless variants of that row's material across
its 12 columns (a plain tile, a lightly decorated/accent tile, and extra
decorative variants for visual variety) — extended palette (DESIGN.md §2.0),
2-3 step highlight/shadow shading per tile, no dithering.

**Rows (top to bottom), each row = one 32x32-tile terrain type, 12 columns of
seamless variants of that material:**
1. **Stone** — grey ashlar/flagstone floor (used for The Old Parish Church,
   The Clocktower, The Public Library & Archive footprints)
2. **Workshop** — warm wood-and-brass workshop floor (Bellows & Sons Pipe
   Organ Works, Iron & Strings Gym)
3. **Wood** — warm wooden floorboards (The Recording Studio, The Carnival &
   Fairground)
4. **Outdoor** — this row does double duty as both grass *and* road, so it
   needs specific variants at specific columns:
   - **Column 1 (index 1):** a worn road/path accent tile (darker dirt/gravel
     fleck variant of the road tile)
   - **Column 2 (index 2):** a grass tile with a small decorative tuft/flower
     accent
   - **Column 3 (index 3):** a worn dirt/gravel road or path tile, plain,
     non-directional (must look correct used for both horizontal and vertical
     road runs)
   - **Column 4 (index 4):** plain grass tile (the base lawn tile, used most
     often)
   - **Columns 5 and 8 (index 5, 8):** two distinct "outdoor built structure"
     tile variants — e.g. a wooden platform/decking tile and a canvas/tarp
     tile — used for buildings that sit directly on the grass (Zip Line Park,
     The Drop)
   - Remaining columns: additional grass/road variants for visual variety
5. **Tunnel** — dark earthy tunnel/cave floor (The Underground Tunnels)
6. **Dock** — weathered dock planking, cool grey-green tones (The Harbor &
   Docks)
7. **Carpet** — rich theater carpet, red and gold tones (The Grand Marquee
   Cinema)
8. **Cyber** — cyber-blue tech-floor with subtle circuit/grid details (The VR
   Escape Room)

For every row except Outdoor, **columns 0 and 1 are the most important** —
they're used as the primary "building interior floor" tile pair (two subtly
different variants that alternate to avoid a repetitive look). Make sure
those two tiles in particular are clean, seamless, and visually distinct from
each other (e.g. plain vs. a tile with a small decorative inlay/seam),
matching that row's material.

**Save to:** `assets/art/tiles/hb_tiles.png`
