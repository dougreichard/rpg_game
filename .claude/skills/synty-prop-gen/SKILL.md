---
name: synty-prop-gen
description: Generate a Synty-style low-poly prop mesh (GLB) for a 3D level from a text prompt (SDXL reference → Hunyuan3D-2.1 → Blender normalize), then drop it into a level as a visual-only mesh over the existing primitive collision. Use when asked to replace box_mesh placeholder props or add thematic set-dressing/hero props to a location, or to build phase meshes for a stateful puzzle. NOTE: a Windows/CUDA RTX-3090 box now runs this whole pipeline as the "Prop Farm" web service (faster, with texture paint) — PREFER it over the local Apple-Silicon/MPS path; see "Preferred path" at the top of this skill.
---

# Synty prop generation (local, M3)

Turns a prompt into a committed `assets/models/props/<name>.glb` matching the Synty
low-poly look, then wires it into a level. Three scriptable stages + a Godot drop-in.
Bundled scripts are in `scripts/` next to this file.

## ⚡ Preferred path: the Prop Farm service (Windows/CUDA RTX-3090 box)
**Generation now runs as a web service on the 3090 — prefer it over the local MPS pipeline below.**
It runs the full chain **reference → shape → (paint → finalize | reduce) → GLB** faster (CUDA),
and has a **degenerate-mesh guard** (Hunyuan silently returns a *cube* when the reference isn't a
single, centered, 3/4-view object — so prompt one object, not a scatter; the service also
auto-retries tiled references and renders at portrait to avoid SDXL grids).

**Two output tracks / Godot materials:**
- `flat` — grey low-poly GLB; **tint per material in Godot** (no texture). The proven default.
  Reduced + flat-shaded + sized via `normalize_prop.py` (~few-k tris).
- `painted` — Hunyuan paints the prop, then `finalize_painted.py` keeps the baked **DIFFUSE
  texture** (real reference colours; reads cleaner than quantising to vertex colours, which washed
  out) and **keeps the mesh EXACTLY as-is** — only downsizes the texture to 512px and applies the
  real-world size + base-align. In Godot use a **standard material that samples the GLB's
  `baseColorTexture`** (NOT `vertex_color_use_as_albedo`); no double-siding needed.
  - ⚠ **Do NOT reduce/recalc-normals/flat-shade/weld a painted mesh.** Hunyuan's paint output is
    **non-watertight / multi-shell** (thousands of open patch seams); any such processing folds or
    flips it → **"crushed + holes" in Godot**. So painted props stay **~40k tris** (a safe reduction
    is future work — correct 40k beats broken 8k). ~+0.x MB/prop vs flat; 512px texture is small.

- **Two-machine division:** the **3090 box generates** (stages 1–3 + paint); the **Mac wires it
  into levels** (stage 4, the Godot drop-in below) and is git source-of-truth. They sync via the
  shared GitHub remote. The service can **auto-commit + push** the finished GLB; the Mac then
  `git pull` and `prop(...)` it in.
- **Use it (from anywhere on the LAN):**
  - Browser: **http://192.168.0.62:7860** (host `DESKTOP-3A5JORP`) — form + live per-stage
    progress + 3D preview + a shared **Jobs** dashboard.
  - REST API (Python): `from gradio_client import Client; Client("http://192.168.0.62:7860")
    .predict(name, prompt, seed, track, angle, height_m, style_image_or_None, commit_bool, api_name="/generate")`
    — `track` = `"flat"` (grey low-poly, tint in Godot) or `"painted"` (diffuse-textured, real colours);
    `height_m` = real-world bbox height in metres so the GLB ships true-sized (`prop(...)` with scale 1.0).
- **What it runs:** the CUDA-variant stage scripts in `scripts/` — `gen_prop_ref_comfy.py`
  (ComfyUI/SDXL + optional IPAdapter set-consistency), `gen_prop_mesh_cuda.py` (Hunyuan shape),
  `gen_prop_paint_cuda.py` (Hunyuan paint, lean: skips discarded mr + super-res; texture_size 1536),
  `finalize_painted.py` (keep diffuse texture + **mesh as-is**, downsize texture 512px, real-world
  size), `normalize_prop.py` (flat-track reduce; default dissolve angle **6°**).
  (`quantize_from_texture.py` = the old vertex-colour Synty-fy, kept as a fallback, not the default.)
