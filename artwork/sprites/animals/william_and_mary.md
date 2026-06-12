---
animals: William & Mary (always a pair)
breed: Rabbits
sheet: assets/art/sprites/william_and_mary.png
canvas: 640 × 512 px
tile: 64 × 64 px
rows: 8
---

# William & Mary — Sprite Sheet

## Visual Design

Always together on the same sheet — every frame contains both rabbits. William
is slightly larger and looks curious/adventurous; Mary is calmer and more
compact. William: grey-and-white. Mary: mostly white. They are never split; the
code always treats them as a unit.

**Role:** Puzzle scouts — always summoned as a pair. William squeezes through
gaps and grates to fetch items or trigger switches in hard-to-reach alcoves;
Mary holds a counterweight or covers a second switch in tandem. Together they
solve two-point puzzles that a single companion cannot. Used in The Drop.

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| William main fur | Mid-grey | `#5C5C6E` |
| Mary main fur | Off-white | `#F4F0E6` |
| Inner ears (both) | Pink | `#FF9CC2` |
| Eyes (both) | Dark dot | `#1A1A22` |

## Animation Table

Both rabbits visible in every row.

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle — pair | 6 | Nose-twitch loop; William looks around, Mary is still |
| 1 | Hop — down (pair) | 8 | Synchronized hopping gait |
| 2 | Hop — right (pair) | 8 | |
| 3 | Brace / Hold — right (pair) | 6 | Both pressed against an object, pushing; feet dug in |
| 4 | William — squeeze through gap | 6 | William low-crawls sideways through narrow gap; Mary waits behind |
| 5 | Reunite | 6 | William returns; nose-bump with Mary |
| 6 | Hurt — pair | 4 | Both startle; ears flat |
| 7 | Death / Down — pair | 8 | Both lie flat simultaneously |

## AI Prompt

> Pixel art sprite sheet, clean modern pixel-art style inspired by
> *Stranger Things: 1984*'s character-swap art (see `gem/william_and_mary.png`
> for fidelity reference), transparent background. Canvas 640 × 512 px, 64×64
> tiles, 8 rows × 10 columns. Subject: TWO rabbits present together in every
> frame — William (slightly larger, grey-and-white, alert adventurous look)
> and Mary (smaller, mostly white, calm). Animations: idle-pair (nose twitch,
> William looks around), hop-toward-pair, hop-right-pair, brace-push-pair
> (both feet dug in against object edge), william-solo-squeeze-through-gap (low
> sideways crawl; Mary waits), reunite-nose-bump, hurt-startle-pair (ears
> flat), death-lie-flat-pair. Both rabbits visible in every row. Confident
> outlines, soft directional shading with 2-3 step highlight/shadow gradients,
> extended vibrant palette (DESIGN.md §2.0), no dithering.

## Save Location

`assets/art/sprites/william_and_mary.png`
