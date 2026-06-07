# CLAUDE.md — Hunkle Bunkle

Project guidance for Claude Code. Auto-loaded as context. Keep it up to date as
the project evolves.

---

## Project overview

**Hunkle Bunkle** is a retro-style, 16-bit, top-down adventure brawler built in
**Godot 4.x with GDScript**. It combines environmental puzzle-solving with
arcade-style beat-em-up combat across 10+ distinct locations.

**Goal:** Find and rescue "Uncle Doug". Players navigate an overworld map,
unlock new locations and characters by solving puzzles and defeating enemies.

**Core loop:** Explore a location → solve environmental puzzles → brawl/evade
enemies → unlock next location or character → repeat.

---

## Characters

Characters are unlocked in order: **Quinn → Erin → Evan → Ben → Ethan**.

Players always control an **active duo**: one character is active and one is on
standby. Press the swap button to switch instantly during play.

| Character | Strengths | Weapon / Tool | Special Ability |
|-----------|-----------|---------------|-----------------|
| Quinn | Mechanical repair, speaks German, British accent | Wrench / tools | **HA** — a booming laugh that stuns nearby enemies |
| Erin | Stealth, debating/fast-talking out of trouble | Fire | **Fast Talk** — talk/bluff way past guards or enemies |
| Evan | Super strength, works with animals | Fists / animals | Commands animals to assist in combat or puzzles |
| Ben | Bard, rhythm-based attacks, perfect pitch | Keytar | Musical AoE that affects enemy behavior; **Perfect Pitch** — identifies exact tones to solve sound-based puzzles |
| Ethan | Technology, hacking | Tech gadgets | Hack panels, doors, and electronic enemies |

### Evan's Animals

Evan can call on animal companions to assist in combat and puzzles. Each animal
has a distinct role; more can be added as the game expands.

