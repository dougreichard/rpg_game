## Gemini prompt — Frosty sprite sheet

Generate a pixel-art creature sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. No part of Frosty should be green.

**Canvas:** 640 x 704 px, divided into a strict grid of 64x64 px tiles, 10
columns x 11 rows. Each animation occupies one full row, frames laid out left
to right starting at column 1. Unused trailing tiles in a row should be left
as plain green background.

**Subject:** Frosty — a medium-small dog, a Schnoodle (Schnauzer/Poodle mix).
Fluffy white fur, a slightly blocky Schnauzer-style muzzle with poodle
fluffiness, always alert and eager-looking. He is a general-purpose combat
companion that charges enemies, headbutts, and returns.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). Near-white
(#F4F0E6) fluffy fur, pink (#FF9CC2) tongue and inner ears, dark dot eyes and
nose (#1A1A22). Use 2-3 step highlight/shadow shading per shape, no dithering,
extended vibrant palette (DESIGN.md §2.0).

**Perspective:** top-down 3/4 overhead view — front of face/chest when moving
toward camera, back/tail when moving away.

**Rows (top to bottom), each 64x64 frames:**
1. Idle (6 frames) — tail wag as a 3-frame loop, head-tilt at frame 5
2. Trot — down/toward camera (8) — light bouncy gait
3. Trot — up/away (8) — tail and back visible
4. Trot — right (8) — profile
5. Gallop — down/toward camera (8) — full sprint, ears flapping
6. Gallop — up/away (8)
7. Gallop — right (8) — low, fast profile stride
8. Charge / Headbutt attack (6) — low sprint (1-3), head-down ram (4), bounce
   back (5-6)
9. Hurt (4) — yip and stumble
10. Death / Down (8) — lies flat, tail stops moving
11. Return to owner (6) — happy trot, tail held high

**Save to:** `assets/art/sprites/frosty.png`
