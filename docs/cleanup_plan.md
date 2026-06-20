# Cleanup plan — completion plan for `cleanup_tasks.md`

Organised so the **Prop-Farm-dependent** work is isolated at the end (Phase F) and **deferred until
the farm's new REST API is up**. Everything in Phases 1–5 uses only GDScript + existing assets +
local Synty Blender bakes (`export_prop.py` — NOT the Prop Farm), so it can proceed now.

> **Farm status:** the Prop Farm (CUDA box) is paused while its REST API is reworked. `export_prop.py`
> (Synty FBX → GLB, local Blender) and `export_anim_authored.py` / `attach_*.py` are **not** the farm
> and remain available.

---

## Phase 1 — Quick GDScript wins (no farm)  ✅ DONE (c4e2604)
1. **First-time intro beat** (`overworld3d.gd` + a `SaveManager`/`GameManager` first-run flag): on the
   very first overworld entry, flash a silly **"Based on Actual Events"** title card, then Quinn barks a
   speech-bubble sequence — "Hi, I'm Quinn" → "Now where is Uncle Doug?" → "What a crock!" (reuse the
   `Npc3D` speech-bubble + a small sequenced timer; one-shot, persisted so it never repeats).
2. **Arcade overworld rename** (`overworld3d.gd` `LOCS`): label the arcade location **"Arcade"** (not
   "Gimme Dat Spoon") to preserve the surprise. (Completion id / scene unchanged.)
3. **Carnival overworld building** (`overworld3d.gd` `LOCS["carnival"].glb`): reuse one of the Carnival's
   interior **hero props** (carousel / funhouse_facade / ticket_booth) as the overworld building instead
   of the generic `fairstall`, for a more thematic read.
4. **The Drop — hedge walls** (`the_drop3d.gd`): swap the visible boundary walls for **hedge/bush props**
   (Synty `bush`/hedge) and keep the existing wall colliders as **invisible** collision mesh (it's an
   outdoor level — matches the outdoor recipe).

