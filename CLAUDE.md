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
| Pocket lantern | **Entry gate** for the Underground Tunnels — now in a Harbor & Docks **manifest locker** (Evan forces it, or Quinn dials it after the crane lifts the manifest); you must carry it to descend (the overworld blocks the door without it) |
| Boiler key | Found by Quinn turning the **Iron & Strings Gym** boiler valve; opens the optional Harbor & Docks supply storeroom (bonus loot) |
| Archive key | Wound from the **Clocktower** weight-crank cabinet (Quinn sequence); opens the optional Library & Archive locked stack (→ VR override chip) |
| Faded photograph | Lore pickup (Underground Tunnels) — short Uncle Doug clue dialogue, no mechanical gate |
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

### Uncle Doug clue trail (one per level — `doug_*` `ItemData`)
Each location yields a tangible Uncle-Doug clue via a small themed objective; the clues
converge on the Grand Marquee Cinema (the endgame). Granted by the level's `_on_special`
ladder, persisted with a per-level flag. (See `docs/level_elaboration_plan.md` §3.)
| Item | Where / how |
|------|-------------|
| Faded photograph | Underground — Depth-2 storeroom loot |
| `pressed_flower` | Old Parish Church — vestry memorial register (after Quinn's candle sequence) |
| `doug_locker_tag` | Iron & Strings Gym — Evan forces Doug's locker (lobby) → "HARBOR" |
| `doug_recording` | Recording Studio — Ben plays Doug's reel (cut-off message) |
| `doug_pocketwatch` | Clocktower — Quinn winds the watch (workshop) → "the Marquee" |
| `doug_crate_tag` | Harbor & Docks — crane lifts the manifest crate → routing to the picture house |
| `doug_checkout_card` | Library & Archive — Ethan hacks the archive → "Grand Marquee — projection schematics" |
| `doug_photo_strip` | Carnival — Quinn fixes the photo booth → Doug holding a Grand Marquee ticket |
| `doug_flashlight` | Underground — opening the sealed vault → "Find me at the pictures. — D." |
| `doug_carabiner` | Zip Line Park — Ben times the snagged clue bag → map ringed on the Marquee |
| `doug_vr_log` | VR Escape Room — Quinn+Ethan co-solve the firewall → Doug's avatar in a rendered cinema |
| `doug_flyer` | The Drop — Ethan re-aims the signal dish → "THE GRAND MARQUEE… come find me" |

The trail is **assembled at the Grand Marquee lobby clue-board** (level 13) — a collection
check that tallies all twelve `doug_*`/lore clues for the final reveal beat.

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
- **Overworld** (`scenes/3d/Overworld3D.tscn`, `scripts/3d/overworld3d.gd`) — a walkable Synty city laid out as a **stacked-boulevard grid**: 3 rows of buildings (`SLOTS`/`COL_X`/`ROW_Z`) **all facing +Z** (the camera is locked looking −Z, so every building faces it — no more per-building yaw guessing), each fronted by an E-W boulevard (`BLVD_Z`) with N-S cross-streets (`CROSS_X`); a **central park** (`_park()` — grass, fountain, gazebo, pond, tree ring, benches, lamps, flower beds, baked from Town/Kids env meshes) fills the middle slot where the 12 NPC quest-givers cluster; `_foliage()` scatters trees/bushes/flowers along the medians. Proximity to a building shows its name billboard + status and `G` enters that location's 3D scene (unlock-gated via each `LOCS` entry's `req` = a completed-location id). The strolling duo is drawn from `GameManager.unlocked_characters` (first two, in unlock order — so Quinn walks alone at the start). Some locations also need an **item in hand** (`ITEM_GATE`, checked across all characters): the Underground Tunnels need the `pocket_lantern` (the door shows a "you'll need a lantern (try the Harbor & Docks)" hint until you carry one). 12 town NPC quest-givers are placed here too — they **wander a small loop** (`Npc3D` waypoints) and bark idle **speech bubbles** (`TOWN_QUIPS`), with a **static one-at-a-time bark gate** in `npc3d.gd` (`_last_bark_ms` / `BARK_GAP_MS`) so the crowd never talks over itself; the NPC nearest the player is `paused` so it holds still to be talked to, and `_nearest_npc` measures the **live** node position (not the spawn point). Per-location buildings are **thematic whole-mesh Synty meshes** (`LOCS[i]["glb"]` in `assets/models/town/`), baked via `export_prop.py`: church, CityHall=library, WaterTower=clocktower, Warehouse=harbor, Chopshop=the_drop, market-stall=carnival, SciFiCity FoodHole=arcade, City OfficeOld_Large=cinema. **Gotchas:** (1) per-pack scale — `export_prop` clobbers the FBX import unit-scale, so cm packs need `--scale 0.01` (some meshes are authored tiny and need ~0.55–0.7); (2) **facing** — the overworld camera always looks −Z, so a building's *front must face +Z*; `LOCS` entries take an optional `yaw` (and `BLD_SCALE`) override since each mesh's native front differs. Modular kit-bash (`synty_source/blender/scripts/assemble_building.py`) exists but the **Casino pack uses external tiling textures that don't resolve to a single atlas**, so those assemblies came out mis-textured — whole-mesh is the reliable path. See `docs/overworld_building_themes.md`.
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

