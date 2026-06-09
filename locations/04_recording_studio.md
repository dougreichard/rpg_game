# 4. The Recording Studio

**Script:** `scripts/levels/recording_studio.gd`
**Entering duo:** Quinn + Ben
**Unlock condition:** Complete Iron & Strings Gym
**Unlocks:** Ethan

---

## Current layout

Entry lobby → control room (soundboard, enemies, hiding spot) → sealed
recording booth (glass-blue BoothDoor StaticBody2D, Ethan prop inside).
Ben tuning the soundboard slides the booth door open via `create_tween()`. ✓

---

## Improved floor plan

```
+---RECORDING BOOTH-----+
|  [ETHAN prop]         |  ← visible once BoothDoor slides up
|  [mic stand]          |
|  [stool]              |
+---GLASS-BoothDoor-----+
|       CONTROL ROOM    |
|  [SOUNDBOARD]         |
|  [speaker cab ×2]     |
|  [reel-to-reel]       |
|  [enemies]            |
|  [hiding spot]        |
|  [loot] [loot]        |
+-------+               |
|  LOBBY               |
|  [Doorway]            |
|  [spawn]              |
+-----------------------+
```

---

## Visual props to add

1. **Soundboard console** — `make_soundboard_texture(w, h)` — wide horizontal panel, two rows of small dot/knob controls, a horizontal fader strip. 80×20px.
2. **Speaker cabinet** — `make_speaker_cab_texture(w, h)` — tall rectangle with a circular driver in the lower center. 20×28px × 2 (one each side of the booth window).
3. **Reel-to-reel** — `make_reel_texture(w, h)` — two overlapping circles (reels) on a horizontal machine body. Optional spinning animation via `_draw()`.
4. **Mic stand** — thin vertical line with a small circle at top and an angled boom. Inside booth only.
5. **Acoustic foam** — checkerboard of small 4×4 squares on booth walls, alternating `FLOOR_ACCENT` and `FLOOR_BASE`. Applied via `_draw()` in the booth zone only.

### Prop draw functions to request

```
"Add make_soundboard_texture(w, h) to PlaceholderArt. A wide dark panel
with two rows of small dot controls (evenly-spaced circles) and a thin
horizontal fader bar across the middle."

"Add make_speaker_cab_texture(w, h) to PlaceholderArt. A rectangle with
a circular driver centered in the lower half and a thin horizontal
tweeter bar in the upper quarter."

"Add make_reel_texture(w, h) to PlaceholderArt. Two overlapping circles
(tape reels) on a flat machine body rectangle."
```

---

## Palette

```
FLOOR_BASE_COLOR   = Color(0.18, 0.18, 0.22)   # dark studio charcoal
FLOOR_ACCENT_COLOR = Color(0.35, 0.28, 0.45)   # purple-grey acoustic foam
```

---

## Puzzles

- Ben presses Special near soundboard → tunes it AND opens booth door (one action, two payoffs)
- Ethan prop becomes visible inside booth once door slides
- `ticket_ethan` loot box inside booth (found where Ethan is freed)
- `tangled_headphone_cable` junk loot box on control room floor

---

## Atmosphere notes

The acoustic foam checkerboard on booth walls is the fastest way to make
the booth look like a booth — it's just a `_draw()` pattern, no new asset.
The glass-blue BoothDoor is already a strong visual; complementing it with
speaker cabinets on either side of the window makes the "looking into the
booth" framing feel deliberate. The reel-to-reel on the control room
console is a good fit for the "recording that's a clue about Uncle Doug"
narrative hint.
