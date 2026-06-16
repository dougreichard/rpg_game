# Visual Upgrade Plan — generated Synty meshes for all levels

Use the local mesh-generation pipeline (Synty-matching) to replace `box_mesh`
placeholder art with bespoke low-poly props, add thematic set-dressing, and give
puzzle props **state that reflects progress**. Pipeline + one-command reuse live in the
**`synty-prop-gen`** skill (`.claude/skills/synty-prop-gen/`). Pilot is **done** (Pipe
Organ — see §8). The 2D tiling-texture pass + multi-room/corridor work are already in
(see `level_elaboration_plan.md`); this is the prop/mesh layer on top.

## 0. Guiding principle — decouple visual from collision
Every gate, floor, wall, and puzzle marker is a primitive `StaticBody` (verified). Hang
generated meshes on top as **visual-only** children; never route gameplay through them.
Generated meshes are static, decimated (~2–6k faces), and MultiMesh-instanced when
repeated. This keeps every verified gate/floor/soft-lock check valid.

## 1. How generation improves the game
Replace placeholder interactables with legible objects (a saw, an organ, a crane — not a
box); add a hero set-piece per level; build a modular generated kit so corridors/corners
aren't bare cubes; keep one ComfyUI style reference so ~60 props read as one Synty pack.

## 2. Per-level upgrades (hero prop → dressing)
Pipe Organ: organ ✅ / saw / bench · Church: altar+pews / candelabra / crypt slab ·
Gym: rack+weights / boiler / lockers · Studio: console+booth / reel / records+cables ·
Clocktower: gear train / bells / pendulum · Harbor: crane / container / nets+buoys ·
Library: shelves / terminal / catalog · Carnival: carousel / photo booth / bunting ·
Underground: vault door / valve / conduit · Zip Line: towers+pulleys / panel · VR:
data pylons / ARIA drone (keep neon) · The Drop: pod+chute / dish / pines · Cinema:
marquee+proscenium / organ / seat rows (MultiMesh) + chandeliers.

## 3. Walls / corridors / corners — indoor vs outdoor
- **Indoor:** relief wall panels; **corner pillars/pilasters** (replace the solid corner
  posts); doorway arches at corridor mouths; baseboards/cornices/beams.
- **Outdoor:** fences/railings/hedges/rock walls; corridors → paths flanked by foliage;
  corners → lamp posts / bollards / planters / trees.
- A small kit (`wall_panel`, `door_arch`, `corner_pillar` indoor; `fence`, `gate_arch`,
  `lamp_post` outdoor), themed per level, feeding the existing `corridor()` API.

## 4. Improve existing puzzles/props
Swap the *visual* of each interactable (saw, bench, gear, bells, soundboard, carousel,
crane, hatch pips, vault wheel/panel, candles, plaques, weight cranks, pendulum, panels,
firewall nodes, projector) for a bespoke mesh — keeping `_on_special` logic, markers, and
collision. Clearer solved-states + the procedural spin/glow we already animate.

## 5. Thematic set-dressing
Non-interactive "lived-in" detail per level (records+cables, nets+buoys, balloons+popcorn,
candelabra, chandeliers+velvet ropes…). MultiMesh the repeated ones (seats, pews, crates,
trees).

## 6. ComfyUI for textures + references
Front of the pipeline: (a) orthographic multi-view **reference sheets** to feed
image-to-3D (better than text-only), (b) tileable **textures/atlases** in the Synty
palette (extend `assets/art/tiles/`). Saved workflow + fixed palette/texel density for
consistency. Run the ComfyUI server in a visible Terminal window.

## 7. Characters (harder — they must animate)
- **Low risk / high ROI:** generate distinct heads/hats/tools/palette-swaps on the
  **existing Synty body rig** (Quinn wrench+cap, Erin torch, Evan bulk, Ben keytar, Ethan
  visor, Doug); they animate for free. Plus static dialog-portrait busts for NPCs.
- **Stretch:** fully bespoke leads + Doug, auto-rigged (Mixamo/ARP) + retargeted to the
  existing clip set. The reused-generic NPCs (Viktor/Marco/Pearl/Cyrus/Lena/Sasha/Priswick
  = `bellows`/`congregant_*`) are prime accessory-swap candidates.

## 8. Stateful puzzle props — phase meshes (PILOTED ✅)
Highest-value use: a puzzle object that **assembles as you solve it**.
- **Generate once, split in Blender into co-registered parts** (NOT separate generations —
  those don't align). One mesh → keep-below / keep-above a cut plane (`mesh.bisect`), no
  renormalize, so parts share the frame and reassemble exactly.
- Drop parts at the same position+scale; toggle `visible` + tint/glow per the persisted
  puzzle flags; reveal a part on its `WorkStation3D` `produced(id)`; re-apply in `_restore`.

**Pilot — Pipe Organ (done):** prompt → SDXL ref → Hunyuan3D-2.1 (MPS) → decimate →
Blender normalize → `organ_console.glb`, then **split** into `organ_part_base.glb` +
`organ_part_pipes.glb`. In-level: bare dusty console → pipe bank **installs** when the
brass pipe is fitted → warm wood + glowing keys on full repair; persists across re-entry;
collision/station untouched. Proves the whole loop + the part-additive headline.

## Pipeline (the `synty-prop-gen` skill)
`gen_prop_ref.py` (SDXL ref) → `gen_prop_mesh.py` (Hunyuan3D shape-only + decimate; MPS
CPU-fallback baked in) → `normalize_prop.py` (Blender) → `assets/models/props/<slug>.glb`
→ `prop()` as a visual-only child. See the skill's `SKILL.md` for invocation + gotchas.

## Risks / mitigations
- **Per-gen style variance** → one shared ComfyUI reference + a poly/texel budget; review
  against Synty packs.  **Untextured shape-only output** → flat Synty tint in Godot, or
  vertex-paint/2-material split in Blender for two-tone.  **Review burden / asset count** →
  full multi-phase only for hero props; reuse one ref/style across a set; MultiMesh repeats.

## Recommended rollout order
1. Hero puzzle props per level (legibility win) — start with the ones currently box-built.
2. The corner/door/wall kit (indoor + outdoor) to dress corridors.
3. Set-dressing passes.
4. Character accessory-swaps; bespoke leads/Doug last.
