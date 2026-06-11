## Gemini prompt — Runner sprite sheet

Generate a pixel-art enemy sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. No part of the Runner or his gear should be green (his tracksuit
is cyan, not green — keep them clearly distinct hues).

**Canvas:** 640 x 512 px, divided into a strict grid of 64x64 px tiles, 10
columns x 8 rows. Each animation occupies one full row, frames laid out left
to right starting at column 1. Unused trailing tiles in a row should be left
as plain green background.

**Subject:** Runner — smaller and leaner than the Grunt, built for speed, not
power. Wears a tracksuit or lightweight athletic gear. No visible weapon —
attacks with quick jabs and kicks. A slightly manic, coiled energy even at
rest. The fastest enemy with the lowest health, so his poses should feel
twitchy and quick.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). Cyan
(#5ED6FF) tracksuit (visually distinct from the Grunt's grey at a glance),
white (#F4F0E6) stripe accent down the sleeves/legs, dark (#1A1A22) boots,
plus general skin tones from the extended palette (DESIGN.md §2.0). Use 2-3
step highlight/shadow shading per shape, no dithering.

**Eyes:** simple 4x4 px white square with a 2x2 px dark pupil — wide and a
little manic-looking, darting.

**Perspective:** top-down 3/4 overhead view — front when facing/moving toward
camera, back when facing away. Only right-facing animations are needed —
left-facing is a code-flip of the right-facing row, do not generate separate
left rows.

**Rows (top to bottom), each 64x64 frames:**
1. Patrol / Idle (6 frames) — bounces lightly on his heels, eyes darting
   quickly side to side
2. Sprint — right (8) — very fast, aggressive forward lean — visibly
   different/faster than the Grunt's walk
3. Windup (4) — short and sharp, noticeably less warning than the Grunt's
   windup
4. Strike (3) — a quick jab or kick, the fastest strike of any enemy
5. Recover (4) — darts back to a safe distance
6. Hurt (3) — a small stumble, bounces back fast
7. Death (6) — falls quickly, a shorter animation than the Grunt's
8. Dash-in (5) — his signature charge move: a low sprint burst right before
   he strikes

**Save to:** `assets/art/sprites/runner.png`