> **Elaboration pass (COMPLETE — all 13 levels; see `docs/level_elaboration_plan.md`):**
> every level is multi-room with `corridor()`s, per-room thematic tiling surfaces +
> solid-colour corner trim (VR keeps its emissive neon-grid look), extra theme-keyed
> puzzles, and a per-level Uncle-Doug clue (the `doug_*` trail, paid off at the Grand
> Marquee clue-board). Each level keeps its original win condition; new puzzles are mostly
> optional/bonus, and each new puzzle is assigned to an ability **in that level's duo**
> (so some plan-doc assignments were reassigned — e.g. Harbor's "Ethan/Erin" steps went to
> Quinn/Evan). Cross-level keys are *mostly optional shortcuts + a few required gates*
> (`pocket_lantern`, the 5 tickets, `rusty_key`).

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

### 1. Bellows & Sons Pipe Organ Works — `PipeOrganWorks3D.tscn` (opening level)
- **Unlock condition:** Available from the start
- **Entering duo:** **Quinn ALONE.** Erin is *found* here, not pre-paired (see Notes).
- **Floor 1:** Lobby (Bellows + organ console; combat-free) · Storeroom (grunts + hidden Erin + the warped plank) · **Workshop** (the table saw + tuning bench) · stair alcove. **Floor 2:** Pipe Loft (out-of-tune pipe + gear blank; runners) + secret spare-gear nook.
- **Key puzzle(s):** A **gather → mill → assemble** crafting chain (uses the reusable `WorkStation3D` kit). Quinn collects three raw materials across both floors — `rough_plank` (Storeroom), `rough_organ_pipe` + `gear_blank` (Pipe Loft) — and processes them at the Workshop tools: **table saw** (`rough_plank`→`windchest_board`, `rough_organ_pipe`→`cut_organ_pipe`), **tuning bench** (`cut_organ_pipe`→`brass_organ_pipe`, `gear_blank`→`trued_gear`). The pipe needs **both** tools (saw *then* tune); each raw item's description hints which tool. Erin then fast-talks the `tuning_key` out of Bellows, which **unlocks the organ console** (ASSEMBLY) so Quinn can fit the three finished parts (`windchest_board` + `brass_organ_pipe` + `trued_gear`).
- **Enemy types:** Grunts (Storeroom) + Runners (Pipe Loft)
- **3D build:** reference for the multi-room kit — rooms joined by `corridor()`s with solid-colour corner posts; **per-room thematic surfaces** (marble lobby / wood workshop / concrete service corridors / tile-stone loft) via `set_theme`; Quinn also flips a breaker sequence to power the workshop tools. **Secret-nook fix:** the loft now has a real `"n"` doorway the removable panel fills (it used to "open" behind a second solid wall) — the spare-gear nook is reachable.
- **Level progress flags:** `enemies_cleared` / `organ_repaired` / `secret_revealed` / `manager_met` / `tuning_key_given` / `erin_recruited` / `plank_taken` / `pipe_taken` / `gear_taken` / `organ_part_<id>` / `gear_bonus_open`
- **NPCs:** Mr. Bellows (dialog-choice, at his desk in the Lobby) — his opening line sends Quinn after Erin ("punks chased her into the back storeroom"); the tuning-key fast-talk choice only appears after Erin is recruited.
- **Notes:** **Erin recruit beat** — Quinn starts solo; clearing the Storeroom grunts makes Erin step out from behind the crates and *join the party* mid-level (`Duo3D.add_member` — Tab swap "wakes up" once there are two bodies). She explains she was tracking a lead on Uncle Doug. Secret lever in the loft reveals the bonus `spare_clockwork_gear`. Win = enemies cleared (Storeroom + Loft) + organ repaired.

