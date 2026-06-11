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
| *(unnamed)* | Lizard | Cold-blooded, climbs | **Vertical-traversal scout** — scales walls/pipes the duo can't reach to flip a switch or drop a rope/ladder down to them; a climbing counterpart to William/Mary's burrowing. *(Implemented — see `lizard_companion.gd`: CLIMB → PERCH → RETURN phase machine; emits `target_reached` signal when it reaches its target position, which levels wire up as an alternate puzzle-gate route. Ethan summons it in both Zip Line Park (`_on_lizard_panel` → `_panel_hacked`) and VR Escape Room (`_on_lizard_bypass` → `_system_hacked`), cooldown-gated and scaled by `_cd_scale` / `animal_treat`.)* |

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
- **`InventoryOverlay`** (`scripts/ui/inventory_overlay.gd`, no `class_name` —
  `extends CanvasLayer`, sibling of `AchievementsOverlay` in `HUD.tscn`,
  `layer = 26`) — a full-screen, scrollable list view that solves the "what
  does this item actually do?" gap the always-on `InventoryPanel` row can't:
  a fixed icon swatch can't show a name or description, and with 46 possible
  items a single character's row would run off-screen. Mirrors
  `achievements_overlay.gd`'s construction exactly (same panel rect/colors,
  `PROCESS_MODE_ALWAYS`, `_unhandled_input` + `set_input_as_handled()`).
  Opened via Pause Menu → **"Inventory"** (new second option, between
  "Resume" and "Achievements" — `pause_menu.gd`'s `OPTIONS_LEVEL`/
  `OPTIONS_OVERWORLD` and `_select_main()` match are extended the same way
  Achievements was). It looks up
  `GameManager.inventories[character_name.to_lower()]` exactly like
  `InventoryPanel`, but takes the duo's two character names via an explicit
  `setup(name_a, name_b)` rather than reading `GameManager.active_player`/
  `standby_player` — those are level-`Player`-only and **unset in the
  overworld** (`overworld_player.gd` is a separate `CharacterBody2D`, never
  registered with `GameManager`), so the first cut showed an empty inventory
  on the overworld even though it worked in levels. `hud.gd.setup(a, b)`
  calls `inventory_overlay.call("setup", a.data.character_name,
  b.data.character_name)`; `overworld_map.gd._spawn_duo()` calls
  `_inventory_overlay.call("setup", active_name, standby_name)` with the same
  names it uses to spawn the overworld duo sprites. Duo membership is stable
  per level/overworld session (swap only toggles active/follow roles, not
  which two characters are in the duo), so `setup()` runs once. Left/right
  switches between the two duo members' tabs; up/down moves a cursor through
  up to `ROWS_VISIBLE` (14) visible rows with scroll-to-keep-cursor-visible
  (`_scroll` offset, same idea as the Achievements list but with scrolling
  since item counts are unbounded); each row shows the item's
  `make_item_icon` swatch, `display_name`, and a FUNCTIONAL/JUNK tag, with the
  selected item's `description` shown in a panel at the bottom.
  `pause_menu.gd._on_unpaused()` closes it (alongside Achievements) if the
  player unpauses mid-browse.

  **Overworld wiring gotcha**: `OverworldMap.tscn` has no static `PauseMenu`/
  overlay nodes — `overworld_map.gd._build_ui()` builds `PauseMenu` and
  `AchievementsOverlay` programmatically as siblings at runtime (`PauseMenu`
  looks them up via `get_node("../Name")`). `InventoryOverlay` had to be added
  to that same programmatic-sibling list (`InventoryOverlayScript.new()`,
  named `"InventoryOverlay"`, added before `PauseMenu`) — missing this caused
  `pause_menu.gd`'s `@onready var _inventory_overlay = get_node
  ("../InventoryOverlay")` to resolve to null and crash in `_ready()` the
  moment the overworld loaded (i.e. on "Continue" from the title screen).
  Any future overlay added to `HUD.tscn` that `PauseMenu` looks up as a
  sibling needs the same addition in `overworld_map.gd._build_ui()`.

  Verified via temp-autoload functional checks in both contexts: PipeOrganWorks
  (granted 16 items to the active character and 2 to standby — correct counts,
  scroll engages and keeps the cursor in view past row 14, tab-switch shows the
  standby's distinct item set, description label matches the selected item's
  `.tres` data) and OverworldMap (granted items to Quinn/Erin, confirmed
  `setup()` receives the right names and each tab's `_ids` reflects that
  character's `GameManager.inventories` entry). Boot check and GUT 24/24
  unaffected.
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

**Follow-up pass: COMPLETE.** All 26 remaining items placed as loot boxes
across the other 12 locations; 7 items wired into existing puzzle-prop gates
(`sheet_music_page`/`tuning_fork` → Clocktower bells hard gate; `library_card`
→ Library librarian desk; `backstage_pass` → Carnival curtain; `crowbar` →
Harbor container; `security_badge` → Underground hatch pip pre-fill;
`film_reel` → Cinema projector hard gate); the 5-ticket Cinema entry gate
implemented as `_has_all_tickets()` on the completion condition. Items without
new-mechanic dependencies placed as collectibles only — their CLAUDE.md
"uses" reference systems that didn't exist yet at the time. Subsequent passes
have implemented: `rusty_key` → Underground Tunnels shortcut door (consume on
use, immediate overworld exit); `guard_whistle` → one-shot `try_use_whistle()`
fallback in all 13 `_on_special_used` functions (any character, consumed from
whichever duo member holds it); `bies_charm` → +10% starting Bies charge via
`register_players_with_preference`; `animal_treat` → halves companion cooldown
via `GameManager.companion_cooldown_scale()` checked at level `_ready()`.
Remaining collectible-only: `pocket_lantern`, `crane_crank_handle`,
`vr_override_chip`, all character tickets, all 6 junk items. Rolled out the same way the Doorway/camera/floor/stealth passes were:
prototype proven at Pipe Organ Works, mechanically repeated 12 more times.
GUT 16/16 unaffected.

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
| Fanny's Bottle | Quest item for Fanny (see "NPC dialog & quests") — a keepsake Doug gave her "the day before he disappeared" |

### Junk / lore collectibles (look load-bearing, do nothing — comedic red herrings)
| Item | Why it seems useful | What it actually does |
|------|---------------------|------------------------|
| Skeleton key | Looks like it should open every locked door | Opens nothing — a note reads "Doesn't fit anything I've tried. — D." Quest item for Moira (see "NPC dialog & quests") — the "D." is Uncle Doug's mark |
| Ticket stub (torn) | Looks like one of the five Grand Marquee tickets | From an unrelated theater; not part of the set |
| Arcade token | Embossed with a defunct arcade's logo | No arcade machine exists anywhere (yet — a planted rumor for a future location). Quest item for Reggie — custom-cast for an unfinished cabinet he and Doug built together |
| Tangled headphone cable | Ethan's sure it'll patch into Recording Studio/VR gear | Just a cable — he keeps it "for parts" |
| Faded treasure map | Covered in confident X's and arrows | Landmarks don't match anything in the game — a forgery or doodle |
| Bent spoon | Quinn insists "it has a story" | Quest item for Gus — it's Doug's old pipe-tapping spoon |
| Lucky rabbit's foot keychain | Evan assumes it'll help him talk to William & Mary | Does nothing for the rabbits — or anyone |
| Embroidered handkerchief | Looks like a keepsake, monogrammed "D" | Quest item for Penny — Doug's handkerchief, lost mid-mend; turning it in grants the Hand-Stitched Patch |
| Hand-Stitched Patch | A little gear-shaped patch | Pure character color — Penny's thank-you for the handkerchief, zero function |
| Brass compass | Engraved "To O., so you always find your way home" | Quest item for Otis — a gift from Doug; turning it in grants the Sailor's Knot Bracelet |
| Sailor's Knot Bracelet | Looks like a good-luck charm | Pure character color — Otis's thank-you for the compass, zero function |

Visually distinguish the two categories in the `InventoryPanel` (e.g. a dimmer
icon border for junk items) so players can tell "this might matter later" from
"this is just a keepsake," without it being a complete non-clue.

> **Status: COMPLETE — full 13-location rollout done.** `ItemData`,
> `GameManager` inventory state/signals, `LootBox`, `InventoryPanel`, and all
> 29 `.tres` item resources implemented and placed. All 13 locations have loot
> boxes; 7 items are wired into puzzle-prop gates; the 5-ticket Cinema
> completion gate (`_has_all_tickets()`) is the headline capstone. See the
> "Follow-up pass: COMPLETE" note above for the per-item placement map.

### Numbered spoon set (NPC quest rewards) *(implemented)*
A 12-piece junk/lore set, layered on top of the existing town quest-givers:
finishing **any** of the 12 town NPC quests (see "NPC dialog & quests" below)
also grants one `numbered_spoon_NN` (`data/items/numbered_spoon_01.tres`
through `_12.tres`, `is_junk = true`, following the `ItemData` convention
exactly). Each spoon's `description` is its own little riff on Quinn's "Bent
spoon...has a story" joke from the junk table above, escalating across the set
toward an explicit Easter-egg hint: early entries read as plain flavor text
("Stamped with a small '1' on the handle...feels like it's part of a set"),
middle entries plant the payoff ("Reggie swears he's seen one just like it
bolted to the side of an old arcade cabinet" — tying back to his arcade-token
quest item and its "planted rumor for a future location" note), and the final
entries spell it out ("One more, and the set's complete...", "...Definitely a
game piece — but for which game?"). No mechanical gate depends on collecting
the set — pure lore/completionist hook, in the same spirit as Penny's
Hand-Stitched Patch or Otis's Sailor's Knot Bracelet.

- **Quest → spoon mapping**: every entry in `QUESTS` and `QUESTS_2`
  (`overworld_map.gd`) gained a `"spoon": "numbered_spoon_0N"` key — gus→01,
  moira→02, reggie→03, fanny→04, penny→05, otis→06, wendell→07, clara→08,
  ambrose→09, dottie→10, tobias→11, agnes→12. `_talk_to_npc()` grants the
  spoon (via `GameManager.grant_item()`, idempotent like every other item
  grant) at the same moment it grants a quest's `give_item` — one extra
  `if quest.get("spoon", "") != ""` check alongside the existing turn-in
  logic, so the established `not_started → active → complete` state machine
  and dialog flow are otherwise untouched.
- **6 new NPCs** (`NPC_DATA_2` in `overworld_map.gd`, alongside the existing
  `NPC_DATA` six) round the roster up to 12 quest-givers — the user's explicit
  call to "add more NPCs so there are enough to give out 12 spoons... some in
  other locations, some freed from hidden/secret rooms":
  - **Wendell, Clara, Ambrose, Dottie** — ordinary fetch-quest NPCs homed in
    the overworld's grass padding (the area outside the original 40×19
    `LOCS` grid — fully painted by `_build_floor()`'s padded `GRID_COLS x
    GRID_ROWS` (60×35) grass pass but never given colliders by
    `_build_building_colliders()`, so it's guaranteed-clear open ground for
    new NPC homes with zero collision risk). Each quest reuses an
    **already-placed** junk item from another location as its `want_item`
    rather than introducing a new collectible/loot box: Wendell wants the
    Carnival's `ticket_stub_torn`, Clara the Recording Studio's
    `tangled_headphone_cable`, Ambrose Harbor & Docks' `faded_treasure_map`,
    Dottie The Drop's `rabbits_foot_keychain` — all four already had loot-box
    placements and `ItemData` entries from the original 29-item rollout, so
    no level scenes changed.
  - **Tobias and Agnes** — one-shot "freed" NPCs gated by `requires_flag` (a
    new optional `NPC_DATA_2` key: `{"location": ..., "flag": ...}`, checked
    in `_spawn_npcs()` via `GameManager.get_level_flag()` before an NPC is
    even instantiated). Tobias requires
    `level_progress["pipe_organ_works"]["secret_revealed"]`; Agnes requires
    `level_progress["old_parish_church"]["secret_revealed"]` — reusing the
    secret-passage flags those two locations already set when their hidden
    rooms are found (see their implementation notes above), so finding either
    secret passage literally "frees" the corresponding NPC into town. Their
    `QUESTS_2` entries have `want_item == ""` and empty `reminder`/`turn_in`
    arrays — `_talk_to_npc()` special-cases `want_item == ""` in the
    `not_started` branch: the very first conversation (`intro`, doubling as
    their thanks for being freed) grants their spoon directly to
    `GameManager.unlocked_characters[0]` (always `"quinn"`) and jumps straight
    to `complete`, skipping the `active`/`reminder` states entirely.
- **`town_npc.gd`** gained a `color: Color` field, set via `setup()`'s new
  `npc_color` param — needed because `_npcs` is no longer guaranteed parallel
  to `NPC_DATA + NPC_DATA_2` once `requires_flag` entries are conditionally
  skipped; `_talk_to_npc()` reads `npc.color` directly for the dialog
  portrait instead of indexing back into the data table.

Verified via a temp-autoload functional script: with neither secret passage
found, exactly 10 NPCs spawn (Tobias/Agnes absent); with both
`secret_revealed` flags set, all 12 spawn. Driving all 12 quests to
completion (granting each `want_item` then re-talking for fetch quests;
single conversation for Tobias/Agnes) confirms all 12 `numbered_spoon_NN`
ids end up granted, each fetch quest's `want_item` is consumed, and
`give_item`s (Hand-Stitched Patch, Sailor's Knot Bracelet) still grant
alongside the new spoon. Boot check and GUT 16/16 unaffected.

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
- **Overworld map** (`scenes/overworld/OverworldMap.tscn`,
  `scripts/overworld/overworld_map.gd`) — *(rebuilt to match the 13 location
  interiors — see `locations/00_overworld_map.md` for the design doc)* a 40x19
  `TileMap` (`PlaceholderArt.make_hb_tileset()`, same atlas as every level) with
  three layers: grass (layer 0, OUTDOOR row with sparse-tuft variety), roads
  (layer 1, orthogonal L-shaped routes between each `CONNECTIONS` pair's door
  tile via `_paint_road()`), and buildings (layer 2, each location's footprint
  painted with its own terrain row from the `LOCS` table — roads running under
  a building are simply covered, no avoidance logic needed). Each building gets
  a `StaticBody2D`/`RectangleShape2D` collider sized to its footprint
  (`_build_building_colliders()`), with a clear "door" tile one row below for
  entry. The unlock chain, lock-overlay tint, and per-location `_draw_icon()`
  flourishes (gear, arch, dumbbell, etc.) are unchanged. **Cursor-based
  selection is gone**: the active/standby duo (first two of
  `GameManager.unlocked_characters`, via `overworld_player.gd` — `Mode.ACTIVE`
  driven by `move_*`, `Mode.FOLLOW` trailing the active character, same
  teleport-if-too-far rule as in-level standbys) walks the town from a spawn
  beside Pipe Organ Works; `swap` toggles which is active/follow, exactly as in
  a level. A handful of `town_npc.gd` wanderers (no `class_name`, same
  preload()+untyped-var pattern as `HidingSpot`/`LootBox`) amble around a home
  point on open grass for atmosphere. Walking the active character within
  `INTERACT_RADIUS` of a building's door tile shows that location's name/status
  in the info panel (locked/unlocked/completed, mirroring the old cursor info
  panel) and `ui_accept`/`attack` calls `_launch()` for it — refused with a
  "locked" message if its `requires` location isn't yet completed. Verified via
  a temp-autoload functional check (3 TileMap layers populated correctly,
  13 colliders, road/building tile spot-checks, duo spawn + swap, NPC wander,
  proximity detection for completed/unlocked/locked locations) plus a headless
  boot check and GUT 16/16.
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
- **Implementation:** Prototype for tile-mapped floors and the Doorway/
  camera-follow/multi-room system (~1352×536 camera bounds). Layout: entry
  bay → hallway → main workshop floor (organ + loot boxes + Grunt/Runner
  spawns) → secret parts closet behind a secret passage (Quinn's Special
  reveals `spare_clockwork_gear`). `level_progress` flags: `enemies_cleared`/
  `organ_repaired`/`secret_revealed`. Completion id: `"pipe_organ_works"`.
  Full history: [docs/implementation_history.md](docs/implementation_history.md#1-bellows--sons-pipe-organ-works).

---

### 2. The Old Parish Church
- **Unlock condition:** Complete Bellows & Sons
- **Unlocks:** Evan (found here)
- **Key puzzle(s):** Quinn's respectful demeanor earns the congregation's trust (unlocks doors, gets information); Erin's skepticism lets her see through deception and argue past gatekeepers — both attitudes are required
- **Enemy types:** TBD
- **Characters required:** Quinn and Erin
- **Notes:** Quinn speaks quietly, removes his hat; Erin debates and calls out manipulation. Neither can solve it alone. Dialogue-heavy puzzle sequences. May contain a pipe organ echoing the starting location.
- **Implementation:** Cross-shaped church floor plan — vestibule (south,
  `Doorway` + spawn) → long nave (Quinn's BLUE pillar and Erin's RED pillar
  on opposite west/east walls, ~440px apart) → hidden organ loft behind a
  secret passage at the altar end (Quinn's Special reveals a lore-only
  pipe-organ prop, no loot box). Camera bounds `184,24`–`776,656`.
  `level_progress` flags: `quinn_done`/`erin_done`/`secret_revealed`.
  Completion id: `"old_parish_church"`. Full history:
  [docs/implementation_history.md](docs/implementation_history.md#2-the-old-parish-church).

---

### 3. Iron & Strings Gym — `IronStringsGym.tscn`
- **Unlock condition:** Complete The Old Parish Church
- **Unlocks:** Ben (found or performing here)
- **Key puzzle(s):** Evan's super strength moves heavy equipment to open paths and trigger mechanisms. Ben's keytar motivates NPCs, times rhythm obstacles, and calms an agitated crowd
- **Enemy types:** Bruiser-type enemies (Grunts + Brutes)
- **Characters required:** Evan and Ben
- **Notes:** Good location for introducing Evan's strength-based traversal. Ben's bard angle shines in a crowd/audience dynamic — maybe a grudge match Ben narrates while Evan fights.
- **Implementation:** Entering duo is **Quinn + Evan** (Ben is unlocked by
  clearing this location, so he can't be in the entering duo). Layout:
  locker room (`Doorway` + spawn) → main gym floor (enemies, hiding spot) →
  Ben's cage alcove, sealed by a barbell that's a literal `StaticBody2D`
  collider — Evan's Special disables it and slides it aside. Camera bounds
  `24,24`–`936,536`. `level_progress` flags: `enemies_cleared`/
  `barbell_moved`. Completion id: `"iron_strings_gym"`. Full history:
  [docs/implementation_history.md](docs/implementation_history.md#3-iron--strings-gym).

---

### 4. The Recording Studio — `RecordingStudio.tscn`
- **Unlock condition:** Complete Iron & Strings Gym
- **Unlocks:** Ethan (found here, trying to fix the equipment)
- **Key puzzle(s):** Someone has scrambled the studio. Ben navigates the soundboard and performs to trigger doors and mechanisms; Ethan repairs and hacks the digital gear. Rhythm-based puzzle element tied to Ben's keytar
- **Enemy types:** Grunts + Runners
- **Characters required:** Ben and Ethan
- **Notes:** Ben's home turf; his musical ability is the primary tool here. May hold a recording that is a clue about Uncle Doug.
- **Implementation:** Entering duo is **Quinn + Ben** (Ethan is unlocked by
  clearing this location). Layout: lobby (`Doorway` + spawn) → control room
  (soundboard console, Grunts/Runners, hiding spot) → sealed recording booth
  behind a glass `BoothDoor` (literal `StaticBody2D` collider). Ben's Special
  at the console both tunes it and slides the door into the ceiling, revealing
  Ethan. Camera bounds `24,24`–`896,536`. `level_progress` flags:
  `enemies_cleared`/`console_tuned`. Completion id: `"recording_studio"`.
  Full history: [docs/implementation_history.md](docs/implementation_history.md#4-the-recording-studio).

---

### 5. The Clocktower — `Clocktower.tscn`
- **Unlock condition:** All five characters unlocked
- **Key puzzle(s):** The tower is one multi-floor mechanical puzzle — gears, pendulums, counterweights, escapements. Quinn repairs each floor's mechanism to ascend. On certain floors, the mechanism is locked behind a sound-based puzzle: the bells or chimes must be struck in the exact right pitch sequence, which only Ben's Perfect Pitch ability can identify and play
- **Enemy types:** Grunts + a Boss ("the clockwork guardian")
- **Characters required:** Quinn and Ben
- **Notes:** Quinn handles the physical mechanics; Ben listens to the tower's bells and plays the correct tonal sequence on his keytar to unlock the next stage. Each floor can have a distinct mechanical theme. The clock face is visible on the overworld map, making it a strong landmark.
- **Implementation:** Entering duo is **Quinn + Ben** (both already
  unlocked). First location with the **Boss** enemy. Layout: a vertical
  shaft of three stacked floors — landing (south, `Doorway` + spawn) → gear
  floor (Quinn's mechanism, Grunts, hiding spot) → belfry (Ben's bells),
  connected by two stairwell gaps; the clockwork-guardian Boss spawns in the
  upper gap and must be cleared to ascend. Camera bounds `264,24`–`616,616`
  (tall 352×592). `level_progress` flags: `enemies_cleared`/`gear_repaired`/
  `bells_played`. Completion id: `"clocktower"`. Full history:
  [docs/implementation_history.md](docs/implementation_history.md#5-the-clocktower).

---

### 6. The Harbor & Docks — `HarborDocks.tscn`
- **Unlock condition:** All five characters unlocked (mid-game; opens alongside Clocktower)
- **Key puzzle(s):** Cranes, cargo containers, boats. Evan moves heavy freight to clear paths or trigger crane mechanisms. Calvin and Coolidge are useful in hard-to-reach areas. A suspicious shipment may be a lead on Uncle Doug
- **Enemy types:** Dock workers (Grunts), smugglers (Runners)
- **Characters required:** Evan (primary)
- **Notes:** Large open environment; cargo container maze is good brawler terrain.
- **Implementation:** Entering duo is **Quinn + Evan**. Layout: pier
  (`Doorway` + spawn) → container-maze yard (collidable `MazeCrateA`/
  `MazeCrateB` obstacles, Grunts/Runners, hiding spot, Calvin & Coolidge
  summon spot) → crane platform sealed by a cargo `Container` (literal
  `StaticBody2D` collider) — Evan's Special disables it and hoists it away
  with a swinging rotation tween. Camera bounds `24,24`–`936,536`.
  `level_progress` flags: `enemies_cleared`/`container_moved`. Completion id:
  `"harbor_docks"`. Full history:
  [docs/implementation_history.md](docs/implementation_history.md#6-the-harbor--docks).

---

### 7. The Public Library & Archive — `LibraryArchive.tscn`
- **Unlock condition:** TBD
- **Key puzzle(s):** Research uncovers critical intel about Uncle Doug. Erin stealth-sneaks past a strict librarian to access restricted stacks; Ethan hacks the digital archive for sealed records
- **Enemy types:** Grunts + a Sentry (ranged) — the prototype's first stealth-flavored use of the new ranged enemy
- **Characters required:** Erin and Ethan
- **Notes:** A slower, stealth-and-puzzle counterpoint to the brawler locations. Erin's fast-talk can resolve some confrontations without combat.
- **Implementation:** Entering duo is **Erin + Ethan** (both already
  unlocked). Layout: reading room (`Doorway` + spawn, Grunt/Sentry patrol,
  hiding spot) → Restricted Stacks (Ethan's terminal), separated by the
  librarian's desk (literal `StaticBody2D` collider) — Erin's Special
  disables it and plays a scale-down + fade tween. Camera bounds
  `24,144`–`936,536`. `level_progress` flags: `enemies_cleared`/
  `librarian_talked`/`archive_hacked`. Completion id: `"library"`. Full
  history: [docs/implementation_history.md](docs/implementation_history.md#7-the-public-library--archive).

---

### 8. The Carnival & Fairground — `Carnival.tscn`
- **Unlock condition:** TBD
- **Key puzzle(s):** Quinn repairs broken rides to open new areas. Ben's keytar draws crowds as cover or distraction. Erin talks her way into the restricted backstage
- **Enemy types:** Carnies, strongmen — Grunts ×2 + a Brute
- **Characters required:** Quinn, Ben, and Erin
- **Notes:** Each attraction is its own zone. Fun atmosphere that shifts darker backstage.
- **Implementation:** Entering duo is **Quinn + Erin** (Ben's musical draw is
  narrative color). Layout: open midway (`Doorway` + spawn, Grunts/Brute,
  broken ride, hiding spot) → backstage alcove sealed by a velvet
  `BackstageGate` (literal `StaticBody2D` collider) — Erin's talk-down at the
  gate both solves the dialogue puzzle and raises it (slide-up + scale-down
  tween), revealing a `_doug_poster` prop. Camera bounds `24,24`–`936,536`.
  `level_progress` flags: `enemies_cleared`/`ride_repaired`/
  `backstage_talked`. Completion id: `"carnival"`. Full history:
  [docs/implementation_history.md](docs/implementation_history.md#8-the-carnival--fairground).

---

### 9. The Underground Tunnels — `UndergroundTunnels.tscn`
- **Unlock condition:** TBD — mid-game; may unlock shortcuts between prior locations
- **Key puzzle(s):** Dark maze of maintenance tunnels. Erin's stealth is critical in tight corridors. Ethan hacks access hatches and junction panels. Evan forces open blocked passages
- **Enemy types:** Patrol-style enemies — Grunts ×2 + a Runner
- **Characters required:** Erin and Ethan (primary); Evan for brute-force sections
- **Notes:** Ties the overworld together. Discovering the tunnel network could open hidden routes between already-visited locations.
- **Implementation:** Entering duo is **Evan + Ethan** (Erin's stealth is
  narrative flavor here). Layout: Y/T-shaped maze — south entry corridor
  (`Doorway` + spawn) → central junction chamber (hiding spot, patrolling
  Grunt) → forking west tunnel (Evan's rubble, standard proximity gate) and
  east tunnel (Ethan's hatch, multi-step gate: `HATCH_PRESSES_REQUIRED` = 3
  pips, see "Puzzle-gate variety"). Camera bounds `24,184`–`936,536`.
  Twinkle's bark distraction (`_summon_twinkle()`) is implemented here — see
  "Stealth & awareness". `level_progress` flags: `enemies_cleared`/
  `rubble_cleared`/`hatch_progress` (int 0-3, persists partial hack progress).
  Completion id: `"underground"`. Full history:
  [docs/implementation_history.md](docs/implementation_history.md#9-the-underground-tunnels).

---

### 10. Zip Line Park — `ZipLinePark.tscn`
- **Unlock condition:** TBD
- **Key puzzle(s):** Navigate zip lines to reach inaccessible areas. Evan's animals retrieve stuck components; Ethan unlocks a control panel to reactivate broken lines. Ben's keytar performance draws a crowd that can be used as cover, or his rhythm cues the timing of zip line releases
- **Enemy types:** Grunt + Runners ×2
- **Characters required:** Evan, Ethan, and Ben
- **Notes:** Vertical traversal is the signature mechanic — lines connect platforms at different heights; some broken or locked.
- **Implementation:** Entering duo is **Ethan + Ben** (Evan's animal-retrieval
  angle is narrative flavor here). Layout: chain of three platforms linked by
  zip-line "Bridge" corridors — Landing (south-west, `Doorway` + spawn, patrol
  + hiding spot) → Mid Platform (Ethan's panel, standard proximity gate) →
  High Platform (Ben's timing-based release gate: pulsing ring, press
  **Special** in the `PULSE_GOOD_WINDOW`, see "Puzzle-gate variety"), each
  platform's north wall higher than the last. Camera bounds `24,164`–
  `936,536`. `level_progress` flags: `enemies_cleared`/`panel_hacked`/
  `release_timed`. Completion id: `"zip_line"`. Full history:
  [docs/implementation_history.md](docs/implementation_history.md#10-zip-line-park).

---

### 11. VR Escape Room — `VrEscapeRoom.tscn`
- **Unlock condition:** TBD
- **Key puzzle(s):** The team is trapped in a VR simulation. Quinn repairs glitches in the VR environment (broken physics, corrupted props); Ethan hacks the underlying system to bypass stages or rewrite the rules. Other characters may assist in specific themed rooms
- **Enemy types:** Glitchy, corrupted versions of standard enemies — Grunts ×2 + a Sentry
- **Characters required:** Quinn and Ethan (primary); others assist per room
- **Notes:** Each stage can have a distinct visual theme (medieval, space, underwater, etc.) without breaking the overall aesthetic. Quinn comments on mechanical logic; Ethan sees the code underneath.
- **Implementation:** Entering duo is **Quinn + Ethan** (both already
  unlocked). Layout: Boot Chamber (neutral cyber-blue, `Doorway` + spawn) →
  Corridor1 → Stage Alpha (warm stone-and-amber "medieval" glitch — Quinn's
  physics-glitch repair) → Corridor2 → Stage Beta (teal-aqua "underwater"
  glitch — Ethan's system console). Each stage gets its own `TileMap` palette
  via `_paint_stage_floor()`, layered over the base floor. Camera bounds
  `24,24`–`776,536`. `level_progress` flags: `enemies_cleared`/
  `glitch_repaired`/`system_hacked`. Completion id: `"vr_room"`. Full history:
  [docs/implementation_history.md](docs/implementation_history.md#11-vr-escape-room).

---

### 12. The Drop — `TheDrop.tscn` (aerial / parachute set piece)
- **Unlock condition:** Late-game, after a credible lead on Uncle Doug's location
- **Key puzzle(s):** The group believes Uncle Doug is below — they jump from a plane/airship and navigate the descent through mid-air obstacles and wind currents. The landing zone is locked until the right character steers to it
- **Enemy types:** Aerial pursuit during descent; ground enemies at the landing site — Grunt + Runner + Brute (the hostile ground crew)
- **Characters required:** Ethan (hacks jammed chute release), Evan (strength on impact/landing), Erin (fast-talks the hostile ground crew after landing)
- **Notes:** Two phases: a kinetic aerial descent, then a standard brawler ground phase. The intel turns out to be a step closer — but not the final answer — escalating tension toward the endgame.
- **Implementation:** Entering duo is **Evan + Ethan** (Erin's fast-talk with
  the ground crew is narrative framing). Layout: Touchdown Clearing
  (`Doorway` + spawn, wreckage at the only exit north — a literal chokepoint)
  → Corridor → Snag Grove (Ethan's jammed chute release). William & Mary
  (`_summon_scout_pair()`) are an alternate route to clearing the wreckage —
  see animal companion roster. Camera bounds `24,24`–`576,536`.
  `level_progress` flags: `enemies_cleared`/`chute_hacked`/`landing_cleared`
  (William & Mary's pair is not itself persisted). Completion id:
  `"the_drop"`. Full history:
  [docs/implementation_history.md](docs/implementation_history.md#12-the-drop).

---

### 13. The Grand Marquee Cinema — `GrandMarqueeCinema.tscn` (endgame)
- **Unlock condition:** Complete The Drop; all five characters required
- **Key puzzle(s):** Quinn repairs the projection equipment; Erin talks past the manager; Evan moves lobby fixtures and aids animals; Ben plays the house organ to manipulate the crowd; Ethan hacks the security system and digital projector
- **Enemy types:** Climactic, high-stakes — Grunts ×2 + a **Boss** (the cinema's guardian)
- **Characters required:** All five
- **Notes:** Penultimate location — Uncle Doug is within reach. Backstage, projection booth, balcony, and lobby are distinct zones. A cinematic boss fight here would feel earned.
- **Implementation:** Entering duo is **Quinn + Ben** (mirrors the
  Clocktower's Boss-fight pairing; Erin/Evan/Ethan's contributions are
  narrative framing). Layout: hub-and-wings — Lobby (south, `Doorway` +
  spawn) → Backstage (central combat hub, the guardian Boss holds the aisle)
  → branches west into the Projection Booth (Quinn's repair) and north onto
  the Balcony (Ben's house organ). Camera bounds `24,24`–`616,536`.
  **Endgame-only behavior**: a cleared Doorway-exit routes to
  `ResultScreen.tscn` instead of the overworld (`_exit_to_overworld()`
  branches on `_cleared`, via idempotent `complete_location`).
  `level_progress` flags: `enemies_cleared`/`projector_repaired`/
  `organ_played`. Completion id: `"grand_marquee"` — the game's endgame
  trigger, Uncle Doug found in the projection booth. Full history:
  [docs/implementation_history.md](docs/implementation_history.md#13-the-grand-marquee-cinema).
  **This is the 13th and final location — the entire Doorway/camera-follow/
  multi-room rollout across all 13 locations is COMPLETE** (see
  [docs/implementation_history.md](docs/implementation_history.md#doorway--camera-follow--multi-room-rollout--full-narrative)).

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

> **Status: COMPLETE — rolled out to all 13 of 13 locations.** Every
> location has a Doorway, a camera that follows the active character within a
> bespoke bounding box, a multi-zone layout matching its own spec, and
> mid-level progress that persists across exits/re-entries via
> `level_progress`/`get_level_flag`/`set_level_flag`. Each location's layout,
> camera bounds, `level_progress` flags, and clear-animation flavor are noted
> in its entry under "Locations" above. For the full per-location rollout
> narrative (verification check counts, GUT status, and design rationale),
> see [docs/implementation_history.md](docs/implementation_history.md#doorway--camera-follow--multi-room-rollout--full-narrative).

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

### NPC dialog & quests *(implemented)*
The overworld town previously had four purely cosmetic `town_npc.gd`
wanderers. They're now **quest-givers** with a paged dialog UI — see
`npc_dialog/` for the full per-NPC writeups (dialog scripts, quest items,
and how each ties into the Uncle Doug mystery).

- **`DialogBoxScript`** (`scripts/ui/dialog_box.gd`, `extends Control`, no
  `class_name` — same preload()+untyped-var convention as `LootBox`/
  `Doorway`/`HidingSpot`, see [[feedback-godot-technical]]) is a single
  programmatic `_draw()` panel (`PANEL_RECT`, above the bottom info panel)
  instantiated once by `overworld_map.gd._build_ui()`. `open(npc_name,
  portrait_color, lines: PackedStringArray)` starts a conversation;
  `advance()` shows the next page or closes (emitting `closed`) after the
  last; `is_open()` lets `overworld_map.gd._process()` route input.
- **`town_npc.gd`** gained `npc_name: String` and `quest_id: String` fields,
  set via an extended `setup(frames, home, name, quest)`.
- **`NPC_DATA`** (`overworld_map.gd`) replaces the old `NPC_HOME_TILES`/
  `NPC_COLORS` arrays — one dict per townsperson (`home`, `name`, `color`,
  `quest_id`) for **Gus, Moira, Reggie, Fanny, Penny, and Otis**, all homed on
  open grass clear of every building footprint. **`NPC_DATA_2`** adds six more
  (Wendell, Clara, Ambrose, Dottie, Tobias, Agnes) — see "Numbered spoon set"
  above for their quests, placement, and the `requires_flag` gating mechanism;
  `_spawn_npcs()` iterates `NPC_DATA + NPC_DATA_2` as one combined list.
- **`QUESTS`** (`overworld_map.gd`) is keyed by `quest_id`, each entry holding
  `want_item`, `give_item` (`""` = none), `spoon` (a `numbered_spoon_NN` id —
  see "Numbered spoon set" above), and four dialog-page arrays: `intro`,
  `reminder`, `turn_in`, `after`. **`QUESTS_2`** holds the six `NPC_DATA_2`
  quests in the same shape; `_talk_to_npc()` looks an NPC's quest up via
  `QUESTS.get(npc.quest_id, QUESTS_2.get(npc.quest_id, {}))`.
- **Quest state machine**, `not_started → active → complete`, persisted as a
  string at `GameManager.level_progress["town"]["quest_<id>"]` via the
  existing `get_level_flag`/`set_level_flag(TOWN_ID, ...)` pair (`TOWN_ID =
  "town"`) — the same pattern every level uses for its own progress, just
  under a town-wide pseudo-location id. `_talk_to_npc(idx)`:
  - `not_started` → shows `intro`, flips to `active`.
  - `active` → `_find_item_holder(want_item)` scans
    `GameManager.unlocked_characters` for `has_item`; if found, shows
    `turn_in`, `consume_item`s the want-item, `grant_item`s the give-item (if
    any), and flips to `complete`. Otherwise shows `reminder`.
  - `complete` → always shows `after`.
- **Input/UI wiring**: `_update_nearby_npc()` (mirrors `_update_nearby()` for
  building doors, `NPC_INTERACT_RADIUS = 40px`) drives a cyan pulsing
  ring + name-label prompt (`_draw_npc_prompt`, distinct color from the
  building doors' yellow `_draw_interact_ring`). `ui_accept`/`attack` in
  `_process()` now branches: dialog open → `_dialog_box.advance()`; else
  NPC nearby → `_talk_to_npc()`; else → `_launch()` (enter building). `swap`
  is suppressed while the dialog is open so players can't swap mid-conversation.
- **Items**: four new `.tres` resources (`embroidered_handkerchief`,
  `stitched_patch`, `brass_compass`, `sailors_knot_bracelet`) follow the
  `ItemData` convention exactly. `embroidered_handkerchief` (Old Parish
  Church, `(480, 460)`) and `brass_compass` (Harbor & Docks, `(600, 350)`)
  are placed as loot boxes the same way every other collectible is; the two
  reward items are never placed as loot boxes — they're granted directly via
  `GameManager.grant_item()` on turn-in. Gus/Moira/Reggie/Fanny's quest items
  (`bent_spoon`, `skeleton_key`, `arcade_token`, `fannys_bottle`) were already
  placed as loot boxes in earlier passes — no level changes needed for those
  four.

### Quest Log *(implemented)*
A pause-menu screen listing the player's discovered NPC quests (the 12
`QuestData.TOWN_QUEST_IDS` from "NPC dialog & quests" above) with their
active/completed status and a one-line objective — the "what was I supposed to
bring back, and to whom?" answer for players returning to town after a level.

- **`QuestData`** (`scripts/systems/quest_data.gd`, `class_name QuestData
  extends RefCounted`) is the quest data previously private to
  `overworld_map.gd`, extracted so both the overworld and in-level HUDs can
  read it: `TOWN_ID`, `NPC_DATA`/`NPC_DATA_2`, `QUESTS`/`QUESTS_2`,
  `TOWN_QUEST_IDS`, plus `get_quest(quest_id)` and `get_npc(quest_id)` static
  helpers. `overworld_map.gd` and `achievement_manager.gd` (the
  `friend_of_the_town` check) both reference `QuestData.*` instead of holding
  their own copies.
- **`QuestLogOverlay`** (`scripts/ui/quest_log_overlay.gd`, no `class_name` —
  `extends CanvasLayer`, sibling of `AchievementsOverlay`/`InventoryOverlay`
  in `HUD.tscn` and in `overworld_map.gd._build_ui()`'s programmatic sibling
  list, `layer = 26`) mirrors `achievements_overlay.gd`'s construction
  exactly. Unlike `InventoryOverlay`, it needs no `setup()` — quest progress
  is global `GameManager.level_progress["town"]` state, identical in both
  contexts. Opened via Pause Menu → **"Quests"** (new entry between
  "Inventory" and "Achievements" — `pause_menu.gd`'s `OPTIONS_LEVEL`/
  `OPTIONS_OVERWORLD` and `_select_main()` extended the same way
  Inventory/Achievements were).
- **No spoilers**: only quests with
  `GameManager.get_level_flag(QuestData.TOWN_ID, "quest_<id>", "not_started")
  != "not_started"` are listed — an NPC the player hasn't talked to yet
  doesn't appear. Each row shows the NPC's name/color and an `ACTIVE`/
  `COMPLETE` tag; a header line shows "N active · M completed".
- **Objective text is derived, not authored** — `_objective_text()` builds a
  line purely from each quest's existing `want_item`/`give_item` fields plus
  `ItemData.display_name` lookups (`load("res://data/items/<id>.tres")`): "Find:
  X. Bring it to Y." while active, "Completed." or "Completed. Reward: Z." once
  done, or "Talk to Y." for the `want_item == ""` Tobias/Agnes quests. No
  changes to the 12 quest dialog blocks were needed.
- Refreshes live via `GameManager.level_flag_set` (filtered to
  `location_id == QuestData.TOWN_ID` and `key.begins_with("quest_")`), so
  turning in a quest while the log isn't open is reflected next time it's
  opened, and `_on_unpaused()` closes it if the player unpauses mid-browse.

Verified via a temp-autoload functional check (3 quest states set —
active/complete-with-reward/active-no-want_item — confirmed correct
filtering, tags, and objective text for all three, plus that an untouched
`not_started` quest stays hidden) plus a headless boot check and GUT 24/24.

### Save / Unlock system *(implemented)*
`save_manager.gd` (autoload `SaveManager`, loaded before `GameManager` so it's
available in `GameManager._ready()`) persists `completed_locations` and
`unlocked_characters` to `user://savegame.cfg` via `ConfigFile`.
`GameManager.complete_location(id)` appends the location, looks up
`UNLOCKS_CHARACTER[id]` to grant the new character, and calls
`SaveManager.save_game()`. `SaveManager.load_game()` runs once on boot from
`GameManager._ready()`. Never store save state in scene nodes.

