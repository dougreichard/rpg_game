---
animal: Twinkle
breed: Pomeranian
sheet: assets/art/sprites/twinkle.png
canvas: 640 × 576 px
tile: 64 × 64 px
rows: 9
---

# Twinkle — Sprite Sheet

## Visual Design

Very small dog — noticeably smaller than Frosty. Round fluffy ball of
cream-colored fur. Distinctive and non-negotiable: perpetually blank/cloudy
eyes (she is blind), single prominent snaggle tooth visible even at rest,
slightly wobbly stance. She looks ridiculous. That is the point. Her bark
is her weapon.

**Role:** Sound-puzzle aggravator / noise distraction. Trots away from Evan,
barks loudly, and emits a `GameManager.emit_noise` burst that lures patrolling
guards toward her racket and away from the duo. Used in Underground Tunnels.

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Fur | Cream | `#F4F0E6` |
| Eyes | Tiny dark dots (barely visible — cloudy) | `#1A1A22` |
| Snaggle tooth | Ivory | `#F0E8C8` |
| Tongue | Tiny pink | `#FF9CC2` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Tiny wobble; snaggle tooth always visible; cloudy eyes |
| 1 | Trot — down | 6 | Legs are so short this looks ridiculous |
| 2 | Trot — right | 6 | |
| 3 | Bark / Distract | 8 | Full-body bark: bounces with each bark, mouth wide, snaggle tooth prominent, concentric sound rings emit |
| 4 | Return trot | 6 | Same as trot-right; code flips for left direction |
| 5 | Hurt | 4 | Tiny stumble; indignant expression |
| 6 | Death / Down | 6 | Flops over; one tiny leg points up |
| 7 | Sniff | 4 | Nose to ground; tail straight up |
| 8 | Annoyed | 4 | Sits; turns head away — used after failed actions |

## AI Prompt

> Pixel art sprite sheet, clean modern pixel-art style inspired by
> *Stranger Things: 1984*'s character-swap art (see `gem/twinkle.png` for
> fidelity reference), transparent background. Canvas 640 × 576 px, 64×64
> tiles, 9 rows × 10 columns. Subject: very small, round, extremely fluffy
> cream-colored Pomeranian — noticeably smaller than Frosty. Cloudy/blank eyes
> (she is blind), single prominent snaggle tooth always visible, slightly
> wobbly unsteady stance. Comedic proportions encouraged. Animations: idle
> (tiny wobble, snaggle tooth, cloudy eyes), trot-toward, trot-right,
> full-body-bark (bouncing, mouth wide, sound rings emit), return-trot,
> hurt-tiny-stumble-indignant, death-flop-leg-up, nose-to-ground-sniff,
> annoyed-head-turn. Confident outlines, soft directional shading with 2-3
> step highlight/shadow gradients, extended vibrant palette (DESIGN.md §2.0),
> no dithering.

## Save Location

`assets/art/sprites/twinkle.png`
