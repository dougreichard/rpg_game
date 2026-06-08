# CLAUDE.md — Hunkle Bunkle

Project guidance for Claude Code. Auto-loaded as context. Keep it up to date as
the project evolves.

---

## Project overview

**Hunkle Bunkle** is a retro-style, 16-bit, top-down adventure brawler built in
**Godot 4.x with GDScript**. It combines environmental puzzle-solving with
arcade-style beat-em-up combat across 13 distinct locations.

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
| Twinkle | Pomeranian | Small, blind, snaggle tooth, annoying bark | **Sound-puzzle aggravator** — her bark is loud and grating enough to startle guards into revealing a hiding spot, rile up a crowd for cover, or — in a pinch — be aimed at an enemy to break its focus (same stagger effect as Frosty, shorter range, more annoying). *(Implemented — see `underground_tunnels.gd`: Evan's Special, used away from the rubble, sends Twinkle trotting off to bark, emitting a noise burst via `GameManager.emit_noise` that lures patrolling guards toward her racket and away from the duo — the "rile up a crowd for cover" use literalized as a genuine distraction tool.)* |
| William & Mary | Rabbits | Quick, burrows (William) / Calm, good listener (Mary) | **Puzzle scouts — always summoned and used as a pair**, never solo: William squeezes through gaps and grates too small for the duo to fetch items or trigger switches in hard-to-reach alcoves, while Mary holds a counterweight or covers a second switch in tandem — together they solve two-point puzzles ("pull a lever here, brace it there") that a single companion can't (mirrors Quinn's "gather parts" cross-dependency from the Pipe Organ Works). *(Implemented — see `the_drop.gd`: Evan's Special, used away from the wreckage, sends the pair scurrying to flanking gaps either side of it; only when BOTH are holding their point at once does it come free — an alternate, animal-handling route to the same "clear the landing site" puzzle his strength solves directly, the literal "two-point puzzle a single companion can't" from their spec.)* |
| Calvin & Coolidge | Great Pyrenees (brothers) | Large, white | **Heavy muscle — always summoned and used as a pair**, never solo: Calvin is the **combat charger** (slams into an enemy with more force/knockback than Frosty, built for bruiser-type fights) while Coolidge is the **puzzle mover** (pairs with Evan's strength to drag or brace especially massive objects — crates, gates — that even Evan alone can't budge); whichever the moment calls for, the other tags along as backup. *(Implemented as a pair — see `harbor_docks.gd`: Evan's Special summons both together, away from a puzzle prop, to charge and stagger the two nearest foes — Calvin takes the nearest, Coolidge the next-nearest, or doubles up on Calvin's target if there's only one enemy left.)* |
| *(unnamed)* | Guinea pigs | Small, numerous, skittish | **Crowd cover** — a scurrying group that can flood a floor, drawing every eye in the room and giving the duo a window to slip past or flank — Erin's stealth sections are the natural pairing. |
| *(unnamed)* | Lizard | Cold-blooded, climbs | **Vertical-traversal scout** — scales walls/pipes the duo can't reach to flip a switch or drop a rope/ladder down to them; a climbing counterpart to William/Mary's burrowing. |

**Combat-assist implementation pattern** *(established via Calvin & Coolidge at Harbor & Docks)*:
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

## Collectibles & Inventory *(core implemented — vertical slice at Pipe Organ Works)*

A cross-location item system: loot boxes scattered through the 13 locations
hold collectibles that gate puzzles, unlock shortcuts, or buff characters —
giving players a reason to revisit earlier locations and explore off the
critical path. The headline use: each character has their own movie ticket,
and all five are required to enter The Grand Marquee Cinema (Location 13).

**Architecture** *(implemented)*:
- `ItemData` Resource (`scripts/systems/item_data.gd`, `data/items/*.tres` —
  29 `.tres` files) — `id`, `display_name`, `description`, `icon_color`,
  `owner_character` (empty = shared item, or a name like `"Quinn"` for
  character-bound items such as the five tickets), `is_junk`. Mirrors the
  `CharacterData`/`EnemyData` Resource convention exactly — same `.tres` text
  format, same `class_name` + `@export` pattern. Icons generated at runtime
  via `PlaceholderArt.make_item_icon(color, is_junk)` (16×16 gem shape,
  darkened/desaturated for junk) — keeps the original-IP/no-imported-assets
  guarantee.
- Inventory state lives on `GameManager` (`inventories: Dictionary`, lowercase
  character name → `Array[String]` of held item ids), persisted via
  `SaveManager` (`cfg.set_value("progress", "inventories", ...)`) alongside
  `unlocked_characters`. Exposed via `GameManager.has_item()` / `grant_item()`
  (idempotent — re-opening an already-looted box is a no-op) and the
  `item_collected(character_name, item_id)` signal — never reach into
  internals.
- `LootBox` (`scripts/systems/loot_box.gd`, `Node2D`, no `class_name` — same
  preload()+untyped-var pattern as `HidingSpot`/`AnimalCompanion`, see
  [[feedback-godot-technical]]) — a chest prop with `setup(item, pos)` /
  `try_open(character_name, character_pos) -> bool`. `try_open` returns
  `true`/`false` so a level's existing `_on_special_used` `if`/`elif` ladder
  can chain it in alongside its other puzzle-gate checks (try loot boxes
  first, fall through to puzzle conditions) — composes with the established
  proximity-gate template rather than replacing it. On open: grants the item,
  plays `"special"` SFX, flips to its open palette via `_draw()`/
  `queue_redraw()`, and stops responding.
- `InventoryPanel` (`scripts/ui/inventory_panel.gd`, `class_name`, sibling to
  `DuoPanel` in `HUD.tscn` at `(1112, 136)` — directly below `DuoPanel`'s
  `(1112, 16)`) — draws each duo member's held item icons as a row via
  `_draw()`/`queue_redraw()`, redrawing on `GameManager.item_collected`/
  `characters_swapped`. Functional items get a gold border
  (`FUNCTIONAL_BORDER`), junk items a dim grey one (`JUNK_BORDER`) — so
  players can tell "might matter later" from "keepsake" at a glance. Wired
  into `hud.gd` via the established `class_name`-on-UI-widget-but-referenced-
  untyped pattern: `@onready var inventory_panel: Node = $InventoryPanel`,
  `inventory_panel.call("setup", a, b)`.
- Gating: level scripts add `GameManager.has_item(char_name, "id")` as an
  extra condition alongside existing `distance_to` + Special checks — the
  same multi-condition pattern Clocktower/The Drop/Grand Marquee already use.

**Vertical slice — Bellows & Sons Pipe Organ Works** (`pipe_organ_works.gd`):
proves the full loop end-to-end. Two loot boxes spawn at `PIPE_LOOT_POS`/
`SPOON_LOOT_POS` — one holding `brass_organ_pipe` (functional: the "scattered
part" the location's spec already calls for), one holding `bent_spoon` (junk:
"Quinn insists it has a story"). `_on_special_used` tries the loot boxes
first, then falls through to the organ-repair check, which now additionally
requires `GameManager.has_item("Quinn", ...) or GameManager.has_item("Erin",
...)` — either duo member finding the shared part counts. The hint label
(`_update_hint`, this location's first — it previously had none) walks the
player through "clear enemies → check crates → repair the organ" in sequence.
Verified functionally end-to-end via a temp-autoload script driving
`special_used` signal emissions directly: loot box open → item granted →
`inventories` updated → puzzle gate passes → re-opening an already-looted box
is a confirmed no-op.

**Follow-up pass (not yet done):** loot boxes + gates in the other 12
locations (including the five-ticket Grand Marquee Cinema gate — its
headline use case) and the remaining ~25 items' puzzle hookups. Scope it
the same way the floor/wall/stealth visual passes were rolled out: prototype
proven on one level, then mechanically repeated across the rest.

### Functional collectibles (gate or buff something)
| Item | Use |
|------|-----|
| Character movie ticket (×5 — one per character) | All five required to enter The Grand Marquee Cinema |
| Rusty key | Opens a shortcut door in the Underground Tunnels |
| Brass organ pipe | The "scattered part" Quinn needs to finish the Pipe Organ Works repair |
| Sheet music page | Gives Ben the correct Clocktower bell sequence instantly |
| Security badge | Auto-fills one pip of Ethan's Underground Tunnels hatch hack |
| Crowbar | Lets Evan force a stuck Harbor & Docks crate without summoning Calvin & Coolidge |
| Library card | Lets Erin/Ethan bypass the librarian dialogue gate at the Library & Archive |
| Pocket lantern | Reveals hidden loot boxes in the dark Underground Tunnels |
| Faded photograph | Lore pickup — short Uncle Doug clue dialogue, no mechanical gate |
| Spare clockwork gear | Speeds up Quinn's Clocktower mechanism repair |
| Guard whistle | Shared one-shot noise distraction (`GameManager.emit_noise`) usable by any character |
| Backstage pass | Lets Quinn/Erin skip the Carnival's backstage-guard talk-down gate |
| Tuning fork | Highlights the correct chime in Ben's sound puzzles |
| Crane crank handle | Required to operate the Harbor & Docks crane mechanism |
| VR override chip | Lets Quinn/Ethan instantly clear one corrupted VR Escape Room stage |
| Film reel | Second item needed (with the projector repair) to restore the Grand Marquee projector |
| Animal treat | Reduces an animal companion's summon cooldown for the rest of the level |
| Bies charm | Adds +10% starting Bies Mode charge at the start of a level |

### Junk / lore collectibles (look load-bearing, do nothing — comedic red herrings)
| Item | Why it seems useful | What it actually does |
|------|---------------------|------------------------|
| Skeleton key | Looks like it should open every locked door | Opens nothing — a note reads "Doesn't fit anything I've tried. — D." |
| Ticket stub (torn) | Looks like one of the five Grand Marquee tickets | From an unrelated theater; not part of the set |
| Arcade token | Embossed with a defunct arcade's logo | No arcade machine exists anywhere (yet — a planted rumor for a future location) |
| Tangled headphone cable | Ethan's sure it'll patch into Recording Studio/VR gear | Just a cable — he keeps it "for parts" |
| Faded treasure map | Covered in confident X's and arrows | Landmarks don't match anything in the game — a forgery or doodle |
| Bent spoon | Quinn insists "it has a story" | Pure character color, zero function |
| Lucky rabbit's foot keychain | Evan assumes it'll help him talk to William & Mary | Does nothing for the rabbits — or anyone |

Visually distinguish the two categories in the `InventoryPanel` (e.g. a dimmer
icon border for junk items) so players can tell "this might matter later" from
"this is just a keepsake," without it being a complete non-clue.

> **Status: core implemented + vertical slice proven.** `ItemData`,
> `GameManager` inventory state/signals, `LootBox`, `InventoryPanel`, and all
> 29 `.tres` item resources exist and are exercised end-to-end at Pipe Organ
> Works (loot box → item granted → organ-repair gate → workshop clear). Full
> rollout to the other 12 locations and the five-ticket Cinema gate is the
> remaining follow-up pass — see the vertical-slice note above.

---

## Prototype

The original prototype scope (Levels 1–2, Quinn + Erin only) is long since
surpassed — all 13 locations and all five characters are implemented (see
"Locations" below). This section now holds the project-wide tunables and
mechanics established during that prototype phase, which still govern the
full game.

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

### Beyond-prototype systems *(not covered elsewhere)*
The original prototype checklist (Quinn/Erin movement, Grunt/Runner combat,
health bars, Bies Mode, one completable room each in the first two locations)
is trivially satisfied by the finished game and isn't worth tracking anymore.
Per-location detail lives in "Locations" below and per-system detail lives in
"Architecture & key systems" — these are the pieces that don't have a more
detailed home elsewhere:
- **Combat polish** (`CombatFX` autoload): screen shake, hit sparks
  (`CPUParticles2D`), hit flash (overbright modulate tween), hit-stop
  (`set_physics_process` pause, real-time timer)
- **Title screen** (`scenes/ui/TitleScreen.tscn`) — programmatic UI, blink
  animation, transitions to OverworldMap
- **Overworld map** (`scenes/overworld/OverworldMap.tscn`) — all 13 locations
  drawn via `Node2D._draw()`, unlock chain, cursor navigation, info panel
- **Full game flow**: TitleScreen → OverworldMap → Level → (on clear) →
  OverworldMap
- **DuoPanel swap-preview UI** (`scripts/ui/duo_panel.gd`, child of `HUD.tscn`)
  — always-visible programmatic `_draw()` panel showing both duo members'
  name/color-swatch/special ability with an active-member highlight that
  pulses on `GameManager.characters_swapped`

---

## Locations

13 locations on the overworld map. The first four locations each introduce one
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

> **Status: All 13 locations have an implemented scene** — see each entry's
> implementation note for the entering duo, puzzle gates, and enemy mix
> actually shipped.

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
- **Implementation note — first level with a Doorway, camera-follow, and a
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

### 2. The Old Parish Church
- **Unlock condition:** Complete Bellows & Sons
- **Unlocks:** Evan (found here)
- **Key puzzle(s):** Quinn's respectful demeanor earns the congregation's trust (unlocks doors, gets information); Erin's skepticism lets her see through deception and argue past gatekeepers — both attitudes are required
- **Enemy types:** TBD
- **Characters required:** Quinn and Erin
- **Notes:** Quinn speaks quietly, removes his hat; Erin debates and calls out manipulation. Neither can solve it alone. Dialogue-heavy puzzle sequences. May contain a pipe organ echoing the starting location.
- **Implementation note — first rollout of Doorway/camera-follow/multi-room
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

### 3. Iron & Strings Gym — `IronStringsGym.tscn`
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
- **Implementation note — third Doorway/camera-follow/multi-room rollout**
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

### 4. The Recording Studio — `RecordingStudio.tscn`
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
- **Implementation note — fourth Doorway/camera-follow/multi-room rollout**
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

### 5. The Clocktower — `Clocktower.tscn`
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
- **Implementation note — fifth Doorway/camera-follow/multi-room rollout, and
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

### 6. The Harbor & Docks — `HarborDocks.tscn`
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
- **Implementation note — sixth Doorway/camera-follow/multi-room rollout**
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

### 7. The Public Library & Archive — `LibraryArchive.tscn`
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
- **Implementation note — seventh Doorway/camera-follow/multi-room rollout**
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

### 8. The Carnival & Fairground — `Carnival.tscn`
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
- **Implementation note — eighth Doorway/camera-follow/multi-room rollout**
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

### 9. The Underground Tunnels — `UndergroundTunnels.tscn`
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
  below. **Twinkle's bark distraction is also implemented here** — Evan's
  Special, used away from the rubble, summons her (`_summon_twinkle()`,
  cooldown-gated): she trots out and barks, emitting a noise burst
  (`GameManager.emit_noise`) that lures patrolling/investigating guards toward
  her racket — the natural home for her "rile up a crowd for cover" ability
  given this location's stealth-maze framing. See CLAUDE.md's "Stealth &
  awareness" section for the full mechanic.
- **Implementation note — ninth Doorway/camera-follow/multi-room rollout, and
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

### 10. Zip Line Park — `ZipLinePark.tscn`
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
- **Implementation note — tenth Doorway/camera-follow/multi-room rollout**
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

### 11. VR Escape Room — `VrEscapeRoom.tscn`
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
- **Implementation note — eleventh Doorway/camera-follow/multi-room rollout,
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

### 12. The Drop — `TheDrop.tscn` (aerial / parachute set piece)
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
  cleared) gate completion of `"the_drop"`. **William & Mary are also
  implemented here** — Evan's Special, used away from the wreckage,
  alternatively calls in the rabbit pair (`_summon_scout_pair()`,
  cooldown-gated): they scurry to flanking gaps either side of the wreck and
  brace it from both sides; only holding both points at once frees the site
  (`_check_scout_pair_holding()`) — a second, animal-handling route to the
  same `_landing_cleared` outcome his strength solves directly. See CLAUDE.md's
  animal companion roster for the full mechanic.
- **Implementation note — twelfth Doorway/camera-follow/multi-room rollout,
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

### 13. The Grand Marquee Cinema — `GrandMarqueeCinema.tscn` (endgame)
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
- **Implementation note — thirteenth and FINAL Doorway/camera-follow/
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
  doorway arm/trigger, full re-entry restoration) plus GUT 16/16 — no
  regressions. `_build_walls()`/`_build_floor()` needed zero script changes —
  12 wall nodes and `FLOOR_COLS`/`FLOOR_ROWS` bumped to 20×17.
  **This is the 13th and final location — the entire Doorway/camera-follow/
  multi-room rollout across all 13 locations is now COMPLETE.**

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
  unit/         test_character_data.gd, test_enemy_data.gd, test_unlock_chain.gd,
                test_stealth_fsm.gd
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
needs to visually cover the playable interior. If a future level uses
different room dimensions, recompute `FLOOR_COLS`/`FLOOR_ROWS` as
`room_px / 32` (rounding up) for that scene.

### Wall art *(rolled out to all 13 levels)*
Walls were previously **invisible colliders** — four `StaticBody2D`s per level
(`TopWall`/`BottomWall`/`LeftWall`/`RightWall`, each with a `RectangleShape2D`
`CollisionShape2D`) bordering the room with nothing drawn over them — the one
loose end the tile-floor visual-style pass left behind. Each level's
`_build_walls()` (called from `_ready()` right after `_build_floor()`) closes
the gap with **zero new tunables and zero magic numbers**:
```gdscript
func _build_walls() -> void:
	var wall_color: Color = FLOOR_BASE_COLOR.darkened(0.35)
	for wall in $Walls.get_children():
		if not wall is StaticBody2D:
			continue
		var shape: CollisionShape2D = wall.get_node("CollisionShape2D")
		var rect: RectangleShape2D = shape.shape
		var sprite := Sprite2D.new()
		sprite.texture = PlaceholderArt.make_wall_texture(wall_color, int(rect.size.x), int(rect.size.y))
		wall.add_child(sprite)
```
- **Color is derived, not hand-picked**: `FLOOR_BASE_COLOR.darkened(0.35)` reuses
  each level's *existing* floor-palette const, so walls automatically read as a
  darker stone border that matches that level's identity — no new per-level
  `WALL_COLOR` consts to keep in sync with the floor palette as it evolves.
- **Size comes from the collider, not a guess**: the sprite is sized to the
  exact `RectangleShape2D.size` it sits on (read at runtime via
  `wall.get_node("CollisionShape2D").shape.size`), so it fits perfectly whether
  it's a `640×16` long top/bottom wall or a `16×360` tall side wall — no
  separate horizontal/vertical textures, and it stays correct even if a future
  level's room dimensions differ from the shared `640×360`.
- `PlaceholderArt.make_wall_texture(color, w, h)` draws a **running-bond brick
  pattern** (`BRICK_W = 16` / `BRICK_H = 8` local consts — a darker `mortar`
  grid offset by half a brick on alternating rows) scaled to fit *any* `w × h`
  at runtime — the same "generate the exact pixels needed, no imported/tiled
  assets" approach as `make_level_tileset`/`make_gate_texture`, keeping the
  original-IP guarantee intact. One function call handles both wall
  orientations cleanly since it isn't tied to a fixed tile grid.
- Sprites are parented directly to their `StaticBody2D` at local position
  `(0, 0)` — automatically centered on the collider with no position math, and
  they travel with the wall if a level ever repositions one.

**Rollout note:** prototyped on Pipe Organ Works (verified via temp-autoload
check that all 4 sprites' texture sizes match their colliders' exactly), then
rolled out to the other 12 via the same config-driven Python regex-insert
technique the floor/stealth rollouts established — clean on the first pass
(no indentation bug this time), verified via a 13-level functional sweep
(`walls_ok=true sprite_count=4` for every scene) plus a full boot-check and
GUT 16/16.

### Stealth & awareness *(rolled out to all 13 levels)*
Levels previously had every enemy spawn straight into `CHASE` — combat started
the instant a scene loaded, leaving no room for puzzle-solving or sneaking. The
`Enemy` FSM now opens with a **patrol-and-detect** phase ahead of the existing
combat loop, so guards have to actually notice the duo before a fight begins:
`enum State { PATROL, INVESTIGATE, CHASE, WINDUP, STRIKE, RECOVER, HIT,
AOE_TELEGRAPH, AOE_SLAM }`. Regular enemies start in `PATROL`; **bosses skip
straight to `CHASE`** (`if data.is_boss: _set_state(State.CHASE)` in
`Enemy._ready()`) since they're meant to be known climactic confrontations, not
sneak-past targets — every other state and the whole `CHASE → WINDUP → STRIKE →
RECOVER → HIT` combat loop (including the boss AoE slam and ranged-Sentry
projectile path) is untouched, so this slots in ahead of combat rather than
replacing it.

- **`PATROL`** — `Enemy._tick_patrol()` walks the guard between randomized
  points within `EnemyData.patrol_radius` of its spawn (`_home_position`),
  pausing for `PATROL_PAUSE_DURATION` at each stop, at `PATROL_SPEED_SCALE`
  (half normal `move_speed` — patrols amble, they don't rush).
- **Detection** — `Enemy._can_see(target)` is a vision-cone + line-of-sight
  check: distance ≤ `EnemyData.vision_range`, angle to target within half of
  `EnemyData.vision_angle_deg` of the guard's current facing
  (`Vector2.angle_to`), and an unobstructed
  `PhysicsRayQueryParameters2D.create()` /
  `direct_space_state.intersect_ray()` against the wall collision layer
  (`WALL_COLLISION_MASK = 1`). A hidden player (`Player.is_hidden`, see below)
  always fails the check regardless of geometry. Sight fills an `_alert_meter`
  toward `ALERT_THRESHOLD` at `SIGHT_GAIN_RATE`; losing sight decays it at
  `ALERT_DECAY_RATE`. Crossing `SUSPICION_THRESHOLD` (~35% alert) escalates
  `PATROL → INVESTIGATE`; reaching `ALERT_THRESHOLD` (100%) escalates straight
  into the existing `CHASE` state — combat begins exactly as it always has from
  there.
- **`INVESTIGATE`** — `Enemy._tick_investigate()`: the guard walks to the last
  spot it either saw or heard the player, lingers for
  `INVESTIGATE_LOOK_DURATION`, then stands down to `PATROL` if its alert meter
  drops back below `SUSPICION_THRESHOLD` without a fresh trigger — a deliberate
  "stood down, not aggro'd forever" design so a missed sighting doesn't
  permanently spoil a stealth attempt.
- **Noise** — `GameManager.emit_noise(position, radius)` /
  `noise_emitted(position, radius)` is the global stealth signal hub (per the
  "use signals, never reach into GameManager" rule). `Player._enter_attack()`
  and `_enter_dash()` ripple noise outward at `ATTACK_NOISE_RADIUS` (110px) /
  `DASH_NOISE_RADIUS` (160px) — loud actions can be *heard* through walls even
  when the player can't be *seen*. `Enemy._on_noise_emitted()` raises a
  `PATROL`/`INVESTIGATE` guard's alert to at least `NOISE_ALERT_FLOOR` (40%) and
  sets its investigate target if the noise is within
  `max(radius, EnemyData.hearing_range)`.
- **Hiding spots** — `scripts/systems/hiding_spot.gd` (`HidingSpot`, no
  `class_name` — see the class_name-resolution gotcha in
  [[feedback-godot-technical]]) is a small `Area2D` shadow/alcove prop
  (`collision_layer = 0`, `collision_mask = 2` to detect the player body only).
  While a `Player` overlaps it, `body_entered`/`body_exited` toggle
  `Player.is_hidden`, which (a) makes `Enemy._can_see()` always return false for
  that player and (b) dims the sprite to `HIDDEN_MODULATE` (55% alpha) so the
  player can visually confirm they're concealed. Every level's
  `_create_hiding_spot()` drops one at a hand-picked `HIDING_SPOT_POS` — chosen
  clear of puzzle-prop gate radii and along a patrol route, so ducking in to
  let a guard pass is always a real tactical option.
- **Distraction / calm-down** — `GameManager.calm_enemies(position, radius)` /
  `enemies_calmed(position, radius)` lets a tool talk down guards that are
  already suspicious. `Player._use_special()` fires it at
  `FAST_TALK_CALM_RADIUS` (130px) specifically when `data.character_name ==
  "Erin"`, extending her established "talk/bluff way past guards" spec from a
  dialogue-puzzle gate into a live combat-avoidance tool.
  `Enemy._on_enemies_calmed()` resets any `INVESTIGATE`/`CHASE`/`RECOVER` guard
  within range straight back to `PATROL` with `_alert_meter = 0`. **Twinkle's
  bark is now wired into this exact pair** — see `scripts/levels/
  underground_tunnels.gd._summon_twinkle()`: Evan's Special, used away from
  the rubble, sends her trotting `TROT_DISTANCE` out (in `evan.facing`,
  `scripts/systems/twinkle_companion.gd`'s `TROT_OUT → BARK → RETURN` phase
  machine — the lightweight, distance-driven sibling of `AnimalCompanion`'s
  combat-charge state machine, same no-`class_name` preload pattern), where
  she calls `GameManager.emit_noise(global_position, BARK_RADIUS)` — a
  220px burst that lures patrolling/investigating guards toward her racket
  and away from the duo's actual position (cooldown-gated, like Calvin &
  Coolidge). Literalizes "rile up a crowd for cover" from her roster spec as
  a genuine noise-distraction tool, distinct from Calvin & Coolidge's
  combat-charge use of the companion pattern. (Other animal-companion
  distractions remain natural future hooks into the same pair.)
- **Awareness telegraph** — extends the established `_draw()`/`queue_redraw()`
  warning-indicator pattern (Boss AoE ring, revive progress-arc) to satisfy
  "combat must stay readable" for stealth too:
  `Enemy._draw_awareness()` renders a translucent forward **vision-cone wedge**
  (`_draw_vision_cone()`, a `draw_colored_polygon()` fan spanning
  `EnemyData.vision_angle_deg` out to `vision_range`, color-graded from
  `VISION_CONE_COLOR_LOW` to `_HIGH` as alert rises) plus a color-graded
  **alert-meter ring** above the guard's head (`draw_arc`, background +
  fill arc scaled by `_alert_meter / ALERT_THRESHOLD`). Players can always see
  exactly what a guard can detect and how close it is to noticing them — the
  same transparency the boss slam-ring and revive-ring already provide.
