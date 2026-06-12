---
npc: Mr. Bellows
location: Bellows & Sons Pipe Organ Works (Manager's Office)
sheet: assets/art/sprites/mr_bellows.png
canvas: 640 × 320 px
tile: 64 × 64 px
rows: 5
---

# Mr. Bellows — Sprite Sheet

## Visual Design

Quinn's manager at Bellows & Sons Pipe Organ Works. Older man, stocky build,
work-worn but respectable — he runs a workshop, not a showroom. Apron over a
collared shirt, rolled-up sleeves. Thinning hair, small round reading glasses,
moustache. He looks like someone who has been a craftsman his whole life.
Always looks slightly flustered. Found seated at his desk in the Manager's
Office; doesn't leave during play.

**Portrait color (in-game dialog):** Muted olive-green `#596652`

**Role:** Quest-giver / dialog NPC. Introduces the organ repair objective;
Erin must fast-talk the `tuning_key` out of him.

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Apron | Faded tan | `#C8A87A` |
| Shirt | Off-white | `#F0E8D0` |
| Trousers | Dark grey | `#5C5C6E` |
| Skin | Warm ruddy | `#D9A36E` |
| Glasses | Small round, dark frame | `#3A3A4A` |
| Moustache / hair | Salt-and-pepper grey | `#8C8C8C` |
| Portrait color | Muted olive-green | `#596652` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle — seated at desk | 6 | Slight lean forward; papers in front; occasional head-raise |
| 1 | Talking — full body | 6 | Gestures with hands; leans forward emphatically |
| 2 | Talking — closeup | 8 | Flustered expression; pats pockets at frame 4 (the tuning key moment) |
| 3 | Relieved | 6 | Leans back; exhales; small smile |
| 4 | Hand over item | 4 | Reaches forward, places tuning key on desk — payoff frame for Erin's fast-talk |

## Notes

- Mr. Bellows is stationary — seated at desk — for the entire scene. No walk
  or chase animations needed.
- The tuning key is visible clipped to his belt during idle/talk frames and
  absent from frame 4 onward once the item is handed over.

## Save Location

`assets/art/sprites/mr_bellows.png`
