---
animal: Lizard (unnamed)
breed: Gecko/skink type
sheet: assets/art/sprites/lizard.png
canvas: 640 × 448 px
tile: 64 × 64 px
rows: 7
---

# Lizard — Sprite Sheet

## Visual Design

Medium gecko/skink type — slim, not large. Tail approximately 1.5× body
length. Olive-green with darker stripe markings. Primary purpose is vertical
traversal (scaling walls and pipes the duo cannot reach), so the climb
animation is the hero animation for this sprite.

**Role:** Vertical-traversal scout. Scales walls and pipes the duo can't reach
to flip a switch or drop a rope/ladder down to them. Used by Ethan in Zip Line
Park and VR Escape Room (via `lizard_companion.gd`'s `CLIMB → PERCH → RETURN`
phase machine).

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Body | Olive green | `#9C8A4E` |
| Stripe markings | Dark stripe | `#5C5C6E` |
| Eye | Tiny yellow | `#FFE066` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 4 | Tongue flick; toe-pads pressed flat |
| 1 | Walk — right (ground) | 6 | Low-slung crawl; limbs alternate |
| 2 | Climb — upward | 8 | Belly flat on vertical surface (viewed from side); limbs alternate; tail swings for balance |
| 3 | Perch / Hold | 4 | Stationary on elevated surface; tail curled — used when holding at target switch |
| 4 | Target reached | 4 | Tail flick, head nod — success signal to Ethan (emits `target_reached` signal in code) |
| 5 | Descend | 8 | Climb animation reversed; head pointing down |
| 6 | Flee / Scatter | 4 | Rapid sprint away |

## Save Location

`assets/art/sprites/lizard.png`
