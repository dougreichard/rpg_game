## Gemini prompt — Quinn sprite sheet

Generate a pixel-art character sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. No part of the character should be green.

**Canvas:** 640 x 1088 px, divided into a strict grid of 64x64 px tiles, 10
columns x 17 rows. Each animation occupies one full row, frames laid out left
to right starting at column 1. Unused trailing tiles in a row should be left
as plain green background.

**Character:** Quinn — a teenage boy, slim build, all-black wide-brim hat,
round wire-frame glasses, long black coat with steel-grey lining, black work
boots, brass wrench tucked in his belt. Pale skin (#FFE3C7), dark brown hair
(#4A2E1C) hidden under the hat. Calm, quietly confident posture.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). Coat/hat
in ink-black (#1A1A22) with a #2E2E3A/#5C5C6E shading ramp, steel-grey
(#6E7A86) coat lining, light-grey (#A8A8B8) glasses rim, amber (#FFC94D)
wrench. Use 2-3 step highlight/shadow shading per shape, no dithering.
Quinn's signature accent color is blue (#4D73D9) — usable for small trim
details.

**Eyes:** simple 4x4 px white square with a 2x2 px dark pupil; small
eyebrows for expression.

**Perspective:** top-down 3/4 overhead view — full face when walking toward
camera, back of head/hat brim when walking away.

**Rows (top to bottom), each 64x64 frames:**
1. Idle (6 frames) — subtle coat sway, blink on frame 4
2. Walk down/toward camera (8) — full stride, coat swings
3. Walk up/away (8) — back of head, hat brim visible
4. Walk right (8) — profile, coat flares slightly
5. Run down (8) — faster stride, coat billows
6. Run up (8)
7. Run right (8) — forward lean, coat streams behind
8. Attack right (6) — wrench swing: reach back (1-2), strike (3), recover (4-6)
9. Special "HA" laugh (8) — arms wide, head back, mouth open, shockwave
   ripple radiating outward on frames 5-8
10. Talking, full body (6) — gesturing hands, slight forward lean
11. Talking closeup (8) — head and shoulders only, eyebrow raises, mouth moves
12. Hurt (4) — recoil backward, hat tilts
13. Death/Down (10) — slow crumple, ends flat with coat spread
14. Revive (8) — rises from floor, shakes head, adjusts hat
15. Dodge/Dash right (5) — low lunge, coat streaming behind
16. Repair/Interact (8) — crouching, wrench in both hands, turning motion
17. Doorway operate (6) — reaches forward with both hands, pushes, steps
    through

Keep proportions consistent across all frames: head ~20px, torso ~20px, legs
~24px tall within each 64x64 tile.
