# Implementation History — Hunkle Bunkle

This file holds the detailed, devlog-style "how was this built and verified"
narratives that used to live inline in `CLAUDE.md`. CLAUDE.md is auto-loaded
into every Claude Code conversation, so the verbose rollout history was moved
here to keep that file lean — read this file when you need the full story
behind a location's layout, a clear-animation flavor, a camera bounding box,
or how a system was verified (functional-check counts, GUT status, etc.).

CLAUDE.md keeps the load-bearing facts for each location (entering duo,
multi-room layout one-liner, `level_progress` flag names, completion id) and
links here for the rest.

---

## Doorway / camera-follow / multi-room rollout — full narrative

> **Status: COMPLETE — rolled out to all 13 of 13 locations** (camera
> tracking + bounds, doorway arm/trigger sequence including "armed but still
> far" / "close but unarmed" edge cases, secret-passage reveal disabling
> collision + fading its sprite + revealing a hidden loot box, `level_progress`
> round-tripping through `set_level_flag`/`get_level_flag`/save/load, and full
> re-entry restoration — skip-spawn, restored organ palette, pre-opened vs.
> still-closed loot boxes — all exercised via a temp-autoload functional script
> driving the live scene; GUT 16/16 unaffected). **The Old Parish Church is
> rolled out second** — a cross-shaped vestibule/nave/hidden-organ-loft plan
> (its dialogue-only, no-enemies spec meant no `_spawn`/`level_progress`
> "enemies_cleared" flag was needed, and its secret passage reveals a pure
> lore prop rather than a loot box, since per-location inventory hookups
> remain separate, still-pending scope) — verified via 31 functional checks +
> GUT 16/16. **Iron & Strings Gym is rolled out third** — a locker-room →
> gym-floor → cage-alcove plan whose barbell graduated from a purely cosmetic
> sprite to a literal `StaticBody2D` collider blocking the cage doorway
> (Evan's Special disables it and slides it aside via `create_tween()`,
> making "moves heavy equipment to open paths" mechanically true) — verified
> via 24 functional checks + GUT 16/16. **The Recording Studio is rolled out
> fourth** — a lobby → control room → sealed-recording-booth plan whose
> `BoothDoor` (a literal glass-blue `StaticBody2D` collider) seals Ethan in;
> tuning the soundboard (Ben's Special, one press) both solves the puzzle
> gate AND slides the door vertically into the ceiling via `create_tween()`,
> nailing "Ben...trigger doors and mechanisms" and the gate in one motion —
> verified via 24 functional checks + GUT 16/16. **The Clocktower is rolled
> out fifth — and is the prototype's first literal "stacked floors" layout**
> (the natural fit this status section called out back at the Pipe Organ
> Works prototype): a vertical shaft of landing → gear floor → belfry,
> connected by stairwell gaps, with the clockwork-guardian Boss spawning
> squarely in the upper gap — "the clockwork guardian holds the stairs"
> made literal layout instead of flavor text. The camera's tall 352×592
> bounding box means the climb genuinely reveals itself floor by floor —
> verified via 22 functional checks + GUT 16/16. **The Harbor & Docks is
> rolled out sixth** — a pier → container-maze yard → crane-platform plan
> whose cargo `Container` graduated from a purely cosmetic sprite-shift to a
> literal `StaticBody2D` collider sealing the platform doorway (Evan's
> Special disables it and **hoists it up and away with a swinging rotation**
> via a parallel `create_tween()` — a third distinct clear-animation flavor
> alongside Iron & Strings' horizontal slide and Recording Studio's vertical
> slide), plus two collidable `MazeCrate` cargo-crate obstacles scattered
> through the yard literalizing "cargo container maze is good brawler
> terrain" as actual routing obstacles rather than flavor text. Calvin &
> Coolidge's existing combat-assist summon carried over untouched, just
> relocated into the new yard — verified via 26 functional checks + GUT
> 16/16. **The Public Library & Archive is rolled out seventh** — a reading
> room → checkpoint → Restricted Stacks plan whose librarian's desk graduated
> from a purely cosmetic sprite-recolor to a literal `StaticBody2D` collider
> sealing the only passage into the stacks (Erin's Special disables it and
> plays a fourth distinct clear-animation flavor — a parallel **scale-down +
> fade** via `create_tween()`, "she packs up her desk and steps aside" —
> alongside Iron & Strings' horizontal slide, Recording Studio's vertical
> slide, and Harbor & Docks' hoist-and-swing), making "Erin...talks her way
> past a strict librarian to access restricted stacks" mechanically true:
> Ethan's terminal is physically unreachable until she does. Its camera's
> `24,144`–`936,536` bounding box is the rollout's first with a non-24 top
> bound (no north alcove, so the topmost wall sits lower) — verified via 28
> functional checks + GUT 16/16. **The Carnival & Fairground is rolled out
> eighth** — an open midway → backstage alcove plan whose `BackstageGate` (a
> velvet curtain barrier) graduated from a purely cosmetic guard-sprite
> recolor to a literal `StaticBody2D` collider sealing the alcove (Erin's
> talk-down, performed right at the gate, both solves the dialogue puzzle AND
> raises it via a FIFTH distinct clear-animation flavor — a parallel upward
> slide + vertical scale-to-near-zero, "a curtain hoisted into the rigging" —
> alongside the gym's horizontal slide, the studio's vertical slide, the
> docks' hoist-and-swing, and the library's scale-down+fade), revealing an
> always-present `_doug_poster` portrait sprite the same way the Recording
> Studio's booth door reveals its `_ethan_prop`. Verified via 31 functional
> checks + GUT 16/16. **The Underground Tunnels is rolled out ninth — and is
> the prototype's first literal "branching maze" layout** (the natural fit
> this status section pre-named back at the Pipe Organ Works prototype): a
> structurally novel Y/T-shaped tunnel network — south entry corridor →
> central junction chamber → forking west tunnel (Evan's rubble) and east
> tunnel (Ethan's hatch), 16 hand-placed wall segments rather than a reused
> footprint. Its camera's `24,184`–`936,536` bounding box carries the
> rollout's highest top bound yet (`CAMERA_LIMIT_TOP = 184` — the maze's
> roof sits well below the room's nominal top, with nothing above it to
> show). It also introduces a new persistence sub-pattern: `level_progress`
> now stores Ethan's **partial** hatch-hacking progress
> (`hatch_progress`, an int) — not just the final pass/fail — so walking out
> mid-hack via the Doorway doesn't erase 1–2 of the 3 required passes.
> Verified via 31 functional checks (including a dedicated
> partial-progress-survives-re-entry check) + GUT 16/16. **Zip Line Park is
> rolled out tenth — and is the prototype's first literal "platforms at
> different heights" layout** (the natural fit this status section pre-named
> back at the Pipe Organ Works prototype): a chain of three platforms —
> Landing (low) → Mid Platform (taller, Ethan's panel) → High Platform
> (tallest, Ben's timing-ring release) — each successive platform's north
> wall reaching further up the screen, a literal staircase silhouette that
> reads as ascension in 2D, linked by two narrow Bridge corridors that are
> themselves the zip-line crossings. Its camera's `24,164`–`936,536`
> bounding box derives `CAMERA_LIMIT_TOP = 164` from the High Platform's
> north wall — the rollout's third non-standard top bound, alongside
> Library & Archive's `144` and Underground Tunnels' `184`. Verified via 27
> functional checks + GUT 16/16. **VR Escape Room is rolled out eleventh —
> and is the prototype's first literal "themed corrupted-stage zones"
> layout** (the natural fit this status section pre-named back at the Zip
> Line Park rollout): a neutral cyber-blue Boot Chamber forks into a
> warm-amber "medieval"-glitch Stage Alpha (Quinn's physics repair) and a
> teal-aqua "underwater"-glitch Stage Beta (Ethan's system hack), each its
> own `TileMap`/palette layered on top of the base floor grid via a new
> `_paint_stage_floor()` helper — crossing a corridor threshold visibly
> recolors the floor underfoot, making "each stage has a distinct visual
> theme" a structural fact rather than a prop-deep one. Its camera's
> `24,24`–`776,536` bounding box is the most compact yet (three modest zones,
> no extreme top bound this time). Verified via 31 functional checks + GUT
> 16/16. **The Drop is rolled out twelfth — and is the prototype's first
> literal "two-phase descent" layout**: a Touchdown Clearing → Corridor →
> Snag Grove chain where the wreckage sits squarely at the clearing's only
> exit, physically gating the path to Ethan's jammed chute release — "the
> landing zone is locked until the right character steers to it" made a
> structural chokepoint, not flavor text. Its camera's `24,24`–`576,536`
> bounding box is the second-most compact yet (after VR Escape Room's
> `776`-wide one). Verified via 34 functional checks — including a dedicated
> William-&-Mary alternate-route check (summon away from the wreck, drive
> both companions to their flanking points, confirm `_landing_cleared`
> flips only once both report `is_holding`) — plus GUT 16/16. **The Grand
> Marquee Cinema is rolled out thirteenth and FINAL** — a literal
> hub-and-wings layout naming its zones outright, per the spec line
> "Backstage, projection booth, balcony, and lobby are distinct zones": a
> Lobby (south, entry) opens into a central Backstage hub — where the
> cinema's guardian Boss "holds the aisle" across the only path forward —
> which branches west into the Projection Booth (Quinn's repair) and north
> up onto the Balcony (Ben's house organ, literally elevated above the
> stage it "manipulates the crowd" from). It's also the only location of
> the 13 where a Doorway-exit can't simply return to the overworld — this
> IS the endgame, Uncle Doug has just been found — so `_exit_to_overworld()`
> uniquely branches on `_cleared`: cleared routes to `ResultScreen.tscn`
> (the same destination the clear-overlay's "press ENTER" already reaches,
> via the idempotent `complete_location` so it never double-grants), while
> an early exit returns to the overworld like every other location's
> Doorway. Verified via 41 functional checks + GUT 16/16.
>
> **THE ENTIRE 13-LOCATION ROLLOUT IS NOW COMPLETE.** Every location now has
> a Doorway, a camera that follows the active character within a bespoke
> bounding box, a multi-zone layout matching its own CLAUDE.md spec, and
> mid-level progress that persists across exits/re-entries via
> `level_progress`/`get_level_flag`/`set_level_flag`. What started as a
> single-location prototype at Pipe Organ Works (proving rooms + hallway +
> secret passage) was mechanically — but bespoke-ly — repeated 12 more
> times, each location getting its own structurally novel layout flavor
> matching its spec: stacked floors (Clocktower), a branching maze
> (Underground Tunnels), platforms at different heights (Zip Line Park),
> themed corrupted-stage zones (VR Escape Room), a two-phase descent (The
> Drop), and finally hub-and-wings (Grand Marquee Cinema) — twelve distinct
> clear-animation flavors and chokepoint mechanics along the way, none of
> them requiring a single change to the shared `_build_walls()`/
> `_build_floor()` helpers.

---

## 1. Bellows & Sons Pipe Organ Works

**Implementation note — first level with a tile-mapped floor:**
`pipe_organ_works.gd._build_floor()` was the **prototype** for the project's
new tile-mapped retro look (replacing the previous walls-on-a-void look —
see CLAUDE.md "Tile-mapped floors"), since rolled out to all 12 other levels.

**Implementation note — first level with a Doorway, camera-follow, and a
bespoke multi-room layout** (see CLAUDE.md "Doorways, camera-follow &
multi-room levels" — this is that system's prototype): the single 640×360
workshop became four spaces matching the location's "scattered across the
factory floor" spec — an **entry bay** (`Doorway` + spawn, where Quinn and
Erin start beside the archway home), a **hallway** connecting it to the
**main workshop floor** (the organ, both original loot boxes, and the
Grunt/Runner spawns — basically the old room, enlarged to 640×480 and
relocated), and a **secret parts closet** behind a **secret passage**: a
wall segment (`Walls/SecretWall`) that looks identical to its neighbors but
conceals a hidden lever — Quinn presses Special near it
(`_reveal_secret_passage`) to disable its `CollisionShape2D` and fade its
sprite via `create_tween()`, revealing a third loot box
(`spare_clockwork_gear`, kept `visible = false` until revealed so it can't
be seen through the wall it sits behind). The `Camera2D` now follows
whichever character is active (`position_smoothing_enabled` +
`CAMERA_LIMIT_*` consts derived from the new ~1352×536 bounding box), and
the `Doorway` lets the duo leave at any time — cleared or not — with
`GameManager.level_progress` persisting `enemies_cleared`/
`organ_repaired`/`secret_revealed`/each loot box's open state so a
re-entered workshop picks up exactly where they left it (skip re-spawning a
cleared floor, restored organ palette, pre-opened boxes). `_build_walls()`
and `_build_floor()` needed no script changes — just more `.tscn` wall
nodes and a bumped `FLOOR_COLS`/`FLOOR_ROWS`.

---

## 2. The Old Parish Church

**Implementation note — first rollout of Doorway/camera-follow/multi-room
beyond the Pipe Organ Works prototype** (see CLAUDE.md "Doorways,
camera-follow & multi-room levels"): the single 640×360 sanctuary became a
**cross-shaped church floor plan** matching its dialogue-heavy, no-enemies
spec — a **vestibule** (`Doorway` + spawn, south end), a long **nave**
(the BLUE/Quinn and RED/Erin pillars relocated to its *opposite* west/east
walls — ~440px apart, so "neither can solve it alone" now also means
physically crossing the nave and swapping, not just standing two paces
apart), and a **hidden organ loft** behind a **secret passage** at the
nave's altar end: a wall segment (`Walls/SecretWall`) Quinn presses Special
near (`_reveal_secret_passage`) to disable its collider and fade its sprite
via `create_tween()`, revealing a small pipe-organ prop — a quiet, optional
discovery that plays the spec's "may contain a pipe organ echoing the
starting location" line as pure lore/flavor (this location has no
loot-box/inventory hookup — that rollout is separate, still-pending scope).
`Camera2D` follows the active character within a `184,24`–`776,656`
bounding box, and the `Doorway` lets the duo leave at any time —
`GameManager.level_progress` persists `quinn_done`/`erin_done`/
`secret_revealed` so a re-entered church restores both pillars' solved
palettes, the open passage, and the clear overlay immediately. Verified via
a 31-check temp-autoload functional script (camera tracking + bounds,
standalone-instance doorway arm/trigger, secret-passage reveal, both pillar
gates, full re-entry restoration) plus GUT 16/16 — no regressions.
`_build_walls()`/`_build_floor()` needed zero script changes, only the
13-wall `.tscn` layout and a bumped `FLOOR_COLS`/`FLOOR_ROWS` (25×21).

---

## 3. Iron & Strings Gym

**Implementation note:** The entering duo is **Quinn + Evan** — at this point in
the unlock chain only Quinn, Erin, and Evan are available (Ben is unlocked BY
clearing this location, so he can't be in the entering duo; this resolves an
apparent tension in the original spec between "Characters required: Evan and
Ben" and "Unlocks: Ben"). Clear the floor of Grunts and a Brute, then have Evan
approach the barbell blocking Ben's cage and press **Special (G)** — his
strength clears it and frees Ben. Both conditions (enemies cleared + barbell
moved) must be met to complete the level.

**Implementation note — third Doorway/camera-follow/multi-room rollout**
(see CLAUDE.md "Doorways, camera-follow & multi-room levels"): the single
640×360 floor became a **locker room → main gym floor → Ben's cage alcove**
layout — a `Doorway` + spawn in the locker room (enemies and the hiding
spot live on the larger gym floor beyond it), with the cage alcove sitting
north of the gym floor behind a doorway the barbell jams shut. The barbell
itself graduated from a **purely cosmetic prop** (a sprite that just
recolored and nudged up 90px) to a **literal `StaticBody2D` collider**
blocking that doorway — Evan's Special now disables its collider and
slides its sprite aside via `create_tween()` (`_move_barbell`, the same
disable-then-animate shape as Pipe Organ Works' secret passage, sliding
rather than fading), making "Evan's super strength moves heavy equipment to
open paths" (this location's spec line) physically true rather than
decorative. It's a sibling of `$Walls` rather than a child, so it keeps its
own bespoke iron-red bordered-rectangle texture
(`make_gate_texture(FLOOR_ACCENT_COLOR, 200, 16)`) instead of the generic
brick pattern — reads as gym equipment jammed in a doorway, not masonry.
`Camera2D` follows the active character within a `24,24`–`936,536`
bounding box; `level_progress` persists `enemies_cleared`/`barbell_moved`
so a re-entered gym skips respawning a cleared floor and restores the
opened cage doorway. Verified via 24 functional checks (camera, standalone
doorway arm/trigger, barbell collider-disable + slide-tween + persistence,
enemies-cleared persistence, full re-entry restoration) plus GUT 16/16 —
no regressions. `_build_walls()`/`_build_floor()` needed zero script
changes — 12 wall nodes (+ the separately-textured Barbell body) and
`FLOOR_COLS`/`FLOOR_ROWS` bumped to 30×17.

---

## 4. The Recording Studio

**Implementation note:** The entering duo is **Quinn + Ben** — same
unlock-chain rule as Iron & Strings Gym applies (Ethan is unlocked BY clearing
this location, so he can't be in the entering duo; Ben is available because he
was freed at the Gym). Clear the floor of Grunts and Runners, then have Ben
approach the soundboard console and press **Special (G)** — his ear tunes it
by Perfect Pitch and frees Ethan. Both conditions (enemies cleared + console
tuned) must be met to complete the level.

**Implementation note — fourth Doorway/camera-follow/multi-room rollout**
(see CLAUDE.md "Doorways, camera-follow & multi-room levels"): the single
640×360 floor became a **lobby → control room → sealed recording booth**
layout — a `Doorway` + spawn in the small entry lobby, the larger control
room beyond it (the soundboard console, Grunts/Runners, the relocated
hiding spot), and a small booth alcove sealed off to its north by a
**soundproof glass `BoothDoor`** (a literal `StaticBody2D` collider, sibling
of `$Walls` so it keeps its own glass-blue `make_gate_texture` rather than
the generic wood-tone brick). "Someone has scrambled the studio" plays out
as Ethan trapped behind a jammed access door wired to the very soundboard
Ben has to tune — one Special press at the console (`_on_special_used`)
both flips `_console_tuned` AND calls `_open_booth_door`, which disables
the door's collider and slides its sprite straight up into the ceiling via
`create_tween()` (`BOOTH_DOOR_SLIDE_OFFSET`, a *vertical* slide — distinct
from Iron & Strings' horizontal barbell slide and Pipe Organ Works' fade,
same disable-then-animate mechanism), revealing an `_ethan_prop` flavor
sprite inside. One action nails both "Ben...trigger doors and mechanisms"
and the puzzle gate at once. `Camera2D` follows the active character within
a `24,24`–`896,536` bounding box; `level_progress` persists
`enemies_cleared`/`console_tuned` so a re-entered studio skips respawning a
cleared floor and restores the open booth door + visible Ethan prop
instantly. Verified via 24 functional checks (camera, standalone doorway
arm/trigger, console-tune → door-disable → slide-tween → Ethan-reveal →
flag-persistence chain, enemies-cleared persistence, full re-entry
restoration) plus GUT 16/16 — no regressions. `_build_walls()`/
`_build_floor()` needed zero script changes — 12 wall nodes (+ the
separately-textured BoothDoor body) and `FLOOR_COLS`/`FLOOR_ROWS` bumped to
28×17.

---

## 5. The Clocktower

**Implementation note:** Entering duo is **Quinn + Ben** (both already unlocked
by this point — no unlock-chain conflict here, since Clocktower doesn't grant a
new character). First location to feature the **Boss** enemy — defeat it, then
Quinn approaches the gear mechanism and Ben approaches the bells, each pressing
**Special (G)** in range. All three conditions (boss/enemies cleared + gear
repaired + bells played) gate completion.

**Implementation note — fifth Doorway/camera-follow/multi-room rollout, and
the prototype's first literal "stacked floors" layout** (see CLAUDE.md
"Doorways, camera-follow & multi-room levels" — the plan called this out as
Clocktower's natural fit back at the Pipe Organ Works prototype): the
single 640×360 room became a **vertical shaft of three stacked floors** —
a ground-floor **landing** (south, `Doorway` + spawn), a **gear floor**
(middle — Quinn's mechanism, two Grunts, the relocated hiding spot), and
the **belfry** (top — Ben's bells) — connected by two stairwell gaps in
the floor dividers between them. The clockwork guardian Boss spawns
squarely in the upper stairwell gap, making "the clockwork guardian holds
the stairs" from this location's hint text into the literal layout rather
than a flavor line — the duo must clear it to ascend from the gear floor to
the belfry. `Camera2D` follows the active character within a tall
`264,24`–`616,616` bounding box (352×592 — far more vertical span than the
720px viewport shows at once, so the climb genuinely reveals itself floor
by floor as the camera pans up the shaft); `level_progress` persists
`enemies_cleared`/`gear_repaired`/`bells_played` so a re-entered tower
skips respawning a cleared floor and restores both mechanism props' solved
palettes. Verified via 22 functional checks (camera tracking up the shaft +
bounds, standalone doorway arm/trigger, both Special-gate puzzles +
persistence, Boss/enemies-cleared persistence, full re-entry restoration)
plus GUT 16/16 — no regressions. `_build_walls()`/`_build_floor()` needed
zero script changes — 8 wall nodes (two long shaft walls + north/south caps
+ four stairwell-divider segments) and `FLOOR_COLS`/`FLOOR_ROWS` bumped to
11×19 for the new narrow-and-tall bounding box.

---

## 6. The Harbor & Docks

**Implementation note:** Entering duo is **Quinn + Evan** (mirrors Iron &
Strings Gym — Evan is the puzzle-solver, Quinn the steady partner; no
unlock-chain conflict since this is a mid-game stop). Clear the dock of Grunts
and Runners, then have Evan approach the cargo container blocking the crane
controls and press **Special (G)** — his strength shoves it aside. Both
conditions (enemies cleared + container moved) gate completion.

**Implementation note — sixth Doorway/camera-follow/multi-room rollout**
(see CLAUDE.md "Doorways, camera-follow & multi-room levels"): the single
640×360 dock floor became a **pier → container-maze yard → crane platform**
layout — a `Doorway` + spawn on the entry pier (west), a large
**container-maze yard** (the gym/studio-shaped main floor, but dressed with
two collidable `MazeCrateA`/`MazeCrateB` cargo crates scattered through it
— siblings of `$Walls` with their own cargo-brown `make_gate_texture` so
they read as freight, not masonry — literalizing "cargo container maze is
good brawler terrain" as actual obstacles to route combat around, not just
flavor text), and a small **crane platform** alcove (north) sealed by the
cargo `Container` itself. The container graduated from a **purely cosmetic
prop** (a sprite that just recolored and nudged sideways) to a **literal
`StaticBody2D` collider** blocking the platform doorway — Evan's Special now
disables its collider and **hoists it up and away with a swinging rotation**
via `create_tween()` (`_move_container`, `CONTAINER_HOIST_OFFSET`/
`_ROTATION` — a parallel position+rotation tween reading as "the crane winches
it off and out of the way," a third distinct clear-animation flavor alongside
Iron & Strings' horizontal slide and Recording Studio's vertical slide),
making "Evan moves heavy freight to clear paths or trigger crane mechanisms"
(this location's own spec line) mechanically true rather than decorative.
**Calvin & Coolidge's existing combat-assist summon is preserved untouched**
— just relocated into the new yard alongside the relocated hiding spot and
Grunt/Runner spawns. `Camera2D` follows the active character within a
`24,24`–`936,536` bounding box (the same footprint shape as Iron & Strings
Gym's locker→gym→cage, re-themed and re-populated rather than reinvented —
bespoke comes from spec-fit content, not novel geometry for its own sake);
`level_progress` persists `enemies_cleared`/`container_moved` so a
re-entered dock skips respawning a cleared floor and restores the hoisted
container's disabled collider + off-screen position instantly. Verified via
26 functional checks (camera tracking + bounds, standalone doorway
arm/trigger, container collider-disable + hoist-tween + persistence, maze
crate colliders/textures, enemies-cleared persistence, full re-entry
restoration) plus GUT 16/16 — no regressions. `_build_walls()`/
`_build_floor()` needed zero script changes — 12 wall nodes (+ the
separately-textured Container and two MazeCrate bodies) and
`FLOOR_COLS`/`FLOOR_ROWS` bumped to 30×17.

---

## 7. The Public Library & Archive

**Implementation note:** Entering duo is **Erin + Ethan** (both already
unlocked — no unlock-chain conflict). Clear the floor of Grunts and a Sentry,
then have Erin approach the librarian and Ethan approach the terminal, each
pressing **Special (G)** in range. Both conditions (enemies cleared + librarian
talked down + terminal hacked) gate completion of `"library"`.

**Implementation note — seventh Doorway/camera-follow/multi-room rollout**
(see CLAUDE.md "Doorways, camera-follow & multi-room levels"): the single
640×360 floor became a **reading room → checkpoint → Restricted Stacks**
layout — a `Doorway` + spawn in the public reading room (west, where the
Grunt/Sentry patrol and the relocated hiding spot live), and the
**Restricted Stacks** (east, the archive terminal's quiet home — the
"slower, stealth-and-puzzle counterpoint" spec line gets a literal quiet
room of its own). The narrow passage between them is sealed by the
**librarian's desk**, which graduated from a **purely cosmetic prop** (a
sprite that just recolored) to a **literal `StaticBody2D` collider** —
the FOURTH cosmetic-to-collider upgrade of this rollout (after Iron &
Strings' barbell, Recording Studio's booth door, and Harbor & Docks'
container — clearly an established move now, not a one-off). Erin's
Special at the desk (`_step_aside_librarian`) disables its collider and
plays a fourth distinct clear-animation flavor — a parallel scale-down +
fade via `create_tween()` ("she packs up her desk and steps aside"),
distinct from the gym's horizontal slide, the studio's vertical slide, and
the docks' hoist-and-swing — making "Erin...talks her way past a strict
librarian to access restricted stacks" mechanically true: the stacks (and
Ethan's terminal inside them) are physically unreachable until she does.
`Camera2D` follows the active character within a `24,144`–`936,536`
bounding box (the first rollout location whose top bound isn't 24 — no
north alcove, so the topmost wall sits lower); `level_progress` persists
`enemies_cleared`/`librarian_talked`/`archive_hacked` so a re-entered
library skips respawning a cleared floor and restores the stepped-aside
desk (collider disabled, sprite scaled+faded) and the terminal's hacked
palette instantly. Verified via 28 functional checks (camera tracking +
bounds, standalone doorway arm/trigger, desk collider-disable +
scale/fade-tween + persistence, terminal-hack + persistence,
enemies-cleared persistence, full re-entry restoration) plus GUT 16/16 —
no regressions. `_build_walls()`/`_build_floor()` needed zero script
changes — 8 wall nodes (+ the separately-textured LibrarianDesk body) and
`FLOOR_COLS`/`FLOOR_ROWS` bumped to 30×17.

---

## 8. The Carnival & Fairground

**Implementation note:** The entering duo is **Quinn + Erin** — Ben's musical
draw is treated as narrative color (the crowd noise covering the team's
approach) since the engine supports only a two-character active duo; Quinn and
Erin's abilities directly gate the puzzle. Clear the midway of Grunts and a
Brute, then have Quinn approach the broken ride and Erin approach the backstage
guard, each pressing **Special (G)** in range. Both conditions (enemies cleared
+ ride repaired + guard talked past) gate completion of `"carnival"`.

**Implementation note — eighth Doorway/camera-follow/multi-room rollout**
(see CLAUDE.md "Doorways, camera-follow & multi-room levels"): the single
640×360 floor became an **open midway → backstage alcove** layout — a
`Doorway` + spawn on the midway (west, where the Grunts/Brute roam, the
broken ride sits, and the relocated hiding spot lives), with a small
**backstage alcove** (north) sealed off by a velvet **`BackstageGate`** — a
curtain/rope barrier that graduated from a **purely cosmetic guard-sprite
recolor** to a **literal `StaticBody2D` collider**, the FIFTH
cosmetic-to-collider upgrade of this rollout (after Iron & Strings'
barbell, Recording Studio's booth door, Harbor & Docks' container, and
Library & Archive's librarian's desk — unmistakably an established move
now). Erin talks the guard down right at the curtain itself
(`BACKSTAGE_POS` coincides with the gate's position) — one Special press
both solves "Erin talks her way into the restricted backstage" (this
location's own spec line) AND physically raises the barrier
(`_raise_curtain`, the same one-action-two-payoffs shape as the Recording
Studio's console/door and the Library's desk/passage). Its clear-animation
is a FIFTH distinct flavor — a parallel upward slide + vertical
scale-to-near-zero via `create_tween()` (`BACKSTAGE_GATE_RISE_OFFSET`/
`_SCALE_TARGET`), reading as a stage curtain hoisted into the rigging —
distinct from the gym's horizontal slide, the studio's vertical slide, the
docks' hoist-and-swing, and the library's scale-down+fade. A small portrait
sprite (`_doug_poster`, always present, naturally hidden behind the opaque
curtain until it rises) makes the clear message's "backstage, a poster
shows Uncle Doug's face" line a literal reveal — the same "prop sits behind
the door the whole time" trick as the Recording Studio's `_ethan_prop`.
`Camera2D` follows the active character within a `24,24`–`936,536`
bounding box; `level_progress` persists `enemies_cleared`/`ride_repaired`/
`backstage_talked` so a re-entered midway skips respawning a cleared floor
and restores both the ride's repaired palette and the curtain's
raised-and-flattened state instantly. Verified via 31 functional checks
(camera tracking + bounds, standalone doorway arm/trigger, curtain
collider-disable + rise-tween + persistence, ride-repair + persistence,
enemies-cleared persistence, full re-entry restoration) plus GUT 16/16 —
no regressions. `_build_walls()`/`_build_floor()` needed zero script
changes — 8 wall nodes (+ the separately-textured BackstageGate body) and
`FLOOR_COLS`/`FLOOR_ROWS` bumped to 30×17.

---

## 9. The Underground Tunnels

**Implementation note:** The entering duo is **Evan + Ethan** — the
brute-force/hacking pairing is what the prototype's puzzle gates need (rubble
vs. hatch); Erin's stealth is treated as narrative flavor for this pass. Clear
the patrol enemies, then have Evan approach the rubble and press **Special
(G)** in range to clear it (the standard proximity-gate). Ethan's hatch is the
prototype's first **multi-step effort** gate: a row of `HATCH_PRESSES_REQUIRED`
(3) progress pips renders above the hatch via `_draw()`/`queue_redraw()`, and
each in-range **Special** press fills one pip (with a brief white flash +
`"hit"` SFX) — only the third completes the hack (green sprite + `"special"`
SFX). Models "the lock takes several hacking passes to crack" rather than a
single instant press. Both conditions (enemies cleared + rubble cleared +
hatch hacked) gate completion of `"underground"`. See CLAUDE.md's
"Puzzle-gate variety" note. **Twinkle's bark distraction is also implemented
here** — Evan's Special, used away from the rubble, summons her
(`_summon_twinkle()`, cooldown-gated): she trots out and barks, emitting a
noise burst (`GameManager.emit_noise`) that lures patrolling/investigating
guards toward her racket — the natural home for her "rile up a crowd for
cover" ability given this location's stealth-maze framing. See CLAUDE.md's
"Stealth & awareness" section for the full mechanic.

**Implementation note — ninth Doorway/camera-follow/multi-room rollout, and
the prototype's first literal "branching maze" layout** (the natural fit
this status section pre-named back at the Pipe Organ Works prototype): the
single 640×360 room became a **Y/T-shaped tunnel network** — a south
**entry corridor** (`Doorway` + Evan/Ethan spawn) opens onto a central
**junction chamber** (the hiding spot and a patrolling Grunt sit at this
crossroads — the one spot every patrol must pass through, so ducking in
here to let one go by is meaningful regardless of which fork the duo is
headed toward), which forks into a **west tunnel** dead-ending at Evan's
rubble and an **east tunnel** dead-ending at Ethan's hatch — structurally
novel geometry (16 hand-placed wall segments forming corridor/junction/
fork gaps) rather than a reused footprint, distinct from the
Harbor & Docks/Carnival "same shape, different theme" approach. `Camera2D`
follows the active character within an unusually tall-topped
`24,184`–`936,536` bounding box — `CAMERA_LIMIT_TOP = 184` (vs. the
standard locations' `24`) because the maze's northernmost wall (the
junction chamber's roof) sits well below the room's nominal top, with no
content above it for the camera to show. **`level_progress` now persists
partial multi-step-gate progress, not just the final pass/fail** — a new
sub-pattern this location introduces: every pip increment on Ethan's
hatch calls `GameManager.set_level_flag(LOCATION_ID, "hatch_progress",
_hatch_progress)`, so a player who's landed 1–2 of the 3 required hacking
passes before walking out through the Doorway doesn't lose that progress —
`_restore_progress()` reads `hatch_progress` back as an int (default `0`)
and the `_draw()` pip row renders exactly where they left off. Twinkle's
bark distraction and the existing pip-rendering code carried over verbatim
— only their trigger positions moved to fit the new branching layout (west
tunnel Grunt, east tunnel Runner, junction Grunt). Verified via 31
functional checks (camera bounds + tracking across both forks and an
active-player swap, standalone doorway arm/trigger, rubble proximity-gate +
persistence, hatch multi-step gate including **partial-progress
persistence** specifically — enter, press Special twice, confirm
`hatch_progress == 2` survives a full destroy-and-reinstantiate re-entry —
enemies-cleared persistence, full re-entry restoration) plus GUT 16/16 — no
regressions. `_build_walls()`/`_build_floor()` needed zero script changes —
16 wall nodes (the most of any location yet, reflecting the maze's
branching structure) and `FLOOR_COLS`/`FLOOR_ROWS` stayed at the shared
30×17 (the bounding box's footprint matches Harbor & Docks/Carnival's
despite the very different interior layout).

---

## 10. Zip Line Park

**Implementation note:** The entering duo is **Ethan + Ben** — hacking the
control panel and rhythm-timing the line release are the two puzzle gates the
prototype implements; Evan's animal-retrieval angle is treated as narrative
flavor here. Clear the floor of Grunt/Runners, then have Ethan approach the
panel and press **Special (G)** in range to hack it (the standard
proximity-gate). Ben's release gate is the prototype's first **timing-based**
gate: a pulsing ring (`_draw()`/`queue_redraw()`, radius animates over a
`PULSE_PERIOD` cycle) telegraphs a recurring "release window" — pressing
**Special** while the ring is in its final `PULSE_GOOD_WINDOW` seconds (it
glows green) succeeds; pressing early/late flashes the ring red, plays a
miss SFX, and imposes a short `MISS_LOCKOUT` before the next attempt. Both
conditions (enemies cleared + panel hacked + release timed) gate completion
of `"zip_line"`. This earns the location's "rhythm cues the timing of zip
line releases" spec line literally, instead of the flat distance-check the
other proximity gates use — see CLAUDE.md's "Puzzle-gate variety" note.

**Implementation note — tenth Doorway/camera-follow/multi-room rollout**
(see CLAUDE.md "Doorways, camera-follow & multi-room levels"): the single
640×360 room became a literal **chain of three platforms linked by
zip-line crossings** — directly literalizing "lines connect platforms at
different heights" — a low **Landing platform** (south-west, `Doorway` +
spawn, the patrol and hiding spot's home turf), a taller **Mid Platform**
(center, Ethan's control panel — its north wall extends further up the
screen than Landing's), and the tallest **High Platform** (north-east,
Ben's release mechanism, where the timing-ring puzzle plays out), each
successive platform's north wall reaching higher than the last — a
literal "staircase" silhouette that reads as ascension even in a top-down
2D frame. Two narrow **Bridge** corridors (the zip-line crossings
themselves) connect them through a shared opening band, so the duo
visibly threads from platform to platform rather than teleporting between
arenas. `Camera2D` follows the active character within a `24,164`–
`936,536` bounding box — `CAMERA_LIMIT_TOP = 164` derives from the High
Platform's north wall, the tallest structure and thus the binding
constraint (a different value from, but the same derivation logic as,
Library & Archive's `144` and Underground Tunnels' `184`).
`level_progress` persists `enemies_cleared`/`panel_hacked`/
`release_timed` so a re-entered park skips respawning a cleared floor and
restores both props' solved-state palettes — the timing-ring simply stops
drawing once `_release_timed` is true, exactly as it does mid-session.
Verified via 27 functional checks (camera bounds + tracking across
platforms + an active-player swap, standalone doorway arm/trigger, panel
proximity-gate + persistence, the timing-gate's good-window press +
persistence — driven by directly setting `_pulse_timer` into its scoring
band so the check isn't a frame-timing race, enemies-cleared persistence,
full re-entry restoration) plus GUT 16/16 — no regressions.
`_build_walls()`/`_build_floor()` needed zero script changes — 20 wall
nodes (the most of any location yet, reflecting the three-platform/
two-bridge chain) and `FLOOR_COLS`/`FLOOR_ROWS` stayed at the shared
30×17.

---

## 11. VR Escape Room

**Implementation note:** Entering duo is **Quinn + Ethan** (matches "primary"
characters in the spec — no unlock-chain conflict, both already unlocked).
Clear the corrupted enemies, then have Quinn approach the physics glitch and
Ethan approach the system console, each pressing **Special (G)** in range.
Both conditions (enemies cleared + glitch repaired + system hacked) gate
completion of `"vr_room"`.

**Implementation note — eleventh Doorway/camera-follow/multi-room rollout,
and the prototype's first literal "themed corrupted-stage zones" layout**
(see CLAUDE.md "Doorways, camera-follow & multi-room levels" — the status
section pre-named this fit back at the Zip Line Park rollout): the single
640×360 room became a **Boot Chamber → Stage Alpha ("medieval" glitch) →
Stage Beta ("underwater" glitch)** layout — a neutral cyber-blue entry room
(`Doorway` + spawn) connects east via Corridor1 into a warm
stone-and-amber **Stage Alpha** (Quinn's physics-glitch repair — a corrupted
castle-gate prop), then north via Corridor2 into a teal-and-aqua
**Stage Beta** (Ethan's system console — a corrupted control panel). This
location's CLAUDE.md spec line — "Each stage can have a distinct visual
theme... without breaking the overall aesthetic" — is made *structurally*
true, not just prop-deep: `_build_floor()` paints the usual base
cyber-blue `TileMap` for the Boot Chamber and corridors, then layers two
more `TileMap`s on top via a new `_paint_stage_floor(name, base, accent,
col_range, row_range)` helper — each its own `PlaceholderArt
.make_level_tileset` palette, painted only over that stage's cell footprint
(computed via `floor`/`ceil` of its interior bounds ÷ 32, e.g. Stage Alpha =
cols 13–21 / rows 6–16) and simply added as a sibling after the base map
(no `move_child` needed — later-added siblings draw on top). Crossing a
corridor threshold visibly recolors the floor underfoot — the simulation's
"stage" boundary is a literal palette seam the player walks across, not a
flavor-text label. `Camera2D` follows the active character within a
`24,24`–`776,536` bounding box (smaller than the shared 936×536 — the most
compact rollout layout yet, since three modest zones plus two short
corridors didn't need more room); `level_progress` persists
`enemies_cleared`/`glitch_repaired`/`system_hacked` so a re-entered
simulation skips respawning a cleared floor and restores both stage props'
solved-state palettes. Verified via 31 functional checks (camera tracking
across all three zones + post-swap, standalone doorway arm/trigger, both
Special-gate puzzles + persistence + re-press no-op, enemies-cleared
persistence, full re-entry restoration including both overlay palettes)
plus GUT 16/16 — no regressions. `_build_walls()` needed zero script
changes — 20 wall segments (the Boot-Chamber/Corridor1/Stage-Alpha/
Corridor2/Stage-Beta chain) and `FLOOR_COLS`/`FLOOR_ROWS` bumped to 25×17.

---

## 12. The Drop

**Implementation note:** The entering duo is **Evan + Ethan** — their
abilities (strength + hacking) are the two puzzle gates the prototype
implements as a single combined "landing site" room; Erin's fast-talk with
the ground crew is folded into the level's narrative framing/hint text rather
than a third playable gate (engine supports a two-character active duo). Clear
the ground crew, then have Ethan approach the jammed chute release and Evan
approach the wreckage blocking the landing site, each pressing **Special (G)**
in range. All three conditions (ground crew cleared + chute hacked + landing
cleared) gate completion of `"the_drop"`. **William & Mary are also
implemented here** — Evan's Special, used away from the wreckage,
alternatively calls in the rabbit pair (`_summon_scout_pair()`,
cooldown-gated): they scurry to flanking gaps either side of the wreck and
brace it from both sides; only holding both points at once frees the site
(`_check_scout_pair_holding()`) — a second, animal-handling route to the
same `_landing_cleared` outcome his strength solves directly. See CLAUDE.md's
animal companion roster for the full mechanic.

**Implementation note — twelfth Doorway/camera-follow/multi-room rollout,
and the prototype's first literal "two-phase descent" layout** (see
CLAUDE.md "Doorways, camera-follow & multi-room levels" — the status
section pre-named this fit several rollouts back): the single 640×360
room became a **Touchdown Clearing → Corridor → Snag Grove** chain that
makes the spec's "the landing zone is locked until the right character
steers to it" a literal chokepoint rather than a flavor line — the
wreckage (`LANDING_POS`) sits squarely at the clearing's only exit north,
physically gating the narrow Corridor that leads to the Snag Grove where
Ethan's jammed chute release (`CHUTE_POS`) hangs tangled in branches.
Clearing it (directly, or via William & Mary bracing both flanks) is what
*opens the path forward* — "a marquee in the distance" only becomes
reachable once the chokepoint yields, nailing the spec's "locked until
cleared" line structurally. `Doorway` + spawn sit in the Touchdown
Clearing (where the duo "touches down"); `Camera2D` follows the active
character within a `24,24`–`576,536` bounding box (the second-most compact
yet, after VR Escape Room's `776`-wide one — three modest zones, no need
for the shared 936-wide footprint). `level_progress` persists
`enemies_cleared`/`chute_hacked`/`landing_cleared` — standard
final-boolean persistence; the transient William & Mary scout pair is
deliberately NOT persisted (only the `landing_cleared` outcome they
produce survives a re-entry, matching how Underground Tunnels' Twinkle
and Harbor & Docks' Calvin & Coolidge are likewise mid-session-only aids).
Verified via 34 functional checks (camera tracking across all three zones
+ after a mid-level swap, standalone doorway arm/trigger, the direct
landing-clear route + persistence + "scout pair NOT summoned" guard, the
chute hack + persistence, enemies-cleared persistence, full re-entry
restoration of both prop palettes, AND a dedicated William-&-Mary
alternate-route check — summon away from the wreck, drive both companions
to their flanking points, confirm `_landing_cleared` flips only once BOTH
report `is_holding`) plus GUT 16/16 — no regressions. `_build_walls()`
needed zero script changes — 12 wall segments and `FLOOR_COLS`/
`FLOOR_ROWS` bumped to 18×17.

---

## 13. The Grand Marquee Cinema

**Implementation note:** The entering duo is **Quinn + Ben** — mirrors the
Clocktower's Boss-fight pairing (both already unlocked, no chain conflict);
Quinn's mechanical-repair and Ben's musical/Perfect-Pitch abilities are the
prototype's two puzzle gates, while Erin/Evan/Ethan's contributions (talking
past the manager, lobby/animal work, hacking security) are folded into
narrative framing for this pass. Defeat the Boss and its Grunts, then have
Quinn approach the projection booth and Ben approach the house organ, each
pressing **Special (G)** in range. All three conditions (boss/enemies cleared
+ projector repaired + organ played) gate completion of `"grand_marquee"` —
the game's endgame trigger, with Uncle Doug found in the projection booth.

**Implementation note — thirteenth and FINAL Doorway/camera-follow/
multi-room rollout** (see CLAUDE.md "Doorways, camera-follow & multi-room
levels" — this closes out the entire 13-location rollout): the single
640×360 theater became a literal **hub-and-wings** layout matching this
location's spec line naming its zones outright — "Backstage, projection
booth, balcony, and lobby are distinct zones." A **Lobby** (south — `Doorway`
+ spawn, the duo's arrival point) opens north into the **Backstage** — the
central combat hub where the cinema's guardian Boss "holds the aisle" across
the only path forward — which in turn branches west into the **Projection
Booth** (Quinn's repair) and north up into the **Balcony** (Ben's house
organ, literally elevated above the stage it overlooks, playing out the
spec's "manipulates the crowd" framing from on high). All three zone
connections are open passages — gaps in shared walls — so the hub-and-spoke
shape mirrors how the spec singles out Backstage as the throughline the
other three zones branch from. `Camera2D` follows the active character
within a `24,24`–`616,536` bounding box; `level_progress` persists
`enemies_cleared`/`projector_repaired`/`organ_played` so a re-entered
cinema skips respawning a cleared floor and restores both solved-prop
palettes. **Unique among all 13 locations**: as the literal endgame, a
*cleared* Doorway-exit can't sensibly lead back to the overworld — Uncle
Doug has just been found — so `_exit_to_overworld()` branches on `_cleared`:
cleared routes to the same `ResultScreen.tscn` the clear-overlay's "press
ENTER" already triggers (via the idempotent `complete_location`, so it never
double-grants), while an early/uncleared exit returns to the overworld
exactly like every other location's Doorway. Verified via 41 functional
checks (camera tracking + bounds + swap-retarget, both Special-gate puzzles
+ persistence + idempotency, Boss/enemies-cleared + finale-trigger, standalone
doorway arm/trigger, full re-entry restoration) plus GUT 16/16 —no
regressions. `_build_walls()`/`_build_floor()` needed zero script changes —
12 wall nodes and `FLOOR_COLS`/`FLOOR_ROWS` bumped to 20×17.
**This is the 13th and final location — the entire Doorway/camera-follow/
multi-room rollout across all 13 locations is now COMPLETE.**
