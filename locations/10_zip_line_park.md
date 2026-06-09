# 10. Zip Line Park

**Script:** `scripts/levels/zip_line_park.gd`
**Entering duo:** Ethan + Ben
**Unlock condition:** TBD (mid-game)

---

## Current layout

Chain of three platforms at ascending heights — Landing (low, SW) → Mid
Platform (center, Ethan's control panel) → High Platform (NE, Ben's
timing-ring release). Two narrow Bridge corridors connect them.

Ben's release gate is a timing gate: a pulsing `_draw()` ring telegraphs a
recurring window; pressing Special during the final `PULSE_GOOD_WINDOW`
seconds (ring glows green) succeeds. Missing flashes red + short lockout. ✓

---

## Improved floor plan

```
+-----HIGH PLATFORM----------+
|  [RELEASE MECHANISM]       |  ← Ben's timing-ring puzzle
|  [zip cable → east wall]   |  ← diagonal line, east side
|  [railing — north+east]    |
+------BRIDGE 2--------------+
       |
+------MID PLATFORM----------+
|  [CONTROL PANEL]           |  ← Ethan's hack
|  [zip cable → east wall]   |
|  [support strut]           |
+------BRIDGE 1--------------+
       |
+-----LANDING----------------+
|  [Doorway]                 |
|  [spawn]                   |
|  [enemies]                 |
|  [hiding spot]             |
|  [loot] [loot]             |
+----------------------------+
```

---

## Visual props to add

1. **Zip line cable** — `_draw()` thin diagonal line from each platform's east edge to the east wall at the platform's top-right corner. One per platform. Bright grey.
2. **Platform railing** — `_draw()` horizontal line along the north + east edges of each platform floor. 3px thick, slightly darker than floor. Creates an elevated-platform silhouette.
3. **Support strut** — `_draw()` diagonal line under Mid Platform's floor level (visible in the bridge gap below it). Gives the platform a "raised on legs" feel.
4. **Control panel** — `make_control_panel_texture(w, h)` — same shape as Recording Studio soundboard but compact (40×16px). Mid Platform prop.
5. **Launch arm bracket** — static metal bracket behind Ben's timing mechanism (vertical post + horizontal arm), suggesting the zip line anchor hardware.

### Prop draw functions to request

```
"In zip_line_park.gd's _build_props(), add zip cable lines via _draw():
for each platform, draw a 1px diagonal line from (platform_east, platform_top)
to (room_right, platform_top - 40). Use a bright grey color."

"Add platform railing lines in zip_line_park.gd's _draw(): a 3px horizontal
line along the north edge of each platform rectangle (the top of each
platform's wall band). Color = floor_accent slightly darkened."

"Add a support strut diagonal in zip_line_park.gd's _draw(): a line from
mid-platform's south-west corner down-left at 45°, ending 32px below.
Reads as the platform leg."
```

---

## Palette

```
FLOOR_BASE_COLOR   = Color(0.25, 0.35, 0.25)   # mossy outdoor wood
FLOOR_ACCENT_COLOR = Color(0.40, 0.55, 0.35)   # fresh-cut wood
```

---

## Puzzles

- Ethan presses Special at control panel → hacks it (standard proximity gate)
- Ben presses Special during ring's green window → timed release (timing gate)
- Both conditions + enemies cleared gate completion
- `guard_whistle` loot box on Landing (one-shot noise distraction)
- `arcade_token` junk loot box on Landing (embossed defunct arcade logo — does nothing)

---

## Atmosphere notes

The zip line cables are the signature element — three diagonal lines from each
platform's east edge to the east wall, drawn in `_draw()`, are free and
immediately communicate "this is a zip line park." Platform railings (horizontal
lines along the north/east edges) give each elevated area a clean silhouette.
The support struts underneath turn the "platforms at different heights" from an
abstract height difference into a visually legible elevated structure. All three
are `_draw()` lines — no new prop functions needed.
