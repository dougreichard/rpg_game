## Gemini prompt — Evan sprite sheet

Generate a pixel-art character sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. No part of the character (or Frosty, in frames where he appears)
should be green.

**Canvas:** 640 x 1088 px, divided into a strict grid of 64x64 px tiles, 10
columns x 17 rows. Each animation occupies one full row, frames laid out left
to right starting at column 1. Unused trailing tiles in a row should be left
as plain green background.

**Character:** Evan — a teenage boy, noticeably broader and bigger than other
characters (he's the tank), worn olive/khaki t-shirt, brown cargo shorts,
hiking boots. No weapon — fists are raised slightly, ready to throw a punch.
Warm, open face with a strong jaw. Confident, friendly strength.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). Olive/khaki
(#9C8A4E) t-shirt, brown (#6E4A2E) cargo shorts, warm skin (#D9A36E), worn boot
brown (a darkened #6E4A2E). Use 2-3 step highlight/shadow shading per shape, no
dithering. Evan's olive/khaki tones double as his signature accent (DESIGN.md
§2.1) — keep them warm and slightly saturated so they read distinctly.

**Eyes:** simple 4x4 px white square with a 2x2 px dark pupil; small
eyebrows for expression.

**Perspective:** top-down 3/4 overhead view — full face when walking toward
camera, back of head/hair when walking away.

**Rows (top to bottom), each 64x64 frames:**
1. Idle (6 frames) — hands at sides, blink on frame 4; Frosty (small fluffy
   white dog) sits at his feet, visible in the bottom 8px of the tile
2. Walk down/toward camera (8) — wide, confident stride
3. Walk up/away (8) — back of head visible
4. Walk right (8) — profile, wide stride
5. Run down (8) — heavy run, slowest of all characters but powerful
6. Run up (8)
7. Run right (8) — forward lean, heavy footfalls
8. Attack right (6) — straight punch: wind-up (1-2), fist extends past the
   tile edge on frame 3, recover (4-6)
9. Special "Animal call" (8) — two-finger whistle (1-4), then a pointing
   gesture (5-8); a small paw-print pixel glyph emits near frame 4
10. Talking, full body (6) — big arm gestures, slightly loud personality reads
    in the pose
11. Talking closeup (8) — head and shoulders only, warm open expression,
    eyebrows active
12. Hurt (4) — barely flinches, just a small stumble
13. Death/Down (10) — slow, heavy fall; takes longer than other characters,
    ends flat
14. Revive (8) — rolls to one knee, stands with visible effort
15. Dodge/Dash right (5) — shortest dash of all characters, low lunge
16. Lift/Shove/Brace — interact (8, looping) — crouches and grabs (1-3),
    heaves upward with exaggerated flexing (4-6), holds/releases (7-8); loops
    smoothly back to frame 1 for sustained heavy-prop puzzle interactions
17. Doorway operate (6) — plants feet wide, braces with both arms spread,
    shoves the door open with effort, steps through

Keep proportions consistent across all frames: head ~20px, torso ~22px (Evan
is broader-shouldered than other characters), legs ~22px tall within each
64x64 tile.
