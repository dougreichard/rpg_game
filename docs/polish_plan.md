# Polish plan — character/world/UI cleanup

Captured from `clenup_tasks.md`. Organised into **3 context-isolated plans** so each can be
executed in one focused pass without thrashing between subsystems. Suggested order: **C (UI)** for a
quick daily-visible win, then **B (world dressing)**, then **A (characters)** — the big one, batched
so the Blender/animation context is loaded once.

---

## Plan A — Characters: identity, look, pose, special anims
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
