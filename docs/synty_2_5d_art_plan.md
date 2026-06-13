# Synty 2.5D Art Overhaul — Plan & Asset List

**Status:** Planning · **Created:** 2026-06-13

A plan to replace Hunkle Bunkle's flat, color-blocked overworld (and eventually
all 13 levels) with a unified **Synty low-poly look**, rendered to 2D sprites so
the game stays 2D — no full 3D rewrite.

---

## Decisions (locked)

| Question | Decision |
|----------|----------|
| Dimensional direction | **2.5D** — render Synty 3D models in Blender to 2D sprites/billboards, drop into the existing 2D Godot scenes |
| Scope | **Whole-game art overhaul** — overworld first as the pilot, then all 13 levels + characters |
| Primary asset source | **Synty 3D packs** (POLYGON series) |
| Blender MCP | **Set it up** so Claude can drive Blender for the conversions |

**Recommended sub-decision (open to change):** keep the **ground plane top-down**
(grass/roads as flat tiles) but render **buildings/props at a fixed 3/4 ("dimetric")
angle** with visible height — the Stardew / Link-to-the-Past convention. This
preserves the current top-down movement, footprint colliders, and door-tile logic
untouched while making structures read as buildings. True isometric is **declined**
(would force a movement + collision rewrite).

---

## Why 2.5D instead of full 3D

Evaluated and declined full 3D. 2.5D keeps Synty's look and the value of the
asset rights **without** rewriting movement, camera, Y-sort, and all 13 levels.
`PlaceholderArt` remains the fallback for anything not yet rendered, so the game
is never broken mid-migration (consistent with `CLAUDE.md`).

---

## Current state (what we're replacing)

From `scripts/overworld/overworld_map.gd` + `scripts/systems/placeholder_art.gd`:

- The overworld is a flat top-down `TileMap`. **"Buildings" are just footprints
  filled with a solid terrain-color tile** (no building art), and roads are
  accent-colored tiles from `hb_tiles.png` (a 16px atlas upscaled 2×). That's
  why buildings don't read as buildings.
- The project **already mixes imported 2D assets** (Kenney Tiny Dungeon is
  imported; ~113 art files exist), so adding asset packs is consistent.
- **Blender MCP is not connected** — no `mcp__blender__*` tools, no `blender`
  binary on PATH. Must be installed/wired first.
- **No Synty assets are in the repo yet.**

---

## The pipeline (one sentence)

Synty FBX → Blender (orthographic render at the fixed 3/4 angle) → PNG sprite
sheets → Godot `Sprite2D`s replacing the `TileMap` footprints and tiles, with
`PlaceholderArt` as the fallback.

---

## Phases

### Phase 0 — Blender MCP setup (prerequisite)

**Done (2026-06-13):**
- ✅ Blender installed — **5.1.2** at `/Applications/Blender.app` (binary:
  `/Applications/Blender.app/Contents/MacOS/Blender`).
- ✅ `uv`/`uvx` installed (runs the MCP server).
- ✅ `blender` server registered in project `.mcp.json` (`uvx blender-mcp`) —
  verified it resolves & starts.
- ✅ `synty_source/` staging folder created (git-ignored + `.gdignore`).
- ✅ Blender add-on downloaded → `synty_source/blender/blender_mcp_addon.py`.