### Achievements *(implemented)*
A 19-achievement tracker — a mix of visible milestones and secret discoveries
— with a Pause Menu screen to view progress and a slide-in toast on unlock.

- **`AchievementData`** (`scripts/systems/achievement_data.gd`,
  `class_name`, `extends Resource`) — `id`, `display_name`, `description`,
  `icon_color`, `secret` (secret achievements show as `"???"` for both name
  and description until unlocked). 19 `.tres` files in `data/achievements/`,
  one per achievement, named after their `id` — same Resource convention as
  `ItemData`/`CharacterData`/`EnemyData`.
- **`AchievementManager`** (autoload, registered in `project.godot` between
  `SaveManager` and `GameManager` — it needs `SaveManager.save_game()` for
  `_unlock()` and runs its retroactive check after `GameManager._ready()`
  loads a save) — `scripts/autoload/achievement_manager.gd`. Holds a curated
  `const ACHIEVEMENT_LIST: Array[AchievementData]` (19 `preload()`s, in
  display order), builds an `id -> AchievementData` `achievements` dict in
  `_ready()`, and connects to **9 `GameManager` signals** to detect unlock
  conditions — never reaches into level scripts directly. Persisted state
  (`unlocked: Dictionary`, `bies_activation_count: int`,
  `companion_types_seen: Dictionary`) is read/written directly by
  `SaveManager` (no underscore prefixes), mirroring `inventories`/
  `level_progress`. `signal achievement_unlocked(id: String)` drives the
  toast and overlay refresh. Public API: `is_unlocked(id)`,
  `get_ordered_ids()`, `get_display_name(id)`, `get_description(id)`,
  `get_icon_color(id)` (all three "get" functions return the secret-locked
  placeholder — `"???"` / a generic message / dim grey — for an unrevealed
  secret achievement).
