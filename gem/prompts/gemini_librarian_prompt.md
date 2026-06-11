## Gemini prompt — Librarian sprite sheet

Generate a pixel-art character sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. No part of the Librarian should be green.

**Canvas:** 640 x 256 px, divided into a strict grid of 64x64 px tiles, 10
columns x 4 rows. Each animation occupies one full row, frames laid out left
to right starting at column 1. Unused trailing tiles in a row should be left
as plain green background.

**Character:** The Librarian — strict and formal. Reading glasses perched on
the end of her nose, hair pulled into a tight bun, a cardigan over a collared
shirt. She always carries a large hardcover book or a stamp. She's the
desk-blocker NPC at The Public Library & Archive — her "step aside" animation
is the visual payoff for Erin's Fast Talk ability.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). Deep teal
(#1F7A78) cardigan, cream (#F4F0E6) collared shirt, brown (#6E4A2E) hardcover
book, grey-brown hair in a tight bun, thin silver/grey glasses frame, warm
skin (#F2C49B). Use 2-3 step highlight/shadow shading per shape, no dithering,
extended palette (DESIGN.md §2.0).

**Eyes:** simple 4x4 px white square with a 2x2 px dark pupil, peering over
the top of her glasses; severe, arched eyebrows.

**Perspective:** top-down 3/4 overhead view, mostly facing the camera (she's
a stationary desk NPC).

**Rows (top to bottom), each 64x64 frames:**
1. Idle (6 frames) — stamps books at her desk, glasses gleam, severe
   expression
2. Refuse (6) — shakes her head firmly, points back the way the duo came
3. Talked-down / Step aside (8) — visibly sighs, packs up her book, and steps
   to the side
4. Talking closeup (6) — severe expression at frame 1, softening slightly by
   frame 6 (Fast Talk is working)

**Save to:** `assets/art/sprites/librarian.png`
