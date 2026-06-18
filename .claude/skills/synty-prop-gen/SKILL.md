---
name: synty-prop-gen
description: Generate a Synty-style low-poly prop mesh (GLB) for a 3D level from a text prompt (SDXL reference → Hunyuan3D-2.1 → Blender), then drop it into a level as a visual-only mesh over the existing primitive collision. Use when asked to replace box_mesh placeholders or add thematic set-dressing/hero props to a location, or to build phase meshes for a stateful puzzle. Primary path = the "Prop Farm" web service on the Windows/CUDA RTX-3090 box (faster, with texture paint); the local Apple-Silicon/MPS scripts are a fallback.
---

# Synty prop generation

Turns a prompt into a committed `assets/models/props/<name>.glb` matching the Synty low-poly
look, then wires it into a level. **Primary path = the Prop Farm service on the CUDA box;** the
local Apple-Silicon/MPS scripts are a fallback. Bundled scripts are in `scripts/` next to this file.

## ⚡ Preferred path: the Prop Farm service (Windows/CUDA RTX-3090 box)
Generation runs as a web service on the 3090 — **prefer it over the local MPS pipeline**. It runs
**reference → shape → (paint → finalize | reduce) → GLB** fast (CUDA), and has a **degenerate-mesh
guard** (Hunyuan silently returns a *cube* when the reference isn't a single, centered, 3/4-view
object — so prompt one object, not a scatter; the service also auto-retries tiled references and
renders at portrait to dodge SDXL grids).

**Typical timings (3090, resident workers, perf-tuned: FlashVDM + TF32):** flat ~1 min, painted
~3–4 min per prop — reference seed-search ~40s (6 candidates; **~6s when a seed is pinned**), shape
~39s, paint ~190s (@2.5k-tri budget), finalize + render a few seconds. (Editing a worker/app needs
a process restart; see `prop_farm/README.md`.)

**Reference seed-search → pin the winner.** The reference stage generates `ref_count` candidates at
**distinct seeds** (`seed … seed+N-1`), hard-filters tiled/empty ones, and picks the **best** by a
single-centered-object × flat-Synty-look score. It **returns the winning seed** (`chosen_seed`); pin
it in the Mac's `prop_presets.json` and re-run with `ref_count=1` + that seed to reproduce the exact
reference fast (pixel-identical). All candidates tiled → a clean `reference FAILED` (no shape on junk).

**Two output tracks / Godot materials:**
- `flat` — grey low-poly GLB; **tint per material in Godot** (no texture). Reduced + flat-shaded +
  sized via `normalize_prop.py` (~few-k tris).
- `painted` — Hunyuan paints the prop; `finalize_painted.py` keeps the baked **DIFFUSE texture**
  (real reference colours) and **keeps the mesh EXACTLY as-is** — only downsizes the texture to
  512px, applies the real-world size + base-align, and forces a **matte material** (`metallicFactor=0`,
  `roughnessFactor=0.9` — Hunyuan leaves metallic unset → glTF default 1.0 → imports as shiny metal).
  In Godot use a **standard material sampling the GLB's `baseColorTexture`** (NOT
  `vertex_color_use_as_albedo`); ships matte, no double-siding needed.
  - **Poly budget** = the **`poly` param** (default 4000): the paint stage's internal **quadric
    remesh** is reduced to that target *before* painting, so the prop is low-poly with **clean
    topology** and the texture carries the detail. Synty ref: Quinn=1,830, church=6,629,
    set-dressing ~400–1,100 → use ~**1,500–2,500** set-dressing, ~**4,000–6,000** hero.
  - ⚠ **NEVER reduce/recalc-normals/flat-shade/weld the painted mesh AFTER paint.** Hunyuan's
    paint output is **non-watertight / multi-shell**; post-paint processing folds/flips it →
    **"crushed + holes" in Godot**. Reduce via `poly` (pre-paint remesh) ONLY.

**Two-machine division:** the **3090 box generates**; the **Mac wires into levels** (below) and is
git source-of-truth, synced via the shared GitHub remote. The service can **auto-commit + push**
the GLB; the Mac then `git pull` + `prop(...)`.

**Use it (LAN):**
- Browser: **http://192.168.0.62:7860** (`DESKTOP-3A5JORP`) — form, live per-stage progress, 3D
  preview, shared **Jobs** dashboard.
- REST API: `from gradio_client import Client; Client("http://192.168.0.62:7860")
  .predict(name, prompt, seed, track, angle, height_m, poly, ref_count, style_image_or_None, commit_bool, api_name="/generate")`
  — `track` = `"flat"`/`"painted"`; `height_m` = real bbox height in metres (ships true-sized →
  `prop(...)` with scale 1.0); `poly` = painted tri budget (default 4000); `ref_count` = reference
  candidates to search (default 6; pass 1 + a pinned seed to reproduce). **Returns a 5-tuple**
  `(status, gallery, model_glb, download, chosen_seed)` — `chosen_seed` is the winning reference seed.