---

### 2. The Old Parish Church — `Church3D.tscn`
- **Unlock condition:** Complete Bellows & Sons
- **Unlocks:** Evan
- **Key puzzle(s):** Quinn's respectful demeanor earns the congregation's trust; Erin's skepticism lets her see through deception — neither can solve it alone
- **Enemy types:** None (dialogue-heavy)
- **3D build:** multi-room — NAVE (lobby: Aldric + 4 congregants + choir leader + exit) → corridor → **VESTRY** (Quinn lights the candle sconces 1→2→3 → opens it; holds the memorial register = Doug objective) and → **CRYPT** (Erin spots the forged plaque among three → opens it). Church/marble + stone surfaces, dark-wood trim. Doug clue: `pressed_flower` from the register.
- **Level progress flags:** `quinn_done` / `erin_done` / `secret_revealed` / `father_aldric_impression` / `manager_met` / `candles_lit` / `register_read`
- **NPCs:** Father Aldric (dialog-choice NPC at the altar; `father_aldric_impression` → `"good"` / `"cool"`)

---

### 3. Iron & Strings Gym — `IronStringsGym3D.tscn`
- **Unlock condition:** Complete The Old Parish Church
- **Unlocks:** Ben
- **Key puzzle(s):** Evan's strength moves the barbell sealing Ben's cage alcove
- **3D build:** multi-room — combat-free LOBBY (clerk Marv + exit + Doug's locker) → WEIGHT FLOOR (combat + barbell/Ben) → BOILER ROOM (east). Evan jams the **pressure plate** to hold the boiler gate open; Quinn turns the **boiler valve** → `boiler_key`; Evan forces **Doug's locker** → `doug_locker_tag`. Concrete/steel surfaces.
- **Enemy types:** Grunts + Brute (weight floor only)
- **Level progress flags:** `enemies_cleared` / `barbell_moved` / `boiler_gate_open` / `boiler_key_taken` / `locker_opened` / `marv_met`
- **NPCs:** Marv (front-desk clerk, lobby)

---

### 4. The Recording Studio — `RecordingStudio3D.tscn`
- **Unlock condition:** Complete Iron & Strings Gym
- **Unlocks:** Ethan
- **Key puzzle(s):** Ben tunes the soundboard console, sliding open the glass BoothDoor and revealing Ethan
- **3D build:** multi-room — combat-free LOBBY (producer Sasha + exit) → LIVE ROOM (combat + Doug's reel + feedback panel) → CONTROL ROOM (booth + console + patch bay). Quinn **repairs the patch bay** to power the dead console (gate before Ben tunes); Ben **plays Doug's reel** → `doug_recording`; Ben **silences the feedback** → `backstage_pass` (optional). Freeing Ethan also grants `sheet_music_page`. Carpet/concrete surfaces.
- **Enemy types:** Grunts + Runners (live room only)
- **Level progress flags:** `enemies_cleared` / `console_tuned` / `patch_repaired` / `reel_played` / `feedback_silenced` / `sasha_met`
- **NPCs:** Sasha (producer, lobby)

---

### 5. The Clocktower — `Clocktower3D.tscn`
- **Unlock condition:** All five characters unlocked
- **Key puzzle(s):** Quinn repairs the gear floor escapement (unbars the belfry stair); Ben plays the correct belfry bell sequence; clockwork-guardian Boss guards the belfry
- **3D build:** 3 floors. New: Ben **times the swinging pendulum** in the antechamber to still it + lift a gate to the belfry (timing gate, live HUD); Quinn winds the **weight cranks 1→2→3** → optional `archive_key`; Quinn winds **Doug's pocket-watch** → `doug_pocketwatch`. Bells now also grant `tuning_fork`. Tile/stone surfaces, brass accents.
- **Enemy types:** Grunts + Boss (clockwork guardian)
- **Level progress flags:** `enemies_cleared` / `gear_repaired` / `bells_played` / `gear_loot_open` / `pendulum_stilled` / `archive_open` / `watch_taken`
- **NPCs:** Hieronymus (stationary in the F1 lobby)

---

### 6. The Harbor & Docks — `HarborDocks3D.tscn`
- **Unlock condition:** All five characters unlocked (opens alongside Clocktower)
- **Key puzzle(s):** Evan (or crowbar) moves the cargo container off the crane platform; Quinn powers the dock; the crane lifts Doug's manifest crate
- **3D build:** multi-room — combat-free OFFICE (Viktor + exit) → DOCK YARD (combat + crane chain) → optional STOREROOM (east, `boiler_key`). Chain: Evan **container** → Quinn **dock-power** → run the **crane** (needs `crane_crank_handle` from the yard) → lifts the manifest crate (`doug_crate_tag`). The **`pocket_lantern`** is now in the manifest locker (Evan force / Quinn dial). Concrete/dirt surfaces, rust trim.
- **Enemy types:** Grunts + Runners (yard only)
- **Level progress flags:** `enemies_cleared` / `container_moved` / `power_on` / `crane_run` / `lantern_taken` / `store_open` / `store_loot` / `viktor_met`
- **NPCs:** Viktor (harbourmaster, in the office lobby)

---

### 7. The Public Library & Archive — `LibraryArchive3D.tscn`
- **Unlock condition:** TBD
- **Key puzzle(s):** Erin talks past Ms. Priswick (or library card) to drop the checkpoint gate; Ethan hacks the restricted archive terminal
- **3D build:** multi-room — combat-free READING ROOM (Priswick checkpoint + exit) → checkpoint gate → STACKS (combat + hiding spots). Archive hack reveals Doug's file → `doug_checkout_card`; the **locked stack** opens via the Clocktower `archive_key` OR Ethan's **catalog cipher** → `vr_override_chip`. Carpet/wood surfaces, deep-green trim.
- **Enemy types:** Grunts + Sentry (ranged) — stacks only
- **Level progress flags:** `enemies_cleared` / `librarian_talked` / `archive_hacked` / `catalog_done` / `stack_open` / `priswick_impression`
- **NPCs:** Ms. Priswick (checkpoint desk, reading room)

---

### 8. The Carnival & Fairground — `Carnival3D.tscn`
- **Unlock condition:** TBD
- **Key puzzle(s):** **Quinn powers up the dead midway** (fixes the power box → the fair's string-lights blaze on) *then* re-belts the carousel (power is a prerequisite); Erin talks down Marco at the backstage gate (or backstage pass). **Quinn** also fixes the photo booth. **Optional:** Erin fast-talks **Madame Esme** the fortune teller (→ `backstage_pass`, an alt route past Marco + a Grand-Marquee Doug lore beat); Erin works the **rigged ring-toss** (→ `ticket_stub_torn`, comedic junk); the funhouse lever-sequence.
- **3D build:** expanded fairground (Zip-bar): big MIDWAY (combat; carousel + photo booth + power box) at origin, with long stall-lined **midway lanes** to a combat-free ENTRANCE PLAZA (barker Pearl + ticket booth + exit + the waiting **crowd**), the BACKSTAGE (Doug poster, behind Marco's gate), a side FUNHOUSE (clown-face facade), and a **SIDESHOW ALLEY** sub-area east (Madame Esme's fortune wagon + the rigged game). Grassy ground + perimeter tree ring (carnival in a park). **Hero props are Prop-Farm painted** (`carousel`/`photo_booth`/`funhouse_facade`/`ticket_booth`); fortune wagon + power box are Synty bakes. Quinn **fixes the photo booth** → `doug_photo_strip`; the **funhouse lever-sequence 1→2→3** → `library_card` (optional). Dirt/bright-wood surfaces, candy-red trim.
- **Enemy types:** Grunts ×2 + Brute (midway only; the roughnecks cleared the civilians out — the crowd waits in the plaza/sideshow)
- **Level progress flags:** `enemies_cleared` / `ride_repaired` / `backstage_talked` / `photo_taken` / `power_on` / `fortune_done` / `game_done` / `fun_open` / `marco_impression` / `pearl_met`
- **NPCs:** Pearl (plaza barker) · Marco (backstage gatekeeper) · Madame Esme (fortune teller, Sideshow Alley) · plaza/sideshow **crowd** (animated Synty Kids + an adult chaperone, ambient speech bubbles)
- **Notes:** Win is unchanged — enemies cleared + ride repaired + backstage opened (the power-up folds into the ride requirement; fortune/game/funhouse are optional bonuses).

---

### 9. The Underground Tunnels — `UndergroundTunnels3D.tscn` (MULTI-FLOOR, 3 depths)
- **Unlock condition:** Recording Studio complete **+ must carry the `pocket_lantern`** (an
  overworld item-gate — see below). The lantern is found in a loot crate at the **Harbor & Docks**.
- **Entering duo:** Evan + Ethan
- **Depths (each its own world region, like Clocktower/Pipe Organ):**
  - **Depth 1 — Maintenance:** the LOBBY (Cyrus + overworld exit, combat-free) + a Pump Room holding the **security badge**. Stairs down to Depth 2.
  - **Depth 2 — The Junction:** the patrol (2 Grunts + Runner) + 2 dark-alcove hiding spots. **West** passage blocked by Evan's **rubble** → Storeroom (`rusty_key` + a `faded_photograph` lore pickup). **East** Hatch Bay: Ethan's **3-pip hatch hack** (carrying the security badge auto-fills one pip) → unlocks the stairs **down to Depth 3** (`add_floor_link(..., locked=true)`, unlocked when `hatch_progress >= 3`).
  - **Depth 3 — The Sealed Vault:** Ethan **drains the flooded passage** (reroutes the pump valves → lifts a gate) to reach the vault room; then Evan forces the seized wheel (`vault_forced`) **and** Ethan hacks the lock panel (`vault_hacked`) → the blast door grinds open (Uncle-Doug clue dialogue + `doug_flashlight`). The **rusty key** opens a maintenance-ladder **shortcut** (a locked `add_stairwell`) straight back up to Depth 1.
- **Key puzzle(s):** Evan rubble · Ethan hatch (multi-step, badge-assisted) · Ethan drain gate · Evan+Ethan combined vault finale · rusty-key shortcut. (Twinkle bark distraction is still design-only.)
- **3D build:** concrete/dirt/stone surfaces per depth (kept dim — lantern-lit). Opening the vault grants `doug_flashlight`.
- **Enemy types:** Grunts ×2 + Runner (Depth 2 patrol). Lobby + vault are combat-free.
- **Win:** `enemies_cleared` + `rubble_cleared` + `hatch_progress >= 3` + `vault_opened`.
- **Level progress flags:** `enemies_cleared` / `rubble_cleared` / `hatch_progress` (int 0–3) / `badge_taken` / `badge_used` / `key_taken` / `photo_taken` / `drain_done` / `vault_forced` / `vault_hacked` / `vault_opened` / `shortcut_open`
- **NPCs:** Cyrus (tunnel maintainer, in the Depth 1 lobby; briefs the descent)
- **Notes:** It's lit because you're carrying the lantern (no in-level lantern pickup anymore). The lantern is purely the **entry gate** now; extra loot is found by exploration (behind Evan's rubble), not lantern-revealed.

---

### 10. Zip Line Park — `ZipLinePark3D.tscn`
- **Unlock condition:** TBD
- **Key puzzle(s):** Ethan hacks the Mid Platform control panel (proximity); Ben catches the timed High Platform release window (timing gate)
- **Enemy types:** Grunt + Runners ×2
- **Level progress flags:** `enemies_cleared` / `panel_hacked` / `release_timed`
- **NPCs:** Lena (safety warden, stationary on Landing platform)

---

### 11. VR Escape Room — `VrEscapeRoom3D.tscn`
- **Unlock condition:** TBD
- **Key puzzle(s):** Quinn repairs physics-glitch node in Stage Alpha; Ethan hacks system console in Stage Beta; Lizard companion offers an alternate bypass route
- **Enemy types:** Grunts ×2 + Sentry (glitchy/corrupted)
- **Level progress flags:** `enemies_cleared` / `glitch_repaired` / `system_hacked`
- **NPCs:** ARIA (virtual assistant, stationary in Boot Chamber)

---

### 12. The Drop — `TheDrop3D.tscn`
- **Unlock condition:** Late-game, after a credible lead on Uncle Doug's location
- **Entering duo:** Evan + Ethan
- **Key puzzle(s):** Evan clears the landing-site **wreckage** gate (clearing→grove); Ethan hacks the jammed **chute release**; Evan (with the dogs) hauls the fallen **mast beam** off the **signal dish**, then Ethan **re-aims the dish** → endgame pointer + `doug_flyer`. **Optional:** Ethan jams the **lookout radio** (→ `animal_treat`) and cracks the **supply drone** (→ `bies_charm`); **Evan pries open the crashed drop pod** in the west crash-site sub-area (→ `faded_treasure_map`, comedic 'mislabeled supply' junk). Rio confirms the marquee sign points to the endgame.
- **3D build:** expanded grove (Zip/Carnival bar): big SNAG GROVE (combat) at origin + a long tree-lined trail south to the combat-free TOUCHDOWN CLEARING (Rio + exit) + a west **crash-site sub-area** (drop pod). Real Synty trees (replacing primitive pine cones) + dense forest ring + grass ground slab (top y=-0.1, below room floors). **Hero props are Prop-Farm painted** (`signal_dish`/`drop_pod`/`supply_drone`); wreckage pile glammed with Synty crates. Grass/stone surfaces, olive trim. **No civilian crowd** (hostile drop site — Rio is the lone friendly).
- **Enemy types:** Grunt + Runner + Brute (hostile ground crew; grove only)
- **Level progress flags:** `enemies_cleared` / `chute_hacked` / `landing_cleared` / `beam_done` / `dish_aimed` / `lookout_done` / `drone_done` / `pod_done` / `rio_met`
- **NPCs:** Rio (ex-crew, stationary in Touchdown Clearing)
- **Notes:** Win = enemies cleared + landing cleared (wreckage) + chute hacked (beam/dish/lookout/drone/pod are bonuses).

---

### 13. The Grand Marquee Cinema — `GrandMarqueeCinema3D.tscn` (endgame)
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
`wall(center, size, col)`, `room(center, w, d, floor_col, wall_col, h, openings, gap, with_floor)`,
`box_mesh(size, col, ofs, emissive, tex)` for primitive props,
and `prop(path, pos, yaw, scale)` for committed GLBs. Collision uses 3D
layers from `Combat3D` (`L_WORLD=1`, `L_PLAYER=2`, `L_ENEMY=4`). See the existing
`scripts/3d/*3d.gd` for patterns (e.g. the organ/gear/carousel built from cylinders+boxes).

**Multi-room layout kit** (used by levels 1–9; see `docs/level_elaboration_plan.md`):
- **`corridor(start, dir, length, floor_col, wall_col, width, h, with_floor, corner_col)`**
  — a walkable hallway joining two room doorways (`dir` = `"n"/"s"/"e"/"w"`). Lays a floor
  strip + two side walls (inset a half-thickness so they butt, never overlap, the room
  walls) + four **solid-colour corner posts** (taller than the walls so no coplanar tops
  → no z-fighting). Returns the far-mouth centre. Short = fill a door gap; long = a
  room-like combat/puzzle space. Corridor length **must equal the gap** between the two
  rooms' edges (mismatched lengths overlap floors → z-fight).
- **Thematic surfaces:** `set_theme(floor_tex_path, wall_tex_path)` (call early, and again
  before each room to vary per space) makes floors/walls tile a texture from
  `assets/art/tiles/synty_*.png` (mipmaps on), **tinted** by the colour each helper is
  given (so brighten the tint colours toward white). Walls + floors use *different*
  textures so they read distinct; **corner posts are flat solid colour** as accent/trim.
  `box_mesh(..., tex)` uses world-space triplanar tiling (cached per colour+texture).
- **Removable gates** (a puzzle opens a passage): a `StaticBody3D` panel filling a doorway
  gap; on solve set `collision_layer = 0` and tween its `position:y` down out of sight.
  **Verify every such reveal** with a physics ray (blocked before → open after, floor
  present behind) — the Pipe Organ secret nook once "opened" behind a second solid wall.
- **Lobby convention:** first room is a textured, combat-free lobby (dialog NPC + exit
  portal via `add_exit_portal`); enemies spawn only in later rooms. `multi_room = true`.

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
  **Generating NEW thematic props** (not from the Synty packs) → the `synty-prop-gen` skill.
  Its **Prop Farm** web service (Windows/CUDA RTX-3090 box, SDXL ref → Hunyuan shape/paint →
  Blender) at **http://192.168.0.62:7860** is the primary path; it can auto-commit+push the
  GLB. The 3090 box generates; the Mac wires props into levels.
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