- **5 new `GameManager` signals** added specifically to feed
  `AchievementManager`, each emitted from an existing call site (no new
  systems):
  - `location_completed(location_id)` — end of `complete_location()`.
  - `enemy_defeated(enemy_name, is_boss)` — `enemy.gd._on_hurtbox_hit()`,
    right before an enemy at 0 HP `queue_free()`s.
  - `player_revived` — end of `GameManager._tick_revive()`'s revive branch.
  - `companion_summoned(companion_name)` — emitted from all 8
    animal-companion summon call sites (Calvin & Coolidge at Harbor & Docks;
    Frosty at Iron & Strings Gym, Underground Tunnels, and The Drop; Twinkle
    at Underground Tunnels; William & Mary at The Drop; the Lizard at Zip
    Line Park and VR Escape Room) with the companion's lowercase key
    (`"frosty"`, `"twinkle"`, `"calvin_coolidge"`, `"william_mary"`,
    `"lizard"`).
  - `level_flag_set(location_id, key, value)` — end of `set_level_flag()`;
    `AchievementManager` watches for `key == "secret_revealed"`.
- **The 19 achievements** (`*` = secret until unlocked):
  | id | Name | Unlocks when | Trigger |
  |----|------|--------------|---------|
  | `welcome_erin` | Reunited | Found Erin at Bellows & Sons Pipe Organ Works | `location_completed("pipe_organ_works")` |
  | `welcome_evan` | Strength in Numbers | Found Evan at The Old Parish Church | `location_completed("old_parish_church")` |
  | `welcome_ben` | Encore | Found Ben at Iron & Strings Gym | `location_completed("iron_strings_gym")` |
  | `welcome_ethan` | Plug and Play | Found Ethan at The Recording Studio | `location_completed("recording_studio")` |
  | `tag_team` | Tag Team | Swapped active character for the first time | `characters_swapped` |
  | `first_blood` | First Blood | Defeated your first enemy | `enemy_defeated` |
  | `boss_slayer` | Boss Slayer | Defeated a boss | `enemy_defeated(_, is_boss=true)` |
  | `got_your_back` | Got Your Back | Revived a downed teammate | `player_revived` |
  | `slow_your_roll` | Slow Your Roll | Activated Bies Mode for the first time | `bies_activated` |
  | `loud_and_clear` | Loud and Clear | Created a noise distraction to lure a guard away | `noise_emitted` |
  | `good_boy` | Good Boy! | Sent Frosty charging into a fight | `companion_summoned("frosty")` |
  | `pack_rat` | Pack Rat | Collected 10 items (any character, any mix) | `item_collected` → total inventory size ≥ `PACK_RAT_TARGET` (10) |
  | `globetrotter` | Globetrotter | Cleared all 13 locations | `location_completed` → `completed_locations.size() >= 13` |
  | `curtain_call` | Curtain Call | Found Uncle Doug at The Grand Marquee Cinema | `location_completed("grand_marquee_cinema")` |
  | `time_lord`* | Time Lord | Activated Bies Mode 25 times | `bies_activated` → `bies_activation_count >= TIME_LORD_TARGET` (25) |
  | `menagerie`* | Menagerie | Called on every animal companion at least once | `companion_summoned` → all 5 `COMPANION_TYPES` seen |
  | `secrets_out`* | Secret's Out | Found a hidden passage | `level_flag_set(_, "secret_revealed", true)` |
  | `complete_set`* | The Complete Set | Collected all twelve numbered spoons | `item_collected` → 12 `numbered_spoon_*` ids held |
  | `friend_of_the_town`* | Friend of the Town | Helped every townsfolk with their request | `item_collected` → all 12 `TOWN_QUEST_IDS` quests at `"complete"` |

  `pack_rat`/`complete_set`/`friend_of_the_town` are re-derived from scratch
  on every `item_collected` via `_check_collectible_achievements()` (scans
  `GameManager.inventories` and `town` quest flags) rather than tracked with
  incremental counters — simpler and always consistent regardless of which
  event satisfies the condition.
