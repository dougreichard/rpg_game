## Gemini prompt — Ethan sprite sheet

Generate a pixel-art character sprite sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background. No part of the character or his gear should be green (his device
glow and AR-glasses tint are cyan, not green — keep them clearly distinct from
the background hue).

**Canvas:** 640 x 1088 px, divided into a strict grid of 64x64 px tiles, 10
columns x 17 rows. Each animation occupies one full row, frames laid out left
to right starting at column 1. Unused trailing tiles in a row should be left
as plain green background.

**Character:** Ethan — a teenage boy, wiry/lean build. Tech-casual: grey
hoodie, dark navy cargo pants with gadget-stuffed pockets, sneakers. Always
has a small glowing device in hand or clipped to his belt — like a cross
between a phone and a hacking tool. Dark-blue rectangular AR glasses (simple
dark-blue rectangles at this resolution). Short, neat dark hair. Efficient,
purposeful movements. Cyan data-stream glyphs appear during hack/special
frames.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black). Grey
(#A8A8B8) hoodie, dark navy (#2F4A99) cargo pants, cyan (#5ED6FF) device glow
and AR-glasses tint, dark hair (#18141A). Use 2-3 step highlight/shadow shading
per shape, no dithering.

**Eyes:** simple 4x4 px white square with a 2x2 px dark pupil; small
eyebrows for expression. AR glasses sit over the eyes as flat dark-blue
rectangles, faintly lit from within.

**Perspective:** top-down 3/4 overhead view — full face when walking toward
camera, back of head/hair when walking away.

**Rows (top to bottom), each 64x64 frames:**
1. Idle (6 frames) — glances down at his device, the screen pulses cyan every
   3 frames, blink on frame 4
2. Walk down/toward camera (8) — device held at his side
3. Walk up/away (8) — back of head, short dark hair visible
4. Walk right (8) — profile, device at side
5. Run down (8) — device pocketed while running
6. Run up (8)
7. Run right (8) — forward lean, device pocketed
8. Attack right (6) — gadget zap: extends the device (1-2), an energy burst
   emits (3), recover (4-6)
9. Special "Hack" (8) — stops, both hands on the device, rapid typing; cyan
   digit/data-stream glyphs radiate outward on frames 4-8
10. Talking, full body (6) — device in hand, gestures with it while talking
11. Talking closeup (8) — head and shoulders, AR glasses faintly lit,
    thoughtful expression
12. Hurt (4) — the device briefly flies out of his hand, he scrambles to
    catch it
13. Death/Down (10) — falls; the device's screen goes dark on the final
    frame, ends flat
14. Revive (8) — recovers, checks the device screen first thing, then stands
15. Dodge/Dash right (5) — quick low side-step
16. Panel interact (8, looping) — crouches at a panel, device plugged in with
    a cable, a small progress glyph pulses above his head; loops smoothly back
    to frame 1, for sustained hacking/puzzle interactions
17. Doorway operate (6) — holds the device up to the door, the screen flashes
    cyan (1-3) as it unlocks, pushes the door open and steps through (4-6)

Keep proportions consistent across all frames: head ~20px, torso ~20px, legs
~24px tall within each 64x64 tile.
