---
npc: ARIA
location: VR Escape Room (Boot Chamber)
sheet: assets/art/sprites/aria.png
canvas: 640 × 256 px
tile: 64 × 64 px
rows: 4
---

# ARIA — Sprite Sheet

## Visual Design

ARIA is the VR system's virtual assistant — a holographic figure rendered
inside the simulation. Her appearance should read as artificial: clean,
symmetrical, slightly too still. Humanoid silhouette in a fitted suit of
shifting blue-white panels (like segmented light armor), no visible hair
(or hair made of light strands), faintly luminous eyes. The overall palette
sits in cyber-blue tones to match the Boot Chamber's color scheme.

**Portrait color (in-game dialog):** Electric blue `#1F63DB`

**Role:** Stationary guide NPC in the Boot Chamber. Introduces the two
corrupted simulation stages and assigns Quinn to Stage Alpha (physics-glitch
repair) and Ethan to Stage Beta (system console hack).

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Body panels | Deep cyber-blue | `#1A3A78` |
| Panel highlights | Electric blue | `#3A7AE0` |
| Panel edges | White-blue glow | `#A0C8FF` |
| Eyes / accent glow | Bright cyan | `#40D0F0` |
| "Hair" or headpiece | Flowing light blue | `#60A8F0` |
| Portrait color | Electric blue | `#1F63DB` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Subtle flicker/scan-line effect on the panels; otherwise perfectly still |
| 1 | Processing | 8 | Panel segments pulse briefly in sequence, left to right |
| 2 | Walk — (hover glide) | 8 | Smooth lateral movement; no leg motion — slides as if on a rail |
| 3 | Talking — closeup | 6 | Panel brightness increases; eyes illuminate more strongly |

## Notes

- Stationary at `ARIA_POS (280, 420)` in the Boot Chamber for the entire
  scene.
- ARIA is opened with the name `"ARIA"` (all-caps) in `_dialog_box.open()`,
  matching the in-universe convention of treating her as a system identifier.
- Her cleared-state line ("Most test subjects don't make it past Beta") hints
  at a dry, slightly unsettling AI personality.

## Save Location

`assets/art/sprites/aria.png`
