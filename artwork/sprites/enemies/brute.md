---
enemy: Brute
sheet: assets/art/sprites/brute.png
canvas: 960 × 512 px
tile: 96 × 64 px
rows: 8
---

# Brute — Sprite Sheet

## Visual Design

Massive — noticeably wider and taller than all other characters. Gym-wear:
tank top, track pants, worn trainers. Big bouncer energy. Slow but every
movement has weight — arms visibly thick even at 32×32. Primary enemy in
Iron & Strings Gym. Hits hardest of all enemies; slowest windup but heaviest
damage.

**Sprite tile: 96×64 px** (wider than standard to give the silhouette room).
Sheet: 960×512 px (10 frames × 96 px wide).

**Stats:** Max HP 110 · Move speed 65 px/s · Attack damage 18 · Range 46 px ·
Windup 0.8 s (longest)

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Tank top | Dark magenta-red | `#C2528C` |
| Track pants | Grey | `#A8A8B8` |
| Skin | Warm | `#D9A36E` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Patrol / Idle | 6 | Slow sway; arms loose; weight visible |
| 1 | Chase — right | 8 | Heavy lumbering walk; slowest enemy by spec |
| 2 | Windup — telegraph | 8 | Long, exaggerated arm-raise; hold at frame 7–8 (the 0.8 s tell) |
| 3 | Strike | 4 | Overhead slam; massive impact |
| 4 | Recover | 6 | Slow to reset — the exploitable window |
| 5 | Hurt | 4 | Barely reacts; small stumble |
| 6 | Death | 10 | Massive slow fall — camera shake fires in code when this plays |
| 7 | Stagger | 4 | Pushed back, arms flail — used when hit by an animal charger |

## Save Location

`assets/art/sprites/brute.png`
