## Gemini prompt — William & Mary sprite sheet

Generate a pixel-art creature sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. No part of either rabbit should be green.

**Canvas:** 640 x 512 px, divided into a strict grid of 64x64 px tiles, 10
columns x 8 rows. Each animation occupies one full row, frames laid out left
to right starting at column 1. Unused trailing tiles in a row should be left
as plain green background.

**Subject:** William & Mary — TWO rabbits that are ALWAYS shown together,
side-by-side, in EVERY single frame (they are never split). William is
slightly larger, grey-and-white, with a curious/adventurous look (alert ears,
head turning). Mary is smaller, mostly white, calm and compact. Both rabbits
must fit together within each 64x64 tile.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). Mid-grey
(#5C5C6E) for William's main fur (with white patches), off-white (#F4F0E6) for
Mary, pink (#FF9CC2) inner ears for both, dark dot eyes (#1A1A22). Use 2-3 step
highlight/shadow shading per shape, no dithering, extended vibrant palette
(DESIGN.md §2.0).

**Perspective:** top-down 3/4 overhead view — front of faces when moving
toward camera, backs/tails when moving away.

**Rows (top to bottom), each 64x64 frames, BOTH rabbits visible in every
frame unless noted:**
1. Idle — pair (6 frames) — nose-twitch loop; William looks around alertly,
   Mary stays still
2. Hop — down/toward camera (pair) (8) — synchronized hopping gait, both in
   sync
3. Hop — right (pair) (8) — synchronized hopping, profile
4. Brace / Hold — right (pair) (6) — both rabbits pressed against an object,
   pushing with feet dug in
5. William — squeeze through gap (6) — William low-crawls sideways through a
   narrow gap (most of the frame); Mary waits behind, visible at the edge
6. Reunite (6) — William returns and nose-bumps Mary
7. Hurt — pair (4) — both startle, ears flat against their backs
8. Death / Down — pair (8) — both rabbits lie flat on their sides
   simultaneously

**Save to:** `assets/art/sprites/william_and_mary.png`
