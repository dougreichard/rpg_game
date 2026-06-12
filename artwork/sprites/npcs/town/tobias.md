---
npc: Tobias
location: Overworld town (appears after Pipe Organ Works secret revealed, tile ~15,-5)
sheet: assets/art/sprites/tobias.png
canvas: 640 × 256 px
tile: 64 × 64 px
rows: 4
---

# Tobias — Sprite Sheet

## Visual Design

Adult man, disheveled in a recently-emerged-from-a-closet way. Rumpled clothes
that have been slept in — collared shirt untucked, jacket creased, trousers
dusty. Squinting slightly at daylight. Not upset about having been stuck in the
parts closet; just glad to be out and fairly philosophical about it. Straightens
up over the course of the conversation once his eyes adjust.

**Portrait color (in-game dialog):** Neutral grey-blue `#80808C`

**Condition:** Only appears after the player reveals the Pipe Organ Works secret
passage (`secret_revealed` flag). He was stuck in the parts closet behind it.

**Quest:** No fetch item required — the first conversation completes the quest
and grants `numbered_spoon_11` directly.

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Jacket | Rumpled grey | `#7A7A8C` |
| Shirt | Off-white, untucked | `#E8E0D0` |
| Trousers | Dusty dark tan | `#8C7A5C` |
| Shoes | Worn brown | `#6E4A2E` |
| Skin | Fair, pale from being inside | `#E8CEA8` |
| Hair | Brown, tousled | `#5C4A36` |
| Portrait color | Neutral grey-blue | `#80808C` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Blinks and squints; straightens jacket; adjusts to the light |
| 1 | Walk — right | 8 | Slightly stiff; stretching his legs for the first time in a while |
| 2 | Walk — down | 8 | |
| 3 | Talking — closeup | 6 | Relieved, bemused expression; fully composed by frame 5 |

## Notes

Tobias only spawns once `GameManager.get_level_flag("pipe_organ_works", "secret_revealed")` is true.
His idle animation should convey the "just emerged from a dark closet" adjustment without being distressing — more comedic bewilderment than trauma.

## Save Location

`assets/art/sprites/tobias.png`
