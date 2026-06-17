"""Stage 2 — mesh(es) from chosen reference(s) via Hunyuan3D-2.1 (MPS), shape only.
Weights cache in ~/.cache/hy3dgen. Outputs ~/ai/refs/<name>_raw.glb (feed to stage 3).

Single prop:
  conda run -n hunyuan3d python gen_prop_mesh.py --name organ_console --seed 11
Fast set-dressing prop:
  conda run -n hunyuan3d python gen_prop_mesh.py --name crate --seed 42 --octree 192 --mc-algo dmc --steps 30
Whole level's set in ONE model load (batch — amortizes the ~7GB load over N props):
  conda run -n hunyuan3d python gen_prop_mesh.py --manifest props.json

manifest = {"defaults": {<any flag>}, "props": [{"name": "...", "seed": "...", <overrides>}, ...]}

GOTCHA baked in: Hunyuan's preprocessing uses an antialiased bilinear resize
(`aten::_upsample_bilinear2d_aa`) that MPS doesn't implement — so we enable the
CPU fallback for unsupported ops BEFORE importing torch. (Found the hard way.)
"""
import os
os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")  # must be set before torch import
import argparse, sys, json, time

REPO = os.path.expanduser("~/ai/hunyuan3d-mac")
os.chdir(REPO)
sys.path.insert(0, REPO)
sys.path.insert(0, os.path.join(REPO, "hy3dshape"))
REFS = os.path.expanduser("~/ai/refs")

ap = argparse.ArgumentParser()
ap.add_argument("--name", help="single prop slug (omit when using --manifest)")
ap.add_argument("--seed", default="11")
ap.add_argument("--manifest", default="", help="JSON file: a list of props to bake in one model load")
ap.add_argument("--octree", type=int, default=0,
                help="marching-cubes grid resolution; 0 = Hunyuan default (~384, ~1-2M raw faces). "
                     "Lower (e.g. 192) → far fewer raw tris + faster dissolve, at the cost of softer "
                     "corners + lost small features. Use for set-dressing; keep default for hero props.")
ap.add_argument("--mc-algo", default="",
                help="surface-extraction algo: '' = Hunyuan default (marching cubes). 'dmc' = dual "
                     "contouring → crisper hard edges, so a lower --octree still keeps sharp corners.")
ap.add_argument("--steps", type=int, default=0,
                help="diffusion steps; 0 = Hunyuan default (50). ~30 is faster with little shape loss "
                     "on chunky props — use for set-dressing, keep default for hero props.")
a = ap.parse_args()

# Build the job list. CLI flags are the per-run defaults; a manifest's "defaults" override
# those, and each prop entry's own keys override the defaults. Single --name => one job.
cli_defaults = {"seed": a.seed, "octree": a.octree, "mc_algo": a.mc_algo, "steps": a.steps}
jobs: list = []
if a.manifest:
    spec = json.load(open(a.manifest))
    base = dict(cli_defaults); base.update(spec.get("defaults", {}))
    for p in spec["props"]:
        j = dict(base); j.update(p); jobs.append(j)
elif a.name:
    j = dict(cli_defaults); j["name"] = a.name; jobs.append(j)
else:
    ap.error("provide --name or --manifest")
print(f"jobs: {[j['name'] for j in jobs]}")

from platform_utils import configure_torch_device
try:
    from torchvision_fix import apply_fix; apply_fix()
except Exception as e:
    print("torchvision fix skipped:", e)
from PIL import Image
from hy3dshape.pipelines import Hunyuan3DDiTFlowMatchingPipeline
try:
    from hy3dshape.rembg import BackgroundRemover
    _rembg = BackgroundRemover()
except Exception as e:
    print("rembg unavailable:", e); _rembg = None

device = configure_torch_device(); print("device:", device)
print("loading shape model (once for all jobs) ...")
pipe = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained("tencent/Hunyuan3D-2.1")

def bake(job: dict) -> None:
    name, seed = job["name"], job["seed"]
    ref = os.path.join(REFS, f"{name}_ref_seed{seed}.png")
    out_raw = os.path.join(REFS, f"{name}_raw.glb")
    if not os.path.exists(ref):
        print(f"!! skip {name}: no ref {ref}"); return
    img = Image.open(ref).convert("RGBA")
    if _rembg is not None:
        img = _rembg(img)
    kw: dict = {}
    if int(job.get("octree", 0)) > 0: kw["octree_resolution"] = int(job["octree"])
    if job.get("mc_algo"):           kw["mc_algo"] = job["mc_algo"]
    if int(job.get("steps", 0)) > 0: kw["num_inference_steps"] = int(job["steps"])
    print(f"-- {name}: extracting {kw or '(defaults)'}")
    t = time.time()
    mesh = pipe(image=img, **kw)[0]
    mesh.export(out_raw)
    try:
        import trimesh
        faces = len(trimesh.load(out_raw, force="mesh").faces)
    except Exception:
        faces = "?"
    print(f"-- {name}: {faces} raw faces in {time.time() - t:.0f}s -> {out_raw}")

for job in jobs:
    bake(job)
print("DONE")