**Stage scripts** (`scripts/`): `gen_prop_ref_comfy.py` (ComfyUI/SDXL, `--count` candidates at
distinct seeds → pipeline ranks + pins the winner, + optional IPAdapter set-consistency),
`gen_prop_mesh_cuda.py` (Hunyuan shape), `gen_prop_paint_cuda.py` (Hunyuan
paint — lean: skips discarded mr + super-res, texture_size 1536, `--remesh-target` = poly budget),
`finalize_painted.py` (keep diffuse + mesh as-is, 512px texture, real-world size), `normalize_prop.py`
(flat-track reduce; default dissolve angle 6°). Service code + ops docs live on the 3090 at
`E:\ai\prop_farm\` (`README.md`, `start_all.bat`) — not in this repo (machine-local infra).

## Into the level (visual-only) — both paths
Drop the committed GLB with `prop("res://assets/models/props/<slug>.glb", pos, yaw, scale)`
(scale `1.0` when generated with a real `height_m`). **Do NOT route gameplay through it** — keep
the existing primitive `StaticBody` collision, `WorkStation3D`/interaction markers and gates
exactly as they are; the GLB is a cosmetic child on top. Reduce/remove the old `box_mesh`
placeholder it replaces. Boot to verify: `godot --headless --path . res://scenes/3d/<Scene>.tscn
--quit-after 60` + `--capture`.

## Stateful puzzle props (phase meshes) — part-additive
For a puzzle whose object changes as it's solved (e.g. the Pipe Organ that visibly assembles),
**do NOT generate each part/phase separately** — independent Hunyuan runs won't co-register
(mismatched scale/style/alignment). Instead:
1. Generate the **finished** prop once.
2. **Split it into co-registered parts in Blender** (one mesh → keep-below / keep-above a cut
   plane via `mesh.bisect(clear_outer / clear_inner, use_fill=True)`, **no renormalize** so each
   part keeps the shared frame). → e.g. `organ_part_base.glb` + `organ_part_pipes.glb`.
3. In the level, drop each part at the **same position + scale**; toggle `visible` (and tint/glow)
   per the persisted puzzle flags — reveal a part on its `WorkStation3D` `produced(id)` signal, and
   re-apply state in `_restore()`. Collision/markers stay put.

Reference: `pipe_organ_works3d.gd` `_organ()` / `_set_organ_phase()` / `_reveal_pipes()`. For a
cheaper degrade (no split), shear/displace geometry in Blender from the finished mesh.

## Style / consistency
- Prompt = subject only; the scripts append the Synty style + 3/4 framing + plain-bg suffix. Prompt
  **one coherent object** — multi-element scenes (rack + loose tools + rods) make the shape thin/sparse.
- Reuse one reference seed/style across related props for a coherent set.
- `flat` = grey, tint per-material in Godot. `painted` = baked diffuse texture (real colours) — use
  the GLB's own material, don't tint.

## Local Apple-Silicon/MPS fallback (only if the service is offline)
Same flow with the MPS scripts (`gen_prop_ref.py` → `gen_prop_mesh.py` → `normalize_prop.py`).
**Paint is CUDA-only** (the MPS CPU rasterizer is too slow), so MPS is **flat-track only**. Env:
conda `hunyuan3d`, Hunyuan MPS fork `~/ai/hunyuan3d-mac`, SDXL ckpt under `~/ComfyUI`, Blender at
`/Applications/Blender.app`, scratch in `~/ai/refs/`.
```
conda run -n hunyuan3d python <S>/gen_prop_ref.py  --name <slug> --prompt "<subject>"   # pick a clean 3/4 ref
conda run -n hunyuan3d python <S>/gen_prop_mesh.py --name <slug> --seed <S>             # -> ~/ai/refs/<slug>_raw.glb
/Applications/Blender.app/Contents/MacOS/Blender --background --python <S>/normalize_prop.py -- \
    ~/ai/refs/<slug>_raw.glb assets/models/props/<slug>.glb 6                            # reduce+normalize (angle 6°)
```
- ⚠ **Corrected (was a slow-MPS assumption):** the old "lower `--octree`/`--steps`/`--mc-algo dmc`
  to save time" two-tier policy is **obsolete on CUDA** (shape ~50s, quadric remesh ~10s).
  **Capture high-detail (octree 256) and reduce via the fast quadric remesh** (`poly` budget on the
  painted track) — don't trade silhouette for speed. On MPS, lowering octree is still a time lever,
  but prefer the service.
- Baked-in MPS gotchas: `PYTORCH_ENABLE_MPS_FALLBACK=1` before torch import (Hunyuan's AA resize
  isn't on Metal); SDXL **float32** (fp16 → black images); raw mesh ~800k faces → always reduce.
