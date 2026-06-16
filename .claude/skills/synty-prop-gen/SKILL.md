---
name: synty-prop-gen
description: Generate a Synty-style low-poly prop mesh (GLB) for a 3D level from a text prompt, using the local Apple-Silicon pipeline (SDXL reference → Hunyuan3D-2.1 on MPS → Blender normalize), then drop it into a level as a visual-only mesh over the existing primitive collision. Use when asked to replace box_mesh placeholder props or add thematic set-dressing/hero props to a location, or to build phase meshes for a stateful puzzle.
---

# Synty prop generation (local, M3)

Turns a prompt into a committed `assets/models/props/<name>.glb` matching the Synty
low-poly look, then wires it into a level. Three scriptable stages + a Godot drop-in.
Bundled scripts are in `scripts/` next to this file.

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

2. **Mesh** (Hunyuan3D shape-only + decimate, several min on MPS):
   ```
   conda run -n hunyuan3d python <S>/gen_prop_mesh.py --name <slug> --seed <S> [--faces 3500]
   ```
   → `~/ai/refs/<slug>_lowpoly.glb`. (CPU-fallback for the unsupported MPS resize op
   is baked into the script — no env var needed.)

3. **Normalize** (Blender, seconds) → commit into the repo:
   ```
   /Applications/Blender.app/Contents/MacOS/Blender --background --python <S>/normalize_prop.py -- \
       ~/ai/refs/<slug>_lowpoly.glb assets/models/props/<slug>.glb
   ```
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
