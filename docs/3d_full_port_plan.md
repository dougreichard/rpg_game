# Hunkle Bunkle — Full 3D Port: retire 2D, go bigger

Status doc + roadmap. Written after the 3D port reached a **playable end-to-end loop**
(boot → 3D Synty-city overworld → enter a building → clear a 3D level → return, progress
persisted). This covers: (1) what's done, (2) the plan to remove the 2D pipelines, (3) the
"remove assumptions" upgrades (camera, vast multi-phase interiors), and (4) where Claude
Design fits.

---

## 1. Where we are now

- **All 13 levels + Gimme Dat Spoon** run as native 3D scenes (`scenes/3d/*`, `scripts/3d/*`).
- **Reusable kit:** `Level3D` (env/floor/wall/prop/spawn/HUD/dialog helpers), `Npc3D`
  (mesh + idle/walk + wander + speech bubble), `Duo3D` (both leads + swap + P2 co-op),
  `Player3D`, `Enemy3D` (full combat FSM + **boss AOE slam** + **ranged Sentry**), `Combat3D`,
  `Projectile3D`, `camera_rig_3d` (re-framable follow cam).
- **Walkable Synty-city overworld** (`Overworld3D`) with real City-pack building shells,
  roads, sidewalks, props; per-location name billboards; unlock gating; `main_scene` boots here.
- **Loop closed:** Esc in any level → Town Map; completion persists via `GameManager`.
- **Asset pipeline:** `synty_source/blender/scripts/export_prop.py` bakes any Synty FBX →
  textured GLB (pack-scale caveat documented).

