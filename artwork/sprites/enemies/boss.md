---
enemy: Boss — Clockwork Guardian
sheet: assets/art/sprites/boss.png
canvas: 1280 × 1280 px
tile: 128 × 128 px
rows: 10
---

# Boss — Clockwork Guardian Sprite Sheet

## Visual Design

Large mechanical figure — armored, angular, clearly constructed. Gear motifs:
visible spinning gears on shoulders or chest plate. Single glowing red eye.
Conveys mass and power. Appears as the Clocktower guardian and the Grand
Marquee Cinema's final guardian — **same sprite, both roles**.

**Use 128×128 px tiles for presence.** Sheet: 1280×1280 px.

**Stats:** Max HP 400 · Move speed 55 px/s · Attack damage 22 · Range 50 px ·
Windup 0.7 s · AoE slam damage 26, radius 110 px · AoE telegraph 1.1 s, cooldown 4.0 s

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Armor | Iron grey | `#5C5C6E` |
| Gear accents | Gold | `#FFC94D` |
| Glowing eye | Red | `#E13B4A` |
| AoE warning ring outline | Off-white | `#F4F0E6` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Shoulder gears visibly spinning; eye pulses red |
| 1 | Chase — right | 8 | Slow, ground-shaking advance |
| 2 | Windup — melee | 6 | Heavy arm raises; eye brightens to full red |
| 3 | Strike — melee | 4 | Heavy downward slam |
| 4 | Recover | 4 | |
| 5 | AoE telegraph | 8 | Plants both feet; eye blazes; arms spread wide. The expanding ring is drawn in code — the sprite sells the body pose/tell only. |
| 6 | AoE slam | 6 | Both fists down; shockwave implied frames 4–6 |
| 7 | AoE recover | 6 | Rises back to standing; gears still spinning |
| 8 | Hurt | 4 | Staggers; armor dents slightly |
| 9 | Death | 12 | Gear-by-gear wind-down; collapses slowly; eye dims and goes dark at final frame |

## Notes

- Bosses skip the `PATROL` state — they enter `CHASE` immediately on spawn
  (see `enemy.gd`). No patrol or alert-scan animation is needed.
- The AoE warning ring / indicator is drawn entirely in code during `AOE_TELEGRAPH`.
  The sprite's row 5 should show the body pose that telegraphs the slam without
  duplicating the ring glow in the pixel art.

## AI Prompt

> Pixel art sprite sheet, clean modern pixel-art style, transparent background.
> Canvas 1280 × 1280 px, 128×128 tiles, 10 rows × 10 columns. Subject: large
> mechanical armored guardian — angular iron-grey armor plates, visible spinning
> gear-motifs on shoulders and chest, single large glowing red eye. Imposing
> and massive. Animations: idle (gears spin, eye pulses), slow-chase-right,
> melee-windup (arm rises, eye blazes), melee-slam-right, recover,
> aoe-telegraph-stance (feet planted, arms spread wide — NO ring glow in
> sprite), aoe-slam (both fists down, implied shockwave), aoe-recover-rise,
> hurt-armor-dent-stagger, death-gear-winddown-collapse (eye dims to black).
> Confident outlines, soft directional shading with 2-3 step highlight/shadow
> gradients, extended vibrant palette (DESIGN.md §2.0), no dithering.

## Save Location

`assets/art/sprites/boss.png`
