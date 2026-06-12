---
character: Ethan
sheet: assets/art/sprites/ethan.png
canvas: 640 × 1088 px
tile: 64 × 64 px
rows: 17
---

# Ethan — Sprite Sheet

## Visual Design

Teenage, wiry/lean build. Tech-casual: grey hoodie, dark navy cargo pants with
gadget-stuffed pockets, sneakers. Always has a small glowing device in hand or
clipped to belt — like a cross between a phone and a hacking tool. Dark-blue
rectangular AR glasses (simple dark-blue rectangles at this resolution). Short
neat dark hair. Efficient, purposeful movements. Cyan data-stream glyphs appear
during hack specials.

## Palette

| Slot | Color | Hex |
|------|-------|-----|
| Hoodie | Grey | `#A8A8B8` |
| Cargo pants | Dark navy | `#2F4A99` |
| Device glow / AR glasses tint | Cyan | `#5ED6FF` |
| Hair | Near-black | `#18141A` |
| UI accent | Teal (DESIGN.md §2.1) | `#33E6D9` |

## Animation Table

| Row | Animation | Frames | Notes |
|-----|-----------|--------|-------|
| 0 | Idle | 6 | Glances at device; screen pulses cyan every 3 frames |
| 1 | Walk — down | 8 | Device at side |
| 2 | Walk — up | 8 | |
| 3 | Walk — right | 8 | |
| 4 | Run — down | 8 | Device pocketed while running |
| 5 | Run — up | 8 | |
| 6 | Run — right | 8 | |
| 7 | Attack — right | 6 | **Ranged gadget shot** — extends device (1–2), fires energy bolt (3), recoil and recover (4–6). This is a **projectile attack, not a melee arc**. The teal beam flash drawn in code replaces the arc and shows the shot direction; no glow in the sprite. |
| 8 | Special — Hack | 8 | Stops; both hands on device; rapid typing; cyan digit glyphs radiate outward frames 4–8 |
| 9 | Panel interact | 6 | Crouching at panel; device plugged in; progress glyph above head |
| 10 | Talking — full body | 6 | Device in hand; gestures with it |
| 11 | Talking — closeup | 8 | AR glasses faintly lit; thoughtful expression |
| 12 | Hurt | 4 | Device briefly flies out of hand; scrambles to catch it |
| 13 | Death / Down | 10 | Falls; device screen goes dark at final frame |
| 14 | Revive | 8 | Recovers; checks device screen first thing |
| 15 | Dodge / Dash | 5 | |
| 16 | Lizard summon | 6 | Holds device up, beeps (1–3); small green lizard appears on arm (4–6) |

## Attack Details

Ethan is the **only ranged player character**. He does not swing a melee
weapon — he fires a projectile from his hacking device. In code, attacking
spawns a `Projectile` node (the same class used by the Sentry enemy) that
travels in `facing` direction at 380 px/s. The visual feedback is a teal
directional beam flash (`_draw_ranged_flash`) drawn at the moment of firing,
not a filled arc wedge.

The attack row (row 7) should animate the device-extend-and-fire motion:
point the device forward, bright flash at the emitter tip, then recover.
**Do not show any arc or sweep in the sprite art.**

| Stat | Value |
|------|-------|
| Attack type | Ranged projectile |
| Flash color | Teal `#33E6D9` |
| Projectile speed | 380 px/s |
| No melee arc | — |

## AI Prompt

> Pixel art sprite sheet, clean modern pixel-art style inspired by
> *Stranger Things: 1984*'s character-swap art (see `gem/ethan.png` for
> fidelity reference), transparent background. Canvas 640 × 1088 px, 64×64
> tiles, 17 rows × 10 columns. Subject: teenage boy, lean wiry build, grey
> hoodie, dark navy cargo pants with gadget pockets, sneakers, short dark hair,
> dark-blue rectangular AR glasses. Small glowing cyan hacking device always
> in hand or clipped to belt. Cyan digit/data-stream glyphs appear during hack
> and attack frames. Animations: idle (device glance, cyan pulse), walk-toward,
> walk-away, walk-right, run-toward (device pocketed), run-away, run-right,
> gadget-ranged-shot-right (extends device, energy bolt fires, recoil recover;
> NO arc or glow overlay — just body pose and device motion), hack-special
> (rapid typing, digit glyphs radiate), panel-crouch-interact (plugged in,
> progress glyph), talking-full-body (device in hand), talking-closeup (AR
> glasses lit), hurt-drops-device, death-screen-goes-dark, revive-checks-
> device-first, dash-right, lizard-summon (lizard appears on arm). Confident
> outlines, soft directional shading with 2-3 step highlight/shadow gradients,
> extended vibrant palette (DESIGN.md §2.0), no dithering.

## Save Location

`assets/art/sprites/ethan.png`
