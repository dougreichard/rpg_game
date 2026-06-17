"""Stage 2 (CUDA variant) — shape-only mesh from a reference image via Hunyuan3D-2.1 on CUDA.
Mirrors the skill's gen_prop_mesh.py (MPS) but uses the upstream repo's shape pipeline.
Weights (tencent/Hunyuan3D-2.1 DiT+VAE) auto-download to HF cache on first run.

  conda run -n hunyuan3d python gen_prop_mesh_cuda.py --image ref.png --out raw.glb [--steps 50] [--octree 256]
"""
import os, sys, argparse, time
REPO = os.environ.get("HY3D_REPO", r"E:\ai\Hunyuan3D-2.1")
sys.path.insert(0, os.path.join(REPO, "hy3dshape"))

ap = argparse.ArgumentParser()
ap.add_argument("--image", required=True)
ap.add_argument("--out", required=True)
ap.add_argument("--steps", type=int, default=50)
ap.add_argument("--octree", type=int, default=256, help="mc grid resolution (silhouette detail)")
ap.add_argument("--import-check", action="store_true")
a = ap.parse_args()

from hy3dshape.rembg import BackgroundRemover
from hy3dshape.pipelines import Hunyuan3DDiTFlowMatchingPipeline
print("imports OK")
if a.import_check:
    sys.exit(0)

import torch
from PIL import Image
print("torch", torch.__version__, "cuda", torch.cuda.is_available())

t0 = time.time()
pipe = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained("tencent/Hunyuan3D-2.1")
print(f"shape pipeline ready in {time.time()-t0:.0f}s")

image = Image.open(a.image).convert("RGBA")
if image.getchannel("A").getextrema() == (255, 255):  # opaque -> remove bg
    print("removing background ...")
    image = BackgroundRemover()(image)

t1 = time.time()
kw = {"image": image, "num_inference_steps": a.steps}
try:
    mesh = pipe(octree_resolution=a.octree, **kw)[0]
except TypeError:
    mesh = pipe(**kw)[0]
print(f"shape gen in {time.time()-t1:.0f}s; faces={len(mesh.faces)}")
mesh.export(a.out)
print("exported", a.out)
