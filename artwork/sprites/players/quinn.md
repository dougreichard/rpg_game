---
character: Quinn
sheet: assets/art/sprites/quinn.png
canvas: 640 × 1088 px
tile: 64 × 64 px
rows: 17
---

# Quinn — Sprite Sheet

## Visual Design

Teenage, slim build. All-black outfit: wide-brim hat, round wire-frame glasses,
long coat, work boots. Brass wrench tucked in belt loop. British
mod-spy-meets-workshop-apprentice. Pale skin, dark brown hair hidden under hat.
Moves with quiet, purposeful confidence.

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Coat / hat | Ink-black | `#1A1A22` |
| Coat shading ramp | Dark blue-grey / mid blue-grey | `#2E2E3A` / `#5C5C6E` |
| Coat lining | Steel-grey | `#6E7A86` |
| Skin | Pale | `#FFE3C7` |
| Wrench | Amber | `#FFC94D` |
| Glasses rim | Light-grey | `#A8A8B8` |
| UI accent | Blue (DESIGN.md §2.1) | `#4D73D9` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Subtle coat sway, blink at frame 4 |
| 1 | Walk — down (toward camera) | 8 | Full stride, coat swings gently |
| 2 | Walk — up (away from camera) | 8 | Back of head; hat brim visible |
| 3 | Walk — right | 8 | Profile; coat flares slightly at back |
| 4 | Run — down | 8 | Faster stride, coat billows |
| 5 | Run — up | 8 | |
| 6 | Run — right | 8 | Forward lean, coat streams behind |
| 7 | Attack — right | 6 | Wrench swing: reach back (1–2), strike (3), recover (4–6). **Arc: 92° filled gold wedge, reach 28 px — the sprite shows the body/wrench motion only; the gold arc overlay is drawn in code and must NOT appear in the sheet itself.** |
| 8 | Special — HA laugh | 8 | Arms wide, head back, mouth open; shockwave ripple radiates outward frames 5–8 |
| 9 | Talking — full body | 6 | Gesturing hands, slight forward lean |
| 10 | Talking — closeup | 8 | Head and shoulders only; eyebrow raises, mouth moves |
| 11 | Hurt | 4 | Recoil backward, hat tilts |
| 12 | Death / Down | 10 | Slow crumple; ends flat, coat spread |
| 13 | Revive | 8 | Rises from floor, shakes head, adjusts hat |
| 14 | Dodge / Dash | 5 | Low lunge right, coat streaming behind |
| 15 | Repair / Interact | 8 | Crouching, wrench in both hands, turning motion |
| 16 | Doorway operate | 6 | Reaches forward with both hands, pushes, steps through |

## Attack Details

Quinn swings his wrench in a **medium-reach arc**. The gold wedge fan drawn in
code is 92° wide and extends 28 px from center. The sprite's attack row (row 7)
should show the wrench arc through space via the body pose — a confident two-handed
reach-back into a forward drive — without any arc glow in the pixel art itself.

| Stat | Value |
|------|-------|
| Arc type | Filled wedge (code-drawn) |
| Arc color | Gold `#FFE04D` |
| Reach | 28 px |
| Arc spread | 92° |
| Hitbox size | 30 × 10 px |

## AI Prompt

> Pixel art sprite sheet, clean modern pixel-art style inspired by
> *Stranger Things: 1984*'s character-swap art (see `gem/quinn.png` for
> fidelity reference), transparent background. Canvas 640 × 1088 px, 64×64
> tiles, 17 rows × 10 columns. Subject: teenage figure, slim build, all-black
> wide-brim hat, round wire-frame glasses, long black coat, black work boots,
> brass wrench in belt. Pale skin, dark brown hair hidden under hat. Animations
> (one per row, left to right): idle (coat sway, blink), walk-toward,
> walk-away, walk-right, run-toward, run-away, run-right, wrench-swing-attack-
> right (reach back → strike → recover; NO arc glow in sprite), HA-laugh-special
> (arms wide, shockwave ripple radiates out), talking-full-body, talking-closeup
> (head + shoulders), hurt-recoil (hat tilts), death-crumple, revive-rise
> (adjusts hat), dash-right, crouch-repair (wrench turning), doorway-push
> (reaches forward, steps through). Confident outlines, soft directional shading
> with 2-3 step highlight/shadow gradients, extended vibrant palette
> (DESIGN.md §2.0), no dithering.

## Save Location

`assets/art/sprites/quinn.png`
