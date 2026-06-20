# Polish plan — character/world/UI cleanup

Captured from `clenup_tasks.md`. Organised into **3 context-isolated plans** so each can be
executed in one focused pass without thrashing between subsystems. Suggested order: **C (UI)** for a
quick daily-visible win, then **B (world dressing)**, then **A (characters)** — the big one, batched
so the Blender/animation context is loaded once.

---

## Plan A — Characters: identity, look, pose, special anims
**Status:** A1 ✅ (09542d6) · A2 ✅ (1e7db03) · A3 ✅ (059c2c6 · 0486b89 · ca729f8) · A4 ✅ DONE — Plan A COMPLETE.

**A4 — per-character Special animations.** Each lead's Special now plays a unique gesture (the "special"
clip): Quinn = HA laugh (the pre-existing "special" seq, unchanged); Erin = fast-talk gesticulation;
Evan = fingers-to-mouth whistle + beckon; Ben = keytar riff; Ethan = tablet hack-tap. Authored as
`special_<name>` POSE_SEQUENCES in render_anim_character.py (+ `_larm`/`_head`/`_spine` helpers), baked
via the new `export_anim_authored --special <key>` arg. **Code:** the "special" clip was baked but
NEVER played — added `_special_anim_t` to player_3d.gd (set on the special input, played in the anim
state machine: attack > special > walk/idle). Rebaking a lead drops its joined accessory, so the flow is
rebake body (--special) → re-attach the accessory (attach_prop/attach_hat). Rig limit: arms only swing in
the side (Z) plane, so "both hands in front" reads as "presenting to the side" — acceptable at the
pulled-back camera.

**A3 — all LOOKS DONE (accessories still TODO).** Body picks (all Doug-approved, all boot clean):
- **Quinn** = SpyKit `SK_Chr_Male_Spy_Necktie` (dark suit+shades, `PolygonSpy_Texture_01_A`) + near-black **flat cap** (Kids `SM_Chr_Attach_Hat_Flatcap_01`) via `attach_hat.py`.
- **Erin** = City `SK_Character_Female_Jacket` (`PolygonCity_Texture_01_A`) — red jacket+tee+jeans (no true sweater mesh exists; Doug picked this).
- **Evan** = unchanged (CityCharacters Jock = red letterman jacket + jeans — already matched spec).
- **Ben** = City `SK_Character_Male_Jacket` (`PolygonCity_Texture_01_A`) — jacket+tee+jeans, tousled hair (off PunkGuy mohawk per Doug).
- **Ethan** = Office `SK_Chr_Developer_Male_01` (`PolygonOffice_Texture_01_A`) — '</>' code t-shirt+jeans+glasses. Freed up by re-baking the church **congregant_m → Office `SK_Chr_Business_Male_02`** so they don't share a mesh.
- **Doug** = unchanged (Office Developer_Male_02 — older/balding/glasses — already matched).

**attach_hat.py** (the hat tool) joins an accessory mesh into the body mesh + weights new verts to a named bone (debugged: bone-parent re-adds 17m leaf-bone length; fresh skin collapses to origin; join-into-body is the only reliable path). It also strips the stray origin "Icosphere" the SpyKit FBX carries (Blender re-import falsely re-reports an Icosphere — trust raw GLB JSON). Generalizes to `Hand_R` for held accessories.

**Process (per Doug):** exhaust Synty mesh options across ALL packs, render candidates, let Doug PICK, before any Blender recolor. **Rig gotcha:** packs that ship ONLY an `Unreal_Characters`/`Unreal` FBX (Heist SWAT, Shops Musician, Casino) use lowercase Unreal-mannequin bones (`upperarm_l`) our pose code won't match → stuck A-pose. Use packs with a standard `SK_Character_*`/`Characters/` rig (`UpperArm_L`, `head`): City, CityCharacters, SpyKit (Characters/, not Unreal/), Office, WesternFrontier, Kids.

