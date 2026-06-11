## Gemini prompt — Erin sprite sheet

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

**Character:** Erin — a teenage girl, lithe and quick build, short
red-auburn hair, fitted dark-green jacket over black jeans, scuffed sneakers.
No visible weapon — hands are slightly raised, ready to talk or move fast.
Small orange flame flickers at her fingertips. Confident, slightly
mischievous expression.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). Deep-green
(#2E7D4F) jacket with #4FB05C highlights, ink-black (#1A1A22) jeans, auburn
(#9C5A2E) hair, flame-orange (#FF9A3C) fingertip flame accents, light-tan
skin (#F2C49B). Use 2-3 step highlight/shadow shading per shape, no
dithering. Erin's signature accent color is orange (#E6591A) — usable for
small trim details.

**Eyes:** simple 4x4 px white square with a 2x2 px dark pupil; small
eyebrows for expression.

**Perspective:** top-down 3/4 overhead view — full face when walking toward
camera, back of head/hair when walking away.

**Rows (top to bottom), each 64x64 frames:**
1. Idle (6 frames) — small orange flame flicker at fingertips, blink on
   frame 4
2. Walk down/toward camera (8) — light, quick steps
3. Walk up/away (8) — back of head, short auburn hair visible
4. Walk right (8) — profile, quick stride
5. Run down (8) — near-sprint, she's the fastest character
6. Run up (8)
7. Run right (8) — aggressive forward lean, arms pumping
8. Attack right (6) — fire jab: hand ignites (1-2), strike burst (3), flame
   fades (4-6)
9. Special "Fast Talk" (8) — rapid hand gestures, leaning forward, small
   speech-bubble pixel glyph above her head
10. Talking, full body (6) — expressive arm gestures, leaning forward
11. Talking closeup (8) — head and shoulders only, half-smile, eyebrow arch
12. Hurt (4) — stumble backward, hair flicks forward
13. Death/Down (10) — falls forward, fingertip flame extinguishes around
    frame 8, ends flat
14. Revive (8) — rolls to hands and knees, pushes up quickly
15. Dodge/Dash right (5) — low side-step, lower to the ground than a normal
    stride
16. Stealth crouch-walk (8) — low crouch, slow tiptoeing step cycle, reduced
    silhouette height, looping
17. Doorway operate (6) — reaches forward with both hands, pushes, steps
    through

Keep proportions consistent across all frames: head ~20px, torso ~20px, legs
~24px tall within each 64x64 tile.
