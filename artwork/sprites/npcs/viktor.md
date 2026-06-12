---
npc: Viktor
location: The Harbor & Docks (pier, near the entrance)
sheet: assets/art/sprites/viktor.png
canvas: 640 × 256 px
tile: 64 × 64 px
rows: 4
---

# Viktor — Sprite Sheet

## Visual Design

The harbourmaster — a broad, weathered man who has clearly seen the docks in
better days and is not pleased about the current state of affairs. Practical
uniform: captain's cap, navy peacoat with gold-anchor buttons, dark trousers,
rubber-soled boots. Full grey beard, slightly ruddy complexion from years
outside. Carries a manifest clipboard he hasn't put down.

**Portrait color (in-game dialog):** Burnt orange `#F58224`

**Role:** Stationary guide NPC near the pier entrance. Confirms the smugglers'
manifest contains Doug's name, directs Evan to move the blocking cargo
container (or suggests a crowbar in the yard as an alternate approach).

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Peacoat | Navy | `#2A3050` |
| Buttons | Dull gold | `#B89040` |
| Captain's cap | Navy with gold band | `#2A3050` |
| Trousers | Dark grey | `#404048` |
| Boots | Black rubber | `#28282E` |
| Skin | Ruddy, weathered | `#C07050` |
| Beard | Grey | `#909098` |
| Portrait color | Burnt orange | `#F58224` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Holds clipboard; occasional glance at it; slow steady breathing |
| 1 | Walk — right | 8 | Heavy deliberate stride |
| 2 | Walk — down | 8 | |
| 3 | Talking — closeup | 6 | Stern, controlled; taps the clipboard at frame 3 when mentioning the manifest |

## Notes

- Stationary at `VIKTOR_POS (220, 460)` near the pier entrance.
- His cleared-state line ("Manifest confirms it — Doug's name is on that
  shipment") is a key Uncle Doug plot beat.

## Save Location

`assets/art/sprites/viktor.png`