**A3 accessories — 4/5 DONE** (via `attach_prop.py`, the generalized hand version of attach_hat: bone arg + euler rotation, solid-tints the prop so no extra texture, joins into the body mesh weighted to `Hand_R`). All boot clean, single-mesh, no new texture files:
- **Quinn** = Town `SM_Item_Wrench_01` (steel tint, ~0.34m, rx90) — reads clearly.
- **Doug** = Office `SM_Prop_Laptop_01` (dark slate, ~0.40m) — dark slab at side, reads.
- **Erin** = Adventure `SM_Prop_Book_01` (blue tome, ~0.30m) — single thick book (the Office Book_Group stack scaled too small to read).
- **Ethan** = Shops `SM_Prop_Computer_Tablet_01` (dark, ~0.30m, rx90) — tablet (a phone was too small/ambiguous).
- **Evan** = none (fists/animals).
- **Ben** = Prop-Farm `ben_keytar.glb` (painted, seed 13 — no Synty keytar exists), attached keeping its diffuse (attach_prop now handles .glb props). ben.glb carries 2 textures (body + keytar).

**Lesson:** the idle hand is a relaxed OPEN pose (no grip), so compact props (book/phone) hide against the hip at gameplay distance — only elongated/bulky items (wrench, laptop, tome, tablet) read; size props ~1.4× and prefer larger items. rx=90 aligns elongated props with this rig's grip.
**Re-bake manifest** (for A3/A4 — `export_anim_authored.py --kind lead`, /tmp/bake_all.sh): leads = `CityCharacters/FBX/Character.fbx` meshes Character_Roadworker(quinn)/HipsterGirl(erin)/Jock(evan)/PunkGuy(ben)/HipsterGuy(ethan), atlas Polygon_City_Characters_Texture_01_A; Doug+NPCs = `Office/Characters/SK_Chr_*` (Developer_Male_02=doug, Boss_Male_01=bellows, Developer_Male_01=congregant_m, Business_Female_01=congregant_f), atlas PolygonOffice_01_A; aldric = `WesternFrontier/.../SK_Chr_Priest_Male_01`, atlas PolygonWesternFrontier_01_A; kids = `Kids/Chr/SK_Chr_Kid_*`, mesh "Kid", atlas PolygonKids_01_A.
**Context:** Blender character pipeline (`synty_source/blender/scripts/export_anim_authored.py`,
`render_anim_character.py` pose code), the lead meshes (`assets/models/characters/{quinn,erin,evan,
ben,ethan,uncle_doug}.glb`), `CharacterData` (`scripts/players/character_data.gd` + `data/characters/*.tres`),
dialog text. Do A1 first (cheap, no Blender); then batch A2–A4 in ONE re-bake pass (all re-bake the leads).

### Reference table (corrected — the source had "Evan" twice; 2nd is **Ethan**)
| Player | Gender | Look | Signature accessory |
|--------|--------|------|---------------------|
| Quinn | male | all-black outfit + black hat | tool (wrench) |
| Erin | female | sweater + pants | book |
| Evan | male | letterman jacket, strong build | (none specified — fists/animals) |
| Ben | male | shirt + jeans | instrument (keytar) |
| Ethan | male | t-shirt + jeans | phone / tablet |
| Uncle Doug | male | older, balding | laptop |

### A1 — Identity & text fixes (no Blender; do first)
- **Doug's initials:** use **"UD"** or **"UNC"**, never an invented surname. Fix `church3d.gd:452`
  ("D. Hunkle" register signature) and grep for any other assumed Doug surname/initials. (Note:
  "Hunkle Bunkle" as the *family/title* — e.g. `result3d.gd` — stays.)
- **Pronouns:** only **Erin is female**; the rest of the leads + Doug are male. Audit dialog/NPC
  lines for wrong pronoun references per character and correct them.
