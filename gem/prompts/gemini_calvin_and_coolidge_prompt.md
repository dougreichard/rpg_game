## Gemini prompt — Calvin & Coolidge sprite sheet

Generate a pixel-art creature sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. No part of either dog should be green.

**Canvas:** 640 x 576 px, divided into a strict grid of 64x64 px tiles, 10
columns x 9 rows. Each animation occupies one full row, frames laid out left
to right starting at column 1. Unused trailing tiles in a row should be left
as plain green background.

**Subject:** Calvin & Coolidge — TWO large, white, fluffy Great Pyrenees
mountain dogs that are ALWAYS shown together in EVERY frame (never split,
significantly bigger than Frosty). Calvin is slightly heavier-set (the
charger); Coolidge is slightly leaner (the brace/pusher). Both have a
characteristic lion-like mane and heavy paws — imposing at rest, devastating
in a charge. Both dogs must fit together within each 64x64 tile.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). White
(#F4F0E6) main coat, light grey (#A8A8B8) for mane depth/shading, dark eyes
and nose (#1A1A22), pink (#FF9CC2) tongue. Use 2-3 step highlight/shadow
shading per shape, no dithering, extended vibrant palette (DESIGN.md §2.0).

**Perspective:** top-down 3/4 overhead view — fronts of faces/chests when
moving toward camera, backs/manes when moving away.

**Rows (top to bottom), each 64x64 frames, BOTH dogs visible in every frame:**
1. Idle — pair (6 frames) — both stand side by side, slow breathing, tails
   sway gently
2. Walk — down/toward camera (pair) (8) — heavy, dignified gait, in step with
   each other
3. Walk — right (pair) (8) — heavy dignified gait, profile
4. Calvin charge attack (6) — Calvin sprints hard ahead, shoulder-first slam;
   Coolidge follows close behind
5. Coolidge brace / push (6) — Coolidge plants himself wide and leans hard
   into a large object; Calvin flanks beside him
6. Dual charge — split (8) — Calvin breaks left and Coolidge breaks right
   simultaneously, a two-target charge
7. Hurt — pair (4) — both flinch, manes ripple
8. Death / Down — pair (8) — both lie flat, manes spread wide
9. Return to Evan (6) — trot back side by side, tails held up

**Save to:** `assets/art/sprites/calvin_and_coolidge.png`
