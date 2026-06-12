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

| Animal | Breed / Type | Appearance / Traits | Role |
|--------|-------------|---------------------|------|
| Frosty | Schnoodle (Schnauzer/Poodle mix) | White fur | **Combat distractor** — charges the nearest enemy, headbutts it to interrupt a windup/stagger it, then returns to Evan's side. |
| Twinkle | Pomeranian | Small, blind, snaggle tooth, annoying bark | **Noise distraction** — trots out in Evan's facing direction, barks via `GameManager.emit_noise`, luring patrolling guards toward the noise and away from the duo. Implemented in `underground_tunnels.gd`. |
| William & Mary | Rabbits | Quick, burrows (William) / Calm, good listener (Mary) | **Puzzle scouts — always a pair**: solve two-point puzzles by holding two positions simultaneously. Implemented in `the_drop.gd` to clear the landing site as an alternate to Evan's strength. |
| Calvin & Coolidge | Great Pyrenees (brothers) | Large, white | **Heavy muscle — always a pair**: Calvin is the combat charger, Coolidge is the puzzle mover. Implemented in `harbor_docks.gd` to charge/stagger the two nearest enemies. |
| *(unnamed)* | Guinea pigs | Small, numerous, skittish | **Crowd cover** — a scurrying group that floods a floor, drawing every eye in the room. Erin's stealth sections are the natural pairing. |
| *(unnamed)* | Lizard | Cold-blooded, climbs | **Vertical-traversal scout** — scales walls/pipes to flip a switch or drop a rope. Implemented in `lizard_companion.gd` (CLIMB → PERCH → RETURN); summonable by Ethan in Zip Line Park and VR Escape Room. |

**Animal companion pattern** (`scripts/systems/animal_companion.gd`, no `class_name` — preload()+untyped var):
three-phase `CHARGE → STRIKE → RETURN` FSM; `STRIKE` toggles `monitoring` on a runtime `Hitbox`
(`collision_layer/mask 8/64`) that rides the existing damage/knockback pipeline. Wire up via
`special_used` signal → `AnimalCompanionScript.new(); .setup(summoner, target, color); add_child(...)`,
gated by a per-companion cooldown.

> Add new animals here as they are designed. Note their combat use, puzzle use, and which locations they appear in.

### Puzzle cross-dependencies (examples)
- Quinn repairs a broken clock → requires parts that Evan's animal companions gathered from hard-to-reach spots.
- Ethan hacks a locked panel → but only if Erin already distracted the guard.
- Design new puzzles to require the *specific* abilities of the active duo so character swapping is meaningful, not optional.

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

## Collectibles & Inventory

Cross-location item system: loot boxes in all 13 locations hold collectibles that gate puzzles,
unlock shortcuts, or buff characters. The headline use: each character has their own movie ticket;
all five are required to enter The Grand Marquee Cinema.

**Architecture:** `ItemData` Resource (`scripts/systems/item_data.gd`, `data/items/*.tres`) with
`id`, `display_name`, `description`, `icon_color`, `owner_character`, `is_junk`. Inventory lives on
`GameManager` (`inventories: Dictionary`, lowercase name → `Array[String]`); use `has_item()` /
`grant_item()` (idempotent) / `consume_item()` and `item_collected` signal — never reach into internals.
`LootBox` (`scripts/systems/loot_box.gd`, no `class_name`) has `setup(item, pos)` /
`try_open(character_name, character_pos) -> bool`; a level's `_on_special_used` tries loot boxes
first, then falls through to puzzle-gate checks.
**Gotcha:** any new `HUD.tscn` overlay that `PauseMenu` looks up as a sibling must also be added to
`overworld_map.gd._build_ui()`'s programmatic sibling list — `OverworldMap.tscn` has no static overlay
nodes, so a missing entry crashes `pause_menu.gd._ready()` on "Continue" from the title screen.

