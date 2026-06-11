## Gemini prompt — Sentry sprite sheet

Generate a pixel-art enemy sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. No part of the Sentry or his gear should be green (his weapon
glow is orange/cyan, not green — keep them clearly distinct hues).

**Canvas:** 640 x 512 px, divided into a strict grid of 64x64 px tiles, 10
columns x 8 rows. Each animation occupies one full row, frames laid out left
to right starting at column 1. Unused trailing tiles in a row should be left
as plain green background.

**Subject:** Sentry — an upright, vigilant figure with the bearing of a
security guard. Dark uniform jacket, peaked cap. Holds a ranged weapon — a
dart pistol or a futuristic zapper that reads clearly as a weapon but is
non-realistic, not a real-world firearm. Used in The Library & Archive and The
VR Escape Room. Measured, methodical movements — never frantic.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). Navy
(#2F4A99) uniform jacket, dark (#18141A) peaked cap, orange (#FF9A3C) weapon
accent/glow (makes the weapon read clearly), white (#F4F0E6) gloves, plus
general skin tones from the extended palette (DESIGN.md §2.0). Use 2-3 step
highlight/shadow shading per shape, no dithering.

**Eyes:** simple 4x4 px white square with a 2x2 px dark pupil, partially
shadowed by the cap brim — alert, focused expression.

**Perspective:** top-down 3/4 overhead view — front when facing/moving toward
camera, back when facing away. Only right-facing animations are needed —
left-facing is a code-flip of the right-facing row, do not generate separate
left rows.

**Rows (top to bottom), each 64x64 frames:**
1. Patrol (6 frames) — a measured, formal walk-in-place, head scanning slowly
2. Chase — right (8) — approaches to attack range, then holds position
3. Windup — take aim (6) — raises the weapon and plants his feet; this is the
   readable telegraph
4. Fire — right (4) — a short, decisive shot, with a muzzle flash on frame 2
5. Recover (4) — returns the weapon to a ready position
6. Hurt (4) — stumbles while still holding the weapon
7. Death (8) — falls, the weapon drops from his hand
8. Alert scan (4) — head and weapon sweep side to side — used for stealth
   vision-cone context

**Save to:** `assets/art/sprites/sentry.png`
