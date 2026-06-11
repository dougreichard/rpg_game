## Gemini prompt — Twinkle sprite sheet

Generate a pixel-art creature sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. No part of Twinkle should be green.

**Canvas:** 640 x 576 px, divided into a strict grid of 64x64 px tiles, 10
columns x 9 rows. Each animation occupies one full row, frames laid out left
to right starting at column 1. Unused trailing tiles in a row should be left
as plain green background.

**Subject:** Twinkle — a Pomeranian, very small and noticeably smaller than
Frosty. A round, fluffy ball of cream-colored fur. Non-negotiable visual
traits: perpetually blank/cloudy eyes (she is blind), a single prominent
snaggle tooth visible even at rest, and a slightly wobbly stance. She looks
ridiculous — that is the point. Her bark is her weapon. Comedic proportions
encouraged.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). Cream
(#F4F0E6) fluffy fur, tiny dark eye dots (barely visible — cloudy/blank look),
ivory snaggle tooth, tiny pink (#FF9CC2) tongue. Use 2-3 step highlight/shadow
shading per shape, no dithering, extended vibrant palette (DESIGN.md §2.0).

**Perspective:** top-down 3/4 overhead view — front of face/chest when moving
toward camera, back/tail when moving away.

**Rows (top to bottom), each 64x64 frames:**
1. Idle (6 frames) — a tiny constant wobble; snaggle tooth always visible;
   cloudy/blank eyes
2. Trot — down/toward camera (6) — her legs are so short this looks
   ridiculous, an exaggerated little waddle
3. Trot — right (6) — profile waddle
4. Bark / Distract (8) — full-body bark: she bounces with each bark, mouth
   wide open, snaggle tooth prominent, concentric sound rings emit outward
5. Return trot (6) — same as trot-right (this row is reused/flipped by code)
6. Hurt (4) — tiny stumble, indignant offended expression
7. Death / Down (6) — flops over onto her side, one tiny leg points straight
   up
8. Sniff (4) — nose pressed to the ground, tail straight up
9. Annoyed (4) — sits down, turns her head away — used after failed actions

**Save to:** `assets/art/sprites/twinkle.png`
