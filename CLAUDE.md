# CLAUDE.md — Hunkle Bunkle

Project guidance for Claude Code. Auto-loaded as context. Keep it up to date as
the project evolves.

---

## Project overview

**Hunkle Bunkle** is a top-down adventure brawler built in **Godot 4.x with
GDScript**, now a **native 3D game** using Synty low-poly meshes directly
(`assets/models/…`, baked from the licensed packs in git-ignored `synty_source/`).
It combines environmental puzzle-solving with arcade-style beat-em-up combat
across 13 distinct locations + a walkable 3D Synty-city overworld.

> **⚠ NATIVE 3D — the 2D/2.5D pipeline is RETIRED (commit ~`b…`, "go all in on 3D").**
> The entire game now lives under `scripts/3d/` + `scenes/3d/` (`Camera3D`,
> `CharacterBody3D`, `Area3D`, glTF meshes). The old 2D scenes/scripts, the PIL
> pixel-sprite generators, the Synty *billboard* render pipeline, `PlaceholderArt`,
> and `assets/art/sprites/` were **deleted**. Do **not** recreate 2D level/player/
> enemy code. See `docs/3d_full_port_plan.md`.
>
> **Reusable 3D kit** (build new content from these): `Level3D` (env/floor/wall/
> box_mesh/prop/spawn_duo/spawn_enemy/spawn_npc/dialog/HUD/pause-stack/hiding-spot
> helpers), `Npc3D` (mesh + idle/walk + wander + speech bubble), `Duo3D` (both
> leads + swap + P2 co-op + Bies + revive + game-over), `Player3D`, `Enemy3D`
> (full stealth + combat FSM, boss AOE, ranged Sentry), `Combat3D`, `Projectile3D`,
> `AnimalCompanion3D`, `HidingSpot3D`, `camera_rig_3d`. Levels are built mostly
> from primitives (`box_mesh`) + a few committed prop GLBs; the overworld uses the
> City-pack town kit in `assets/models/town/` (baked via
> `synty_source/blender/scripts/export_prop.py`). Title/Result/Pause/overlays are
> shared `Control` UI on `CanvasLayer`s. `UITheme` (`scripts/ui/ui_theme.gd`,
> warm Synty skin from `assets/art/ui/`) + Nunito font remain the UI look.
>
> **Kept as the shared, render-agnostic core** (do not delete): autoloads
> (GameManager/SaveManager/AchievementManager/Audio/CombatFX/TransitionManager),
> Resource scripts (`CharacterData`, `EnemyData`, `ItemData`, `QuestData`,
> `DialogTree`, `AchievementData`, `SpoonGame`) + their `data/*.tres`, and the
> shared UI overlays (pause_menu, inventory/quest/achievement overlays, dialog_box).
> NOTE: GameManager still holds dead 2D `active_player`/revive/swap/bies code,
> kept compiling but untyped/null — the 3D build never runs it (Duo3D owns it).

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
| Frosty | Schnoodle (Schnauzer/Poodle mix) | White fur | **Combat distractor** — charges the nearest enemy, headbutts it to interrupt a windup/stagger it, then returns to Evan's side. **(in 3D)** |
| Calvin & Coolidge | Great Pyrenees (brothers) | Large, white | **Heavy muscle — always a pair**: charge/stagger the two nearest enemies. **(in 3D — Evan's Special summons one dog per nearby enemy, up to two.)** |
| Twinkle | Pomeranian | Small, blind, snaggle tooth, annoying bark | **Noise distraction** — trots out in Evan's facing, barks via `GameManager.emit_noise` to lure patrolling guards away. *(design; not yet ported to 3D)* |
| William & Mary | Rabbits | Quick, burrows (William) / Calm, good listener (Mary) | **Puzzle scouts — always a pair**: hold two positions to solve two-point puzzles. *(design; not yet ported)* |
| *(unnamed)* | Guinea pigs | Small, numerous, skittish | **Crowd cover** — a scurrying group that floods a floor, drawing every eye in the room (Erin's stealth sections). *(design; not yet ported)* |
| *(unnamed)* | Lizard | Cold-blooded, climbs | **Vertical-traversal scout** — scales walls/pipes to flip a switch or drop a rope; Ethan summons it in Zip Line Park / VR Escape Room. *(design; not yet ported)* |

**Animal companion (3D)** — `scripts/3d/animal_companion3d.gd` (`AnimalCompanion3D`, preload):
`CHARGE → STRIKE → RETURN`; STRIKE does a one-shot `Combat3D.strike` (damage + knockback that
staggers a windup). Evan's Special summons one dog per nearby enemy up to two (Frosty solo /
Calvin & Coolidge pair) — see `Player3D._summon_companion`, gated by a cooldown
(`GameManager.companion_cooldown_scale`). The other named companions (Twinkle/William&Mary/Lizard)
are puzzle-specific and not yet ported to 3D.

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
In 3D, levels place loot as a `box_mesh` crate and grant its item in `_on_special` (proximity +
`GameManager.grant_item`, set a persisted flag), then fall through to puzzle-gate checks — see
`pipe_organ_works3d.gd._loot_crate` / `_on_special` for the pattern.
**Gotcha:** `PauseMenu` looks up its overlays (Achievements/Inventory/QuestLog/toast) as siblings,
so they must all be created as direct children of the level root — done centrally in
`Level3D.build_ui_stack()` (every level + the overworld call it). A new overlay must be added there.

### Functional collectibles (gate or buff something)
| Item | Use |
|------|-----|
| Character movie ticket (×5 — one per character) | All five required to enter The Grand Marquee Cinema |
| Rusty key | Opens a shortcut door in the Underground Tunnels |
| Brass organ pipe | A finished Pipe Organ Works part — the **tuned** result of milling `rough_organ_pipe` (table saw → `cut_organ_pipe` → tuning bench). One of three parts fitted to the organ |
| Pipe Organ crafting parts | `rough_plank`→`windchest_board` (table saw); `rough_organ_pipe`→`cut_organ_pipe` (saw)→`brass_organ_pipe` (tuning bench); `gear_blank`→`trued_gear` (tuning bench). Raw + intermediate parts of the Pipe Organ Works gather→mill→assemble chain (`WorkStation3D`); each raw item's description hints its tool |
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

### Scale & meshes (3D)
- **World scale:** ~1 unit = 1 metre; characters ~1.7 m (capsule). Movement is on the
  **XZ ground plane** (`PX_PER_M = 32` converts the old px-based `*Data` stats to m/s).
- **Character/enemy meshes:** Synty glTF in `assets/models/characters|enemies/`.
- **Level geometry:** mostly primitives via `Level3D.box_mesh`/`floor_box`/`wall` + a few
  committed prop GLBs (`assets/models/props/`); the overworld uses the City town kit in
  `assets/models/town/`.
- **Viewport:** 1280×720

### Character stats *(starting values in the `CharacterData` `.tres`; tune there)*
*(Distances/speeds are stored in the original px units; the 3D code divides by `PX_PER_M = 32` → metres/(m/s) at runtime.)*

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
**Sentry** (`data/enemies/sentry.tres`, `is_ranged = true`): holds at long range, fires a `Projectile3D` (`scripts/3d/projectile3d.gd`, a moving `Area3D`) instead of a melee `Combat3D.strike`.
**Boss** (`data/enemies/boss.tres`, `is_boss = true`): `Enemy3D` adds `AOE_TELEGRAPH → AOE_SLAM` — an expanding translucent red ring mesh grows over `slam_telegraph_duration`, then one `Combat3D.strike` of `slam_radius` + screen shake; bosses commit (take damage during the wind-up, not interrupted). In Clocktower and Grand Marquee Cinema. (Mesh is currently a scaled/tinted grunt.)

### Bies Mode
- **Charges** as the active character deals damage — 10% charge per hit landed
- **Activates** at 100% charge via the `bies_mode` input
- **Effect:** `Engine.time_scale = 0.4` for 5 seconds, then snaps back to 1.0
- **HUD:** charge bar always visible; pulses when full

### Standby character (`Player3D` STANDBY_AI)
- Single-player: follows the active teammate (keeps a small gap), teleporting to their side past `LEASH` (~9 m). Co-op (any `p2_*` input seen): becomes player-2 controlled.
- Swap (Tab) is instant, no cooldown; `Duo3D` handles it and hands the camera to the new active body.

### Game flow & UI systems
- **Flow:** `Title3D` → `Overworld3D` → `*3D` level → (Esc/clear) → `Overworld3D`; endgame → `Result3D`.
- **Overworld** (`scenes/3d/Overworld3D.tscn`, `scripts/3d/overworld3d.gd`) — a walkable Synty city (City-pack road/building/prop GLBs in `assets/models/town/`). Duo walks the avenue; proximity to a building shows its name billboard + status and `G` enters that location's 3D scene (unlock-gated). 12 town NPC quest-givers are placed here too.
- **Combat polish** (`CombatFX` autoload): screen shake + hit-stop; enemies flash an overbright tint on hit and a red tint on windup. (The old 2D hit-spark particles don't render in 3D — a 3D `GPUParticles3D` spark is a candidate add.)

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

All 13 locations are fully implemented as native-3D scenes (`scenes/3d/*3D.tscn`,
`scripts/3d/*3d.gd`) on the shared `Level3D` kit, with stealth, camera follow, and mid-level
progress persistence. The per-location design (puzzles/NPCs/flags/duo) is captured in the
per-location subsections below.

**Puzzle-gate variety:** Most locations use a **proximity gate** (in-range + press Special = instant success).
Two diversify this:
- **Zip Line Park** — **timing gate**: a pulsing HUD bar (`_update_pulse_hud`); press Special (Ben) while it reads OPEN (`abs(sin(_pulse)) > PULSE_OPEN`).
- **Underground Tunnels** — **multi-step gate**: `HATCH_PRESSES_REQUIRED` (3) glowing pips (Ethan); each press fills one, persisted as the `hatch_progress` int.

Keep the baseline proximity gate as the default; use timing or multi-step only when the location's spec calls for that flavor.

**Lobby convention:** every level's **first room is "the lobby"** — it holds the level's
dialog NPC and the overworld exit portal, may contain puzzle parts / loot / props, but is
**combat-free**: spawn **no enemies** there. Combat belongs in the *later* rooms/floors, so
the player lands in a calm, talk-first space rather than getting jumped on entry. (Already
applied to the multi-floor levels: Clocktower lobby = Hieronymus only, enemies on floors 2–3;
Pipe Organ Works lobby = the Workshop with Bellows + the organ, enemies in the Storeroom / Pipe
Loft. Still-single-room levels inherit this as they're converted to multi-room.)

---

### 1. Bellows & Sons Pipe Organ Works — `PipeOrganWorks.tscn` (opening level)
- **Unlock condition:** Available from the start
- **Entering duo:** **Quinn ALONE.** Erin is *found* here, not pre-paired (see Notes).
- **Floor 1:** Lobby (Bellows + organ console; combat-free) · Storeroom (grunts + hidden Erin + the warped plank) · **Workshop** (the table saw + tuning bench) · stair alcove. **Floor 2:** Pipe Loft (out-of-tune pipe + gear blank; runners) + secret spare-gear nook.
- **Key puzzle(s):** A **gather → mill → assemble** crafting chain (uses the reusable `WorkStation3D` kit). Quinn collects three raw materials across both floors — `rough_plank` (Storeroom), `rough_organ_pipe` + `gear_blank` (Pipe Loft) — and processes them at the Workshop tools: **table saw** (`rough_plank`→`windchest_board`, `rough_organ_pipe`→`cut_organ_pipe`), **tuning bench** (`cut_organ_pipe`→`brass_organ_pipe`, `gear_blank`→`trued_gear`). The pipe needs **both** tools (saw *then* tune); each raw item's description hints which tool. Erin then fast-talks the `tuning_key` out of Bellows, which **unlocks the organ console** (ASSEMBLY) so Quinn can fit the three finished parts (`windchest_board` + `brass_organ_pipe` + `trued_gear`).
- **Enemy types:** Grunts (Storeroom) + Runners (Pipe Loft)
- **Level progress flags:** `enemies_cleared` / `organ_repaired` / `secret_revealed` / `manager_met` / `tuning_key_given` / `erin_recruited` / `plank_taken` / `pipe_taken` / `gear_taken` / `organ_part_<id>` / `gear_bonus_open`
- **NPCs:** Mr. Bellows (dialog-choice, at his desk in the Lobby) — his opening line sends Quinn after Erin ("punks chased her into the back storeroom"); the tuning-key fast-talk choice only appears after Erin is recruited.
- **Notes:** **Erin recruit beat** — Quinn starts solo; clearing the Storeroom grunts makes Erin step out from behind the crates and *join the party* mid-level (`Duo3D.add_member` — Tab swap "wakes up" once there are two bodies). She explains she was tracking a lead on Uncle Doug. Secret lever in the loft reveals the bonus `spare_clockwork_gear`. Win = enemies cleared (Storeroom + Loft) + organ repaired.

---

### 2. The Old Parish Church — `OldParishChurch.tscn`
- **Unlock condition:** Complete Bellows & Sons
- **Unlocks:** Evan
- **Key puzzle(s):** Quinn's respectful demeanor earns the congregation's trust; Erin's skepticism lets her see through deception — neither can solve it alone
- **Enemy types:** None (dialogue-heavy)
- **Level progress flags:** `quinn_done` / `erin_done` / `secret_revealed` / `father_aldric_impression`
- **NPCs:** Father Aldric (dialog-choice NPC at the altar; `father_aldric_impression` → `"good"` / `"cool"`)

---

### 3. Iron & Strings Gym — `IronStringsGym.tscn`
- **Unlock condition:** Complete The Old Parish Church
- **Unlocks:** Ben
- **Key puzzle(s):** Evan's strength moves the barbell sealing Ben's cage alcove
- **Enemy types:** Grunts + Brutes
- **Level progress flags:** `enemies_cleared` / `barbell_moved`

---

### 4. The Recording Studio — `RecordingStudio.tscn`
- **Unlock condition:** Complete Iron & Strings Gym
- **Unlocks:** Ethan
- **Key puzzle(s):** Ben tunes the soundboard console, sliding open the glass BoothDoor and revealing Ethan
- **Enemy types:** Grunts + Runners
- **Level progress flags:** `enemies_cleared` / `console_tuned`

---

### 5. The Clocktower — `Clocktower.tscn`
- **Unlock condition:** All five characters unlocked
- **Key puzzle(s):** Quinn repairs the gear floor escapement; Ben plays the correct belfry bell sequence (tuning fork item helps); clockwork-guardian Boss guards the stairs
- **Enemy types:** Grunts + Boss (clockwork guardian)
- **Level progress flags:** `enemies_cleared` / `gear_repaired` / `bells_played`
- **NPCs:** Hieronymus (stationary on landing floor)

---

### 6. The Harbor & Docks — `HarborDocks.tscn`
- **Unlock condition:** All five characters unlocked (opens alongside Clocktower)
- **Key puzzle(s):** Evan (or crowbar item) moves the cargo container blocking the crane platform; Calvin & Coolidge combat assist; Viktor's manifest confirms Doug's name on the shipment
- **Enemy types:** Grunts (dock workers) + Runners (smugglers)
- **Level progress flags:** `enemies_cleared` / `container_moved`
- **NPCs:** Viktor (harbourmaster, stationary near pier entrance)

---

### 7. The Public Library & Archive — `LibraryArchive.tscn`
- **Unlock condition:** TBD
- **Key puzzle(s):** Erin talks her way past the librarian (or library card item bypasses the desk); Ethan hacks the restricted archive terminal
- **Enemy types:** Grunts + Sentry (ranged)
- **Level progress flags:** `enemies_cleared` / `librarian_talked` / `archive_hacked`

---

### 8. The Carnival & Fairground — `Carnival.tscn`
- **Unlock condition:** TBD
- **Key puzzle(s):** Quinn repairs the broken ride; Erin talks down the backstage gate (or backstage pass item skips the guard conversation)
- **Enemy types:** Grunts ×2 + Brute
- **Level progress flags:** `enemies_cleared` / `ride_repaired` / `backstage_talked`

---

### 9. The Underground Tunnels — `UndergroundTunnels.tscn`
- **Unlock condition:** TBD
- **Key puzzle(s):** Evan clears west rubble (proximity gate); Ethan hacks east hatch (multi-step, 3 pips); Twinkle bark distraction; rusty key opens a shortcut door
- **Enemy types:** Grunts ×2 + Runner (patrol-style)
- **Level progress flags:** `enemies_cleared` / `rubble_cleared` / `hatch_progress` (int 0–3, persists partial hack)
- **NPCs:** Cyrus (tunnel maintainer, stationary at junction chamber)

---

### 10. Zip Line Park — `ZipLinePark.tscn`
- **Unlock condition:** TBD
- **Key puzzle(s):** Ethan hacks the Mid Platform control panel (proximity); Ben catches the timed High Platform release window (timing gate)
- **Enemy types:** Grunt + Runners ×2
- **Level progress flags:** `enemies_cleared` / `panel_hacked` / `release_timed`
- **NPCs:** Lena (safety warden, stationary on Landing platform)

---

### 11. VR Escape Room — `VrEscapeRoom.tscn`
- **Unlock condition:** TBD
- **Key puzzle(s):** Quinn repairs physics-glitch node in Stage Alpha; Ethan hacks system console in Stage Beta; Lizard companion offers an alternate bypass route
- **Enemy types:** Grunts ×2 + Sentry (glitchy/corrupted)
- **Level progress flags:** `enemies_cleared` / `glitch_repaired` / `system_hacked`
- **NPCs:** ARIA (virtual assistant, stationary in Boot Chamber)

---

### 12. The Drop — `TheDrop.tscn`
- **Unlock condition:** Late-game, after a credible lead on Uncle Doug's location
- **Key puzzle(s):** Evan clears landing-site wreckage (or William & Mary two-point puzzle); Ethan hacks jammed chute release in Snag Grove; Rio confirms the marquee sign points to the endgame
- **Enemy types:** Grunt + Runner + Brute (hostile ground crew)
- **Level progress flags:** `enemies_cleared` / `chute_hacked` / `landing_cleared`
- **NPCs:** Rio (ex-crew, stationary in Touchdown Clearing)

---

### 13. The Grand Marquee Cinema — `GrandMarqueeCinema.tscn` (endgame)
- **Unlock condition:** Complete The Drop; all five characters + all five movie tickets required
- **Key puzzle(s):** Quinn repairs the projection booth; Ben plays the house organ on the Balcony; Boss guards the Backstage aisle; Uncle Doug found in the projection booth
- **Enemy types:** Grunts ×2 + Boss (cinema guardian)
- **Level progress flags:** `enemies_cleared` / `projector_repaired` / `organ_played`
- **NPCs:** Cecil / Usher (chief usher, dialog-choice tree, stationary in Lobby)
- **Notes:** Win needs enemies cleared + projector + organ + **all 5 tickets** → Uncle Doug is revealed in the booth and `_win` routes to `Result3D.tscn` after a beat. Completion id is `"grand_marquee"`.

```
Location template:
- Name:
- Scene/script: (scenes/3d/<Name>3D.tscn / scripts/3d/<name>3d.gd)
- Unlock condition:
- Unlocks: (character, if applicable)
- Key puzzle(s): (which character's ability gates each)
- Enemy types:
- Level progress flags:
- NPCs: (if any)
- Notes:
```

---

## Tech stack & targets

- **Engine:** Godot 4.x (confirm with `godot --version`; prefer 4.3+ APIs). Use GDScript 2.0 idioms.
- **Rendering:** **native 3D** — `Node3D`/`CharacterBody3D`/`Area3D`, Synty glTF
  meshes, a fixed 3/4 follow `Camera3D` (`camera_rig_3d`, re-framable; pulled back
  for the overworld). Top-down brawler readability is preserved by the fixed angle
  + ground-plane (XZ) movement. Boot flow: `Title3D` → `Overworld3D` (walkable
  Synty city) → `*3D` level → back; endgame → `Result3D`.
- **Platforms:** Desktop — Windows, macOS, Linux.

---

## Running, building, testing

```bash
# Run the project
godot --path .

# Run a single scene (e.g. a level directly, skipping the title/overworld)
godot --path . res://scenes/3d/IronStringsGym3D.tscn

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
scenes/3d/        Title3D, Overworld3D, Result3D, Spoon3D + one *3D.tscn per location
scripts/3d/       level3d, overworld3d, title3d, result3d, <location>3d (×13),
                  player_3d, duo3d, enemy_3d, combat3d, projectile3d, camera_rig_3d,
                  npc3d, animal_companion3d, hiding_spot3d, spoon3d
  ui/             ui_theme, dialog_box, pause_menu, inventory/quest/achievement
                  overlays, how_to_play_overlay, ui_factory  (shared Control UI)
  systems/        item_data, dialog_tree, quest_data, achievement_data, spoon_game
                  (Resource/shared logic — render-agnostic)
  players/        character_data.gd   (CharacterData Resource only)
  enemies/        enemy_data.gd       (EnemyData Resource only)
  autoload/       game_manager, save_manager, achievement_manager, audio,
                  combat_fx, transition_manager, …
data/
  characters/   quinn.tres … ethan.tres   enemies/  grunt … boss.tres   items/  *.tres
assets/
  models/       characters/ enemies/ props/ town/  (Synty glTF)
  art/ui/  fonts/  music/  sfx/
addons/         gut/ (vendored GUT v9.6.0+)
tests/unit/     test_character_data, test_enemy_data, test_unlock_chain, test_stealth_fsm, …
```

---

## Architecture & key systems

### GameManager (autoload)
Owns global state: current location, unlocked characters, active duo, score,
game over / victory. Spawns levels and broadcasts via signals. Never let scenes
reach up into GameManager's internals — use signals.

### Player3D (`CharacterBody3D`) — `scripts/3d/player_3d.gd`
One lead body; `Duo3D` owns two and swaps which is active. XZ-plane `move_and_slide`.
- `mode` selects the input source: ACTIVE (player 1), STANDBY_P2 (co-op), STANDBY_AI
  (follows the active teammate with a leash-teleport).
- `_attack` opens a `Combat3D.strike` (and emits noise); `bies_charge` +0.1 per landed hit.
- HP→0 **downs** the body (revivable, not dead); `is_hidden` is set by hiding spots.
- Character-specific stats/abilities live in a `CharacterData` Resource — no per-character
  code forks in `player_3d.gd`. (`PX_PER_M = 32` converts the px-based stats to m/s.)

### Enemy3D (`CharacterBody3D`) — `scripts/3d/enemy_3d.gd`
Full FSM: `PATROL → INVESTIGATE → CHASE → WINDUP → STRIKE → RECOVER → HIT` (plus
`AOE_TELEGRAPH`/`AOE_SLAM` for Boss; ranged Sentry fires `Projectile3D` from STRIKE).
Bosses skip straight to `CHASE` — known confrontations, not sneak-past targets.
Windup **must telegraph** (anim + red tint) before a strike. `mesh_scale`/`mesh_tint`
make a Brute/Boss a larger, darker grunt. Enemies join the `enemy3d` group.

### Combat3D — `scripts/3d/combat3d.gd`
`Combat3D.strike(node, world_pos, radius, mask, on_hit, life)` spawns a one-shot `Area3D`
that overlaps targets on the given layer (`L_WORLD=1` / `L_PLAYER=2` / `L_ENEMY=4`) and
calls `on_hit(body)`. Damage resolution applies knockback + hit-flash; `CombatFX` adds
screen-shake / hit-stop.

### Spawning + win conditions
Levels spawn enemies directly in `_build_level` via `Level3D.spawn_enemy(data, pos, mesh,
scale, tint)` (no wave system — small fixed encounters per room) and poll
`enemies_alive()`. Puzzle state is tracked inline per level as `GameManager` level-flags
(`set_level_flag`/`get_level_flag`), keyed by ability via the `_on_special(char_name)`
ladder (e.g. only Quinn repairs, only Ethan hacks), so the win check ANDs "enemies cleared"
with the level's puzzle flags.

### Crafting / interaction stations (`WorkStation3D`)
`scripts/3d/work_station3d.gd` (`WorkStation3D`, no `class_name` — `preload()`) is a
reusable `Area3D` interaction node for **gather → process → assemble** puzzles (debut:
Pipe Organ Works). Three `Kind`s configured via `setup(kind, pos, label, best_with)`:
- **SOURCE** — a raw-material crate: grants `produces` once, then dims.
- **TOOL** — a workbench: each `recipes` entry `{"in": id, "out": id}` consumes a carried
  input → grants the output. Multiple recipes per tool (the table saw cuts both plank and
  pipe); chains form when one tool's output is another tool's input.
- **ASSEMBLY** — a fixture: consumes the finished `parts` set as they're brought; emits
  `completed` when all are in.
Built via `Level3D.add_station(kind, pos, label, best_with)` (mirrors `add_hiding_spot`).
Input stays on the level's existing Special hook: the level keeps a `_stations` array and
in `_on_special` calls `st.try_use(char_name, player.global_position)` — the station does
the range + `best_with` + item checks (via `GameManager.has_item/grant_item/consume_item`)
and owns its marker mesh + floating `Label3D` prompt. Signals: `produced(id)`, `completed`,
`message(text)` (wire to the level's HUD hint). Persist with level flags + `restore_taken()`
/ `restore_part(id)` in `_restore`. Gate a station behind a flag by skipping its `try_use`
in `_on_special` (e.g. the organ stays locked until `tuning_key_given`).

### Mid-level party recruit (`Duo3D.add_member`)
`Duo3D` tolerates a **single-body** party (swap is guarded by `bodies.size() > 1`; a lone
body down → game over), so a level can `spawn_duo([QUINN], …)` and grow the party later.
`Duo3D.add_member(data, at)` builds a `Player3D` body, wires its `special_used`, appends it,
and re-applies roles (newcomer = standby AI-follow); **Tab swap "wakes up" automatically**
once there are two bodies. Used for the Erin "found in the Storeroom" beat in Pipe Organ
Works — persist with an `erin_recruited` flag and re-recruit silently in `_restore`.

### Building level geometry (3D)
Levels subclass `Level3D` and build their space in `_build_level()` from helpers:
`build_env(bg, ambient, …)` (sun + WorldEnvironment), `floor_box(w, d, col)`,
`wall(center, size, col)`, `box_mesh(size, col, ofs, emissive)` for primitive props,
and `prop(path, pos, yaw, scale)` for committed GLBs. Theme per location with light
colours + a small palette; dress with primitives and the prop GLBs. Collision uses 3D
layers from `Combat3D` (`L_WORLD=1`, `L_PLAYER=2`, `L_ENEMY=4`). See the existing
`scripts/3d/*3d.gd` for patterns (e.g. the organ/gear/carousel built from cylinders+boxes).

### Stealth & awareness
Enemy FSM opens with `PATROL → INVESTIGATE` before the combat loop. Key rules:

- **PATROL:** walks between randomized points within `patrol_radius` of `_home_position` at half speed.
- **Detection (`_can_see`):** vision-cone + LOS raycast. Distance ≤ `vision_range`, angle within `vision_angle_deg/2`, no wall obstruction, and `Player.is_hidden == false`. Alert fills toward `ALERT_THRESHOLD`; losing sight decays it. `SUSPICION_THRESHOLD` (~35%) → INVESTIGATE; `ALERT_THRESHOLD` (100%) → CHASE.
- **INVESTIGATE:** walks to last seen/heard position, lingers `INVESTIGATE_LOOK_DURATION`, then stands down to PATROL if alert drops below `SUSPICION_THRESHOLD`.
- **Noise:** `GameManager.emit_noise(pos, radius)` / `noise_emitted` (positions passed as XZ `Vector2`, metres). `Player3D._attack` emits noise; guards within `max(radius, hearing_range)` raise alert to at least `NOISE_ALERT_FLOOR` (40%) and investigate.
- **Hiding spots** (`scripts/3d/hiding_spot3d.gd`, `HidingSpot3D`): an `Area3D` that sets `Player3D.is_hidden` while a body overlaps (suppresses sight; noise still gives you away). `Level3D.add_hiding_spot(pos)`; placed in Underground/Library/VR.
- **Distraction:** `GameManager.calm_enemies(pos, radius)` / `enemies_calmed` resets INVESTIGATE/CHASE guards to PATROL. Erin's Special fires this (130px ≈ 4 m).
- **Awareness telegraph:** a flat translucent vision-cone **sector mesh** on the ground, rotated to the guard's facing and graded yellow→red by alert (hidden once chasing).
- **EnemyData tunables:** `vision_range` (170px), `vision_angle_deg` (100°), `hearing_range` (90px), `patrol_radius` (80px).

### Doorways, camera-follow & mid-level persistence
All 13 locations use three structural systems:

- **Exit to overworld:** press **Esc** → the shared Pause menu (`Level3D.build_ui_stack`) → **Quit to Map** returns to `Overworld3D`. (The old Doorway return-to-spawn system is retired.)
- **Camera follows active body:** `camera_rig_3d` (`Camera3D`) stays a level-root child, smoothly follows the active duo body at the fixed 3/4 angle; `reframe(dist, elev)` pulls it back for the overworld.
- **Mid-level progress persistence:** `GameManager.level_progress: Dictionary` (`location_id → {flag: value}`). Use `get_level_flag(id, key, default)` / `set_level_flag(id, key, value)` (setter auto-saves). Each level's `_restore()` reads flags back in `_build_level` to skip cleared enemies, show solved-state, and re-grant looted items.

### Bies Mode (`Duo3D` / `Player3D`)
Applies `Engine.time_scale = 0.4` for a brief window. Governs cooldown/charge. Emits
`bies_activated` / `bies_ended` for HUD and VFX.

### HUD
Each 3D level builds a lightweight HUD in its own `_build_hud` (a goal line + a transient
hint line + a centre banner, via `Level3D.hud_label`/`make_hud_layer`), plus the shared
**Bies charge bar** (`Level3D._build_bies_bar`, bottom-centre, fills/pulses gold). Per-character
health bars + a boss health bar aren't built yet — a candidate HUD upgrade.

### UI skin — UITheme + Nunito font (cozy-warm Synty)
`scripts/ui/ui_theme.gd` (`class_name UITheme`) is the global UI look: a code-built warm
palette (gold/cream on dark-brown panels) skinned from Synty ApocalypseHUD sprites
(`assets/art/ui/`, copied by `synty_source/blender/scripts/copy_ui_sprites.sh`). The
global font is **Nunito SemiBold** (`assets/fonts/Nunito-SemiBold.ttf`, OFL), set via
`project.godot` `gui/theme/custom_font` — **not** the old PressStart2P pixel font.
Use these instead of re-deriving styles:
- Control-based UI: `theme = UITheme.get_theme()` on a root → Buttons/Labels/Panels/
  ProgressBars restyle. Per-character health bar: `bar.add_theme_stylebox_override("fill", UITheme.bar_fill_box(color))`.
- `_draw` overlays: `UITheme.panel_box().draw(get_canvas_item(), rect)` for the warm box,
  `UITheme.draw_frame(self, rect, UITheme.GOLD, "simple"|"med")` for the decorative border.
- Hand-drawn text: `UITheme.font()` (not `ThemeDB.fallback_font`) so it matches themed Controls.
- Input prompts: `UITheme.draw_glyph(ci, rect, action, ...)` in `_draw`, or
  `UITheme.make_glyph_control(action, px)` in the Control tree (key sprite + letter;
  letter keys F/G/V/B/WASD composite on the blank key, Tab/Enter/arrows are dedicated sprites).
Palette consts (`GOLD`, `CREAM`, `TEXT`, `ACCENT`, `PANEL_BG`, …) are the single source of UI colour.

### Co-op revive + game over (`Duo3D._tick_revive`)
A downed body (HP→0; mesh crumples) is revived when the upright teammate stands within
`REVIVE_RADIUS` (~2 m) for `REVIVE_HOLD` (1.5 s) — restores HP to 50% + brief i-frames.
If the *active* body goes down, control auto-swaps to the upright partner. Both down →
"BOTH DOWN — Press Enter to retry" overlay → `get_tree().reload_current_scene()` on `ui_accept`.

### NPC dialog & quests
12 town NPCs are quest-givers (full roster + dialog in `QuestData`, `scripts/systems/quest_data.gd`). Key systems:

- **`DialogBox`** (`scripts/ui/dialog_box.gd`, no `class_name`): `open(npc_name, portrait_color, tree, start_node, active_character)` walks a `DialogTree`. `advance()` pages, enters choice mode, or closes (emitting `closed(effects: Array)`).
- **Quest state machine:** `not_started → active → complete`, persisted at `GameManager.level_progress["town"]["quest_<id>"]` via `get_level_flag`/`set_level_flag(TOWN_ID, ...)`.
- **`QuestData`** (`scripts/systems/quest_data.gd`, `class_name`): `TOWN_ID`, `NPC_DATA`/`NPC_DATA_2`, `QUESTS`/`QUESTS_2`, `TOWN_QUEST_IDS`, `get_quest(id)`, `get_npc(id)`. Used by both `overworld3d.gd` and `achievement_manager.gd`.
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

- Original IP for **names, story, characters, music** — no licensed/brand names.
- **Art assets:** the look is **Synty low-poly 3D**, built from the licensed Synty
  POLYGON packs the project owns (raw FBX/textures staged in git-ignored `synty_source/`;
  baked glTF meshes committed under `assets/models/`). Bake new static meshes with
  `synty_source/blender/scripts/export_prop.py` (per-pack scale gotcha: City = metres,
  Town = cm). Original art and CC0/OFL assets are also fine. **Not** retro/pixel-art and
  **not** 2.5D billboards — both pipelines are retired (see Project overview).
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