### Functional collectibles (gate or buff something)
| Item | Use |
|------|-----|
| Character movie ticket (×5 — one per character) | All five required to enter The Grand Marquee Cinema |
| Rusty key | Opens a shortcut door in the Underground Tunnels |
| Brass organ pipe | First of two parts (with the tuning key) Quinn needs to finish the Pipe Organ Works repair |
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
| Tuning key | Second piece (with the brass organ pipe) Quinn needs for Pipe Organ Works — Erin fast-talks it out of Mr. Bellows |
| Crane crank handle | Required to operate the Harbor & Docks crane mechanism |
| VR override chip | Lets Quinn/Ethan instantly clear one corrupted VR Escape Room stage |
| Film reel | Second item needed (with the projector repair) to restore the Grand Marquee projector |
| Animal treat | Reduces an animal companion's summon cooldown for the rest of the level |
| Bies charm | Adds +10% starting Bies Mode charge at the start of a level |
| Fanny's Bottle | Quest item for Fanny — a keepsake Doug gave her "the day before he disappeared" |

### Junk / lore collectibles (look load-bearing, do nothing — comedic red herrings)
| Item | Why it seems useful | What it actually does |
|------|---------------------|------------------------|
| Skeleton key | Looks like it should open every locked door | Opens nothing — a note reads "Doesn't fit anything I've tried. — D." Quest item for Moira |
| Ticket stub (torn) | Looks like one of the five Grand Marquee tickets | From an unrelated theater; not part of the set |
| Arcade token | Embossed with a defunct arcade's logo | No arcade machine exists (yet). Quest item for Reggie — custom-cast for an unfinished cabinet he and Doug built |
| Tangled headphone cable | Ethan's sure it'll patch into Recording Studio/VR gear | Just a cable — he keeps it "for parts" |
| Faded treasure map | Covered in confident X's and arrows | Landmarks don't match anything in the game |
| Bent spoon | Quinn insists "it has a story" | Quest item for Gus — it's Doug's old pipe-tapping spoon |
| Lucky rabbit's foot keychain | Evan assumes it'll help him talk to William & Mary | Does nothing for the rabbits |
| Embroidered handkerchief | Looks like a keepsake, monogrammed "D" | Quest item for Penny — turning it in grants the Hand-Stitched Patch |
| Hand-Stitched Patch | A little gear-shaped patch | Pure character color — Penny's thank-you, zero function |
| Brass compass | Engraved "To O., so you always find your way home" | Quest item for Otis — turning it in grants the Sailor's Knot Bracelet |
| Sailor's Knot Bracelet | Looks like a good-luck charm | Pure character color — Otis's thank-you, zero function |

Visually distinguish functional from junk in `InventoryPanel` (gold vs. dim grey border).

