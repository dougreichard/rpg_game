## Gemini prompt — Environment props reference sheet

Generate a pixel-art prop reference sheet, in a clean modern pixel-art style
similar to *Stranger Things: 1984*'s character-swap art (vibrant, lightly
shaded, confident outlines — not flat 8-bit).

**Background:** solid flat neon green (#00FF00), completely uniform, no
gradient, no pattern, no noise/static — a clean chroma-key green-screen
background, so each prop can be cropped out individually. No part of any prop
should be green.

**Canvas:** 512 x 512 px, divided into a strict grid of 128x128 px cells, 4
columns x 4 rows. Each cell contains ONE complete prop, centered, sized to
fill most of the cell with a small margin of green background around it. Two
cells are unused — leave them as plain green background.

**Subject:** A reference sheet of the recurring puzzle/environment props used
across Hunkle Bunkle's 13 locations (currently generated procedurally as flat
beveled shapes — this sheet is the hand-drawn upgrade reference). Each prop
should be drawn in its own representative accent color (given per cell below)
so it reads clearly on its own; in-game these are tinted per-location, so
think of each as "the canonical version" of that prop.

**Palette:** Soft near-black ink outline (#1A1A22, not pure black) on every
prop. Use 2-3 step highlight/shadow shading per shape, no dithering, extended
palette (DESIGN.md §2.0).

**Perspective:** top-down 3/4 overhead view, matching the character sprites'
perspective — these props sit on the same floors the characters walk on.

**Cells (left to right, top to bottom), each 128x128:**
1. **Pipe organ** — a tall, ornate pipe organ facade: a row of vertical brass
   pipes of varying heights (#9C8A4E brass, #FFC94D gold highlights) set into
   a dark wood (#4A2E1C) frame with carved detail. (Bellows & Sons Pipe Organ
   Works, Old Parish Church organ loft)
2. **Soundboard / terminal console** — a wide control console: dark grey
   (#2E2E3A) housing, a row of small glowing cyan (#5ED6FF) buttons/sliders
   and one larger screen showing a simple waveform or data readout. (The
   Recording Studio, VR Escape Room, Library terminal)
3. **Clockwork gear mechanism** — two or three interlocking brass/gold
   (#9E8447) gears of different sizes against a dark iron-grey (#5C5C6E)
   backplate, teeth clearly visible. (The Clocktower)
4. **Twin bells** — two large brass/gold (#FFC94D) bells hanging side by side
   from a dark wooden beam, with visible clappers (#1A1A22) inside each. (The
   Clocktower belfry)
5. **Barbell** — a weightlifting barbell: an iron-grey (#5C5C6E) bar with two
   large round weight plates on each end, one plate accented in red
   (#E13B4A). (Iron & Strings Gym)
6. **Pew bench** — a long wooden church pew, dark brown (#4A2E1C) wood with a
   simple carved backrest, viewed from a 3/4 angle. (The Old Parish Church)
7. **Stone altar** — a rectangular stone altar block (#999489 grey stone)
   draped with a red (#E13B4A) cloth that hangs over the front face. (The Old
   Parish Church)
8. **Stained glass panel** — a single tall stained-glass window panel divided
   into a 3x4 grid of small colored glass segments (mix of blues #4D9CE6,
   reds #E13B4A, greens #4FB05C, and gold #FFC94D), set in a dark lead-line
   (#1A1A22) frame. (The Old Parish Church nave)
9. **Lit candle** — a cream-colored (#F4F0E6) candle in a small brass holder,
   with a glowing orange/yellow (#FF9A3C / #FFE066) flame and a soft glow
   halo. (The Old Parish Church)
10. **Unlit candle** — the same candle and brass holder as cell 9, but with no
    flame and a small dark wisp of smoke from a recently-extinguished wick.
    (The Old Parish Church)
11. **Pointed arch window** — a tall Gothic pointed-arch window: a stone
    (#999489) frame around a teal/aqua (#4FD1C5) stained-glass pane, with a
    simple cross-shaped mullion. (The Old Parish Church altar wall)
12. **Gate / door panel** — a generic rectangular beveled panel with a thick
    dark (#1A1A22) frame and a 3D-recessed inset center, in a neutral
    iron-grey (#5C5C6E) — the base look for doors, containers, and barbell
    gates across multiple locations.
13. **Loot box / chest** — a small wooden treasure chest, brown (#6E4A2E)
    body with gold (#FFC94D) metal trim/corner brackets and a latch/lock,
    closed.
14. **Loot box / chest, opened** — the same chest as cell 13, but with the lid
    open and a faint warm glow coming from inside.
15. **Doorway archway** — a stone or wood archway/frame representing a level
    entrance/exit, with a dark, slightly mysterious opening in the center
    (no character standing in it).
16. *(unused — plain green background)*

**Save to:** `gem/prompts/gemini_environment_props.png` (reference sheet —
individual props should be cropped out and saved to their own files under
`assets/art/tiles/` or wired into `placeholder_art.gd`'s relevant
`make_*_texture()` functions as real-image overrides).
