# NVIDIA / CUDA setup — Hunyuan3D-2.1 PAINT model (Option A)

> **For the Claude session running on the NVIDIA machine.** You have no prior context;
> this is self-contained. Goal: stand up the Hunyuan3D-2.1 **paint/texture** model on this
> CUDA box and texture a prop mesh from a reference image. This was impractical on the Mac
> (CPU rasterizer fallback — slow + buggy); on CUDA the real `custom_rasterizer` kernel runs
> fast. See the repo memory note `reference_hunyuan_paint_macos.md` for background.

## What this project does (1 paragraph)
**Hunkle Bunkle** is a Godot 3D game. Props are made Synty-low-poly via a local pipeline
(the **`synty-prop-gen`** skill at `.claude/skills/synty-prop-gen/`): SDXL reference image →
Hunyuan3D-2.1 **shape-only** mesh → Blender reduce/normalize/split → flat per-material tint
in Godot. On the Mac we deliberately skip the paint model. **Your job:** add the paint model
so we can texture props from their reference images (real colours), then later bake/quantize
that texture down to a flat Synty palette.

## 0. Verify the box
```
nvidia-smi                       # confirm GPU + VRAM (want >= ~12-16 GB; dinov2-giant + paint)
nvcc --version                   # CUDA toolkit (needed to BUILD custom_rasterizer)
python --version                 # 3.10-3.12
git --version ; cmake --version  # build tools / C++ compiler present
blender --version                # for the reduce/normalize/split stages (any 4.x/5.x)
```
If `nvcc` is missing you must install a CUDA toolkit whose version matches the PyTorch CUDA
build you install below, or `custom_rasterizer` won't compile.

## 1. Clone the UPSTREAM repo (not the Mac fork)
The Mac uses a `-mac` fork with CPU fallbacks. On CUDA use Tencent's official release:
```
mkdir -p ~/ai && cd ~/ai
git clone https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1   # confirm exact URL on GitHub
```
(If that org/name 404s, search GitHub for "Tencent Hunyuan3D-2.1" — it's the official 2.1
release with both `hy3dshape` and `hy3dpaint`.)

## 2. Env + CUDA PyTorch
```
conda create -n hunyuan3d python=3.10 -y && conda activate hunyuan3d
# pick the CUDA build matching your driver/toolkit (example: cu121)
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121
cd ~/ai/Hunyuan3D-2.1 && pip install -r requirements.txt
```

## 3. Build the real custom_rasterizer + renderer (the whole point of using CUDA)
```
cd ~/ai/Hunyuan3D-2.1/hy3dpaint/custom_rasterizer
pip install -e .                 # compiles the CUDA kernel — NO CPU-fallback patch needed
cd ../DifferentiableRenderer
bash compile_mesh_painter.sh     # if present; builds the rasterize extension
python -c "import custom_rasterizer; print('custom_rasterizer OK')"
```

## 4. Extra paint deps + checkpoints
```
pip install xatlas realesrgan basicsr
mkdir -p ~/ai/Hunyuan3D-2.1/hy3dpaint/ckpt
curl -L -o ~/ai/Hunyuan3D-2.1/hy3dpaint/ckpt/RealESRGAN_x4plus.pth \
  https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth
```
The Hunyuan3D-2.1 weights and `facebook/dinov2-giant` (~4.5 GB) auto-download from
HuggingFace on first run.

## 5. Run the paint pipeline (committed script)
The project ships `.claude/skills/synty-prop-gen/scripts/gen_prop_paint.py`. It's
cross-machine — set `HY3D_REPO` to your clone:
```
export HY3D_REPO=~/ai/Hunyuan3D-2.1
conda run -n hunyuan3d python .claude/skills/synty-prop-gen/scripts/gen_prop_paint.py \
  --mesh docs/nvidia_handoff/tuning_bench_shape.glb \
  --image docs/nvidia_handoff/tuning_bench_ref.png \
  --out ~/painted_bench.glb \
  --views 6 --resolution 512    # full sizes now that the GPU rasterizer is fast
```
A **pilot reference + shape mesh** is committed under `docs/nvidia_handoff/` so you can paint
immediately without setting up SDXL. (To make NEW props end-to-end you'd also run
`gen_prop_ref.py` (needs an SDXL checkpoint) → `gen_prop_mesh.py` (shape) first — see the
skill's `SKILL.md`.)

## 6. Verify + report back
- Open `~/painted_bench.glb` (Blender or a glTF viewer) — it should be a TEXTURED bench
  (walnut/steel from the reference), not flat-grey.
- Note timing + VRAM use, and any build/runtime fixes you had to make (so we can fold them
  into the skill for next time).

## 7. After it works — Synty-fy the texture (follow-up, not blocking)
The paint output is **photoreal PBR**, which clashes with the flat Synty look. Plan:
quantize the baked texture to a small flat palette (or vertex-bake + posterize). The shape /
normalize / split tools in `synty-prop-gen` still apply. Coordinate before committing any
painted props into a level — the Mac side owns the level wiring.

## Gotchas (from the Mac attempt)
- `custom_rasterizer` build needs CUDA toolkit matching the torch CUDA version.
- `basicsr` imports a removed `torchvision.transforms.functional_tensor`; the repo ships a
  `torchvision_fix` shim (applied in `gen_prop_paint.py`) — keep it.
- Don't apply the Mac `render_fallback.py` patch — that's CPU-only; you want the CUDA kernel.
