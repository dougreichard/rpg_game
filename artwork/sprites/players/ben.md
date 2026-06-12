---
character: Ben
sheet: assets/art/sprites/ben.png
canvas: 640 × 1088 px
tile: 64 × 64 px
rows: 17
---

# Ben — Sprite Sheet

## Visual Design

Teenage, medium build, full bard energy. Patchwork jacket (multiple muted
colors sewn together — the classic bard coat), dark trousers, worn ankle boots.
Electric keytar always slung across his body; it glows faintly cyan at the keys
during attacks and specials. Messy mid-brown hair, easy smile. Musical note and
sound-wave pixel glyphs appear during attacks and specials.

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Jacket patches | Blues | `#4D9CE6` / `#2F4A99` |
| Jacket patches | Greens | `#4FB05C` / `#2E7D4F` |
| Jacket patches | Reds | `#E13B4A` / `#FF6B5C` |
| Trousers | Dark grey | `#5C5C6E` |
| Keytar body | Grey-black + cyan keys | `#3A3A4A` + `#5ED6FF` |
| Hair | Mid-brown | `#9C5A2E` |
| UI accent | Purple (DESIGN.md §2.1) | `#D94DE6` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Keytar resting; fingers tap keys; small musical note glyph floats upward |
| 1 | Walk — down | 8 | Keytar sways with step |
| 2 | Walk — up | 8 | |
| 3 | Walk — right | 8 | |
| 4 | Run — down | 8 | Keytar tucked under arm while running |
| 5 | Run — up | 8 | |
| 6 | Run — right | 8 | |
| 7 | Attack — right | 6 | Keytar swing: raise over shoulder (1–2), wide horizontal sweep (3), follow-through (4–6). **Widest melee arc of all characters — nearly a half-circle at 172°, widest hitbox (54 px); the sprite shows the body/keytar sweep only; the purple arc overlay is drawn in code and must NOT appear in the sheet.** |
| 8 | Special — AoE musical wave | 8 | Plants feet, plays hard; concentric sound-wave rings radiate outward frames 4–8; note glyphs scatter |
| 9 | Perfect Pitch listen | 6 | Tilts head, hand cupped to ear; musical note glyphs appear above head |
| 10 | Talking — full body | 6 | Enthusiastic, big gestures |
| 11 | Talking — closeup | 8 | Wide grin, eyebrows active |
| 12 | Hurt | 4 | Recoil; keytar swings wildly |
| 13 | Death / Down | 10 | Falls; keytar clatters down beside him at frame 7 |
| 14 | Revive | 8 | Rolls up; grabs keytar first, then stands |
| 15 | Dodge / Dash | 5 | |
| 16 | Perform — crowd address | 8 | Full-body performance pose; arms out, slight sway; note glyphs everywhere |

## Attack Details

Ben swings his keytar in a **wide horizontal sweep** — the broadest melee arc
in the game, nearly a half-circle. The purple wedge drawn in code is 172° wide,
covering almost everything in front of and beside him. The sprite's attack row
should sell the sweeping keytar stroke: raise over the shoulder, then a
confident horizontal whip through the air.

| Stat | Value |
|------|-------|
| Arc type | Filled wedge (code-drawn) |
| Arc color | Purple `#D94DE6` |
| Reach | 26 px |
| Arc spread | 172° (widest melee arc) |
| Hitbox size | 54 × 14 px (widest hitbox) |

## AI Prompt

> Pixel art sprite sheet, clean modern pixel-art style inspired by
> *Stranger Things: 1984*'s character-swap art (see `gem/ben.png` for
> fidelity reference), transparent background. Canvas 640 × 1088 px, 64×64
> tiles, 17 rows × 10 columns. Subject: teenage boy, medium build,
> multi-color patchwork jacket (each patch a different palette color), dark
> trousers, ankle boots, messy brown hair. Electric keytar slung across body
> with glowing cyan keys. Musical note and sound-wave pixel glyphs appear in
> attack and special frames. Animations: idle (finger tap, floating note
> glyph), walk-toward, walk-away, walk-right, run-toward (keytar tucked),
> run-away, run-right, keytar-wide-sweep-attack (raise over shoulder → wide
> horizontal sweep; NO arc glow in sprite), aoe-musical-wave-special (planted
> stance, concentric rings + note scatter), perfect-pitch-listen (hand to ear,
> notes above head), talking-full-body, talking-closeup (wide grin),
> hurt-recoil-keytar-swings, death-fall-keytar-clatters-beside, revive-grab-
> keytar-first, dash-right, crowd-address-perform (arms out, swaying).
> Confident outlines, soft directional shading with 2-3 step highlight/shadow
> gradients, extended vibrant palette (DESIGN.md §2.0), no dithering.

## Save Location

`assets/art/sprites/ben.png`
