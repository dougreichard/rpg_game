## Gemini prompt — Boss (Clockwork Guardian) sprite sheet

Generate a pixel-art boss sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. No part of the Guardian should be green (its glowing eye is red,
its accents are gold — keep both clearly distinct from the background hue).

**Canvas:** 1280 x 1280 px, divided into a strict grid of 128x128 px tiles
(large — this is the biggest enemy in the game), 10 columns x 10 rows. Each
animation occupies one full row, frames laid out left to right starting at
column 1. Unused trailing tiles in a row should be left as plain green
background.

**Subject:** The Clockwork Guardian — a large mechanical figure: armored,
angular, clearly built rather than born. Gear motifs throughout — visible
spinning gears on its shoulders or chest plate. A single glowing red eye. It
should convey mass and power. This same sprite sheet is used for both its
appearances: the clockwork guardian of The Clocktower, and the final guardian
of The Grand Marquee Cinema.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). Iron grey
(#5C5C6E) armor plating, gold (#FFC94D) gear accents/rivets, red (#E13B4A)
glowing single eye, off-white (#F4F0E6) accents matching the in-game AoE
warning-ring color. Use 2-3 step highlight/shadow shading per shape, no
dithering, extended palette (DESIGN.md §2.0).

**Eye:** a single glowing red circular eye, centered on the "head"/topmost
section — its glow should visibly intensify in windup/telegraph frames and
dim/go dark in the death row.

**Perspective:** top-down 3/4 overhead view — front when facing/moving toward
camera, back when facing away. Only right-facing animations are needed —
left-facing is a code-flip of the right-facing row, do not generate separate
left rows.

**Rows (top to bottom), each 128x128 frames:**
1. Idle (6 frames) — shoulder gears visibly spinning, the eye pulses red
2. Chase — right (8) — a slow, ground-shaking advance
3. Windup — melee (6) — a heavy arm raises, the eye brightens to full
   brightness
4. Strike — melee (4) — a heavy downward slam
5. Recover (4) — settles back to a ready stance
6. AoE telegraph (8) — plants both feet, the eye blazes at full brightness,
   arms spread wide (the in-game expanding warning ring is drawn separately in
   code, but this pose should sell the "incoming AoE" tell)
7. AoE slam (6) — both fists slam down, with an implied shockwave on frames
   4-6
8. AoE recover (6) — rises back to standing, gears still spinning
9. Hurt (4) — staggers, armor visibly dents slightly
10. Death (12) — a gear-by-gear wind-down, collapsing slowly; the eye dims and
    goes completely dark on the final frame

**Save to:** `assets/art/sprites/boss.png`
