## Gemini prompt — Lizard sprite sheet

Generate a pixel-art creature sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. The lizard's body is olive-green but must read as a clearly
different, more yellow/muted olive tone than the bright neon-green
background — keep strong contrast between the two so the background can be
cleanly removed.

**Canvas:** 640 x 448 px, divided into a strict grid of 64x64 px tiles, 10
columns x 7 rows. Each animation occupies one full row, frames laid out left
to right starting at column 1. Unused trailing tiles in a row should be left
as plain neon-green background.

**Subject:** A medium gecko/skink-type lizard — slim, not large, with a tail
about 1.5x its body length. Olive-green body with darker stripe markings.
Its primary purpose is vertical traversal (scaling walls and pipes the duo
can't reach), so the climbing animation is this sprite's hero animation.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). Olive
green (#9C8A4E) body, dark stripe markings (#5C5C6E), tiny yellow eye
(#FFE066). Use 2-3 step highlight/shadow shading per shape, no dithering,
extended vibrant palette (DESIGN.md §2.0).

**Perspective:** top-down 3/4 overhead view for ground-based rows; side view
for the climb/descend rows (belly flat against a vertical surface, as if
viewed face-on to a wall).

**Rows (top to bottom), each 64x64 frames:**
1. Idle (4 frames) — tongue flick, toe-pads pressed flat against the surface
2. Walk — right (ground) (6) — low-slung crawl, limbs alternate, profile
3. Climb — upward (8) — belly flat against a vertical surface viewed from the
   side, limbs alternate climbing motion, tail swings for balance
4. Perch / Hold (4) — stationary on an elevated surface, tail curled — used
   when holding position at a target switch
5. Target reached (4) — tail flick and head nod, a success signal to Ethan
6. Descend (8) — the climb animation reversed, head pointing downward
7. Flee / Scatter (4) — rapid sprint away, low and fast

**Save to:** `assets/art/sprites/lizard.png`