- **`EnemyData` "Stealth" export group** — new tunables (no magic numbers):
  `vision_range` (170px), `vision_angle_deg` (100°), `hearing_range` (90px),
  `patrol_radius` (80px). Tune per-enemy via `.tres` Resources as usual — e.g. a
  Sentry could get a wider `vision_angle_deg` to suit a watchtower role.

**Rollout note:** every combat level (all but The Old Parish Church, which has
no enemies) got a `_create_hiding_spot()` and an updated hint label steering the
player toward "patrols haven't spotted you — sneak past or strike before
they're alerted" framing instead of "clear the floor!" — see each location's
implementation note for its hiding-spot position and exact hint text.

### Doorways, camera-follow & multi-room levels *(prototyped at Pipe Organ Works)*
Every one of the 13 location scenes previously shared an identical blueprint:
a single 640×360 room, a **static** `Camera2D` at `(320,180)` with
`zoom=(2,2)` (the zoomed viewport exactly framed the room, so the camera never
needed to move), and a "press ENTER on the clear overlay" exit straight to
`OverworldMap.tscn` — no way to leave mid-level, and no sense of a place
larger than one arena. Three structural upgrades replace that, proven on
Pipe Organ Works as the prototype (the location with the most existing
infrastructure — loot boxes, a hint label, the organ puzzle):

