---
npc: Father Aldric
location: The Old Parish Church (near the altar)
sheet: assets/art/sprites/father_aldric.png
canvas: 640 × 320 px
tile: 64 × 64 px
rows: 5
---

# Father Aldric — Sprite Sheet

## Visual Design

The priest of the Old Parish Church. Older, measured, composed — he has been
here a long time and carries himself accordingly. Traditional clerical cassock
(long dark garment), white collar, hair gone mostly white. Round and a little
portly. Expression defaults to politely neutral; shifts visibly to either
warmth (Quinn's respectful approach) or mild irritation (Erin's blunt one).
Stationary near the altar; does not follow or fight.

**Portrait color (in-game dialog):** Warm brown `#8C806B`

**Role:** Dialog-choice NPC. His reaction to the duo's first conversation
depends on which character is active and which response the player chooses
(respectful vs. blunt). Outcome persisted as `father_aldric_impression`
(`"good"` / `"cool"`).

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Cassock | Near-black with soft sheen | `#2E2E3A` |
| Collar | White | `#F4F0E6` |
| Skin | Aged warm | `#D4A87A` |
| Hair | White | `#F0EEE8` |
| Portrait color | Warm brown | `#8C806B` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Hands clasped before him; slight gentle sway; composed |
| 1 | Talking — full body | 6 | Small deliberate gestures; measured pace |
| 2 | Talking — closeup (neutral / pleased) | 8 | Warm expression; small smile at frame 5–8 — used when impression is `"good"` |
| 3 | Talking — closeup (amused / cool) | 8 | Slight eyebrow raise; faint knowing half-smile — used when impression is `"cool"` |
| 4 | Talking — closeup (annoyed) | 6 | Pinched expression, lips pressed; gives nothing away — reaction to bluntness |

## Notes

- Father Aldric is stationary at `ALDRIC_POS` for the entire scene.
- Three closeup variants map to the three dialog outcomes (pleased, amused,
  annoyed) so the portrait color can convey his emotional state without
  requiring a full new portrait color per state.

## Save Location

`assets/art/sprites/father_aldric.png`
