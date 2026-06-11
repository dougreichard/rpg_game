## Gemini prompt — Carnival Guard sprite sheet

Generate a pixel-art character sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. No part of the guard should be green.

**Canvas:** 640 x 256 px, divided into a strict grid of 64x64 px tiles, 10
columns x 4 rows. Each animation occupies one full row, frames laid out left
to right starting at column 1. Unused trailing tiles in a row should be left
as plain green background.

**Character:** The Carnival Guard — theatrical, fitting his fairground
setting: an old-fashioned circus-uniform with a red jacket trimmed in gold
braid, black trousers, and a flat cap with a badge. Broad-shouldered but not
genuinely threatening — more "jobsworth bouncer" than real danger. He guards
the backstage curtain at The Carnival & Fairground.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). Red
(#E13B4A) jacket with gold (#FFC94D) braid trim, dark (#18141A) trousers and
flat cap, gold (#FFC94D) cap badge, warm skin (#D9A36E). Use 2-3 step
highlight/shadow shading per shape, no dithering, extended palette (DESIGN.md
§2.0).

**Eyes:** simple 4x4 px white square with a 2x2 px dark pupil; skeptical,
heavy eyebrows.

**Perspective:** top-down 3/4 overhead view, mostly facing the camera (he's a
stationary gate NPC).

**Rows (top to bottom), each 64x64 frames:**
1. Idle (6 frames) — arms crossed, tapping one foot impatiently
2. Refuse (6) — shakes his head, one hand out in a "stop" gesture
3. Convinced / Step aside (8) — looks surprised (frame 3), then amused (frame
   5), then waves the duo through and steps out of the way
4. Talking closeup (6) — skeptical expression, gold cap badge clearly visible

**Save to:** `assets/art/sprites/carnival_guard.png`
