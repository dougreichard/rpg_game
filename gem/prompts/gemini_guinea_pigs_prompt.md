## Gemini prompt — Guinea Pigs sprite sheet

Generate a pixel-art creature sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. No part of any guinea pig should be green.

**Canvas:** 640 x 384 px, divided into a strict grid of 64x64 px tiles, 10
columns x 6 rows. Each animation occupies one full row, frames laid out left
to right starting at column 1. Unused trailing tiles in a row should be left
as plain green background.

**Subject:** A scurrying group of 3-4 guinea pigs, ALWAYS shown together in
EVERY frame. Small round bodies, short stubby legs, varied classic
tri-color coloring (brown, white, tan) across the individuals. Their purpose
is crowd-cover chaos — flooding a floor with distracting scurrying motion —
so animations should emphasize mass movement and a loose, scattering cluster.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). Brown
(#9C5A2E), white (#F4F0E6), and tan (#D9A36E) varied across the 3-4
individuals, tiny dark dot eyes (#1A1A22). Use 2-3 step highlight/shadow
shading per shape, no dithering, extended vibrant palette (DESIGN.md §2.0).

**Perspective:** top-down 3/4 overhead view.

**Rows (top to bottom), each 64x64 frames, ALL 3-4 guinea pigs visible in
every frame:**
1. Idle scatter (6 frames) — 4 guinea pigs milling about, randomly oriented,
   each shifting position slightly frame to frame
2. Scurry — right (8) — rapid little legs, the group moves together as a
   loose cluster, profile
3. Scurry — down/toward camera (8) — same rapid scurry, toward camera
4. Flood — panic scatter (8) — the group explodes outward from the center in
   all directions, used on summon/release
5. Calm — regroup (6) — the pigs slow down and cluster back together
6. Death (6) — all four roll onto their backs, tiny legs sticking up

**Save to:** `assets/art/sprites/guinea_pigs.png`
