---
npc: Lena
location: Zip Line Park (Landing platform)
sheet: assets/art/sprites/lena.png
canvas: 640 × 256 px
tile: 64 × 64 px
rows: 4
---

# Lena — Sprite Sheet

## Visual Design

The park's safety warden — practical and professional, permanently in
high-vis gear. Sturdy build, no-nonsense posture. Safety vest over a fitted
long-sleeved shirt, cargo trousers, climbing harness still clipped on. Hair
pulled back tightly. She speaks in the clipped cadence of someone used to
giving briefings over wind noise.

**Portrait color (in-game dialog):** Teal `#29A197`

**Role:** Stationary guide NPC on the Landing platform. Explains that the
release power has been cut and directs Ethan to the Mid Platform control panel
and Ben to the timed window on the High Platform.

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Safety vest | High-vis yellow-green | `#B8D420` |
| Base shirt | Teal-grey | `#3A7070` |
| Cargo trousers | Olive | `#5C6040` |
| Harness webbing | Orange-tan | `#C87840` |
| Boots | Dark brown | `#3A2E20` |
| Skin | Medium warm | `#C09060` |
| Hair | Dark brown, tied back | `#3A2A20` |
| Portrait color | Teal | `#29A197` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Arms crossed; scanning the zip-line platforms above; professional stillness |
| 1 | Walk — right | 8 | Efficient stride; harness clips jingle slightly |
| 2 | Walk — down | 8 | |
| 3 | Talking — closeup | 6 | Direct eye contact; matter-of-fact expression; points upward at frame 4 |

## Notes

- Stationary at `LENA_POS (220, 440)` on the Landing platform for the
  entire scene.
- After the location is cleared she notes "unusual technique" for Ben's
  timing window — dry approval.

## Save Location

`assets/art/sprites/lena.png`
