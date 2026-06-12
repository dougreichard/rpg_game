---
animals: Calvin & Coolidge (always a pair)
breed: Great Pyrenees (brothers)
sheet: assets/art/sprites/calvin_and_coolidge.png
canvas: 640 × 576 px
tile: 64 × 64 px
rows: 9
---

# Calvin & Coolidge — Sprite Sheet

## Visual Design

Two large, white, fluffy mountain dogs — significantly bigger than Frosty.
Calvin is slightly heavier-set (the charger); Coolidge is slightly leaner
(the brace/pusher). Both have the characteristic Great Pyrenees lion-like mane
and heavy paws. Imposing at rest; devastating in a charge. Always together;
code never separates them.

**Note:** If 64×64 is too cramped for two large dogs, use 96×64 px tiles
(sheet becomes 960×576 px).

**Role:** Heavy muscle — Calvin is the combat charger (larger knockback than
Frosty), Coolidge is the puzzle mover (pairs with Evan to drag massive objects
even Evan alone can't budge). Whichever the moment calls for, the other tags
along as backup. Used at Harbor & Docks.

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Main coat | White | `#F4F0E6` |
| Mane depth shading | Light grey | `#A8A8B8` |
| Eyes and nose | Near-black | `#1A1A22` |
| Tongue | Pink | `#FF9CC2` |

## Animation Table

Both dogs visible in every row.

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle — pair | 6 | Both stand side by side; slow breath; tails sway |
| 1 | Walk — down (pair) | 8 | Heavy, dignified gait |
| 2 | Walk — right (pair) | 8 | |
| 3 | Calvin charge attack | 6 | Calvin sprints hard, shoulder-first slam; Coolidge follows behind |
| 4 | Coolidge brace / push | 6 | Coolidge plants wide, leans hard into large object; Calvin flanks |
| 5 | Dual charge — split | 8 | Calvin breaks left, Coolidge breaks right simultaneously — two-target charge |
| 6 | Hurt — pair | 4 | Both flinch; manes ripple |
| 7 | Death / Down — pair | 8 | Both lie flat; manes spread wide |
| 8 | Return to Evan | 6 | Trot back side by side; tails up |

## AI Prompt

> Pixel art sprite sheet, clean modern pixel-art style inspired by
> *Stranger Things: 1984*'s character-swap art (see
> `gem/calvin_and_coolidge.png` for fidelity reference), transparent
> background. Canvas 640 × 576 px, 64×64 tiles, 9 rows × 10 columns. Subject:
> TWO large white Great Pyrenees dogs always together in every frame — Calvin
> (heavier-set, charger) and Coolidge (slightly leaner, braces). Both have
> lion-like manes and heavy paws, visibly larger than Frosty. Animations:
> idle-pair (slow breath, tail sway), heavy-walk-toward-pair,
> heavy-walk-right-pair, calvin-shoulder-charge (Calvin sprints ahead,
> Coolidge follows), coolidge-brace-push (Coolidge wide-planted against
> object, Calvin flanks), dual-charge-split (both break in opposite
> directions simultaneously), hurt-flinch-mane-ripple-pair,
> death-lie-flat-manes-spread-pair, return-trot-pair (tails up). Both dogs in
> every frame. Confident outlines, soft directional shading with 2-3 step
> highlight/shadow gradients, extended vibrant palette (DESIGN.md §2.0), no
> dithering.

## Save Location

`assets/art/sprites/calvin_and_coolidge.png`
