---
enemy: Runner
sheet: assets/art/sprites/runner.png
canvas: 640 × 512 px
tile: 64 × 64 px
rows: 8
---

# Runner — Sprite Sheet

## Visual Design

Smaller and leaner than the Grunt — built for speed, not power. Tracksuit or
lightweight athletic gear. No visible weapon — attacks with quick jabs and
kicks. A slightly manic, coiled energy even in idle. Fastest enemy; lowest
health.

**Stats:** Max HP 30 · Move speed 170 px/s · Attack damage 8 · Range 30 px ·
Windup 0.3 s

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Tracksuit | Cyan (visually distinct from Grunt grey at a glance) | `#5ED6FF` |
| Stripe accent | White | `#F4F0E6` |
| Boots | Dark | `#1A1A22` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Patrol / Idle | 6 | Bounces on heels; quick darting eyes |
| 1 | Sprint — right | 8 | Very fast, aggressive forward lean — distinct from Grunt's walk |
| 2 | Windup | 4 | Short and sharp — noticeably less warning than the Grunt |
| 3 | Strike | 3 | Quick jab or kick — fastest strike |
| 4 | Recover | 4 | Darts back to distance |
| 5 | Hurt | 3 | Small stumble; bounces back fast |
| 6 | Death | 6 | Falls quickly — shorter animation than Grunt |
| 7 | Dash-in | 5 | Signature charge move: low sprint burst before striking |

## Save Location

`assets/art/sprites/runner.png`
