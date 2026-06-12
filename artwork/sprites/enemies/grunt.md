---
enemy: Grunt
sheet: assets/art/sprites/grunt.png
canvas: 640 × 512 px
tile: 64 × 64 px
rows: 8
---

# Grunt — Sprite Sheet

## Visual Design

Stocky, anonymous aggressor. Worn jacket, heavy boots, gloves. Face partly
obscured by a bandana or cap brim — deliberately generic threat. Carries a
blunt weapon (pipe or bat) in one hand. Should read instantly as "enemy" at
32×32 from the silhouette alone.

**Stats:** Max HP 60 · Move speed 80 px/s · Attack damage 12 · Range 40 px ·
Windup 0.6 s

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Jacket | Dark grey | `#5C5C6E` |
| Trousers | Navy | `#2F4A99` |
| Bandana accent | Red | `#E13B4A` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Patrol / Idle | 6 | Slow walk-in-place; glances left and right |
| 1 | Chase — right | 8 | Purposeful walk toward target |
| 2 | Windup — telegraph | 6 | Raises weapon overhead; holds at frame 5–6 (the visible tell) |
| 3 | Strike — right | 4 | Weapon comes down fast |
| 4 | Recover | 4 | Weapon low; briefly exposed |
| 5 | Hurt | 4 | Staggers back |
| 6 | Death | 8 | Crumples; weapon drops beside him |
| 7 | Alert scan | 4 | Head turns slowly to scan; used for stealth vision-cone context |

## Save Location

`assets/art/sprites/grunt.png`
