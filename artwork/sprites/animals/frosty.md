---
animal: Frosty
breed: Schnoodle (Schnauzer/Poodle mix)
sheet: assets/art/sprites/frosty.png
canvas: 640 × 704 px
tile: 64 × 64 px
rows: 11
---

# Frosty — Sprite Sheet

## Visual Design

Medium-small dog, fluffy white fur. Schnauzer facial structure (slightly blocky
muzzle) with poodle fluffiness. Always alert and eager. General-purpose combat
companion — charges enemies, headbutts, returns to Evan.

**Role:** Combat distractor. Charges the nearest enemy, headbutts it to interrupt
a windup or stagger it, then returns to Evan's side.

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Fur | Near-white | `#F4F0E6` |
| Tongue / inner ears | Pink | `#FF9CC2` |
| Eyes and nose | Near-black | `#1A1A22` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Tail wag (3-frame loop); head-tilt at frame 5 |
| 1 | Trot — down | 8 | |
| 2 | Trot — up | 8 | |
| 3 | Trot — right | 8 | |
| 4 | Gallop — down | 8 | |
| 5 | Gallop — up | 8 | |
| 6 | Gallop — right | 8 | |
| 7 | Charge / Headbutt attack | 6 | Low sprint (1–3), head-down ram (4), bounce back (5–6) |
| 8 | Hurt | 4 | Yip and stumble |
| 9 | Death / Down | 8 | Lies flat; tail stops |
| 10 | Return to owner | 6 | Happy trot, tail high |

## AI Prompt

> Pixel art sprite sheet, clean modern pixel-art style inspired by
> *Stranger Things: 1984*'s character-swap art (see `gem/frosty.png` for
> fidelity reference), transparent background. Canvas 640 × 704 px, 64×64
> tiles, 11 rows × 10 columns. Subject: small fluffy white dog,
> Schnauzer/Poodle mix, slightly blocky muzzle, round dark eyes, pink tongue
> visible in active frames. Animations: idle (tail wag, head tilt),
> trot-toward, trot-away, trot-right, gallop-toward, gallop-away, gallop-right,
> headbutt-charge-attack (low sprint → head-down ram → bounce back),
> hurt-stumble-yip, death-lie-flat (tail stops), happy-return-trot (tail
> high). Confident outlines, soft directional shading with 2-3 step
> highlight/shadow gradients, extended vibrant palette (DESIGN.md §2.0), no
> dithering.

## Save Location

`assets/art/sprites/frosty.png`