- *(Optional)* add a `gender` field to `CharacterData` if any runtime text needs it (currently none does —
  it's all authored strings, so a grep-and-fix is likely enough).

### A2 — Idle-pose fix (A-pose) — affects every lead + NPC
- Leads/NPCs still read as A-pose. The idle clip is authored in `render_anim_character.py`
  (`POSE_SEQUENCES["npc_idle"]`). Bring the arms convincingly **down to the sides** (and a little
  relaxed bend) so idle reads as "standing," not "T/A-pose." One pose edit → re-bake all leads + the
  NPC meshes (congregant_m/f, bellows, aldric, kids). *(Lobby-NPC A-pose is fixed here too; their
  props are Plan B.)*

### A3 — Player look + signature accessory (the meaty pipeline)
- Restore each lead's outfit + accessory (table above). **Approach, least-human-interaction first:**
  1. **Synty texture/material swap** — pick the right Synty source body/outfit + atlas region; recolour
     by moving UVs to a different atlas swatch (e.g. all-black for Quinn) or a material tint in the bake.
  2. **Accessory as an attached prop** — bake/generate the signature item (wrench, book, keytar, phone,
     laptop, hat) and parent it to the right hand/head bone in the export (or place as a child offset).
     Synty packs first (tools/instruments exist), Prop Farm for anything missing.
  3. **If recolour/UV won't do it** → create a `blender_assets/` folder with a `.blend` per rig family +
     a short README of the manual step, and a script that consumes it — minimise human interaction, but
     accept a documented manual step for the leads (they're important; exact > automated).
- Output: re-baked `{name}.glb` per lead (+ Doug) with correct look + accessory, animating via the
  existing clip set.

### A4 — Special-power animations
- A unique, thematic clip per character's Special, played on `special` (Quinn's HA laugh-stun, Erin's
  fast-talk gesture, Evan's animal-summon whistle, Ben's keytar riff, Ethan's hack gesture). Author as
  new `POSE_SEQUENCES` entries + add to `LEAD_CLIPS` in `export_anim_authored.py`; `Player3D._attack`/
  special hook plays the clip. Batches with the A2/A3 re-bake.

---

## Plan B — World dressing: lobby NPCs + overworld
**Status:** B1 ✅ (c42c6df — lobby-NPC props) · B2 ✅ (88775c8 — overworld last-played duo) · B3 ⬜ (optional).
**Context:** level scripts (`scripts/3d/*3d.gd`), `overworld3d.gd`, `GameManager`, prop placement +
Prop Farm. GDScript-only (no Blender); independent of Plan A.

### B1 — Lobby-NPC thematic props
- Each lobby NPC should sit/stand with a themed prop, restoring lost staging:
  - **Bellows** (Pipe Organ) — back at a **desk** (we lost the seated-at-desk staging).
  - **Cecil/usher** (Cinema) — at a **ticket booth / concession stand** (ticket_booth prop exists).
  - Sweep the rest: Viktor (harbour office desk), Sasha (studio console), Priswick (library desk —
    now `desk.glb`), Marv (gym front desk), Cyrus, Lena, Rio, ARIA, Pearl/Marco. Add a fitting prop
    (mostly reuse `desk`/`table`/`ticket_booth`/existing level props).
- *(NPC A-pose itself is fixed in Plan A2.)*

### B2 — Overworld returns the last-played duo
- Returning to the overworld should stroll the **duo from the location just played**, not always the
  first-two-unlocked. `overworld3d._overworld_duo()` currently slices `unlocked_characters[0..1]`.
  Fix: `GameManager` records the entering duo per level (or the last duo); the overworld reads it
  (fall back to first-two on a fresh boot).

### B3 — Overworld buildings via Prop Farm
- Most town buildings are good; a few could use Prop-Farm upgrades. Identify the weak ones
  (`overworld3d.gd` `LOCS[i]["glb"]`) and regenerate/replace the worst offenders. Lower priority.

---

## Plan C — UI / HUD readability ✅ DONE (commit 48f0255)
Implemented the "Compact corners" option: shared `Level3D.build_default_hud()` — top-left objective
chip (hidden when empty), auto-fading bottom hint toast, auto-dismissing top win ribbon. All 13
levels alias their `_hud_goal/_hud_hint/_hud_banner` to it. (Original notes below for reference.)
**Context:** UI (`scripts/ui/`, `Level3D.hud_label`/`make_hud_layer`, per-level `_hud_goal/_hud_hint/
_hud_banner`). GDScript Control work; independent.

- The on-screen text is **busy and blocks play** — the end-level banner sits over the field (can hide
  collectibles you still want to grab), and the hint line eats a lot of space.
- **Directions to explore:**
  - End-level banner → smaller, **auto-dismiss** after a beat (or move to a corner / make it not cover
    the play area); don't block collectible pickup.
  - Hint text → a compact, **auto-fading** one-liner (toast-style, bottom corner) instead of a wide
    persistent band; queue messages briefly.
  - Goal text → collapse to a small corner objective chip (expand on a key, or only show when idle).
  - Reuse `UITheme` styling so it stays cohesive. Propose 1–2 mockups before committing.