**Remaining manual steps (must be done inside Blender's UI — one time):**
1. Open Blender → **Edit ▸ Preferences ▸ Add-ons ▸ Install from Disk…** → pick
   `synty_source/blender/blender_mcp_addon.py` → enable **"Interface: Blender MCP"**.
2. In the 3D viewport press **N** for the sidebar → **BlenderMCP** tab →
   **Connect to MCP server** (starts the socket on port 9876).
3. **Restart Claude Code** so it picks up the new `blender` entry in `.mcp.json`.
   The `mcp__blender__*` tools then become available (with Blender running +
   connected).

**Then:** smoke test — drive Blender to render a test PNG.

**Blocker / needed from you:** the **filesystem path to the Synty packs**
(unzip them into `synty_source/packs/<PackName>/`).

### Phase 1 — Define the render pipeline (do once, reuse forever) — ✅ DONE (2026-06-13)

**Locked decisions & artifacts:**
- **Angle LOCKED: 3/4 dimetric** — azimuth 45°, elevation 30°, orthographic
  (compared against near-top-down on a real building; 3/4 chosen).
- **Render script:** `synty_source/blender/scripts/render_synty.py` — headless,
  batchable (`Blender --background --factory-startup --python render_synty.py -- ...`),
  auto-frames any FBX, applies the pack's shared albedo atlas, key+fill sun +
  soft ambient, transparent film, Standard view transform, EEVEE, RGBA PNG.
- **Validated** on `SM_Bld_House_Preset_01` + `SM_Bld_Shop_01` (Town pack) →
  `synty_source/renders/_samples/v2_*.png`. Color confirmed vibrant.
- **Whole buildings:** use the `SM_Bld_*_Preset_*` / `SM_Bld_Shop_*` /
  `SM_Bld_Church_*` FBX (pre-assembled), not the modular `SM_Bld_House_Wall/Roof`
  kit pieces.

Original notes:
- Reusable Blender scene/template: orthographic camera at the agreed 3/4 angle,
  fixed lighting (consistent sun direction so all shadows match), transparent film.
- **Scale contract** tied to the grid: 32 px/tile, 1280×720 viewport, integer
  scaling. Render buildings at 2–4× a tile-multiple footprint (e.g. a 4×3-tile
  building → 128×96 footprint, ~128×192 sprite incl. roof height). Import with
  `filter=off`, `mipmaps=off`.
- Output convention: `assets/art/synty/<category>/<name>.png` + a small manifest
  (footprint tiles, pixel pivot at the door) so Godot placement is data-driven.
- **Deliverable:** 1–2 sample buildings + a ground/road tile rendered end-to-end
  and approved before batching.

### Phase 2 — Overworld pilot (the proof)

**Stage 1 — building sprites: ✅ DONE (2026-06-13).** All 13 rendered to
`assets/art/synty/buildings/<location_id>.png` via
`synty_source/blender/scripts/render_overworld_buildings.sh` (re-runnable).

| Location id | Synty FBX | Pack | Note |
|-------------|-----------|------|------|
| pipe_organ_works | OfficeOld_Small_01 | City | tall brick works ✅ |
| old_parish_church | Church_01 | Town | ✅ steeple+gothic |
| iron_strings_gym | Shop_01 | Town | ✅ |
| recording_studio | Shop_02 | Town | ✅ |
| clocktower | WaterTower_01 | Construction | tower stand-in (no clock face) |
| harbor_docks | SK_Veh_Crane_01 | Construction | ✅ full mobile crane |
| library | CityHall_01 | City | ✅ columned civic |
| carnival | Stall_03 | Adventure | ✅ fairground market booth |
| underground | Portable_Office_01 | Construction | site-hut entrance |
| zip_line | GardenShed_01 | Town | park hut |
| vr_room | Large_04 | SciFiCity | ✅ sleek tech tower |
| the_drop | Chopshop_01 | SciFiCity | garage/warehouse, plain |
| grand_marquee | OfficeOld_Large_01 | City | ✅ grand facade |

**Stage 2 — Godot wiring: ✅ DONE (2026-06-13).** `overworld_map.gd` now:
- enables `y_sort_enabled` on the root so building sprites, the duo, and town
  NPCs interleave by screen-Y;
- `_build_building_sprites()` adds one `Sprite2D` per location, anchored at the
  front-bottom centre of its footprint, scaled to `footprint_w *
  BUILDING_WIDTH_FACTOR (1.4)`, dimmed if the location is locked;
- `_build_floor()` only tile-fills footprints with **no** sprite (fallback), and
  `_draw_building_overlay()` skips the old flat icon/tint when a sprite exists
  (name label still drawn for every location).
- Building PNGs are alpha-trimmed (PIL) so anchoring/scaling is tight; Godot
  `.import` files generated. Verified by screenshot — all 13 read as buildings.

**Stage 3 — props & cohesion: ✅ DONE (2026-06-13).**
- Synty ground tileset baked from NatureBiomes terrain (grass + dirt path) →
  `PlaceholderArt.make_synty_ground_tileset()`, replacing the old `hb_tiles`.
- `SPREAD` (1.5x) + `_grid()` scale building anchors & NPC homes apart; grid grown.
- `_scatter_props()` sprinkles Synty trees/bushes/hedges (assets/art/synty/props/)
  on free grass via a deterministic hash, avoiding roads/buildings/doors/NPC homes.
- Stand-in upgrades: harbor → full mobile crane; vr_room → sleek SciFi tower.

Remaining (optional): clocktower clock face + the_drop are acceptable stand-ins;
could add lamps/fences; tune `BUILDING_WIDTH_FACTOR` / `SCATTER_DENSITY`.

Original notes:
- Render the **13 building exteriors** (one fitting Synty building per location)
  + a **road + grass + path** ground set from Synty modular pieces.
- Godot side, in `overworld_map.gd`:
  - Replace `_paint_building()` footprint-fill with a **`Sprite2D` per location**
    anchored on the footprint, parented under a **Y-sorted** node so the duo
    walks correctly in front of / behind buildings. Keep
    `_build_building_colliders()` and door-tile entry logic **as-is**.
  - Swap the grass/road `TileMap` source from `hb_tiles.png` to the Synty-derived
    ground atlas; keep the existing layer / `set_cell` structure and `_paint_road`
    L-routing.
  - Add scatter props (trees, lamps, fences) as optional Y-sorted sprites for
    cohesion.
- `PlaceholderArt` stays the fallback for any building not yet rendered.

### Phase 3 — Roll out to the 13 levels

**Pilot — Pipe Organ Works floor + walls: ✅ DONE (2026-06-13).**
- Reusable, parameterized PlaceholderArt helpers (so every level reuses them):
  - `make_synty_floor_tileset(atlas_path)` — 64x32 atlas (plain + accent 32px
    tiles) baked from a Synty interior surface; cached per path.
  - `make_synty_wall_tile(tex_path)` — tileable wall texture; pair with a Sprite2D
    `region_enabled` + `region_rect = wall size` + `texture_repeat ENABLED`.
- `assets/art/tiles/synty_floor_workshop.png` (Shops wood) +
  `synty_wall_concrete.png` (Shops concrete), baked via PIL.
- `pipe_organ_works.gd` `_build_floor`/`_build_walls` now use them.

**Pilot props: ✅ DONE (2026-06-13).** Pipe Organ Works dressed with Synty
billboard props (barrel, oil-drum stack, brick pallet, crate, bucket, toolbox —
`assets/art/synty/props/`) via `_create_synty_props()` (bottom-anchored, fixed
positions). Signature organ/bellows/pipe-racks kept as PlaceholderArt (no Synty
equivalent). LootBox `_draw()` untouched (shared across levels). → Pipe Organ
Works is now a fully-Synty pilot level (floor + walls + props).

**Old Parish Church: ✅ DONE (2026-06-13).** Cobblestone floor
(`synty_floor_church.png`) + stone-block walls (`synty_wall_stone.png`); Town
church-prop billboards — pews, altar (church stand), candles — via a reusable
`_apply_synty_billboard()` helper (feet-anchored, scaled, falls back to
PlaceholderArt if a PNG is missing). Stained-glass / arch windows kept as
PlaceholderArt wall decals.

**Phase 3 rollout: ✅ COMPLETE (2026-06-13).** All 13 location environments are
on the Synty interior pipeline (per-theme floor/wall tiles baked from
Shops/NatureBiomes textures + prop billboards). Levels: Pipe Organ Works, Old
Parish Church, Carnival, Iron & Strings Gym, Recording Studio, Library &
Archive, Underground Tunnels, VR Escape Room, Harbor & Docks, Clocktower, The
Drop, Zip Line Park, Grand Marquee Cinema. Signature puzzle props with no Synty
equivalent (pipe organ, bells, glass booth door, chute) stay PlaceholderArt; the
"Gimme Dat Spoon" arcade is a programmatic `_draw()` UI minigame (no environment
to reskin). Floor tilesets: workshop wood, church/clocktower cobblestone, gym
tile, studio/cinema carpet, library marble, tunnel/dock/VR concrete, carnival/
drop dirt, park grass. Walls: concrete, stone, brick, wood.

### Phase 5 — Enemies & bosses (2026-06-13)

- **Code-driven windup telegraph** added to `enemy.gd`: a filling warning ring +
  intensifying red flash during WINDUP (was animation-only). Satisfies the
  "attacks must be telegraphed" guardrail for *any* sprite — animated or billboard
  — and improves combat readability across the board.
- **Boss → Synty Mech billboard.** `enemy.gd._try_synty_billboard()` loads
  `assets/art/synty/enemies/<enemy_name>.png` when present, building a SpriteFrames
  with every combat-state anim pointing at the single 3/4 pose (centered, like the
  PIL sheets). The clockwork/cinema guardian bosses now appear as the Mech
  `SM_Veh_Mech_01`. Works for any enemy that gets a billboard PNG later.
- **Regular enemies kept on their animated PIL sheets** — they have full
  windup/attack/death frames, which read better in melee than a static billboard.
  Gang Warfare/Heist humans are ASCII-only (not importable) and CityCharacters
  overlap the townsfolk, so a billboard reskin of regular enemies was declined.

**Remaining (optional):** animated character/enemy sheets (needs the rig-case
retarget); converting Gang Warfare/Heist ASCII FBX if distinct human enemies are
wanted; minor polish (clocktower clock face, richer cinema walls).

**Interior-asset survey (2026-06-13).** The Office + Shops + Casino packs cover
every level's interior. Floor/wall textures: Shops has Marble, Carpet (×6),
Tile (×5), Cobblestone, Concrete/Concrete_Blocks/Stripe, Brick (white/coloured),
ArcadeCarpet; Casino adds **Church_Wall**, HotelWall (×13), more Carpet. Props:
Office = servers, monitors, modems, **projector**, ducting, cable trays, pipes,
desks, chairs, couches, bookshelves, book groups, plants, rugs, posters; Shops =
gym benches, shelves, counters, registers, freezers, clothes racks, food/produce
displays, warehouse boxes. Verified billboards render cleanly. Rollout map:

| Level | Floor / Wall | Key Synty props |
|-------|--------------|-----------------|
| Old Parish Church | Cobblestone / **Church_Wall** | pews, shelves, candles |
| Iron & Strings Gym | Tile / Brick_White | gym benches, racks (Shops) |
| Recording Studio | Carpet / Concrete | desk, monitor, couch, server, posters (Office) |
| Clocktower | Concrete / stone Brick | gears (keep) + crates |
| Harbor & Docks | Concrete_Blocks / Concrete | warehouse boxes, barrels (Construction) |
| Library & Archive | Marble / Brick_White | bookshelves, book groups, desks, chairs (Office) |
| Carnival | ArcadeCarpet / Brick_Coloured | food/produce displays, market (Shops) |
| Underground Tunnels | Concrete / Concrete_Blocks | ducting, pipes, cable trays, server (Office) |
| VR Escape Room | Tile / Arcade_Wall | servers, monitors, modems, ducting, projector (Office) |
| Grand Marquee | Carpet/Marble / HotelWall | projector, couch, art, posters (Office) |
| Gimme Dat Spoon | ArcadeCarpet / Arcade_Wall | (arcade dressing) |
| Zip Line Park / The Drop | outdoor (grass/dirt) | nature + Construction crates |

### Phase 4 — Characters & enemies

**Overworld characters: ✅ DONE (2026-06-13).**
- CityCharacters ships all 19 characters in one binary FBX (`FBX/Character.fbx`)
  sharing a single armature, with **no animation clips**. So billboards, not
  animated sheets: `render_character.py` isolates a mesh, poses the shared rig
  from T-pose into a relaxed arms-down idle + slight stride, and renders the
  **front 3/4** (az 225 / el 30) → `assets/art/synty/characters/<key>.png`.
- 17 rendered: 5 leads (quinn=Roadworker, erin=HipsterGirl, evan=Jock,
  ben=PunkGuy, ethan=HipsterGuy) + 12 town NPCs (by quest_id).
- `overworld_map.gd`: `_billboard_frames()` builds a SpriteFrames whose
  idle/walk anims all point at the single billboard, so `overworld_player` /
  `town_npc` (which play those anims + flip_h) work unchanged; `_apply_billboard`
  scales to `CHAR_TARGET_H` and feet-anchors for y-sort. Falls back to the PIL
  sheet / placeholder when no billboard exists.
- Trade-off: billboards are a single static pose (no walk cycle) — motion reads
  via movement + flip; a code-driven bob could be added later. In-level
  characters/enemies still use the PIL sheets (unchanged).

**Remaining (optional):** in-level characters + enemies; a 2-frame idle/walk bob.

---

## Phase 6 — Hybrid cleanup (post-playtest, 2026-06-13)

**Problem (from a playtest):** inside levels the look reads as a *hybrid* — Synty
floors/props sit next to flat/programmatic and pixel-art elements, so it doesn't
feel cohesively 2.5D. Audit of what's still NOT Synty in levels:

| Element | Current | Impact |
|---------|---------|--------|
| **Walls** | Synty *texture* tiled FLAT on a top-down rect (no height/face) | **High** — reads flat next to 3/4 props; headline fix |
| **In-level player + NPCs** | PIL pixel sheets (`try_load_player`/`try_load_npc`) | **High** — most obvious pixel-art remnant; it's the character you control |
| **Regular enemies** | PIL pixel sheets | **High** — pixel-art vs Synty world |
| **Puzzle-gate props** | `make_gate_texture` ×~20 (doors, levers, hatches, booth doors, containers) | **Med** — flat bevel rectangles |
| **LootBox chest** | programmatic `_draw()` (draw_rect) | **Med** — one shared file, fixes every level at once |
| **Secret / office-wing walls** | still `make_wall_texture` (old brick) ×~12 | **Med** — built outside the main `_build_walls` |
| **Signature props** | `make_organ/bellows/gear/console/bell/...` | **Low** — no Synty equivalent; kept on purpose |
| **HUD / menus** | programmatic Control UI | **Low** — optional reskin (ApocalypseHUD pack owned) |

### Pass 6a — 2.5D walls (headline) — ✅ DONE (2026-06-13)
Implemented option #2 (faux-extruded): `PlaceholderArt.add_synty_wall_faces(wall,
size, tex)` builds a **lit top surface + a shadowed "front face" strip** (15 px)
along each wall's south edge, so walls read as low blocks instead of flat tiles.
Rolled out to all 13 levels' `_build_walls`. (Hero-room 3/4 wall billboards —
option #1 — remain a future upgrade.)

Original options considered:
Give walls real height instead of a flat texture. Options (pick one, prototype on
one level first):
1. **3/4 wall-segment billboards** (best look): render a Synty modular wall piece
   (Shops/Office/SciFiSpace have them) at the locked 3/4 angle; tile/9-slice it
   along each `$Walls` rect; add under a Y-sorted node so the duo passes behind
   tall walls — same trick as the overworld buildings. Most work, most cohesive.
2. **Faux-extruded wall**: keep the top-down rect but draw a Synty *top* strip +
   a darker *front* face strip (a few px of fake height). Cheap, code-only, reads
   far better than flat; no new renders.
3. **Per-pack wall cap**: a thin 3/4 "wall cap" billboard along the south edge of
   each wall run only (where height reads most), flat texture elsewhere.
   Recommend prototyping **#2** (cheap, global via the shared `_build_walls`
   helper) and reserving **#1** for hero rooms.

### Pass 6b — in-level characters & enemies — ✅ DONE (2026-06-13)
Resolved with **static Synty billboards + code-driven combat feedback** (no
combat animation clips exist in our packs, so this is the achievable route — and
it's the same approach the Mech boss already used):
- **Duo** (`player.gd._try_synty_billboard`): reuses each lead's overworld
  billboard for every player anim, centered (hurtbox-aligned), with a walk bob +
  ground shadow. The **attack arc is already code-drawn** (`_draw`), and
  hit-flash / dash motion+i-frames carry the rest, so combat stays readable.
- **Enemies** (already wired via `enemy.gd._try_synty_billboard`): rendered
  grunt/runner/brute/sentry billboards — a "crime crew" from Heist (thug/mobster/
  FBI) + a Western Frontier soldier brute (stocky → bigger). The **windup
  telegraph** (filling ring + red flash) + hit-flash provide the combat tells.
- Trade-off: no per-frame walk/attack *frames*, but the world is now fully Synty.

**Result: the entire game is Synty** — environments, props, all NPCs + congregation,
the duo, regular enemies, and bosses. PIL/PlaceholderArt remain only as fallbacks.

### Pass 6c — puzzle-gate props — ✅ DONE (2026-06-13, active ones)
Most `make_gate_texture` calls were already **fallbacks** (inside
`if not _apply_synty_billboard()`), so they never run. Swapped the remaining
**active** flat props for Synty billboards: underground **hatch** (SciFi floor
hatch) + **shortcut door** (Office door); the 3 **levers/switches** (pipe organ,
church, zip-line release) → SciFi button panel. Left as-is (signature/animated):
the house **organs**, the **glass booth door** + **librarian desk** (they scale/
fade-tween), the **Doug poster**, and the harbor **maze crates**.

### Pass 6d — LootBox chest (one change, every level) — ✅ DONE (2026-06-13)
`loot_box.gd` now shows a Synty wooden crate (`loot_crate.png`), dimmed when
looted; the programmatic `_draw()` chest stays as fallback. One shared file →
fixed all 13 levels at once.

### Pass 6e — leftover old-brick walls — ✅ DONE (2026-06-13)
The Pass 6a rollout replaced every level's `_build_walls` body, so no active
`make_wall_texture` calls remain in levels (only stale comments). Nothing to do.

**Recommended order:** 6d (lootboxes, trivial global win) → 6a #2 (faux-height
walls, global) → 6c (gate props) → 6e (leftover walls) → then decide on 6b.

### Updated-art candidates — new packs (2026-06-13)
Added & processed: **LegendaryChest**, **Western** (Cowboy/Sheriff/Gunman/
Business_Man/Cowgirl/Badguy — binary `Characters.fbx`), **WesternFrontier**
(Priest, GoldMiner, Bandit, Salesman, … — binary individual `SK_Chr_*` files).
Initial dig done (samples rendered to `/tmp/{legendary_chest,priest,goldminer}.png`).
Tasks to "dig in" later:
- **Father Aldric (church NPC) → Western Frontier `SK_Chr_Priest_Male_01`** —
  ✅ DONE. `old_parish_church.gd._create_father_aldric` builds a priest billboard
  (idle/talk emotion anims → one pose), feet-anchored, PIL fallback.
- **Quinn → a Western character** — explored (GoldMiner = rugged western worker,
  Salesman = Victorian gent). **Held:** none beat the current Roadworker for the
  "mechanic" read, so Quinn stays Roadworker unless the user prefers a swap.
  (Pose fix below now makes any of them one render away.)
- **LegendaryChest → optional loot-box upgrade.** Fancier than the wooden crate
  but **fantasy gold-ornate** (may clash with the modern town — taste call). It's
  modular: `Chest_01` (open body) + `Lid_01` → assemble for closed/open states.
- **Pose fix:** ✅ DONE. `render_character.py`'s `POSE` dict now covers BOTH the
  old POLYGON rig (`Shoulder_L`…) and the modern Sidekick rig (`UpperArm_L`,
  `Thigh_L`, `calf_l`…), which the Western/Frontier + CityCharacters v2 packs use.
  Their characters now render arms-down. (Also: render_character.py falls back to
  the single/first mesh when `--mesh` doesn't match, for individual `SK_*` files.)
- These also tie into **Phase 6b** (in-level characters) — if we tackle animated
  sprites, the priest/Quinn come along.

### In-level NPCs → Synty billboards — ✅ DONE (2026-06-13)
`PlaceholderArt.apply_npc_billboard(spr, key)` + a per-NPC billboard makes each a
one-line swap. Theme-matched across the WHOLE roster (not just western):
- **Uncle Doug → Office `Developer`** (a literal programmer — user's pick).
- **ARIA → SciFiSpace `RobotFemale`** (an actual android).
- **Cyrus → SciFiSpace `Junker`**, **Viktor → SciFiSpace `CrewCaptain`**.
- **Carnival guard → HorrorCarnival `Strongman`**, **Hieronymus → HorrorCarnival
  `FortuneTeller`**.
- **Rio → SciFiSpace `Crew`**, **Lena → CityCharacters `Paramedic`**,
  **Librarian → Office `Business_Female`**, **Cecil/Usher → Office `Boss`**.
- Plus earlier: **Mr. Bellows → W.Frontier `Salesman`**, **Father Aldric →
  W.Frontier `Priest`**. So packs map by theme: SciFiSpace→tech levels,
  HorrorCarnival→carnival, Office/City→modern, Western→period NPCs.
Wired via a regex over the identical NPC-creation blocks; all boot clean, PIL
fallback retained. The church **congregation** crowd (elder/deacon/choir/
caretaker/widow/confused) also got their own ordinary-churchgoer billboards
(CityCharacters + Office Cleaner). **Only pixel-art left: the controllable duo +
regular enemies** (true 6b — needs the animation pipeline).

### Other things worth checking (noticed during the audit)
- **Drop shadows** are characters-only; buildings, props, and level billboards
  float slightly — extend the shadow helper to all billboards.
- **In-level NPC portraits / dialog** use placeholder colors — fine, but verify.
- **Projectiles / combat FX** (`projectile.gd`, CombatFX sparks) are programmatic
  — likely fine stylistically, but check they don't read as "pixel" next to Synty.
- **Per-level lighting**: a `CanvasModulate` tint per level would unify the mixed
  art under one mood and hide a lot of the hybrid seams cheaply.
- **Floor tile softness**: the baked 32px floor tiles are a bit muddy up close;
  consider 64px tiles or a sharper downscale if any floor reads blurry.

---

## How this maps to the six original goals

1. **Buildings/roads look right** → Phase 2 (3/4 building sprites + Synty ground set).
2. **Art fits together** → single Blender render template = uniform angle, lighting,
   palette; shared scatter props.
3. **Blender MCP** → Phase 0.
4. **Synty assets** → primary source for all environment art.
5. **Other 2D assets** → Kenney/CC0 kept only as gap-fillers, flagged per-asset.
6. **Switch to 3D?** → Evaluated and **declined** in favor of 2.5D.

---

## Risks to watch

- Synty textures are **atlas-shared** across many models — watch material export
  from Blender.
- 13 buildings + ground + props is a real render **batch** — Phase 1's template is
  what makes it cheap.
- The **3/4 building angle must be locked** before batching, or everything
  re-renders.

---

# Synty Asset List

**Note:** Synty now runs a **~$30/mo subscription that unlocks the entire
catalog**. If subscribed, you already have everything below. If you own individual
packs, confirm which and the per-location list can be trimmed.

✅ = pack confirmed in catalog · ⚠️ = verify exact name / has caveats

## Starter set (unblocks Phase 0–2, the overworld pilot)

| Pack | Why first | |
|------|-----------|---|
| **POLYGON Starter Pack** (free) | Pipeline test asset for Blender→Godot before touching paid content | ✅ |
| **POLYGON Town Pack** | Backbone for the overworld — small-town buildings, roads, props | ✅ |
| **POLYGON City Pack** | Bigger facades + modular office buildings, street furniture, cinema/marquee structures | ✅ |
| **POLYGON Nature Pack** | Trees/terrain/scatter for cohesion + outdoor levels (park, the drop, zip line) | ⚠️ verify exact name |

That set is enough to render all 13 building exteriors + the town ground.

## Per-location → pack map (Phases 2–3)

| # | Location | Primary pack(s) | |
|---|----------|-----------------|---|
| 1 | Pipe Organ Works | **Construction** (tools/industrial interior) + Town exterior; organ stays custom | |
| 2 | Old Parish Church | **Apocalypse Pack** (Church w/ full interior — pews/altar) | ⚠️ run-down style, needs cleanup pass |
| 3 | Iron & Strings Gym | **Shops Pack** (treadmills, racks, weights, benches) | ✅ |
| 4 | Recording Studio | **Office Pack** interior; soundboard/instruments custom | |
| 5 | Clocktower | **Town/City** tower building; clock face custom | |
| 6 | Harbor & Docks | **Construction** (cranes, containers, loading docks) + Apocalypse docks | |
| 7 | Library & Archive | **City / Office** (shelves, terminals) | |
| 8 | Carnival & Fairground | **GAP — no dedicated Synty fair/carnival pack.** Fill from City/Adventure props + custom, or hunt for a theme-park pack | ⚠️ |
| 9 | Underground Tunnels | **Construction** (tunnels/pipes/hatches) + Apocalypse sewers | |
| 10 | Zip Line Park | **Nature** + **Adventure** (platforms/rope) | |
| 11 | VR Escape Room | **Sci-Fi Cyber City** (neon panels, glitch tech — Ethan fit) | ✅ |
| 12 | The Drop | **Nature** (grove/clearing) + Construction wreckage | |
| 13 | Grand Marquee Cinema | **City** (marquee/theater facade) + Office/custom interior | |

## Characters (Phase 4, later)

- **POLYGON City Characters Pack** and/or **POLYGON Adventure** characters for the
  5 leads + townsfolk + enemies.

## Known gaps — won't come from Synty (keep PlaceholderArt or AI pixel)

- Carnival rides / fairground
- The pipe organ
- Recording / music gear, the keytar
- Clock face

These signature props have no Synty equivalent and stay custom.

## Phase 7 — Frame-animated combat billboards (2026-06-13)

**Supersedes the Phase 4 "no animation clips / single static pose" trade-off.** The
owned **AnimLocomotion** pack (`synty_source/packs/AnimLocomotion/Animations/Polygon|Sidekick/…`)
*does* ship full-body idle/walk/run clips, so the in-level combat duo is now
**true-directional frame animation**, and *Gimme Dat Spoon* gets seated billboards.

**Pipeline (git-ignored under `synty_source/blender/scripts/`):**
- `render_anim_character.py` — renders one anim×azimuth as per-frame PNGs. Two modes:
  *clip* (transfer a Synty action onto the character armature; Blender 5 needs the
  action **slot** bound, else bones stay at rest) and *pose* (hand-authored keyframe
  sequences in `POSE_SEQUENCES` for attack/special/hurt/down/dash/revive/seated —
  no clips exist for these). `--freeze-arms` mutes the action's arm channels and
  holds the A-pose: the clips were authored for an A-pose bind but CityCharacters
  binds in a T-pose, so raw arm rotations splay outward. **Thigh forward pitch is
  local Y on this rig, not X** (found empirically — sitting/collapse poses use Y).
- `assemble_strips.py` (PIL) — union-crops every frame to one shared square box (so
  scale + footing stay constant across anims) and concatenates each anim into a
  horizontal strip `assets/art/synty/characters/anim/<key>/<anim>.png`.
- `render_anim_lead.sh <key> <mesh>` — full per-lead job list. Facings: down=az225
  (front), up=az45 (back), right=az135; **left = flip_h in engine**.

**Godot:** `player.gd._load_animated_frames()` slices each strip into `AtlasTexture`
frames (frame side == strip height), keyed loop/fps via `ANIM_LOOPING`/`ANIM_FPS`;
`_try_synty_billboard()` prefers it, falling back to the single static billboard then
PIL. `_set_state` routes attack/dash/hurt/down through the existing `_play_directional`
(degrades gracefully when a facing is missing); the synthetic walk-bob is gated off
when animated. `gimme_dat_spoon.gd` draws seated billboards (idle/grab/out per turn
state) on colored seat pads instead of the circle tokens.

**Done:** all 5 leads (29 strips each — idle, walk/run ×3, attack/special/hurt/down/
dash/revive ×3, seated ×4) + Uncle Doug seated (Office `SM_Chr_Developer_Male_02`).
Verified: loader builds 29 anims with correct frame/loop/fps; spoon table shows all 6
seated; 69 GUT pass; clean boot.
**Remaining (optional):** roll the same pipeline to the regular enemies; per-facing
authored combat poses (currently one pose seq rendered at 3 azimuths).

**To revisit (playtest feedback, 2026-06-13):** quality pass needed —
- **Walk reads as skating/static**, not a real stride. Sample more frames across the
  cycle and/or pick a clip with more vertical/leg travel; the union-crop + centered
  paste may also be flattening the up/down bob (consider feet-anchored, not centered).
- **More frames overall** — current counts (walk 8, poses 2–3) are below the old PIL
  sheets; bump locomotion sampling and add in-between pose keys.
- **Arms clip inside the torso** in some poses — the `--freeze-arms` A-pose and the
  authored shoulder angles need widening / depth offset so hands clear the body.

## Practical acquisition order

1. **Free Starter Pack** + **Town** + **City** + **Nature** (whole overworld pilot)
2. **Construction**, **Shops**, **Office**, **Sci-Fi Cyber City**, **Apocalypse**,
   **Adventure** (as we roll into the 13 levels)
3. **City Characters** (Phase 4)

---

## Open questions for you

1. Are you on the **Synty subscription** (= you have everything) or do you own
   **specific packs**? (If specific, list them so the plan trims to what's owned.)
2. Want me to **dig for a carnival/fairground** solution now, or defer it?
3. Confirm the **3/4 building angle** recommendation, or prefer a different look.
4. Point me at where the **Synty packs will live** on disk so Phase 0 can start.

## Sources

- https://syntystore.com/
- https://syntystore.com/products/polygon-town-pack
- https://syntystore.com/products/polygon-city-pack
- https://syntystore.com/products/polygon-office-pack
- https://syntystore.com/products/polygon-construction-pack
- https://syntystore.com/products/polygon-shops-pack
- https://syntystore.com/products/polygon-sci-fi-cyber-city
- https://syntystore.com/products/polygon-apocalypse-pack
- https://syntystore.com/products/polygon-adventure-pack
- https://syntystore.com/products/polygon-city-characters-pack
