## Gemini prompt — Grunt sprite sheet

Generate a pixel-art enemy sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. No part of the Grunt or his gear should be green.

**Canvas:** 640 x 512 px, divided into a strict grid of 64x64 px tiles, 10
columns x 8 rows. Each animation occupies one full row, frames laid out left
to right starting at column 1. Unused trailing tiles in a row should be left
as plain green background.

**Subject:** Grunt — a stocky, anonymous aggressor. Worn jacket, heavy boots,
gloves. His face is partly obscured by a bandana or low cap brim — a
deliberately generic threat. He carries a blunt weapon (a pipe or bat) in one
hand. He should read instantly as "enemy" from silhouette alone, even at
32x32.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). Dark grey
(#5C5C6E) jacket, navy (#2F4A99) trousers, red (#E13B4A) bandana accent, plus
general neutral/skin tones from the extended palette (DESIGN.md §2.0). Use
2-3 step highlight/shadow shading per shape, no dithering.

**Eyes:** mostly hidden by the bandana/cap brim — where visible, a simple
narrow dark sliver is enough; this character should not read as friendly.

**Perspective:** top-down 3/4 overhead view — front when facing/moving toward
camera, back when facing away. Only right-facing animations are needed —
left-facing is a code-flip of the right-facing row, do not generate separate
left rows.

**Rows (top to bottom), each 64x64 frames:**
1. Patrol / Idle (6 frames) — slow walk-in-place, glances left and right
2. Chase — right (8) — purposeful walk toward the target
3. Windup — telegraph (6) — raises the weapon overhead; holds the pose at
   frames 5-6 (this is the readable "tell" before he strikes)
4. Strike — right (4) — weapon comes down fast
5. Recover (4) — weapon held low, briefly exposed/vulnerable
6. Hurt (4) — staggers backward
7. Death (8) — crumples to the ground, weapon drops and lands beside him
8. Alert scan (4) — head turns slowly side to side as if scanning — used for
   stealth vision-cone context

**Save to:** `assets/art/sprites/grunt.png`
