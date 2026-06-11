## Gemini prompt — Uncle Doug sprite sheet

Generate a pixel-art character sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. No part of Uncle Doug should be green.

**Canvas:** 640 x 256 px, divided into a strict grid of 64x64 px tiles, 10
columns x 4 rows. Each animation occupies one full row, frames laid out left
to right starting at column 1. Unused trailing tiles in a row should be left
as plain green background.

**Character:** Uncle Doug — a middle-aged man, balding on top with trim,
greying stubble, a stocky build, and reading glasses on a chain around his
neck. He wears a rumpled collared shirt and slacks — he clearly did not dress
for an adventure. Warm, slightly bewildered expression. He's found in the
projection booth at the end of The Grand Marquee Cinema — this is the rescue
payoff for the whole game.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). Steel-blue
(#6E7A86) rumpled collared shirt, dark grey (#2E2E3A) slacks, grey/white
balding hair with a fringe, grey stubble beard, gold (#FFC94D) glasses chain,
warm skin (#D9A36E). Use 2-3 step highlight/shadow shading per shape, no
dithering, extended palette (DESIGN.md §2.0).

**Eyes:** simple 4x4 px white square with a 2x2 px dark pupil, behind a thin
pair of glasses; warm, slightly worried eyebrows.

**Perspective:** top-down 3/4 overhead view, mostly facing the camera (he's
an NPC, not a moving character).

**Rows (top to bottom), each 64x64 frames:**
1. Idle (6 frames) — adjusts his glasses, glances nervously around
2. Wave / Relief (8) — waves with both arms and breaks into a wide, relieved
   smile — the rescue payoff moment
3. Talking, full body (6)
4. Talking closeup (8) — glasses slightly askew, warm and thankful expression

**Save to:** `assets/art/sprites/uncle_doug.png`
