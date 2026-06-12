---
npc: Cyrus
location: Underground Tunnels (central junction chamber)
sheet: assets/art/sprites/cyrus.png
canvas: 640 × 256 px
tile: 64 × 64 px
rows: 4
---

# Cyrus — Sprite Sheet

## Visual Design

The tunnels' maintenance worker, sheltering in the junction chamber since the
patrol moved in. Practical work clothes: heavy canvas coveralls, worn tool
belt, safety helmet pushed back on his head. Medium build, mid-40s, calm
under pressure — the kind of person who documents everything and fixes things
quietly. Carries a small lamp; the junction chamber is dim.

**Portrait color (in-game dialog):** Blue-grey `#4F638C`

**Role:** Stationary guide NPC in the central junction chamber. Orients the
duo to the two branching passages (west rubble for Evan, east hatch for
Ethan's multi-step hack) and notes the pocket lantern at the junction.

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Coveralls | Heavy canvas, navy-grey | `#3A4050` |
| Tool belt | Worn leather | `#6A4A30` |
| Safety helmet | Dull yellow, pushed back | `#C8A820` |
| Work boots | Scuffed dark | `#302820` |
| Skin | Medium warm | `#B07850` |
| Hair | Dark, short, some grey | `#483828` |
| Lamp | Warm glow accent | `#E0A840` |
| Portrait color | Blue-grey | `#4F638C` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Holds lamp; slow look left then right; keeping an eye on the patrol corridors |
| 1 | Walk — right | 8 | Careful, quiet steps; lamp held steady |
| 2 | Walk — down | 8 | |
| 3 | Talking — closeup | 6 | Steady and matter-of-fact; points offscreen at frame 3 (toward the forking passages) |

## Notes

- Stationary at `CYRUS_POS (350, 430)` in the central junction chamber.
- He explicitly mentions the pocket lantern — the one item that reveals the
  dark loot boxes deeper in the tunnels.

## Save Location

`assets/art/sprites/cyrus.png`