- **Retroactive unlocks** — `AchievementManager._ready()` calls
  `call_deferred("_check_retroactive")`, which replays
  `_on_location_completed()` for every already-`completed_locations` entry
  and runs `_check_collectible_achievements()` once — so a save from before
  this system existed immediately unlocks everything it already qualifies
  for (e.g. `globetrotter` if all 13 locations were already cleared).
- **`AchievementsOverlay`** (`scripts/ui/achievements_overlay.gd`,
  `extends CanvasLayer`, `layer = 26`, sibling of `PauseMenu` in `HUD.tscn`)
  — a full-screen list (`PANEL_RECT`) of all 19 achievements in
  `ACHIEVEMENT_LIST` order, each row showing an icon-color swatch, name
  (`"???"` + dimmed if a locked secret), and an `UNLOCKED`/`LOCKED` tag, plus
  an "`N / 19 unlocked`" progress line and a description panel for the
  cursor-selected row. Mirrors `pause_menu.gd`'s programmatic
  `_draw()`-free `ColorRect`/`Label` construction, color consts, and
  `_unhandled_input` + `set_input_as_handled()` pattern (`move_up`/
  `move_down` to navigate, `ui_cancel` to close). Opened via Pause Menu →
  **"Achievements"** (new second option, between "Resume" and "Options" —
  `pause_menu.gd`'s `OPTIONS` array and `_select_main()` match are
  reindexed accordingly): the pause menu hides its own panel, calls
  `_achievements_overlay.open()`, and restores itself via the overlay's
  `closed` signal (`_on_achievements_closed()`). Refreshes live on
  `AchievementManager.achievement_unlocked` while open.
