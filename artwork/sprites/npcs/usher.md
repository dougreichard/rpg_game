---
npc: Cecil (the Usher)
location: The Grand Marquee Cinema (Lobby)
sheet: assets/art/sprites/usher.png
canvas: 640 × 256 px
tile: 64 × 64 px
rows: 4
---

# Cecil (the Usher) — Sprite Sheet

## Visual Design

Cecil is the Grand Marquee's chief usher — theatrical and impeccably turned
out even on a bad night. Classic usher's uniform: deep crimson jacket with
gold braid, matching pillbox hat (slightly tilted), pressed black trousers,
white gloves. Slender, precise posture, probably 50s. Carries a small
gold-handled torch. He is composed and decorous but clearly unnerved by
whatever is happening backstage.

**Portrait color (in-game dialog):** Crimson `#BA1C24`

**Role:** Stationary guide NPC in the Lobby. Presents a dialog-choice tree
on first meeting (guardian-blocking-backstage vs. projection-booth-access).
Returns post-clear with a brief congratulatory line and directions to the
projection booth.

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Jacket | Deep crimson | `#8A1018` |
| Gold braid / trim | Warm gold | `#C89040` |
| Pillbox hat | Matching crimson | `#8A1018` |
| Trousers | Near-black | `#282028` |
| Gloves | White | `#F4F0EA` |
| Torch handle | Gold | `#C89040` |
| Torch beam | Warm yellow | `#F0D060` |
| Skin | Fair, composed | `#D4A880` |
| Hair | Dark, neatly parted | `#2E2828` |
| Portrait color | Crimson | `#BA1C24` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Stands at attention; torch held out slightly; pillbox hat perfectly level |
| 1 | Walk — right | 8 | Measured, ceremonial stride; white gloves visible at each step |
| 2 | Walk — down | 8 | |
| 3 | Talking — closeup | 6 | Controlled expression; sweeps torch arm at frame 2 (toward the lobby); small grimace at frame 5 when backstage is mentioned |

## Notes

- Stationary at `USHER_POS (480, 420)` in the Lobby for the entire scene.
- In-game dialog name is `"Cecil"` (not "Usher") — `_dialog_box.open("Cecil", ...)`.
- The sprite file is named `usher.png` to match `SpriteLoader.try_load_npc("usher")`.
- The intro dialog uses a `choices` tree (not `from_pages`): the player can
  ask about the backstage guardian or the projection booth; both branches
  are informational with no mechanical gate.

## Save Location

`assets/art/sprites/usher.png`