## Phase 2 — Harbor & Docks props/cleanup (no farm)  ✅ DONE
Chain-link fence baked (GangWarfare `SM_Bld_Fence_Wire_01`, cm→`--scale 0.01`) + run along the
north/water edge with a crane gap; the placeholder `_stack` colour-cubes now stack real
`cargo_container.glb`; the outdoor-resize + extra-puzzle pass was already applied in the level
elaboration ("if so ok" → left as-is).
5. **Chain-link fence**: bake a Synty wire/metal fence (`SM_Bld_Fence_Wire_01` or `SM_Bld_Metal_Fence_01/02`)
   via `export_prop.py` and line the open outdoor edges with it (it's a dockside yard).
6. **Kill remaining generic cubes**: find the leftover `box_mesh` placeholders in `harbor_docks3d.gd` and
   replace with fitting Synty/existing props (or hide them as collision-only).
7. **Audit the outdoor pass**: confirm Harbor got the "resize for outdoors" + extra-puzzle treatment; if
   not, apply the outdoor recipe (spaced areas, bush boundary, a dressed sub-area).

## Phase 3 — Arcade overworld building polish (no farm; farm upgrade deferred → F)  ✅ DONE
Baked Synty `SM_Sign_Large_Arcade_01` (cm→`--scale 0.01`) and mounted it on the arcade building front (keeps the Gimme Dat Spoon surprise). Bespoke farm building still deferred to F.
8. Theme the current arcade building **now** with the Synty **`SM_Sign_Large_Arcade_01`** sign (+ maybe a
   couple of arcade-machine props at the entrance). A bespoke farm-generated arcade building is a
   deferred nice-to-have (Phase F).

## Phase 4 — Al's Rooftop Garden (no farm for the core)  ✅ DONE (core)
**Access (per Doug): NOT a new overworld building — it IS the Arcade's interior.** The
`gimme_dat_spoon` LOCS `scene` was repointed from `Spoon3D.tscn` → `AlsRooftopGarden3D.tscn`; the
"Arcade" building + ARCADE sign stay, so entering the Arcade (after Grand Marquee / Doug found)
drops you on Al's dusk rooftop jazz club. Al (host, bellows mesh) greets; Uncle Doug sits at a
bistro table (recap dialog that flips to a celebratory state at 12 spoons); Fred & Ginger pose as a
dance pair (congregant_m/f); a cabinet (`▶ PLAY`, `SPOON_POS`) launches the real `Spoon3D` game.
Rooftop deck + hand-built parapet + garden dressing + warm lights + `Audio.play_music("jazz")`
(procedural fallback). Combat-free, boots clean. `_spoons_held()` counts numbered_spoon_01..12.
**Deferred / optional (not blocking):** Fred's top hat (attach_hat), a ballroom-dance authored clip,
bespoke Prop-Farm jazz props (Phase F). **Verify in-engine:** rooftop layout / NPC spots are by
estimate — eyeball + nudge positions.
9. New `scenes/3d/AlsRooftopGarden3D.tscn` + `scripts/3d/als_rooftop_garden3d.gd` on the `Level3D` kit —
   an **outdoor rooftop jazz club**. **Gating:** unlocks **after Uncle Doug is found**, and is an
   alternate way to reach the Arcade **until Gimme Dat Spoon is unlocked**; then either kept or removed
   once all 12 spoons are acquired (add the proper unlock/lock gate in `overworld3d.gd`).
   - **Al** — cool-jazz-musician lobby NPC (dialog; can share or have his own tree).
   - **Uncle Doug** — seated, with several dialog interactions (some recap what the player accomplished,
     some point toward finding all the spoons).
   - **Fred & Ginger** NPCs (reuse lead/NPC meshes; **top hat** via `attach_hat.py`; a **ballroom-dance**
     authored pose-sequence clip) — the dance anim is **optional/nice-to-have**.
   - **Jazzy music** (`Audio.play_music` — procedural or an asset track).
   - Build from existing Synty props + primitives now; any bespoke jazz-club props → Phase F (optional).

## Phase 5 — Gimme Dat Spoon presentation polish (no farm; big UI/camera task)
10. **Camera direction**: stop the current camera drift; on each turn **jump-cut** to a player camera
    across the table, then **slow dolly-in**. Pause a beat for NPC turns; for the **human** player, hold
    after the dolly until their choice is made.
11. **Lower-third** (poker-tournament style): the active player's **name + spoon count**.
12. **PiP announcer**: a picture-in-picture "color commentator" giving commentary via a speech bubble,
    drawing on the player's run (the things they had to unlock via each character's **special ability** or
    **inventory**).
13. **UI polish**: a **scrollbar** for a long spoon list during selection; general tidy.
14. Add **storytelling animations** where they help the beat.

---

## Phase F — DEFERRED until the Prop Farm's new REST API is live
- **B3 building rerolls** (from `polish_plan.md`): regenerate `gym_bld`, `organ_works_bld`, `studio_bld`
  (came out rough); then wire into Gym / Pipe Organ Works / Recording Studio overworld slots.
- **Arcade building** (Phase 3): optional bespoke farm-generated arcade/video-hall building (Synty sign
  covers it until then).
- **Al's Rooftop Garden** (Phase 4): optional bespoke jazz-club props.
- **Pets / rigging infra** (`cleanup_tasks.md` "Pets"): check whether **UniRig** is installed on the
  Windows box; if not, request it be added + made accessible. Then explore adding a **character-generator
  endpoint to the Prop Farm** for rigging the pets (and evaluate it for NPCs too). This is Windows-box +
  new-API infrastructure — fully gated on the farm/API.

**Suggested order:** Phase 1 (fast, visible) → 2 → 3 → 4 → 5; Phase F whenever the farm/API returns.
Phases are independent enough to reorder on request.