| Animal | Breed / Type | Appearance / Traits | Role |
|--------|-------------|---------------------|------|
| Frosty | Schnoodle (Schnauzer/Poodle mix) | White fur | **Combat distractor** — charges the nearest enemy, headbutts it to interrupt a windup/stagger it, then returns to Evan's side. The general-purpose companion; appears wherever Evan needs backup mid-brawl. |
| Twinkle | Pomeranian | Small, blind, snaggle tooth, annoying bark | **Sound-puzzle aggravator** — her bark is loud and grating enough to startle guards into revealing a hiding spot, rile up a crowd for cover, or — in a pinch — be aimed at an enemy to break its focus (same stagger effect as Frosty, shorter range, more annoying). |
| William | Rabbit | Quick, burrows | **Puzzle scout** — squeezes through gaps and grates too small for the duo, fetching items or triggering switches in hard-to-reach alcoves (mirrors Quinn's "gather parts" cross-dependency from the Pipe Organ Works). |
| Mary | Rabbit | Calm, good listener | **Puzzle scout** (paired with William) — where one rabbit can pull a lever, the other can hold a counterweight; together they solve two-point puzzles a single companion can't. |
| Calvin | Great Pyrenees | Large, white | **Heavy combat charger** — slams into an enemy with more force/knockback than Frosty; built for bruiser-type fights. *(Implemented — see `harbor_docks.gd`: Evan's Special summons Calvin to charge and stagger the nearest foe when used away from a puzzle prop.)* |
| Coolidge | Great Pyrenees | Large, white | **Heavy puzzle mover** — Calvin's brother; pairs with Evan's strength to drag or brace especially massive objects (crates, gates) that even Evan alone can't budge — the "hard-to-reach areas" muscle referenced at the Harbor & Docks. |
| *(unnamed)* | Guinea pigs | Small, numerous, skittish | **Crowd cover** — a scurrying group that can flood a floor, drawing every eye in the room and giving the duo a window to slip past or flank — Erin's stealth sections are the natural pairing. |
| *(unnamed)* | Lizard | Cold-blooded, climbs | **Vertical-traversal scout** — scales walls/pipes the duo can't reach to flip a switch or drop a rope/ladder down to them; a climbing counterpart to William/Mary's burrowing. |

**Combat-assist implementation pattern** *(established via Calvin at Harbor & Docks)*:
`scripts/systems/animal_companion.gd` is a small reusable `Node2D` (no `class_name`
— wired via `preload()` + untyped `var` per the class_name-resolution gotcha) with
a three-phase `CHARGE → STRIKE → RETURN` state machine. On `STRIKE` it toggles
`monitoring` on a runtime-built `Hitbox` (same `collision_layer/mask` as the
player's melee `Hitbox` — `8`/`64` — so it overlaps `Enemy` `Hurtbox`es and rides
the existing damage/knockback/`State.HIT`-stagger pipeline for free, no parallel
damage path). A level wires it up by listening for `special_used` on the
companion-summoning character and, when their Special is used away from any
puzzle-prop range, finding the nearest living `Enemy` and calling
`AnimalCompanionScript.new(); .setup(summoner, target, color); add_child(...)`,
gated by a short per-companion cooldown so it can't be spammed every frame.

> Add new animals here as they are designed. Note their combat use, puzzle use,
> and which locations they appear in.

### Puzzle cross-dependencies (examples)
- Quinn repairs a broken clock → requires parts that Evan's animal companions
  gathered from hard-to-reach spots.
- Ethan hacks a locked panel → but only if Erin already distracted the guard.
- Design new puzzles to require the *specific* abilities of the active duo so
  character swapping is meaningful, not optional.

---

## Bies Mode

**Bies Mode** is a temporary **bullet-time / slowdown** power that lets players
sense and react to incoming danger. Time slows briefly, giving the player a
window to dodge, counter, or spot hidden threats. Triggered by a dedicated
input; governed by a cooldown or charge meter.

---

## Player count

**Primarily single-player** with **optional local co-op**. In co-op, Player 2
controls the standby character. In single-player, the AI (or idle state) handles
the standby character. Both modes share the same scenes and input map.

---

## Prototype

**Scope:** Levels 1 and 2 (Pipe Organ Works + Old Parish Church), Quinn + Erin
playable with the swap mechanic, free/CC pixel art assets.

### Pixel grid
- **Tile size:** 32×32 px
- **Character sprite:** 32×32 px (matches tile size — full tile-grid alignment)
- **Viewport:** 1280×720 (scale up with integer scaling in project settings)

### Character stats *(starting values — tune via exported vars)*

| Stat | Quinn | Erin | Evan |
|------|-------|------|------|
| Max HP | 120 | 90 | 150 |
| Move speed (px/s) | 140 | 180 | 120 |
| Attack damage | 20 | 15 | 28 |
| Attack cooldown (s) | 0.5 | 0.35 | 0.65 |
| Dash distance (px) | 120 | 160 | 100 |
| Dash i-frame duration (s) | 0.15 | 0.2 | 0.12 |

Quinn is tankier and hits harder than Erin; Erin is faster and attacks more
often; Evan is the slowest but hits hardest and has the most HP — built around
brute force.

### Enemy stats *(starting values — tune via exported vars)*

| Stat | Grunt | Runner | Brute | Sentry | Boss |
|------|-------|--------|-------|--------|------|
| Max HP | 60 | 30 | 110 | 45 | 400 |
| Move speed (px/s) | 80 | 170 | 65 | 50 | 55 |
| Attack damage | 12 | 8 | 18 | 14 | 22 |
| Attack range (px) | 40 | 30 | 46 | 220 | 50 |
| Windup duration (s) | 0.6 | 0.3 | 0.8 | 0.5 | 0.7 |
| AoE slam damage / radius (px) | — | — | — | — | 26 / 110 |
| AoE slam telegraph / cooldown (s) | — | — | — | — | 1.1 / 4.0 |
| Projectile speed (px/s) | — | — | — | 260 | — |

**Grunt:** walks toward the player, melee attack with a visible windup.
**Runner:** dashes in fast, low health, easy to one-shot but hard to hit.
**Brute:** slow, telegraphs a long windup, but hits hard and soaks damage —
the bruiser-type enemy for Iron & Strings Gym.
**Sentry** (`data/enemies/sentry.tres`, `is_ranged = true`): holds at long
`attack_range` and fires a `Projectile` (`scripts/systems/projectile.gd`,
`extends Hitbox`) instead of opening a melee `Hitbox` — same telegraphed
chase → windup → strike FSM, just a ranged payload. Adds enemy variety to
The Library & Archive and The VR Escape Room.
**Boss** (`data/enemies/boss.tres`, `is_boss = true`): adds an `AOE_TELEGRAPH` →
`AOE_SLAM` pair of states to the Enemy FSM. On a cooldown, it stops chasing,
draws an expanding warning ring via `_draw()`/`queue_redraw()` (the required
"visible wind-up ring/indicator" per the guardrails) for `slam_telegraph_duration`
seconds, then spawns a runtime `Hitbox` with a `CircleShape2D` centered on itself
that damages/knocks back anything in `slam_radius` for one active window before
returning to its normal chase/melee loop. The clockwork guardian in The Clocktower
and the climactic guardian of The Grand Marquee Cinema.

### Bies Mode
- **Charges** as the active character deals damage — 10% charge per hit landed
- **Activates** at 100% charge via the `bies_mode` input
- **Effect:** `Engine.time_scale = 0.4` for 5 seconds, then snaps back to 1.0
- **HUD:** charge bar always visible; pulses when full

### Standby character
- Holds position when not active — no AI, no auto-attack
- Teleports to the active character's side if the active character moves more than
  300 px away (prevents the standby getting permanently stuck off-screen)
- Swap has no cooldown in the prototype; add one later if it feels exploitable

### Prototype "done" checklist *(completed 2026-06-06)*
- [x] Quinn and Erin move, attack, dash, and swap
- [x] Grunt and Runner spawn, chase, telegraph, and attack
- [x] Health bars visible and functional for both characters
- [x] Bies Mode fills, activates, and times out correctly
- [x] Pipe Organ Works: at least one completable room with enemies
- [x] Old Parish Church: at least one room requiring both Quinn and Erin's dialogue approaches
- [x] No script/parse errors on boot

### Also implemented (beyond original checklist)
- [x] Combat polish: screen shake (`CombatFX` autoload), hit sparks (`CPUParticles2D`), hit flash (overbright modulate tween), hit-stop (`set_physics_process` pause, real-time timer)
- [x] Title screen (`scenes/ui/TitleScreen.tscn`) — programmatic UI, blink animation, transitions to OverworldMap
- [x] Overworld map (`scenes/overworld/OverworldMap.tscn`) — all 13 locations drawn via `Node2D._draw()`, unlock chain, cursor navigation, info panel
- [x] Full game flow: TitleScreen → OverworldMap → Level → (on clear) → OverworldMap
- [x] Save/unlock persistence (`SaveManager` autoload, `ConfigFile`) — survives relaunch
- [x] Procedural audio (`Audio` autoload) — SFX synthesized at runtime, no imported sound files
- [x] Ben and Ethan playable (`data/characters/{ben,ethan}.tres`); all five characters built
- [x] Levels 3 and 4 implemented: Iron & Strings Gym (Quinn+Evan) and The Recording Studio (Quinn+Ben)
- [x] Boss enemy with telegraphed AoE slam (`AOE_TELEGRAPH` → `AOE_SLAM` FSM states, warning-ring `_draw()`)
- [x] Mid-game location: The Clocktower (Quinn+Ben, gear-repair + bell-sequence puzzle, Boss fight)
- [x] Mid-game location: The Harbor & Docks (Quinn+Evan, dock-worker/smuggler combat + cargo-container strength puzzle)
- [x] Sentry enemy — ranged attacker (`is_ranged`/`projectile_speed` on `EnemyData`, `Projectile` class `extends Hitbox`, fired from `Enemy._fire_projectile()`); reuses the Hitbox/Hurtbox damage pipeline for a non-melee attack type
- [x] Mid-game location: The Library & Archive (Erin+Ethan, stealth/hacking, Grunt+Sentry)
- [x] Mid-game location: The Carnival & Fairground (Quinn+Erin, ride-repair + backstage talk-down, Grunt×2+Brute)
- [x] Mid-game location: The Underground Tunnels (Evan+Ethan, rubble-clearing + hatch-hacking, Grunt×2+Runner)
- [x] Mid-game location: Zip Line Park (Ethan+Ben, panel-hacking + rhythm-timed release, Grunt+Runner×2)
- [x] Mid-game location: The VR Escape Room (Quinn+Ethan, glitch-repair + system-hacking, Grunt×2+Sentry)
- [x] Late-game location: The Drop (Evan+Ethan, aerial-descent framing → ground brawl, chute-hack + landing-clear, Grunt+Runner+Brute)
- [x] Endgame location: The Grand Marquee Cinema (Quinn+Ben, projector-repair + house-organ puzzle, second Boss fight, Grunt×2+Boss)
- [x] DuoPanel swap-preview UI (`scripts/ui/duo_panel.gd`, child of `HUD.tscn`) — always-visible programmatic `_draw()` panel showing both duo members' name/color-swatch/special ability with an active-member highlight that pulses on `GameManager.characters_swapped`

---

## Locations

10+ locations on the overworld map. The first four locations each introduce one
new character. After all characters are unlocked, mid-game and late-game
locations open up.

**Unlock order summary:**

| # | Location | Characters available | Unlocks |
|---|----------|---------------------|---------|
| 1 | Bellows & Sons Pipe Organ Works | Quinn | Erin |
| 2 | The Old Parish Church | Quinn, Erin | Evan |
| 3 | Iron & Strings Gym | Quinn, Erin, Evan | Ben |
| 4 | The Recording Studio | Quinn, Erin, Evan, Ben | Ethan |
| 5–11 | Mid-game locations | All five | — |
| 12 | The Drop | All five | — |
| 13 | The Grand Marquee Cinema | All five | Endgame |

> **Status: All 13 locations have a prototype-implemented scene** (see each
> entry's "prototype implemented" tag and implementation note for the entering
> duo, puzzle gates, and enemy mix actually shipped).

> **Puzzle-gate variety:** Most locations use the baseline **proximity gate**
> (`character.global_position.distance_to(PROP_POS) < RADIUS`, then press
> **Special**, instant success). Two locations diversify this template with a
> mechanic that matches their narrative spec more literally:
> - **Zip Line Park** (`zip_line_park.gd`) — Ben's release is a **timing gate**:
>   a pulsing `_draw()` ring telegraphs a recurring window; pressing Special
>   inside the final `PULSE_GOOD_WINDOW` succeeds, missing flashes red and
>   imposes a short `MISS_LOCKOUT` before retrying. Earns "rhythm cues the
>   timing of zip line releases" literally instead of flatly.
> - **Underground Tunnels** (`underground_tunnels.gd`) — Ethan's hatch is a
>   **multi-step effort gate**: `HATCH_PRESSES_REQUIRED` (3) progress pips
>   render above the prop; each in-range Special press fills one (flash + SFX),
>   only the last completes the hack. Models "the lock takes several passes to
>   crack" rather than one instant press.
>
> Both reuse the established `_draw()`/`queue_redraw()` programmatic-rendering
> pattern (no new assets) and the existing `special_used` signal wiring — no
> new input actions or systems were needed. Keep the baseline proximity gate as
> the default for new locations; reach for a timing or multi-step variant only
> when a location's spec calls for that flavor specifically (forcing variety
> everywhere would make the simple gates feel arbitrary by comparison).

---

### 1. Bellows & Sons Pipe Organ Works
- **Unlock condition:** Available from the start — Quinn's opening location
- **Unlocks:** Erin (found or rescued here)
- **Key puzzle(s):** Quinn repairs a massive broken pipe organ using scattered parts throughout the workshop; bellows, pipes, and mechanical components strewn across the factory floor
- **Enemy types:** TBD
- **Characters required:** Quinn
- **Notes:** Introduces Quinn's mechanical repair as the core mechanic. Conveyor belts, pneumatic lifts, and pipe racks double as traversal and combat obstacles. A repaired organ could trigger a door, reveal a passage, or defeat a boss.
- **Implementation note — first level with a tile-mapped floor:** `pipe_organ_works.gd._build_floor()` was the **prototype** for the project's
  new tile-mapped retro look (replacing the previous walls-on-a-void look —
  see "Tile-mapped floors" below), since rolled out to all 12 other levels.

---

### 2. The Old Parish Church
- **Unlock condition:** Complete Bellows & Sons
- **Unlocks:** Evan (found here)
- **Key puzzle(s):** Quinn's respectful demeanor earns the congregation's trust (unlocks doors, gets information); Erin's skepticism lets her see through deception and argue past gatekeepers — both attitudes are required
- **Enemy types:** TBD
- **Characters required:** Quinn and Erin
- **Notes:** Quinn speaks quietly, removes his hat; Erin debates and calls out manipulation. Neither can solve it alone. Dialogue-heavy puzzle sequences. May contain a pipe organ echoing the starting location.

---

### 3. Iron & Strings Gym *(prototype implemented — `IronStringsGym.tscn`)*
- **Unlock condition:** Complete The Old Parish Church
- **Unlocks:** Ben (found or performing here)
- **Key puzzle(s):** Evan's super strength moves heavy equipment to open paths and trigger mechanisms. Ben's keytar motivates NPCs, times rhythm obstacles, and calms an agitated crowd
- **Enemy types:** Bruiser-type enemies (Grunts + Brutes)
- **Characters required:** Evan and Ben
- **Notes:** Good location for introducing Evan's strength-based traversal. Ben's bard angle shines in a crowd/audience dynamic — maybe a grudge match Ben narrates while Evan fights.
- **Implementation note:** The entering duo is **Quinn + Evan** — at this point in
  the unlock chain only Quinn, Erin, and Evan are available (Ben is unlocked BY
  clearing this location, so he can't be in the entering duo; this resolves an
  apparent tension in the original spec between "Characters required: Evan and
  Ben" and "Unlocks: Ben"). Clear the floor of Grunts and a Brute, then have Evan
  approach the barbell blocking Ben's cage and press **Special (G)** — his
  strength clears it and frees Ben. Both conditions (enemies cleared + barbell
  moved) must be met to complete the level.

---

### 4. The Recording Studio *(prototype implemented — `RecordingStudio.tscn`)*
- **Unlock condition:** Complete Iron & Strings Gym
- **Unlocks:** Ethan (found here, trying to fix the equipment)
- **Key puzzle(s):** Someone has scrambled the studio. Ben navigates the soundboard and performs to trigger doors and mechanisms; Ethan repairs and hacks the digital gear. Rhythm-based puzzle element tied to Ben's keytar
- **Enemy types:** Grunts + Runners
- **Characters required:** Ben and Ethan
- **Notes:** Ben's home turf; his musical ability is the primary tool here. May hold a recording that is a clue about Uncle Doug.
- **Implementation note:** The entering duo is **Quinn + Ben** — same
  unlock-chain rule as Iron & Strings Gym applies (Ethan is unlocked BY clearing
  this location, so he can't be in the entering duo; Ben is available because he
  was freed at the Gym). Clear the floor of Grunts and Runners, then have Ben
  approach the soundboard console and press **Special (G)** — his ear tunes it
  by Perfect Pitch and frees Ethan. Both conditions (enemies cleared + console
  tuned) must be met to complete the level.

---

### 5. The Clocktower *(prototype implemented — `Clocktower.tscn`)*
- **Unlock condition:** All five characters unlocked
- **Key puzzle(s):** The tower is one multi-floor mechanical puzzle — gears, pendulums, counterweights, escapements. Quinn repairs each floor's mechanism to ascend. On certain floors, the mechanism is locked behind a sound-based puzzle: the bells or chimes must be struck in the exact right pitch sequence, which only Ben's Perfect Pitch ability can identify and play
- **Enemy types:** Grunts + a Boss ("the clockwork guardian")
- **Characters required:** Quinn and Ben
- **Notes:** Quinn handles the physical mechanics; Ben listens to the tower's bells and plays the correct tonal sequence on his keytar to unlock the next stage. Each floor can have a distinct mechanical theme. The clock face is visible on the overworld map, making it a strong landmark.
- **Implementation note:** Entering duo is **Quinn + Ben** (both already unlocked
  by this point — no unlock-chain conflict here, since Clocktower doesn't grant a
  new character). First location to feature the **Boss** enemy — defeat it, then
  Quinn approaches the gear mechanism and Ben approaches the bells, each pressing
  **Special (G)** in range. All three conditions (boss/enemies cleared + gear
  repaired + bells played) gate completion.

---

### 6. The Harbor & Docks *(prototype implemented — `HarborDocks.tscn`)*
- **Unlock condition:** All five characters unlocked (mid-game; opens alongside Clocktower)
- **Key puzzle(s):** Cranes, cargo containers, boats. Evan moves heavy freight to clear paths or trigger crane mechanisms. Calvin and Coolidge are useful in hard-to-reach areas. A suspicious shipment may be a lead on Uncle Doug
- **Enemy types:** Dock workers (Grunts), smugglers (Runners)
- **Characters required:** Evan (primary)
- **Notes:** Large open environment; cargo container maze is good brawler terrain.
- **Implementation note:** Entering duo is **Quinn + Evan** (mirrors Iron &
  Strings Gym — Evan is the puzzle-solver, Quinn the steady partner; no
  unlock-chain conflict since this is a mid-game stop). Clear the dock of Grunts
  and Runners, then have Evan approach the cargo container blocking the crane
  controls and press **Special (G)** — his strength shoves it aside. Both
  conditions (enemies cleared + container moved) gate completion.

---

### 7. The Public Library & Archive *(prototype implemented — `LibraryArchive.tscn`)*
- **Unlock condition:** TBD
- **Key puzzle(s):** Research uncovers critical intel about Uncle Doug. Erin stealth-sneaks past a strict librarian to access restricted stacks; Ethan hacks the digital archive for sealed records
- **Enemy types:** Grunts + a Sentry (ranged) — the prototype's first stealth-flavored use of the new ranged enemy
- **Characters required:** Erin and Ethan
- **Notes:** A slower, stealth-and-puzzle counterpoint to the brawler locations. Erin's fast-talk can resolve some confrontations without combat.
- **Implementation note:** Entering duo is **Erin + Ethan** (both already
  unlocked — no unlock-chain conflict). Clear the floor of Grunts and a Sentry,
  then have Erin approach the librarian and Ethan approach the terminal, each
  pressing **Special (G)** in range. Both conditions (enemies cleared + librarian
  talked down + terminal hacked) gate completion of `"library"`.

---

### 8. The Carnival & Fairground *(prototype implemented — `Carnival.tscn`)*
- **Unlock condition:** TBD
- **Key puzzle(s):** Quinn repairs broken rides to open new areas. Ben's keytar draws crowds as cover or distraction. Erin talks her way into the restricted backstage
- **Enemy types:** Carnies, strongmen — Grunts ×2 + a Brute
- **Characters required:** Quinn, Ben, and Erin
- **Notes:** Each attraction is its own zone. Fun atmosphere that shifts darker backstage.
- **Implementation note:** The entering duo is **Quinn + Erin** — Ben's musical
  draw is treated as narrative color (the crowd noise covering the team's
  approach) since the engine supports only a two-character active duo; Quinn and
  Erin's abilities directly gate the puzzle. Clear the midway of Grunts and a
  Brute, then have Quinn approach the broken ride and Erin approach the backstage
  guard, each pressing **Special (G)** in range. Both conditions (enemies cleared
  + ride repaired + guard talked past) gate completion of `"carnival"`.

---

### 9. The Underground Tunnels *(prototype implemented — `UndergroundTunnels.tscn`)*
- **Unlock condition:** TBD — mid-game; may unlock shortcuts between prior locations
- **Key puzzle(s):** Dark maze of maintenance tunnels. Erin's stealth is critical in tight corridors. Ethan hacks access hatches and junction panels. Evan forces open blocked passages
- **Enemy types:** Patrol-style enemies — Grunts ×2 + a Runner
- **Characters required:** Erin and Ethan (primary); Evan for brute-force sections
- **Notes:** Ties the overworld together. Discovering the tunnel network could open hidden routes between already-visited locations.
- **Implementation note:** The entering duo is **Evan + Ethan** — the
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
  hatch hacked) gate completion of `"underground"`. See "Puzzle-gate variety"
  below.

---

### 10. Zip Line Park *(prototype implemented — `ZipLinePark.tscn`)*
- **Unlock condition:** TBD
- **Key puzzle(s):** Navigate zip lines to reach inaccessible areas. Evan's animals retrieve stuck components; Ethan unlocks a control panel to reactivate broken lines. Ben's keytar performance draws a crowd that can be used as cover, or his rhythm cues the timing of zip line releases
- **Enemy types:** Grunt + Runners ×2
- **Characters required:** Evan, Ethan, and Ben
- **Notes:** Vertical traversal is the signature mechanic — lines connect platforms at different heights; some broken or locked.
- **Implementation note:** The entering duo is **Ethan + Ben** — hacking the
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
  other proximity gates use — see "Puzzle-gate variety" below.

---

### 11. VR Escape Room *(prototype implemented — `VrEscapeRoom.tscn`)*
- **Unlock condition:** TBD
- **Key puzzle(s):** The team is trapped in a VR simulation. Quinn repairs glitches in the VR environment (broken physics, corrupted props); Ethan hacks the underlying system to bypass stages or rewrite the rules. Other characters may assist in specific themed rooms
- **Enemy types:** Glitchy, corrupted versions of standard enemies — Grunts ×2 + a Sentry
- **Characters required:** Quinn and Ethan (primary); others assist per room
- **Notes:** Each stage can have a distinct visual theme (medieval, space, underwater, etc.) without breaking the overall aesthetic. Quinn comments on mechanical logic; Ethan sees the code underneath.
- **Implementation note:** Entering duo is **Quinn + Ethan** (matches "primary"
  characters in the spec — no unlock-chain conflict, both already unlocked).
  Clear the corrupted enemies, then have Quinn approach the physics glitch and
  Ethan approach the system console, each pressing **Special (G)** in range.
  Both conditions (enemies cleared + glitch repaired + system hacked) gate
  completion of `"vr_room"`.

---

### 12. The Drop *(aerial / parachute set piece — prototype implemented as `TheDrop.tscn`)*
- **Unlock condition:** Late-game, after a credible lead on Uncle Doug's location
- **Key puzzle(s):** The group believes Uncle Doug is below — they jump from a plane/airship and navigate the descent through mid-air obstacles and wind currents. The landing zone is locked until the right character steers to it
- **Enemy types:** Aerial pursuit during descent; ground enemies at the landing site — Grunt + Runner + Brute (the hostile ground crew)
- **Characters required:** Ethan (hacks jammed chute release), Evan (strength on impact/landing), Erin (fast-talks the hostile ground crew after landing)
- **Notes:** Two phases: a kinetic aerial descent, then a standard brawler ground phase. The intel turns out to be a step closer — but not the final answer — escalating tension toward the endgame.
- **Implementation note:** The entering duo is **Evan + Ethan** — their
  abilities (strength + hacking) are the two puzzle gates the prototype
  implements as a single combined "landing site" room; Erin's fast-talk with
  the ground crew is folded into the level's narrative framing/hint text rather
  than a third playable gate (engine supports a two-character active duo). Clear
  the ground crew, then have Ethan approach the jammed chute release and Evan
  approach the wreckage blocking the landing site, each pressing **Special (G)**
  in range. All three conditions (ground crew cleared + chute hacked + landing
  cleared) gate completion of `"the_drop"`.

---

### 13. The Grand Marquee Cinema *(endgame — prototype implemented as `GrandMarqueeCinema.tscn`)*
- **Unlock condition:** Complete The Drop; all five characters required
- **Key puzzle(s):** Quinn repairs the projection equipment; Erin talks past the manager; Evan moves lobby fixtures and aids animals; Ben plays the house organ to manipulate the crowd; Ethan hacks the security system and digital projector
- **Enemy types:** Climactic, high-stakes — Grunts ×2 + a **Boss** (the cinema's guardian)
- **Characters required:** All five
- **Notes:** Penultimate location — Uncle Doug is within reach. Backstage, projection booth, balcony, and lobby are distinct zones. A cinematic boss fight here would feel earned.
- **Implementation note:** The entering duo is **Quinn + Ben** — mirrors the
  Clocktower's Boss-fight pairing (both already unlocked, no chain conflict);
  Quinn's mechanical-repair and Ben's musical/Perfect-Pitch abilities are the
  prototype's two puzzle gates, while Erin/Evan/Ethan's contributions (talking
  past the manager, lobby/animal work, hacking security) are folded into
  narrative framing for this pass. Defeat the Boss and its Grunts, then have
  Quinn approach the projection booth and Ben approach the house organ, each
  pressing **Special (G)** in range. All three conditions (boss/enemies cleared
  + projector repaired + organ played) gate completion of `"grand_marquee"` —
  the game's endgame trigger, with Uncle Doug found in the projection booth.

---

```
Location template:
- Name:
- Unlock condition:
- Unlocks: (character, if applicable)
- Key puzzle(s):
- Enemy types:
- Characters required:
- Notes:
```

---

## Tech stack & targets

- **Engine:** Godot 4.x (confirm with `godot --version`; prefer 4.3+ APIs).
  Use GDScript 2.0 idioms.
- **Rendering:** 2D. `Node2D` + Y-sort for depth (screen-Y = depth; small `z`
  for jump height).
- **Platforms:** Desktop — Windows, macOS, Linux.

---

## Running, building, testing

```bash
# Run the project
godot --path .

# Run a single scene
godot --path . res://scenes/levels/arena.tscn

# Headless boot check (CI)
godot --headless --path . --quit-after 200

# GUT unit tests (configured — addons/gut, GUT v9.6.0; tests in tests/unit/)
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit

# Export release build (configure presets first)
godot --headless --path . --export-release "Linux/X11" build/hunkle_bunkle.x86_64
```

Always boot the game (or the relevant scene) after non-trivial changes to
confirm it loads with no script/parse errors before marking a task done.

---

## Suggested project structure

```
project.godot
CLAUDE.md
scenes/
  players/      Player.tscn, CharacterSelect.tscn
  enemies/      Grunt.tscn, Runner.tscn, Brute.tscn, Boss.tscn
  levels/       (one .tscn per location)
  overworld/    OverworldMap.tscn
  ui/           HUD.tscn, TitleScreen.tscn, ResultScreen.tscn, PauseMenu.tscn
scripts/
  players/      player.gd, character_data.gd
                states/  idle.gd walk.gd attack.gd dash.gd hurt.gd down.gd
  enemies/      enemy.gd
                states/  chase.gd windup.gd strike.gd recover.gd hit.gd
  systems/      wave_spawner.gd, combat.gd, hitbox.gd, hurtbox.gd
                bies_mode.gd, puzzle_manager.gd
  autoload/     game_manager.gd, audio.gd, save_manager.gd
data/
  characters/   quinn.tres, erin.tres, evan.tres, ben.tres, ethan.tres
  waves.tres
  enemy_stats.tres
assets/         art/, sfx/, music/, fonts/
addons/         gut/ (vendored GUT v9.6.0+ — see "GUT unit tests" below)
tests/
  unit/         test_character_data.gd, test_enemy_data.gd, test_unlock_chain.gd
```

---

## Architecture & key systems

### GameManager (autoload)
Owns global state: current location, unlocked characters, active duo, score,
game over / victory. Spawns levels and broadcasts via signals. Never let scenes
reach up into GameManager's internals — use signals.

### Player (`CharacterBody2D`)
FSM: `idle → walk → attack → dash → hurt → down/revive`.
- `move_and_slide()` for motion; vertical movement is ~0.6× horizontal speed.
- Dash grants brief i-frames.
- **Character swap**: instantly switches active ↔ standby character. Standby
  character follows or holds position (configurable).
- Character-specific stats and abilities live in a `CharacterData` Resource,
  loaded at runtime. No per-character code forks in `player.gd`.

### Enemy (`CharacterBody2D`)
FSM: `chase → windup → strike → recover`, plus `hit/knockback`.
- Windup **must telegraph** (animation + UI tell) before a strike.
- Boss adds AoE slam with a visible wind-up ring/indicator.

### Combat (Area2D)
Attacks spawn a short-lived **Hitbox** (`Area2D`) that overlaps enemy
**Hurtbox** (`Area2D`). All damage resolution in `combat.gd` via signals.
Apply: knockback, hitstun, hit-flash, particles, screen-shake, brief hit-stop.

### WaveSpawner
Reads `data/waves.tres`. Spawns from screen edges up to a max concurrent count.
Emits `wave_cleared` when queue is empty and no enemies remain.

### PuzzleManager
Tracks puzzle state per location. Emits signals when puzzle conditions are met
(e.g., `clock_repaired`, `panel_hacked`). Puzzle logic references character
abilities by type, not by character name, so new characters can plug in.

### Tile-mapped floors *(rolled out to all 13 levels)*
Levels previously rendered with **no floor/background art at all** — just
invisible `StaticBody2D` walls + characters on a transparent canvas. The new
retro/Zelda-style look replaces that with an actual `TileMap` floor, generated
and painted entirely at runtime (matches the `PlaceholderArt` no-imported-assets
pattern — keeps the original-IP guarantee). Prototyped on Pipe Organ Works,
then rolled out to the other 12 — every level now has a `_build_floor()`:
- `PlaceholderArt.make_level_tileset(base: Color, accent: Color) -> TileSet`
  draws a 64×32 px atlas (two 32×32 tiles — a plain seamed floor square and an
  accent variant with a small decorative fleck) into an `Image`, wraps it in a
  `TileSetAtlasSource` (`texture_region_size = Vector2i(32, 32)`), and packs it
  into a `TileSet` (`tile_size = Vector2i(32, 32)` — matches the pixel grid).
- A level's `_build_floor()` (see `pipe_organ_works.gd`) builds a `TileMap`,
  assigns the generated `TileSet`, `add_child`s it, then `move_child(tm, 0)` so
  it renders behind everything else (no Y-sort is enabled anywhere in the
  project, so tree order alone controls draw order). It then `set_cell()`s a
  grid covering the room, alternating the plain/accent tile on a period (e.g.
  every 4th cell) for a checkerboard-ish two-tone dungeon-floor look.
- Tunables (`FLOOR_BASE_COLOR`, `FLOOR_ACCENT_COLOR`, `FLOOR_COLS`/`ROWS`,
  `FLOOR_ACCENT_PERIOD`) are exported as level-script consts — vary the palette
  per location for visual identity (e.g. warmer tones for the Pipe Organ Works
  workshop, cooler stone tones for The Old Parish Church).

**Rollout note:** every one of the 13 level scenes shares the identical
640×360 room (camera at `(320, 180)`, `zoom = Vector2(2, 2)`, walls at the same
positions/thicknesses), so the same `FLOOR_COLS = 20` / `FLOOR_ROWS = 12` /
`FLOOR_ACCENT_PERIOD = 4` grid drops into all of them unchanged — only
`FLOOR_BASE_COLOR` / `FLOOR_ACCENT_COLOR` vary per location to give each a
distinct palette/identity (e.g. cool stone + candlelight for the Old Parish
Church, industrial grey + iron-red for Iron & Strings Gym, dark earthy tones
for the Underground Tunnels, cyber-blue + glitch-cyan for the VR Escape Room,
theater red + gold for the Grand Marquee Cinema). Tile-grid borders are NOT
aligned pixel-perfectly with the wall colliders' thickness — the floor just
needs to visually cover the playable interior; walls remain invisible colliders
(a later pass could add matching wall-tile art). If a future level uses
different room dimensions, recompute `FLOOR_COLS`/`FLOOR_ROWS` as
`room_px / 32` (rounding up) for that scene.

### Bies Mode (`bies_mode.gd`)
Applies a time-scale slowdown (`Engine.time_scale`) for a brief window. Governs
cooldown/charge. Emits `bies_activated` / `bies_ended` for HUD and VFX.

### HUD
Per-character health, active duo display, Bies Mode charge, boss health bar.
Driven by signals from GameManager / players — never polls node internals.

### Co-op revive *(implemented)*
A downed player is revived when their teammate stands nearby for a hold. If both
are down → game over.

**Implementation note:** Works in both single-player and co-op without any new
input actions or a "co-op mode" flag — `GameManager.swap_characters()` already
has zero state guards, so when the active character goes `DOWN`, the player can
press `swap` immediately to take control of the living standby and walk back to
the fallen teammate. `GameManager._tick_revive(delta)` (called every
`_process` from the active/standby pairing) treats `active_player` as the
rescuer and `standby_player` as the one who may need reviving — this flips
correctly after a swap, so no per-mode logic is needed:
- Within `GameManager.REVIVE_RADIUS` (48px) of a downed standby, their
  `revive_progress` fills toward `Player.REVIVE_HOLD_DURATION` (1.5s); moving
  away or the rescuer also being down decays it at `REVIVE_DECAY_RATE`.
- On reaching the hold duration, `Player.revive()` restores HP to
  `REVIVE_HP_FRACTION` (50%) of max, grants `dash_iframe_duration` i-frames
  (prevents instant re-death on revival), plays the `"special"` SFX +
  `CombatFX.sparks`, and returns the character to `State.IDLE`.
- `Player._draw()` renders a radial progress-arc ring above the downed
  character's head (`REVIVE_RING_OFFSET`/`RADIUS`/`BG_COLOR`/`FILL_COLOR`),
  mirroring the Boss telegraph-ring pattern — keeps the revive readable per the
  "combat must stay readable" guardrail.
- If both characters are `DOWN` simultaneously, `_trigger_game_over()` freezes
  gameplay (`Engine.time_scale = 0.0`, same mechanism as Bies Mode), shows a
  programmatic `CanvasLayer`/`Label` "TEAM DOWN... Press ENTER to retry"
  overlay, and `_retry_level()` reloads the current scene
  (`get_tree().reload_current_scene()`) and restores `time_scale = 1.0` on
  `ui_accept`.

### Save / Unlock system *(implemented)*
`save_manager.gd` (autoload `SaveManager`, loaded before `GameManager` so it's
available in `GameManager._ready()`) persists `completed_locations` and
`unlocked_characters` to `user://savegame.cfg` via `ConfigFile`.
`GameManager.complete_location(id)` appends the location, looks up
`UNLOCKS_CHARACTER[id]` to grant the new character, and calls
`SaveManager.save_game()`. `SaveManager.load_game()` runs once on boot from
`GameManager._ready()`. Never store save state in scene nodes.

### Audio (autoload `Audio`)
`audio.gd` generates short SFX procedurally at runtime as `AudioStreamWAV`
buffers (sine/square/noise tones and frequency sweeps), cached by name and
played from a small `AudioStreamPlayer` pool — no external sound assets
(keeps the original-IP guarantee). Covers: attack, dash, special, hit, hurt,
defeat, swap, bies, ui_move, ui_select. Call `Audio.play("name")`.

### GUT unit tests *(configured)*
`addons/gut/` holds **GUT v9.6.0** (vendored from `bitwes/Gut` — pin to v9.6.0+;
older releases like v9.3.0 declare an inner `Logger` class that collides with
Godot 4.6's native `Logger` and fail to parse). The plugin is enabled via
`project.godot`'s `[editor_plugins]` section. Tests live in `tests/unit/` and
are pure data/logic checks with **no scene instantiation and no autoload
mutation** — they `load()` `.tres` Resources directly and read `const`
dictionaries, so they can't corrupt `user://savegame.cfg` or leave the
`GameManager` singleton in a dirty state for the next test:
- `test_character_data.gd` / `test_enemy_data.gd` — assert each character's and
  enemy's `.tres` stats match the CLAUDE.md spec tables (regression guard
  against accidental balance-tuning drift) plus the qualitative relationships
  the spec describes ("Evan hits hardest", "Runner is glass-cannon vs. Brute").
- `test_unlock_chain.gd` — asserts `GameManager.UNLOCKS_CHARACTER` matches the
  documented unlock order and grants each character exactly once.

Run with `.gutconfig.json` (project root) via:
```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

**Gotcha — fresh addon scripts need an editor rescan before their `class_name`s
resolve**, the same global-class-cache trap documented in
[[feedback-godot-technical]] for in-project scripts. Dropping `addons/gut/`
into the project and enabling it in `project.godot` is NOT enough — running
`gut_cmdln.gd` immediately throws `Identifier "GutUtils" not declared in the
current scope.` The fix: run the editor headlessly once to force a full project
(re)scan/import — `godot --headless --editor --path . --quit-after 2000` — which
populates `.godot/global_script_class_cache.cfg` with `GutTest`, `GutUtils`,
etc. Only then does `gut_cmdln.gd` resolve them. This only needs to happen once
per machine/checkout (the cache persists in `.godot/`, which is gitignored —
CI environments will need this step in their pipeline before the test command).

---

## Input

Single-player controls one active character; swap button switches the active duo
member. In co-op, P2 gets their own action set.

Suggested input actions (define in Project Settings → Input Map):

```
move_up / move_down / move_left / move_right
attack          — primary attack
special         — character special ability
dash            — dash (i-frames)
swap            — swap active ↔ standby character
bies_mode       — activate Bies Mode

# Co-op second player
p2_move_up / p2_move_down / p2_move_left / p2_move_right
p2_attack / p2_special / p2_dash / p2_bies_mode
```

```gdscript
var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
if Input.is_action_just_pressed("attack"):
    _start_attack()
if Input.is_action_just_pressed("swap"):
    _swap_active_character()
```

Default keyboard: WASD + F (attack) + V (dash) + G (special) + Tab (swap) +
B (Bies Mode). Gamepad bindings alongside each action.

---

## GDScript conventions

- `snake_case` — vars, functions, filenames. `PascalCase` — nodes, classes.
  `SCREAMING_SNAKE_CASE` — constants.
- **Static typing everywhere**: `var hp: int = 100`, typed function signatures.
- **Signals over polling**: connect with `signal.connect(callable)`.
- One responsibility per script/node; compose behavior from scenes.
- Tunables (speeds, damage, HP, wave config) in **exported vars or Resources**,
  never hard-coded magic numbers.
- `@onready` for node refs; avoid deep `get_node("../../..")` — prefer exported
  `NodePath`s or groups.
- Gameplay math in `_physics_process(delta)`; never assume a fixed FPS.

---

## Working with scenes

`.tscn`/`.tres` files are plain text — small, surgical edits by hand are fine.
For structural work (new nodes, reparenting, signal wiring), keep it consistent
with how the editor serializes, then reopen in the editor to confirm it's valid.

---

## Guardrails

- Original IP only — no licensed names, music, or assets.
- Enemy attacks must be **telegraphed**; combat must stay **readable**.
- Character abilities should feel distinct and be required by at least one puzzle
  or encounter — no ability should be purely cosmetic.
- Don't commit `.godot/` cache or build artifacts; respect `.gitignore`.

---

## Definition of done for a task

1. Project boots with no script/parse errors.
2. The changed system is exercised (run the relevant scene and confirm behavior).
3. Tunables exposed in the editor; no stray magic numbers.
4. Follows the conventions above.