- **Camera follows the active player** — `Camera2D` stays a level-root child
  (NOT reparented to the player — that would complicate the active/standby
  swap); each level's `_setup_camera()` turns on
  `position_smoothing_enabled`/`position_smoothing_speed` (a tunable const)
  and sets `limit_left/top/right/bottom` from the level's own
  `CAMERA_LIMIT_*` consts (its bounding-box). `_process` simply re-targets
  `camera.global_position = GameManager.active_player.global_position` every
  frame — smoothing makes the retarget on `characters_swapped` feel natural
  for free, no extra signal wiring needed.
- **`Doorway`** (`scripts/systems/doorway.gd`, `Node2D`, no `class_name` —
  same `preload()`+untyped-`var` pattern as `LootBox`/`HidingSpot`/
  `AnimalCompanion`, see [[feedback-godot-technical]]) is the location's
  entrance/exit prop. The duo spawns right beside it, so `check(player_pos)`
  "arms" itself only once the active character has walked at least
  `ARM_RADIUS` (96px) away — preventing an instant-exit on scene load — then
  returns `true` the moment they come back within `TRIGGER_RADIUS` (56px),
  **at any point in the level, cleared or not** (the user's explicit choice:
  "allow exit any time"). A level polls it from `_process` exactly like it
  polls loot boxes (`LootBox.try_open`'s `-> bool` shape) and calls
  `_exit_to_overworld()` on a `true` — a helper distinct from the existing
  clear-overlay "press ENTER" exit, which still fires `complete_location()`
  on first clear; `_exit_to_overworld()` also calls it when `_cleared` is
  true (e.g. the duo cleared the floor, then walked out instead of pressing
  ENTER) — safe because `complete_location` is idempotent.
- **Mid-level progress persistence** (new capability — the user chose
  "persist mid-level progress across exits" over resetting on re-entry):
  `GameManager.level_progress: Dictionary` is a flat per-location flag store
  (`location_id -> {flag_name: value}`), mirroring `inventories`/`has_item`/
  `grant_item` exactly — `get_level_flag(id, key, default)` /
  `set_level_flag(id, key, value)` (the setter calls `SaveManager.save_game()`,
  same as `grant_item`). `save_manager.gd` persists it via one more
  `cfg.set_value`/`get_value("progress", "level_progress", ...)` pair
  alongside `"inventories"` — `ConfigFile` round-trips nested `Dictionary`
  natively, so no new serialization code was needed. Crucially, this reuses
  the **exact booleans a level already tracks locally**
  (`_enemies_cleared`, `_organ_repaired`, a loot box's `is_open`) rather than
  inventing per-enemy IDs or a parallel tracking system — a level's
  `_restore_progress()` (called from `_ready()`, before `_spawn()`) reads
  them back: skips spawning entirely if the floor was already cleared,
  restores solved-state sprite palettes, and passes `already_open` (new
  `LootBox.setup` param) to pre-open previously-looted boxes. Every place the
  level flips one of these booleans to `true` also calls
  `GameManager.set_level_flag(...)`.
- **Bespoke multi-room layouts** (the user's choice: "bespoke per location,
  matching its spec" — not a templated reskin) — see the Pipe Organ Works
  implementation note below for how its single-floor-workshop spec became
  *entry bay → hallway → main workshop → secret parts closet*. The
  mechanically interesting part: **`_build_walls()` needed zero changes** —
  it already iterates `$Walls.get_children()` generically and sizes/textures
  a sprite to *whatever* `CollisionShape2D` rect it finds, so carving out
  more rooms is purely additive `.tscn` node placement (CLAUDE.md:
  "`.tscn`/`.tres` are plain text — small, surgical edits by hand are fine").
  `_build_floor()` likewise just needed `FLOOR_COLS`/`FLOOR_ROWS` bumped to
  cover the new bounding box — tiles painted outside room footprints simply
  sit behind walls, invisible to the player.

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
- `test_stealth_fsm.gd` — covers the PATROL/INVESTIGATE/detection system (see
  "Stealth & awareness" above) the same scene-free way: `EnemyData`'s "Stealth"
  export-group tunables (`vision_range`/`vision_angle_deg`/`hearing_range`/
  `patrol_radius`) are read straight off each enemy `.tres`, and the `Enemy`
  FSM's threshold/rate **consts** (`SUSPICION_THRESHOLD`, `ALERT_THRESHOLD`,
  `SIGHT_GAIN_RATE`, `ALERT_DECAY_RATE`, `NOISE_ALERT_FLOOR`,
  `PATROL_SPEED_SCALE`, `PATROL_PAUSE_DURATION`, `INVESTIGATE_LOOK_DURATION`)
  are read directly off the globally-registered `Enemy` class — no `Enemy.new()`,
  no node ever enters the tree. Beyond matching the spec values, it locks in
  the *qualitative* relationships the FSM depends on to feel right: alert rises
  faster than it decays, `SUSPICION_THRESHOLD < ALERT_THRESHOLD` (so the
  PATROL → INVESTIGATE → CHASE ladder actually escalates in order), and —
  load-bearing for Twinkle's bark and noise distractions generally —
  `NOISE_ALERT_FLOOR` sits *above* `SUSPICION_THRESHOLD` but *below*
  `ALERT_THRESHOLD`, so a noise burst alone is loud enough to pull a guard into
  INVESTIGATE but never snaps it straight into CHASE.

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