- **`AchievementToast`** (`scripts/ui/achievement_toast.gd`, `extends
  CanvasLayer`, `layer = 20`, sibling of `PauseMenu`/`AchievementsOverlay` in
  `HUD.tscn`) — a small "ACHIEVEMENT UNLOCKED" panel that slides in from the
  right, holds for `HOLD_DURATION` (3s), and slides back out via a single
  `create_tween()` on a `Control` container's `position:x`. Triggered by
  `AchievementManager.achievement_unlocked`, plays the `"special"` SFX, and
  shows the achievement's icon color + display name (so a secret
  achievement's name is revealed at the moment it unlocks, not before).
  `PROCESS_MODE_ALWAYS` keeps it animating even if the unlock coincides with
  a pause.
- **Persistence** — `save_manager.gd` adds three keys under `"progress"`:
  `achievements_unlocked` (→ `AchievementManager.unlocked`),
  `achievements_bies_count` (→ `bies_activation_count`), and
  `achievements_companions_seen` (→ `companion_types_seen`).
- **GUT coverage** — `tests/unit/test_achievements.gd` (8 tests, scene-free):
  count is in the CLAUDE.md-spec 12–20 range, ids are unique/non-empty, every
  `.tres` filename matches its `id`, both secret and visible achievements
  exist, `achievements`/`get_ordered_ids()` are populated correctly from
  `ACHIEVEMENT_LIST`, and a locked secret achievement's name/description are
  hidden via `get_display_name()`/`get_description()`.

> **Gotcha**: a freshly-added `class_name` Resource script (like
> `AchievementData`) isn't visible to other scripts under `--headless
> --quit-after` until the global script class cache is rebuilt — same trap as
> GUT's addon scripts (see "GUT unit tests" below). Run
> `godot --headless --editor --path . --quit-after 2000` once after adding a
> new `class_name` Resource type to populate
> `.godot/global_script_class_cache.cfg` before the next boot check.

### Audio (autoload `Audio`)
`audio.gd` generates short SFX procedurally at runtime as `AudioStreamWAV`
buffers (sine/square/noise tones and frequency sweeps), cached by name and
played from a small `AudioStreamPlayer` pool. Covers: attack, dash, special,
hit, hurt, defeat, swap, bies, ui_move, ui_select. Call `Audio.play("name")`.
Real audio files (OGG/WAV) may be dropped into `assets/sfx/` or `assets/music/`
and loaded via `load()` — `Audio.play()` can be extended to fall back to a file
if one exists before synthesising on the fly.

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
