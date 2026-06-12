---
npc: Rio
location: The Drop (Touchdown Clearing)
sheet: assets/art/sprites/rio.png
canvas: 640 × 256 px
tile: 64 × 64 px
rows: 4
---

# Rio — Sprite Sheet

## Visual Design

Former crew member who bailed on the operation after seeing the manifest.
Compact, wiry, alert — the kind of person who moves quietly by habit. Worn
field jacket with the insignia stripped off, dark trousers, sturdy boots.
Short hair, guarded expression. She introduces herself by first name only and
volunteers just enough to get the duo moving. Clearly uncomfortable staying
in one place.

**Portrait color (in-game dialog):** Army green `#4F6333`

**Role:** Stationary guide NPC in the Touchdown Clearing. After the ground
crew is down she can be approached; she directs Evan to clear the wreckage
and Ethan to hack the jammed chute release in the Snag Grove.

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Field jacket | Faded olive, stripped insignia | `#5C6840` |
| Trousers | Dark earth | `#3A3020` |
| Boots | Worn black | `#2A2828` |
| Skin | Tan, weathered | `#B07848` |
| Hair | Dark brown, short | `#2E2018` |
| Portrait color | Army green | `#4F6333` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Weight on one foot; arms loose at sides; scanning the perimeter |
| 1 | Walk — right | 8 | Low-profile stride, quick |
| 2 | Walk — down | 8 | |
| 3 | Talking — closeup | 6 | Minimal expression; eyes sharp; leans in slightly at frame 4 when she mentions the marquee sign |

## Notes

- Stationary at `RIO_POS (500, 430)` in the Touchdown Clearing.
- Her cleared-state line ("The marquee sign I saw before the drop — it had
  his name on it") is the direct narrative bridge to The Grand Marquee Cinema.

## Save Location

`assets/art/sprites/rio.png`