### Numbered spoon set (NPC quest rewards)
12-piece junk/lore set: finishing any of the 12 town NPC quests also grants one `numbered_spoon_NN`
(`data/items/numbered_spoon_01.tres`–`_12.tres`). Descriptions escalate toward an Easter-egg hint
about an old arcade cabinet (tying back to Reggie's `arcade_token`). Pure lore/completionist hook.
Tobias/Agnes are `requires_flag` NPCs — Tobias unlocked by Pipe Organ Works `secret_revealed`,
Agnes by Old Parish Church `secret_revealed`.

---

## Game specs

### Pixel grid
- **Tile size:** 32×32 px
- **Character sprite (gameplay footprint):** 32×32 px (matches tile size — full tile-grid alignment)
- **Character sprite source art:** 64×64 px per frame (2× oversample); all five sheets are PIL-generated via `generators/gen_*.py` — see `DESIGN.md` §3/§4 for the full spec.
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
often; Evan is the slowest but hits hardest and has the most HP.

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
**Brute:** slow, telegraphs a long windup, but hits hard and soaks damage.
**Sentry** (`data/enemies/sentry.tres`, `is_ranged = true`): holds at long range, fires a `Projectile` (`scripts/systems/projectile.gd`, `extends Hitbox`) instead of opening a melee Hitbox.
**Boss** (`data/enemies/boss.tres`, `is_boss = true`): adds `AOE_TELEGRAPH → AOE_SLAM` states. Draws an expanding warning ring via `_draw()`/`queue_redraw()` for `slam_telegraph_duration`, then spawns a runtime `Hitbox` with `CircleShape2D` for one active window. In Clocktower and Grand Marquee Cinema.

### Bies Mode
- **Charges** as the active character deals damage — 10% charge per hit landed
- **Activates** at 100% charge via the `bies_mode` input
- **Effect:** `Engine.time_scale = 0.4` for 5 seconds, then snaps back to 1.0
- **HUD:** charge bar always visible; pulses when full

### Standby character
- Holds position when not active — no AI, no auto-attack
- Teleports to the active character's side if the active character moves more than 300 px away
- Swap has no cooldown; add one later if it feels exploitable

### Game flow & UI systems
- **Flow:** TitleScreen → OverworldMap → Level → (on clear) → OverworldMap
- **Overworld map** (`scenes/overworld/OverworldMap.tscn`) — 40×19 `TileMap` with three layers (grass, roads, buildings). Duo walks the town; proximity to a building door shows name/status and triggers `_launch()`. See `locations/00_overworld_map.md`.
- **DuoPanel** (`scripts/ui/duo_panel.gd`) — always-visible `_draw()` panel showing both duo members' name/color/special, active highlight pulses on `GameManager.characters_swapped`.
- **Combat polish** (`CombatFX` autoload): screen shake, hit sparks (`CPUParticles2D`), hit flash (overbright tween), hit-stop (`set_physics_process` pause).

---

## Locations

13 locations on the overworld map. The first four each introduce one new character.

**Unlock order:**

| # | Location | Entering duo | Unlocks | Completion id |
|---|----------|-------------|---------|---------------|
| 1 | Bellows & Sons Pipe Organ Works | Quinn + Erin | Erin | `"pipe_organ_works"` |
| 2 | The Old Parish Church | Quinn + Erin | Evan | `"old_parish_church"` |
| 3 | Iron & Strings Gym | Quinn + Evan | Ben | `"iron_strings_gym"` |
| 4 | The Recording Studio | Quinn + Ben | Ethan | `"recording_studio"` |
| 5 | The Clocktower | Quinn + Ben | — | `"clocktower"` |
| 6 | The Harbor & Docks | Quinn + Evan | — | `"harbor_docks"` |
| 7 | The Public Library & Archive | Erin + Ethan | — | `"library"` |
| 8 | The Carnival & Fairground | Quinn + Erin | — | `"carnival"` |
| 9 | The Underground Tunnels | Evan + Ethan | — | `"underground"` |
| 10 | Zip Line Park | Ethan + Ben | — | `"zip_line"` |
| 11 | VR Escape Room | Quinn + Ethan | — | `"vr_room"` |
| 12 | The Drop | Evan + Ethan | — | `"the_drop"` |
| 13 | The Grand Marquee Cinema | Quinn + Ben | Endgame | `"grand_marquee"` |

All 13 locations are fully implemented with multi-room layouts, camera follow, Doorway system,
stealth patrol, and mid-level progress persistence. See `docs/implementation_history.md` for the
full per-location build narrative.

**Puzzle-gate variety:** Most locations use a **proximity gate** (in-range + press Special = instant success).
Two diversify this:
- **Zip Line Park** — **timing gate**: pulsing `_draw()` ring; press Special inside `PULSE_GOOD_WINDOW`.
- **Underground Tunnels** — **multi-step gate**: `HATCH_PRESSES_REQUIRED` (3) progress pips; each press fills one.

Keep the baseline proximity gate as the default; use timing or multi-step only when the location's spec calls for that flavor.

---

### 1. Bellows & Sons Pipe Organ Works — `PipeOrganWorks.tscn`
- **Unlock condition:** Available from the start
- **Key puzzle(s):** Quinn repairs the pipe organ; requires `brass_organ_pipe` + `tuning_key` (Erin fast-talks the key from Mr. Bellows)
- **Enemy types:** Grunts + Runners
- **Level progress flags:** `enemies_cleared` / `organ_repaired` / `secret_revealed` / `manager_met` / `tuning_key_given`
- **Camera bounds:** `(24,24)–(1352,656)`; `FLOOR_COLS = 43` / `FLOOR_ROWS = 20`
- **NPCs:** Mr. Bellows (dialog-choice, at his desk in Manager's Office)
- **Notes:** Erin is "on loan" at the start; officially recruited on completion. Secret passage reveals `spare_clockwork_gear`.

---

### 2. The Old Parish Church — `OldParishChurch.tscn`
- **Unlock condition:** Complete Bellows & Sons
- **Unlocks:** Evan
- **Key puzzle(s):** Quinn's respectful demeanor earns the congregation's trust; Erin's skepticism lets her see through deception — neither can solve it alone
- **Enemy types:** None (dialogue-heavy)
- **Level progress flags:** `quinn_done` / `erin_done` / `secret_revealed` / `father_aldric_impression`
- **Camera bounds:** `(184,24)–(776,656)`
- **NPCs:** Father Aldric (dialog-choice NPC at the altar; `father_aldric_impression` → `"good"` / `"cool"`)

---

### 3. Iron & Strings Gym — `IronStringsGym.tscn`
- **Unlock condition:** Complete The Old Parish Church
- **Unlocks:** Ben
- **Key puzzle(s):** Evan's strength moves the barbell sealing Ben's cage alcove
- **Enemy types:** Grunts + Brutes
- **Level progress flags:** `enemies_cleared` / `barbell_moved`
- **Camera bounds:** `(24,24)–(936,536)`

---

### 4. The Recording Studio — `RecordingStudio.tscn`
- **Unlock condition:** Complete Iron & Strings Gym
- **Unlocks:** Ethan
- **Key puzzle(s):** Ben tunes the soundboard console, sliding open the glass BoothDoor and revealing Ethan
- **Enemy types:** Grunts + Runners
- **Level progress flags:** `enemies_cleared` / `console_tuned`
- **Camera bounds:** `(24,24)–(896,536)`

---

### 5. The Clocktower — `Clocktower.tscn`
- **Unlock condition:** All five characters unlocked
- **Key puzzle(s):** Quinn repairs the gear floor escapement; Ben plays the correct belfry bell sequence (tuning fork item helps); clockwork-guardian Boss guards the stairs
- **Enemy types:** Grunts + Boss (clockwork guardian)
- **Level progress flags:** `enemies_cleared` / `gear_repaired` / `bells_played`
- **Camera bounds:** `(264,24)–(616,616)` (tall vertical shaft)
- **NPCs:** Hieronymus (stationary on landing floor)

---

### 6. The Harbor & Docks — `HarborDocks.tscn`
- **Unlock condition:** All five characters unlocked (opens alongside Clocktower)
- **Key puzzle(s):** Evan (or crowbar item) moves the cargo container blocking the crane platform; Calvin & Coolidge combat assist; Viktor's manifest confirms Doug's name on the shipment
- **Enemy types:** Grunts (dock workers) + Runners (smugglers)
- **Level progress flags:** `enemies_cleared` / `container_moved`
- **Camera bounds:** `(24,24)–(936,536)`
- **NPCs:** Viktor (harbourmaster, stationary near pier entrance)

---

### 7. The Public Library & Archive — `LibraryArchive.tscn`
- **Unlock condition:** TBD
- **Key puzzle(s):** Erin talks her way past the librarian (or library card item bypasses the desk); Ethan hacks the restricted archive terminal
- **Enemy types:** Grunts + Sentry (ranged)
- **Level progress flags:** `enemies_cleared` / `librarian_talked` / `archive_hacked`
- **Camera bounds:** `(24,144)–(936,536)`

---

### 8. The Carnival & Fairground — `Carnival.tscn`
- **Unlock condition:** TBD
- **Key puzzle(s):** Quinn repairs the broken ride; Erin talks down the backstage gate (or backstage pass item skips the guard conversation)
- **Enemy types:** Grunts ×2 + Brute
- **Level progress flags:** `enemies_cleared` / `ride_repaired` / `backstage_talked`
- **Camera bounds:** `(24,24)–(936,536)`

---

### 9. The Underground Tunnels — `UndergroundTunnels.tscn`
- **Unlock condition:** TBD
- **Key puzzle(s):** Evan clears west rubble (proximity gate); Ethan hacks east hatch (multi-step, 3 pips); Twinkle bark distraction; rusty key opens a shortcut door
- **Enemy types:** Grunts ×2 + Runner (patrol-style)
- **Level progress flags:** `enemies_cleared` / `rubble_cleared` / `hatch_progress` (int 0–3, persists partial hack)
- **Camera bounds:** `(24,184)–(936,536)`
- **NPCs:** Cyrus (tunnel maintainer, stationary at junction chamber)

---

### 10. Zip Line Park — `ZipLinePark.tscn`
- **Unlock condition:** TBD
- **Key puzzle(s):** Ethan hacks the Mid Platform control panel (proximity); Ben catches the timed High Platform release window (timing gate)
- **Enemy types:** Grunt + Runners ×2
- **Level progress flags:** `enemies_cleared` / `panel_hacked` / `release_timed`
- **Camera bounds:** `(24,164)–(936,536)`
- **NPCs:** Lena (safety warden, stationary on Landing platform)

---

### 11. VR Escape Room — `VrEscapeRoom.tscn`
- **Unlock condition:** TBD
- **Key puzzle(s):** Quinn repairs physics-glitch node in Stage Alpha; Ethan hacks system console in Stage Beta; Lizard companion offers an alternate bypass route
- **Enemy types:** Grunts ×2 + Sentry (glitchy/corrupted)
- **Level progress flags:** `enemies_cleared` / `glitch_repaired` / `system_hacked`
- **Camera bounds:** `(24,24)–(776,536)`
- **NPCs:** ARIA (virtual assistant, stationary in Boot Chamber)

---

### 12. The Drop — `TheDrop.tscn`
- **Unlock condition:** Late-game, after a credible lead on Uncle Doug's location
- **Key puzzle(s):** Evan clears landing-site wreckage (or William & Mary two-point puzzle); Ethan hacks jammed chute release in Snag Grove; Rio confirms the marquee sign points to the endgame
- **Enemy types:** Grunt + Runner + Brute (hostile ground crew)
- **Level progress flags:** `enemies_cleared` / `chute_hacked` / `landing_cleared`
- **Camera bounds:** `(24,24)–(576,536)`
- **NPCs:** Rio (ex-crew, stationary in Touchdown Clearing)

---

### 13. The Grand Marquee Cinema — `GrandMarqueeCinema.tscn` (endgame)
- **Unlock condition:** Complete The Drop; all five characters + all five movie tickets required
- **Key puzzle(s):** Quinn repairs the projection booth; Ben plays the house organ on the Balcony; Boss guards the Backstage aisle; Uncle Doug found in the projection booth
- **Enemy types:** Grunts ×2 + Boss (cinema guardian)
- **Level progress flags:** `enemies_cleared` / `projector_repaired` / `organ_played`
- **Camera bounds:** `(24,24)–(616,536)`
- **NPCs:** Cecil / Usher (chief usher, dialog-choice tree, stationary in Lobby)
- **Notes:** On clear, `_exit_to_overworld()` routes to `ResultScreen.tscn` (endgame). Completion id is `"grand_marquee"`.

```
Location template:
- Name:
- Unlock condition:
- Unlocks: (character, if applicable)
- Key puzzle(s):
- Enemy types:
- Level progress flags:
- Camera bounds:
- NPCs: (if any)
- Notes:
```

---

## Tech stack & targets

- **Engine:** Godot 4.x (confirm with `godot --version`; prefer 4.3+ APIs). Use GDScript 2.0 idioms.
- **Rendering:** 2D. `Node2D` + Y-sort for depth (screen-Y = depth; small `z` for jump height).
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
godot --headless --path . --export-release "Linux" build/hunkle_bunkle.x86_64
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
- **Character swap**: instantly switches active ↔ standby character. Standby character follows or holds position.
- Character-specific stats and abilities live in a `CharacterData` Resource, loaded at runtime. No per-character code forks in `player.gd`.

### Enemy (`CharacterBody2D`)
Full FSM: `PATROL → INVESTIGATE → CHASE → WINDUP → STRIKE → RECOVER → HIT` (plus `AOE_TELEGRAPH`/`AOE_SLAM` for Boss).
Bosses skip straight to `CHASE` — they're meant as known confrontations, not sneak-past targets.
Windup **must telegraph** (animation + UI tell) before a strike.

### Combat (Area2D)
Attacks spawn a short-lived **Hitbox** (`Area2D`) that overlaps enemy **Hurtbox** (`Area2D`).
All damage resolution in `combat.gd` via signals. Apply: knockback, hitstun, hit-flash, particles, screen-shake, brief hit-stop.

### WaveSpawner
Reads `data/waves.tres`. Spawns from screen edges up to a max concurrent count.
Emits `wave_cleared` when queue is empty and no enemies remain.

### PuzzleManager
Tracks puzzle state per location. Emits signals when puzzle conditions are met
(e.g., `clock_repaired`, `panel_hacked`). Puzzle logic references character
abilities by type, not by character name, so new characters can plug in.

### Tile-mapped floors & wall art
All 13 levels use programmatically generated `TileMap` floors and wall sprites — no imported assets.

**Floor:** `PlaceholderArt.make_level_tileset(base, accent) -> TileSet` draws a 64×32 px atlas
(two 32×32 tiles). `_build_floor()` builds a `TileMap`, `move_child(tm, 0)` so it renders behind
everything else, and `set_cell()`s a grid with `FLOOR_COLS/ROWS/ACCENT_PERIOD` consts.
Standard rooms share `FLOOR_COLS = 20` / `FLOOR_ROWS = 12` / `FLOOR_ACCENT_PERIOD = 4`; only
`FLOOR_BASE_COLOR` / `FLOOR_ACCENT_COLOR` vary per location. For non-standard rooms,
recompute as `room_px / 32` (round up).

**Walls:** `_build_walls()` iterates `$Walls.get_children()`, reads each `CollisionShape2D`'s
`RectangleShape2D.size`, and attaches a `Sprite2D` via `PlaceholderArt.make_wall_texture(color, w, h)`
(running-bond brick pattern, sized at runtime). Wall color is `FLOOR_BASE_COLOR.darkened(0.35)` —
derived automatically, no separate const needed.

### Stealth & awareness
Enemy FSM opens with `PATROL → INVESTIGATE` before the combat loop. Key rules:

- **PATROL:** walks between randomized points within `patrol_radius` of `_home_position` at half speed.
- **Detection (`_can_see`):** vision-cone + LOS raycast. Distance ≤ `vision_range`, angle within `vision_angle_deg/2`, no wall obstruction, and `Player.is_hidden == false`. Alert fills toward `ALERT_THRESHOLD`; losing sight decays it. `SUSPICION_THRESHOLD` (~35%) → INVESTIGATE; `ALERT_THRESHOLD` (100%) → CHASE.
- **INVESTIGATE:** walks to last seen/heard position, lingers `INVESTIGATE_LOOK_DURATION`, then stands down to PATROL if alert drops below `SUSPICION_THRESHOLD`.
- **Noise:** `GameManager.emit_noise(position, radius)` / `noise_emitted` signal. `Player._enter_attack()` / `_enter_dash()` emit noise at 110px / 160px. Guards within `max(radius, hearing_range)` raise alert to at least `NOISE_ALERT_FLOOR` (40%) and investigate the source.
- **Hiding spots** (`scripts/systems/hiding_spot.gd`, no `class_name`): `Area2D` that sets `Player.is_hidden` while overlapping. Dims sprite to 55% alpha. One per level at `HIDING_SPOT_POS`.
- **Distraction:** `GameManager.calm_enemies(position, radius)` / `enemies_calmed` resets INVESTIGATE/CHASE guards back to PATROL. Erin's Special fires this at 130px. Twinkle's bark uses `emit_noise` to lure guards away.
- **Awareness telegraph:** Vision-cone wedge (`draw_colored_polygon`) + alert-meter arc rendered via `_draw()`, color-graded by alert level.
- **EnemyData tunables:** `vision_range` (170px), `vision_angle_deg` (100°), `hearing_range` (90px), `patrol_radius` (80px).

### Doorways, camera-follow & mid-level persistence
All 13 locations use three structural systems:

- **`Doorway`** (`scripts/systems/doorway.gd`, no `class_name`): arms after the active character walks `ARM_RADIUS` (96px) away from spawn; triggers exit when they return within `TRIGGER_RADIUS` (56px). Exit allowed at any time. Poll `doorway.check(player_pos)` from `_process` and call `_exit_to_overworld()` on `true`.
- **Camera follows active player:** `Camera2D` stays a level-root child (not reparented). `_setup_camera()` turns on `position_smoothing` and sets `limit_*` from `CAMERA_LIMIT_*` consts. `_process` sets `camera.global_position = GameManager.active_player.global_position` each frame.
- **Mid-level progress persistence:** `GameManager.level_progress: Dictionary` (`location_id → {flag: value}`). Use `get_level_flag(id, key, default)` / `set_level_flag(id, key, value)` (setter calls `SaveManager.save_game()`). `_restore_progress()` in `_ready()` reads flags back to skip re-spawning cleared enemies, restore solved-state sprites, and pass `already_open` to pre-open looted boxes.

### Bies Mode (`bies_mode.gd`)
Applies `Engine.time_scale = 0.4` for a brief window. Governs cooldown/charge. Emits
`bies_activated` / `bies_ended` for HUD and VFX.

### HUD
Per-character health, active duo display, Bies Mode charge, boss health bar.
Driven by signals from GameManager / players — never polls node internals.

### Co-op revive
A downed player is revived when their teammate stands within `REVIVE_RADIUS` (48px) for
`REVIVE_HOLD_DURATION` (1.5s). Revival restores HP to 50% and grants i-frames.
`Player._draw()` renders a radial progress-arc ring above the downed character's head.
If both are `DOWN` simultaneously → game over overlay → `get_tree().reload_current_scene()` on `ui_accept`.

### NPC dialog & quests
12 town NPCs are quest-givers (`npc_dialog/` for full writeups). Key systems:

- **`DialogBox`** (`scripts/ui/dialog_box.gd`, no `class_name`): `open(npc_name, portrait_color, tree, start_node, active_character)` walks a `DialogTree`. `advance()` pages, enters choice mode, or closes (emitting `closed(effects: Array)`).
- **Quest state machine:** `not_started → active → complete`, persisted at `GameManager.level_progress["town"]["quest_<id>"]` via `get_level_flag`/`set_level_flag(TOWN_ID, ...)`.
- **`QuestData`** (`scripts/systems/quest_data.gd`, `class_name`): `TOWN_ID`, `NPC_DATA`/`NPC_DATA_2`, `QUESTS`/`QUESTS_2`, `TOWN_QUEST_IDS`, `get_quest(id)`, `get_npc(id)`. Used by both `overworld_map.gd` and `achievement_manager.gd`.
- **Effects:** `_apply_dialog_effects(effects: Array)` — applied on `dialog_box.closed`, never mid-conversation. Handles `consume_item`, `grant_items`, `set_flag`.
- In-level NPCs (Hieronymus, Lena, Rio, Viktor, ARIA, Cyrus, Cecil/Usher) follow the same `DialogBox` / `effects` pattern with `_create_<npc>_npc()` / `_talk_to_<npc>()` / `_on_<npc>_dialog_closed()`.

### Dialog choices (DialogTree)
`scripts/systems/dialog_tree.gd` (no `class_name` — preload()+untyped var):

- A tree is `Dictionary[String, Dictionary]`, node id → node. Node has `lines`, optional `next` or `choices`, optional `effects`.
- A choice has `text`, optional `best_with` (character name), `next`/`next_alt`, optional `effects`.
- `from_pages(pages, last_node_effects = {})` — converts linear paged dialog to a tree.
- `resolve_choice(choice, active_character)` — returns `next_alt` if `best_with` doesn't match active character, else `next`.

### Quest Log
`scripts/ui/quest_log_overlay.gd` (no `class_name`, `extends CanvasLayer`, `layer = 26`).
Opened via Pause Menu → **"Quests"**. Only shows quests where `quest_<id> != "not_started"` (no spoilers).
Objective text is derived from `want_item`/`give_item` fields — no authored strings. Refreshes on `GameManager.level_flag_set`.

### Save / Unlock system
`save_manager.gd` (autoload `SaveManager`, loaded before `GameManager`) persists
`completed_locations` and `unlocked_characters` to `user://savegame.cfg` via `ConfigFile`.
`GameManager.complete_location(id)` appends the location, looks up `UNLOCKS_CHARACTER[id]`,
and calls `SaveManager.save_game()`. `SaveManager.load_game()` runs once on boot. Never store save state in scene nodes.

### Achievements
22-achievement tracker with pause-menu overlay (`AchievementsOverlay`, `layer = 26`) and
slide-in toast (`AchievementToast`, `layer = 20`). `AchievementManager` autoload (between
`SaveManager` and `GameManager`) connects to 12 `GameManager` signals to detect conditions.

| id | Name | Trigger |
|----|------|---------|
| `welcome_erin` | Reunited | `location_completed("pipe_organ_works")` |
| `welcome_evan` | Strength in Numbers | `location_completed("old_parish_church")` |
| `welcome_ben` | Encore | `location_completed("iron_strings_gym")` |
| `welcome_ethan` | Plug and Play | `location_completed("recording_studio")` |
| `tag_team` | Tag Team | `characters_swapped` |
| `first_blood` | First Blood | `enemy_defeated` |
| `boss_slayer` | Boss Slayer | `enemy_defeated(_, is_boss=true)` |
| `got_your_back` | Got Your Back | `player_revived` |
| `slow_your_roll` | Slow Your Roll | `bies_activated` (first time) |
| `loud_and_clear` | Loud and Clear | `noise_emitted` |
| `good_boy` | Good Boy! | `companion_summoned("frosty")` |
| `pack_rat` | Pack Rat | `item_collected` → total inventory ≥ 10 |
| `globetrotter` | Globetrotter | `completed_locations.size() >= 13` |
| `curtain_call` | Curtain Call | `location_completed("grand_marquee_cinema")` |
| `time_lord`* | Time Lord | `bies_activation_count >= 25` |
| `menagerie`* | Menagerie | all 5 companion types summoned |
| `secrets_out`* | Secret's Out | `level_flag_set(_, "secret_revealed", true)` |
| `complete_set`* | The Complete Set | all 12 `numbered_spoon_*` ids held |
| `friend_of_the_town`* | Friend of the Town | all 12 town quests `"complete"` |
| `arcade_discovered`* | Hidden Arcade | `spoon_arcade_entered` |
| `power_spoon_master`* | Power Trip | all 6 `SPOON_POWER_TYPES` used in Gimme Dat Spoon |
| `spoon_champion`* | Last Spoon Standing | `spoon_game_won` |

`*` = secret (shows as `"???"` until unlocked).

### Audio (autoload `Audio`)
`audio.gd` generates SFX procedurally at runtime as `AudioStreamWAV` buffers, cached by name.
Covers: attack, dash, special, hit, hurt, defeat, swap, bies, ui_move, ui_select. Call `Audio.play("name")`.
Music: `Audio.play_music("track_name")` — loads from `assets/music/<name>.ogg|wav` first (falling back to
procedural). Imported WAV files use IMA ADPCM (`compress/mode=2`); `loop_end` is set via
`int(s.get_length() * float(s.mix_rate)) - 1` (not raw byte math) to correctly loop any format.

### GUT unit tests *(configured — GUT v9.6.0)*
`addons/gut/` — pin to v9.6.0+ (v9.3.0 collides with Godot 4.6's native `Logger`).
Tests in `tests/unit/` are pure data/logic checks with no scene instantiation.

**Gotcha — fresh `class_name`s need an editor rescan** before resolving (both GUT addon scripts
and in-project scripts). Fix: `godot --headless --editor --path . --quit-after 2000` to populate
`.godot/global_script_class_cache.cfg`. Run once per machine/checkout.

---

## Input

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

Default keyboard: WASD + F (attack) + V (dash) + G (special) + Tab (swap) + B (Bies Mode). Gamepad bindings alongside each action.

---

## GDScript conventions

- `snake_case` — vars, functions, filenames. `PascalCase` — nodes, classes. `SCREAMING_SNAKE_CASE` — constants.
- **Static typing everywhere**: `var hp: int = 100`, typed function signatures.
- **Signals over polling**: connect with `signal.connect(callable)`.
- One responsibility per script/node; compose behavior from scenes.
- Tunables (speeds, damage, HP, wave config) in **exported vars or Resources**, never hard-coded magic numbers.
- `@onready` for node refs; avoid deep `get_node("../../..")` — prefer exported `NodePath`s or groups.
- Gameplay math in `_physics_process(delta)`; never assume a fixed FPS.

---

## Working with scenes

`.tscn`/`.tres` files are plain text — small, surgical edits by hand are fine.
For structural work (new nodes, reparenting, signal wiring), keep it consistent
with how the editor serializes, then reopen in the editor to confirm it's valid.

---

## Guardrails

- Original IP only — no licensed names, music, or assets. Imported assets are
  allowed as long as they are original (created for this project) or from a
  compatible open/free license (CC0, OFL, etc.). `PlaceholderArt` remains
  available as a fallback for anything not yet replaced with real art.
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
