---
enemy: Sentry
sheet: assets/art/sprites/sentry.png
canvas: 640 × 512 px
tile: 64 × 64 px
rows: 8
---

# Sentry — Sprite Sheet

## Visual Design

Upright vigilant posture — like a security guard. Dark uniform jacket, peaked
cap. Holds a ranged weapon: a dart pistol or futuristic zapper (read-as-weapon
but non-realistic — this is not a firearm). Used in The Library & Archive and
The VR Escape Room. Measured, methodical movements.

**Stats:** Max HP 45 · Move speed 50 px/s · Attack damage 14 · Range 220 px ·
Windup 0.5 s · Is ranged (fires `Projectile`, speed 260 px/s)

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Uniform | Navy | `#2F4A99` |
| Cap | Near-black | `#18141A` |
| Weapon accent | Orange (makes it read clearly) | `#FF9A3C` |
| Gloves | White | `#F4F0E6` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Patrol | 6 | Measured formal walk-in-place; head scans |
| 1 | Chase — right | 8 | Approaches to attack range, then holds |
| 2 | Windup — take aim | 6 | Raises weapon; plants feet; the telegraph |
| 3 | Fire — right | 4 | Short decisive shot; muzzle flash at frame 2 |
| 4 | Recover | 4 | Returns weapon to ready position |
| 5 | Hurt | 4 | Stumble; holds weapon |
| 6 | Death | 8 | Falls; weapon drops |
| 7 | Alert scan | 4 | Head and weapon sweep — vision-cone context |

## Save Location

`assets/art/sprites/sentry.png`