**Still placeholder / box-geometry:** level *interiors* are primitives (the overworld proves
the Synty-mesh pipeline; interiors haven't been re-dressed yet). Stealth-vision FSM not ported
to `Enemy3D`. No 3D title/menu/result screen. Town building door-facing is a guess.

---

## 2. Plan to retire the 2D pipelines

Goal: reach a checkpoint where the 2D scenes/scripts/art can be deleted without losing
anything, then delete them. Do it **gated** — only delete once each capability has a 3D peer.

### 2A. Parity checklist (must all be ✅ before deleting 2D)
| Capability | 2D home | 3D peer | State |
|---|---|---|---|
| Title / new-game / continue | `TitleScreen.tscn` | *(none yet)* | ❌ build 3D title |
| Result / endgame screen | `ResultScreen.tscn` | cinema banner only | ❌ build 3D result |
| Pause menu / How-to-Play / Quests / Achievements / Inventory overlays | `PauseMenu` + overlays | *(none yet)* | ❌ port overlays (these are `Control`-based — reuse as-is on a 3D `CanvasLayer`) |
| Overworld town + NPC quests (12 quest-givers) | `overworld_map.gd` | `Overworld3D` (no NPC quests yet) | ⚠ town walk done; **port the 12 NPC quests** |
| Stealth (vision cone / noise / hiding / calm) | `enemy.gd` | `Enemy3D` (combat only) | ❌ port stealth FSM |
| Animal companions (Frosty, Twinkle, etc.) | `animal_companion.gd` + per-level | *(none)* | ❌ port companions |
| Bies Mode | `bies_mode.gd` | `Engine.time_scale` reusable as-is | ⚠ wire input + HUD in 3D |
| Save/achievements/audio/dialog/items | autoloads (render-agnostic) | reused unchanged | ✅ |

### 2B. Sequenced work to reach the checkpoint
1. **3D shell screens** — Title (New/Continue/How-to-Play), Result/endgame, Pause menu.
   The existing overlays are `Control` trees; they drop onto a 3D `CanvasLayer` with almost
   no change. ~1–2 sessions.
2. **Port the 12 town NPC quests** into `Overworld3D` — reuse `QuestData`, `DialogBox`,
   `quest_log_overlay`. Place quest-givers as `Npc3D` around the town. ~1 session.
3. **Stealth FSM in `Enemy3D`** — PATROL/INVESTIGATE + vision cone (3D raycast on the XZ
   plane) + `GameManager.emit_noise`/`calm_enemies` (already render-agnostic) + 3D hiding
   volumes. Re-enable stealth on the levels that use it. ~1–2 sessions.
4. **Animal companions in 3D** — port the `CHARGE→STRIKE→RETURN` pattern onto Area3D; wire
   the per-level summons. ~1 session.
5. **Bies Mode + companion/animal HUD bits** in the 3D HUD. ~0.5 session.
6. **Interior art pass** (see §3) — not strictly required to delete 2D, but it's the point
   of the port; can run in parallel.
7. **Flip the switch:** delete `scenes/levels/`, `scenes/ui/` (2D), `scripts/levels/`,
   `scripts/players|enemies|overworld` (2D), the PIL sprite generators, and the
   billboard render pipeline. Keep autoloads, data resources, `assets/art/synty` source,
   `synty_source/`. Update `CLAUDE.md` + memory to declare 3D the only pipeline.

### 2C. Near-term easy wins (low-risk, do anytime)
- Town **building door-facing**: confirm Synty front orientation, fix yaw per row.
- **Texture dedup**: the town kit embeds 25 copies of the City atlas (~8 MB). Export with a
  shared external texture (or post-process GLBs to reference one PNG). Saves most of that.
- A **GUT test** for the overworld unlock-gating (`LOCS`/`requires` ↔ `completed_locations`).

---

## 3. Removing assumptions — go bigger

### 3A. Camera — recommendation: **dynamic fixed-angle, not OTS 3rd-person**
A true over-the-shoulder 3rd-person camera tempts "vast interiors," but it fights two pillars
of this game:
- **Local co-op** needs *both* leads framed at once — OTS can't.
- **Brawler readability** depends on seeing telegraphs/AOE rings from above — OTS hides them.

Recommendation: keep the **3/4 follow** as the combat default, but make it **room-aware**:
- Per-room/per-phase camera framing (distance, elevation, optional yaw) via the existing
  `camera_rig_3d.reframe()` — pull back in big halls, push in for tight tunnels, go higher
  for vertical shafts.
- Smooth blends on phase transitions (the rig already has a tween `move_to` API for set-pieces).
- **Optional** free-look/zoom for solo *exploration* phases that snaps back to fixed 3/4 when
  combat starts. Expose a player toggle.
This buys vast/complex spaces without losing co-op or combat clarity. (A full OTS mode could be
a later *single-player-only* option, not the default.)

### 3B. Vast, multi-phase interiors — a **Phase/Room architecture**
Today each level = one room (a box). Reframe a level as a **graph of Rooms (phases)**:
- **`Room3D`** node: own geometry/lighting/props, spawn points, an optional puzzle, optional
  combat wave, a camera framing, and entry/exit portals. Built from Synty interior kits.
- **`Level3D` becomes a Room orchestrator**: holds the room graph, streams/activates the
  current room(s), tracks per-room completion flags (already have `level_progress`), and
  decides win when the *required* rooms are done.
- **Portals**: doorways / **stairs** (Player3D already has gravity + `move_and_slide`, so ramps
  and stepped stairs traverse Y today) / **elevators** / **tunnel mouths**. Multi-floor,
  basements, and sub-buildings all fall out of "a Room at a different Y connected by a portal."
- **Optional content**: each Room flags its puzzle/combat as *required* (gates progress) or
  *optional* (loot, lore, a companion, a shortcut). This directly enables "rooms are phases,
  each with optional puzzles/combat."

Worked example — **Clocktower** becomes a 3-phase dungeon:
`Lobby (talk Hieronymus)` → stairs → `Gear Hall (Quinn puzzle + grunts)` → stairs →
`Belfry (Ben bells + the Boss arena)`, with an *optional* side `Maintenance Crawlspace`
(loot + a spare-gear shortcut). Same content, far richer space.

Rollout: build `Room3D` + the orchestrator, convert **one** level (Clocktower or Underground —
both are natural multi-floor/tunnel fits) as the vertical slice, checkpoint, then convert the
rest during the interior-art pass. The 13 existing single-room levels keep working as
"one-room levels" until converted, so this is incremental.

### 3C. Interior art — use the **whole Synty library**
The overworld proved `export_prop.py`. For interiors, bake per-theme kits and dress rooms:
- Gym → **(no Synty gym pack)** use Construction/Shops props + the primitives we have.
- Studio/Office/Library → **Office** pack (desks, shelves, mixing/AV props).
- Church → **Knights/Adventure** stone + the Town church pieces.
- Harbor → **Construction** (containers, cranes, crates).
- Carnival → **HorrorCarnival** pack (rides, stalls, tents) — already owned.
- Tunnels/Drop → **Nature/Construction**; VR → **SciFiCity/SciFiSpace**; Casino → **Casino**
  pack for Gimme Dat Spoon.
Bake these as committed GLBs; dress `Room3D`s with them. (Watch the per-pack cm/m scale.)

---

## 4. Should we use Claude Design? — **yes, for the UI layer only**

`claude.ai/design` (the `DesignSync` tool + `/design-sync` skill) is a **UI design-system**
tool: it keeps a library of **HTML/CSS component previews** (buttons, panels, cards, HUD
widgets, type/color tokens) in a Claude project you can iterate on visually, and syncs them to
a local folder. It is **not** a 3D/level/world design tool.

Where it helps Hunkle Bunkle:
- Design a coherent **game-UI design system** — title, pause menu, HUD (health/Bies/boss bar),
  dialog box, inventory panel, quest log, the overworld building cards/billboards — as HTML/CSS
  components with shared **tokens** (the warm Synty gold/cream palette, Nunito type, spacing,
  the key-glyph prompts). Iterate look-and-feel fast and visually, in one place.
- Then **translate the tokens + component specs into Godot** `UITheme` (`scripts/ui/ui_theme.gd`)
  and the `Control` scenes. Claude Design is the *source of truth for the look*; `UITheme` is the
  *implementation*. This is especially valuable right now because the 2D→3D move means rebuilding
  Title/Result/Pause/HUD anyway (§2B.1) — design them once, cleanly, in Design.

How to use it (workflow):
1. `/design-sync` → create/select a Claude Design project (e.g. "Hunkle Bunkle UI").
2. Author component previews (HUD bar, dialog box, menu button, inventory tile, building card)
   with the warm-Synty tokens; iterate visually on claude.ai/design.
3. Sync down; I translate each component's tokens/spec into `UITheme` + the matching Godot
   `Control` scene, one component at a time.

Where it does **not** help: 3D camera, level/room layout, Synty mesh dressing, combat — those
stay in Godot + the Blender export pipeline. Net: **adopt Claude Design for the UI/HUD redesign
that the port needs anyway; keep everything 3D/world in the current Godot+Blender flow.**

---

## 5. Suggested order

1. Easy wins (door-facing, texture dedup) + **3D shell screens** (Title/Result/Pause) — and in
   parallel start a **Claude Design** UI system to drive those screens' look.
2. Port **town NPC quests**, **stealth FSM**, **animal companions**, **Bies** → hit the §2A
   parity checklist.
3. **Delete the 2D pipeline**; declare 3D canonical in `CLAUDE.md`.
4. Build the **`Room3D` phase system**; convert Clocktower as the vertical slice.
5. **Interior art pass** with per-theme Synty kits; convert remaining levels to multi-phase.
