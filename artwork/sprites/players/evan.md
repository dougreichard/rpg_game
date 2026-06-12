---
character: Evan
sheet: assets/art/sprites/evan.png
canvas: 640 × 1088 px
tile: 64 × 64 px
rows: 17
---

# Evan — Sprite Sheet

## Visual Design

Teenage, noticeably broader and bigger than other characters — he is the tank.
Casual: worn olive/khaki t-shirt, cargo shorts, hiking boots. Fists are his
weapons (no tool). Often has an animal visible nearby in idle. Warm, open face
with strong jaw. Super-strength reads in exaggerated flexing during heavy-lift
animations. Slowest character but hits hardest and has the most HP.

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| T-shirt | Olive/khaki | `#9C8A4E` |
| Cargo shorts | Brown | `#6E4A2E` |
| Skin | Warm | `#D9A36E` |
| Boots | Dark brown | `#4A2E18` |
| UI accent | Olive (DESIGN.md §2.1) | `#9C8A4E` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Hands at sides; Frosty the dog sits at his feet (visible at bottom 8 px of tile) |
| 1 | Walk — down | 8 | Wide, confident stride |
| 2 | Walk — up | 8 | |
| 3 | Walk — right | 8 | |
| 4 | Run — down | 8 | Heavy run — slowest of all characters |
| 5 | Run — up | 8 | |
| 6 | Run — right | 8 | |
| 7 | Attack — right | 6 | Haymaker: wind back (1–2), thunderous straight punch (3), fist extends past tile edge, recover (4–6). **Longest melee reach (32 px), 115° arc — the sprite shows the body pose and extended fist only; the amber arc overlay is drawn in code and must NOT appear in the sheet.** |
| 8 | Special — Animal call | 8 | Two-finger whistle (1–4), then pointing gesture (5–8); small paw-print glyph emits |
| 9 | Lift / Shove | 8 | Crouches and grabs (1–3), heaves upward (4–6), releases (7–8) — for heavy puzzle props |
| 10 | Talking — full body | 6 | Big arm gestures; slightly loud personality reads in the pose |
| 11 | Talking — closeup | 8 | |
| 12 | Hurt | 4 | Barely flinches — small stumble only |
| 13 | Death / Down | 10 | Slow, heavy fall; takes longer than other characters |
| 14 | Revive | 8 | Rolls, one knee, stands with effort |
| 15 | Dodge / Dash | 5 | Shortest dash of all characters |
| 16 | Brace / Hold | 6 | Feet wide, arms spread, leaning into something — used for two-point puzzle holds |

## Attack Details

Evan's haymaker is the **longest-reach melee attack** in the game. The amber
wedge drawn in code extends furthest from center and covers a solid forward
cone. The fist should visibly extend past the tile edge on frame 3 of the
attack row to read the super-strength at pixel scale.

| Stat | Value |
|------|-------|
| Arc type | Filled wedge (code-drawn) |
| Arc color | Amber `#FFA633` |
| Reach | 32 px (longest melee reach) |
| Arc spread | 115° |
| Hitbox size | 40 × 14 px |

## AI Prompt

> Pixel art sprite sheet, clean modern pixel-art style inspired by
> *Stranger Things: 1984*'s character-swap art (see `gem/evan.png` for
> fidelity reference), transparent background. Canvas 640 × 1088 px, 64×64
> tiles, 17 rows × 10 columns. Subject: teenage boy, broad/muscular build
> (visibly larger than other characters), worn olive khaki t-shirt, brown
> cargo shorts, hiking boots, warm skin tone. White schnoodle dog (Frosty)
> visible at his feet in idle frame. Animations: idle (dog at feet),
> walk-toward, walk-away, walk-right, heavy-run-toward, heavy-run-away,
> heavy-run-right, haymaker-punch-right (wind back → thunderous punch, fist
> extends beyond tile edge; NO arc glow in sprite), animal-call-whistle-point
> (paw glyph emits), heavy-lift-shove (crouches → heaves → releases),
> talking-full-body (big gestures), talking-closeup, hurt-slight-flinch,
> death-heavy-slow-fall, revive-knee-stand, short-dash-right, brace-wide-stance.
> Confident outlines, soft directional shading with 2-3 step highlight/shadow
> gradients, extended vibrant palette (DESIGN.md §2.0), no dithering.

## Save Location

`assets/art/sprites/evan.png`
