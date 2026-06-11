## Gemini prompt — Brute sprite sheet

Generate a pixel-art enemy sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. No part of the Brute should be green.

**Canvas:** 960 x 512 px, divided into a strict grid of 96x64 px tiles (wider
than the standard 64x64 — this enemy needs the extra width for his
silhouette), 10 columns x 8 rows. Each animation occupies one full row, frames
laid out left to right starting at column 1. Unused trailing tiles in a row
should be left as plain green background.

**Subject:** Brute — massive, noticeably wider and taller than every other
character and enemy in the game. Gym-wear: tank top, track pants, worn
trainers. Big bouncer energy. He's slow, but every movement should carry
visible weight — his arms should look thick and powerful even at small sizes.
He's the primary enemy at Iron & Strings Gym, hits hardest of all enemies, and
has the slowest windup but the heaviest damage.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). Dark
magenta-red (#C2528C) tank top, grey (#A8A8B8) track pants, warm skin
(#D9A36E), worn dark trainers. Use 2-3 step highlight/shadow shading per
shape, no dithering, extended palette (DESIGN.md §2.0).

**Eyes:** simple 4x4 px white square with a 2x2 px dark pupil, set in a
heavy, blunt face.

**Perspective:** top-down 3/4 overhead view — front when facing/moving toward
camera, back when facing away. Only right-facing animations are needed —
left-facing is a code-flip of the right-facing row, do not generate separate
left rows.

**Rows (top to bottom), each 96x64 frames:**
1. Patrol / Idle (6 frames) — a slow sway, arms loose, his sheer weight should
   be visible even standing still
2. Chase — right (8) — a heavy, lumbering walk; the slowest enemy by spec
3. Windup — telegraph (8) — a long, exaggerated overhead arm-raise, holding
   at frames 7-8 (the spec's longest tell, 0.8s)
4. Strike (4) — an overhead slam with massive impact
5. Recover (6) — slow to reset — this is the exploitable window for players
6. Hurt (4) — barely reacts, just a small stumble
7. Death (10) — a massive, slow fall — the game triggers a camera shake when
   this plays
8. Stagger (4) — pushed back, arms flailing — used when hit by an animal
   companion's charge attack

**Save to:** `assets/art/sprites/brute.png`
