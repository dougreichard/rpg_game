## Gemini prompt — Sentry Projectile sprite sheet

Generate a small pixel-art VFX sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. No part of the projectile should be green.

**Canvas:** 320 x 32 px, divided into a strict grid of 32x32 px tiles, 10
columns x 1 row. Frames laid out left to right starting at column 1. Only the
first 4 columns are used — leave columns 5-10 as plain green background.

**Subject:** The Sentry's projectile — a small, fast-moving energy bolt or
disc. It's only on screen for a fraction of a second, so it should read as a
bright, glowing, slightly abstract shape rather than a literal object — think
a compact glowing disc or short bolt with a trailing glow.

**Palette:** Cyan (#5ED6FF) and orange (#FF9A3C) glow, with a bright white
(#FFFFFF) hot core. Soft outer glow/falloff, no dithering, extended palette
(DESIGN.md §2.0).

**Rows (top to bottom), each 32x32 frames:**
1. Fly (4 frames) — a spinning or pulsing glow loop; each frame should be a
   slightly different rotation/pulse phase of the same glowing disc/bolt so it
   reads as continuous motion when looped

**Save to:** `assets/art/sprites/projectile_sentry.png`
