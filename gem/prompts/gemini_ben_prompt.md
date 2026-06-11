## Gemini prompt — Ben sprite sheet

Generate a pixel-art character sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. No part of the character or his gear should be green (avoid
green patches in the jacket).

**Canvas:** 640 x 1088 px, divided into a strict grid of 64x64 px tiles, 10
columns x 17 rows. Each animation occupies one full row, frames laid out left
to right starting at column 1. Unused trailing tiles in a row should be left
as plain green background.

**Character:** Ben — a teenage boy, medium build, full bard energy. Patchwork
jacket made of multiple muted-color patches sewn together, dark trousers, worn
ankle boots. An electric keytar is always slung across his body; its keys glow
faintly cyan during attacks and specials. Messy mid-brown hair, easy smile.
Small musical-note and sound-wave pixel glyphs appear during attack/special
frames.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). Patchwork
jacket uses several patch colors — blues (#4D9CE6 / #2F4A99), greens (#4FB05C
/ #2E7D4F), reds (#E13B4A / #FF6B5C), one per patch. Dark grey (#5C5C6E)
trousers, grey/black keytar body with glowing cyan (#5ED6FF) keys, mid-brown
(#9C5A2E) hair. Use 2-3 step highlight/shadow shading per shape, no dithering.

**Eyes:** simple 4x4 px white square with a 2x2 px dark pupil; small
eyebrows for expression.

**Perspective:** top-down 3/4 overhead view — full face when walking toward
camera, back of head/hair when walking away.

**Rows (top to bottom), each 64x64 frames:**
1. Idle (6 frames) — keytar resting against his body, fingers tap the keys, a
   small musical-note glyph floats upward, blink on frame 4
2. Walk down/toward camera (8) — keytar sways with each step
3. Walk up/away (8) — back of head, messy brown hair visible
4. Walk right (8) — profile, keytar swaying
5. Run down (8) — keytar tucked under one arm while running
6. Run up (8)
7. Run right (8) — forward lean, keytar tucked
8. Attack right (6) — keytar swing: raise it overhead (1-2), swing forward
   (3), follow-through (4-6)
9. Special "AoE musical wave" (8) — plants feet, plays hard; concentric
   sound-wave rings radiate outward on frames 4-8, musical note glyphs scatter
10. Talking, full body (6) — enthusiastic, big expressive gestures
11. Talking closeup (8) — head and shoulders, wide grin, eyebrows active
12. Hurt (4) — recoil backward, keytar swings wildly
13. Death/Down (10) — falls; the keytar clatters down beside him around
    frame 7, ends flat
14. Revive (8) — rolls up, grabs the keytar first, then stands
15. Dodge/Dash right (5) — quick low side-step
16. Perfect Pitch listen — interact (8, looping) — tilts his head, one hand
    cupped to his ear, small musical-note glyphs appear and drift above his
    head; loops smoothly back to frame 1, for sustained sound-puzzle
    interactions
17. Doorway operate (6) — keytar swings behind him as he reaches forward with
    both hands, pushes the door open, steps through

Keep proportions consistent across all frames: head ~20px, torso ~20px, legs
~24px tall within each 64x64 tile.
