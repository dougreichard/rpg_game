---
npc: Agnes
location: Overworld town (appears after Old Parish Church secret revealed, tile ~15,23)
sheet: assets/art/sprites/agnes.png
canvas: 640 × 256 px
tile: 64 × 64 px
rows: 4
---

# Agnes — Sprite Sheet

## Visual Design

Older woman, musician — specifically an organist. Long skirt and a neat
blouse, practical shoes suitable for pedal-work. Reading glasses pushed up on
her head (not on her nose). Sheet music perpetually tucked under one arm. A
little dusty from the organ loft. Warm and slightly distracted — she was
happily practicing and wasn't bothered by being up there; finding the loft
was a mutual discovery. Cheerful and unflappable.

**Portrait color (in-game dialog):** Soft lavender `#A69EC7`

**Condition:** Only appears after the player reveals the Old Parish Church
secret passage (`secret_revealed` flag). She was in the organ loft it leads to.

**Quest:** No fetch item required — the first conversation completes the quest
and grants `numbered_spoon_12` directly.

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Blouse | Soft lavender | `#B8A8D0` |
| Long skirt | Charcoal grey | `#5C5C6E` |
| Shoes | Black, low-heeled | `#2E2E3A` |
| Skin | Fair, aged | `#F0D4B0` |
| Hair | White-silver, neat | `#D8D8D8` |
| Glasses (pushed up) | Round gold-wire | `#C8A03A` |
| Sheet music (prop) | Cream paper | `#F0E8C8` |
| Portrait color | Soft lavender | `#A69EC7` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Holds sheet music loosely; hums to herself (subtle head-bob); brushes a little dust from her blouse |
| 1 | Walk — right | 8 | Measured, upright walk; music tucked tight under arm |
| 2 | Walk — down | 8 | |
| 3 | Talking — closeup | 6 | Warm and cheerful; glasses bob as she gestures; genuinely delighted to have company |

## Notes

Agnes only spawns once `GameManager.get_level_flag("old_parish_church", "secret_revealed")` is true.
She should look at ease — someone interrupted in the middle of pleasant practice, not someone who was trapped.

## Save Location

`assets/art/sprites/agnes.png`
