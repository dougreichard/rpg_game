---
npc: Hieronymus
location: The Clocktower (landing floor, near the stairwell)
sheet: assets/art/sprites/hieronymus.png
canvas: 640 × 256 px
tile: 64 × 64 px
rows: 4
---

# Hieronymus — Sprite Sheet

## Visual Design

The clocktower's long-tenured keeper — a theoretical expert who freely admits
he is "more theorist than fighter." Lean, older, slightly flustered. Long dark
coat with many small pockets for tools and notes; wire-rimmed spectacles;
thinning hair always a little disheveled. He spent thirty years studying the
tower's mechanisms without ever being able to silence the guardian himself.
Carries himself with academic dignity slightly undermined by visible nerves.

**Portrait color (in-game dialog):** Warm brown-grey `#706359`

**Role:** Stationary guide NPC on the landing floor. Briefs Quinn and Ben on
the two-part tower puzzle (gear escapement + belfry bell sequence). No puzzle
gate depends on talking to him, but he contextualizes both objectives.

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Coat | Dark slate with faint green tinge | `#3A3D38` |
| Waistcoat | Aged ivory | `#D8D0BC` |
| Trousers | Dark grey-brown | `#4A4440` |
| Shoes | Near-black | `#2A2828` |
| Skin | Pale aged | `#C8A888` |
| Hair | Grey-white, thin | `#C0BEB8` |
| Spectacles | Thin brass wire | `#C8A048` |
| Portrait color | Warm brown-grey | `#706359` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Consulting a small notebook; occasional glance up toward the upper floors |
| 1 | Walk — right | 8 | Quick, precise steps; coat tails flutter slightly |
| 2 | Walk — down | 8 | |
| 3 | Talking — closeup | 6 | Earnest, slightly worried; gestures with the notebook |

## Notes

- Stationary at `HIERONYMUS_POS (280, 500)` on the landing floor for the
  entire scene.
- After the location is cleared he expresses thirty years of relief in one
  quiet line.

## Save Location

`assets/art/sprites/hieronymus.png`