- **Service code + full ops docs** live on the 3090 at `E:\ai\prop_farm\` (`README.md`,
  `start_all.bat`) — *not* in this repo (machine-local infra, like the ComfyUI/Hunyuan clones).
- **Fallback:** if the 3090/service is offline, the local Apple-Silicon/MPS pipeline below still works.

## Prerequisites (already set up on this machine — verify, don't reinstall)
- conda env **`hunyuan3d`** (torch+MPS, diffusers, trimesh, rembg).
- Hunyuan3D-2.1 MPS fork at `~/ai/hunyuan3d-mac`; weights cached in `~/.cache/hy3dgen` (~7 GB).
- SDXL ckpt `~/ComfyUI/models/checkpoints/sd_xl_base_1.0.safetensors`.
- Blender at `/Applications/Blender.app`. Scratch outputs go to `~/ai/refs/` (out of repo).
- Quick check: `conda env list | grep hunyuan3d && ls ~/.cache/hy3dgen`.

## Pipeline
Run heavy stages **backgrounded** (they exceed a single command timeout). `<S>` = this skill's `scripts/` dir.

1. **Reference** (SDXL, ~1 min/3 seeds):
   ```
   conda run -n hunyuan3d python <S>/gen_prop_ref.py --name <slug> --prompt "<subject>"
   ```
   Review `~/ai/refs/<slug>_ref_seed*.png`; pick the one with a clean, centred,
   **3/4 perspective** (best depth cues for image-to-3D) and a full object on plain bg.

2. **Mesh** (Hunyuan3D shape-only, several min on MPS):
   ```
   conda run -n hunyuan3d python <S>/gen_prop_mesh.py --name <slug> --seed <S>
   ```
   Saves `~/ai/refs/<slug>_raw.glb` (feed to stage 3). CPU-fallback for the unsupported
   MPS resize op is baked in — no env var needed.

   **Two-tier speed/quality policy** (the prop list is long; bake accordingly):
   - **Hero props** (saw, organ, crane, gear train, carousel…): defaults. High-res capture
     + dissolve preserves the silhouette + small features best (~8–10 min/prop).
   - **Set-dressing** (crates, records, buoys, balloons, seats…): lighten the raw mesh at
     the source — `--octree 192 --mc-algo dmc --steps 30` (~3–4 min/prop, never hangs):
     - `--octree N` — lower marching-cubes grid → far fewer raw tris + near-instant dissolve,
       at the cost of softer corners + dropped small features.
     - `--steps N` — fewer diffusion steps (~30 vs default 50); faster, little loss on chunks.
     - `--mc-algo dmc` — dual contouring → crisper hard edges at low `--octree`. **Requires
       `pip install diso`** (NOT installed by default, and may not build on Apple Silicon);
       without it the gen errors out, so leave it off unless you've confirmed diso imports.
   Reliable fast lever = `--octree` alone. NOTE: `--octree`/`--steps` only help **flat-panel**
   props; props with many **thin/cylindrical features** (rods, pipes, railings) stay dense and
   slow to dissolve regardless — for those the pre-collapse in stage 3 is what bounds the time.

   **Batch a whole level's set in ONE model load** (the ~7 GB model load is otherwise paid
   per prop — batching amortizes it across N):
   ```
   conda run -n hunyuan3d python <S>/gen_prop_mesh.py --manifest level_props.json
   ```
   `manifest = {"defaults": {<any flag>}, "props": [{"name": "...", "seed": "...", <overrides>}, …]}`
   — `defaults` (e.g. the fast-path flags) apply to all; each entry can override per-prop.

3. **Reduce + normalize** (Blender, seconds) — feed it the **RAW** mesh:
   ```
   /Applications/Blender.app/Contents/MacOS/Blender --background --python <S>/normalize_prop.py -- \
       ~/ai/refs/<slug>_raw.glb assets/models/props/<slug>.glb [angle_deg=12] [face_cap=0]
   ```
   Reduction is **Limited Dissolve / planar decimate** (merges coplanar faces → flats stay
   flat, edges stay crisp) with an optional **collapse cap** — NOT pure quadric collapse,
   which distorts flat panels and lumps hard-surface props. Tune `angle_deg` (~8–15) for
   how aggressively coplanar faces merge; set `face_cap` (e.g. 4000) only if still dense.
   Output is height 1.0, base at floor (Y=0), centred — scale to real size in Godot.

4. **Into the level (visual-only):** add it with `prop("res://assets/models/props/<slug>.glb", pos, yaw, scale)`.
   **Do NOT route gameplay through it** — keep the existing primitive `StaticBody`
   collision, `WorkStation3D`/interaction markers, and gates exactly as they are; the
   GLB is a cosmetic child on top. This preserves every verified gate/floor/soft-lock
   check. Reduce/remove the old `box_mesh` placeholder body it replaces. Boot the scene
   (`godot --headless --path . res://scenes/3d/<Scene>.tscn --quit-after 60`) + `--capture`.

## Stateful puzzle props (phase meshes) — part-additive
For a puzzle whose object changes as it's solved (e.g. the Pipe Organ that visibly
assembles), **do NOT generate each part/phase separately** — independent Hunyuan runs
won't co-register (mismatched scale/style/alignment). Instead:

1. Generate the **finished** prop once (stages 1–3 above).
2. **Split it into co-registered parts in Blender** (one mesh → keep-below / keep-above a
   cut plane via `mesh.bisect(clear_outer / clear_inner, use_fill=True)`, **no renormalize**
   so each part keeps the shared frame). → e.g. `organ_part_base.glb` + `organ_part_pipes.glb`.
3. In the level, drop each part at the **same position + scale**; toggle `visible` (and
   tint/glow) per the persisted puzzle flags — reveal a part on its `WorkStation3D`
   `produced(id)` signal, and re-apply state in `_restore()`. Collision/markers stay put.

Reference implementation: `pipe_organ_works3d.gd` `_organ()` / `_set_organ_phase()` /
`_reveal_pipes()` — bare console (dusty) → pipe bank installs with the brass pipe → warm
wood + glowing keys when repaired. The "broken" state is just the base part, unlit.
For a cheaper degrade (no split), shear/displace geometry in Blender from the finished mesh.

## Style + consistency tips
- Prompt = subject only; the script appends the Synty style + framing + plain-bg suffix.
- Keep `--faces` ~2000–4000 for props; lower for small items.
- For a coherent set, reuse one reference seed/style across related props.
- Texture is intentionally skipped (flat Synty palette); tint/colour in Godot or via a
  simple material if needed.

## Gotchas (already handled, here for memory)
- `PYTORCH_ENABLE_MPS_FALLBACK=1` is set in `gen_prop_mesh.py` before torch import —
  Hunyuan's antialiased resize isn't implemented on Metal.
- SDXL must run **float32** on MPS (fp16 → black images).
- Raw Hunyuan mesh is ~800k faces — always decimate (the script does).
- stdout is block-buffered on the long runs; judge progress by output files / pid CPU.
