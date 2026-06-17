"""Stage 2-alt (Option A) — TEXTURE a generated prop mesh from its reference image via
Hunyuan3D-2.1's paint model (hy3dpaint). Outputs a textured GLB. Heavy + slow on macOS:
needs the custom_rasterizer CPU build + RealESRGAN ckpt + dinov2-giant (~4.5GB, auto-pulled).
The result is photoreal PBR — to stay Synty you'd still bake it down + quantise to a flat
palette. Use only when you want real reference colour rather than the flat-tint/split path.

  conda run -n hunyuan3d python gen_prop_paint.py --mesh <in.glb> --image <ref.png> --out <out.glb>
"""
import os
os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")
import sys, argparse, shutil

# Repo path: Mac fork by default; on a CUDA box set HY3D_REPO to the upstream Hunyuan3D-2.1
# checkout (where the real custom_rasterizer CUDA kernel is built).
REPO = os.path.expanduser(os.environ.get("HY3D_REPO", "~/ai/hunyuan3d-mac"))
PAINT = os.path.join(REPO, "hy3dpaint")
os.chdir(PAINT)                              # demo runs from here (relative cfgs/ckpt paths)
sys.path.insert(0, PAINT)
sys.path.insert(0, os.path.join(PAINT, "custom_rasterizer"))

ap = argparse.ArgumentParser()
ap.add_argument("--mesh", required=True)
ap.add_argument("--image", required=True)
ap.add_argument("--out", required=True)
ap.add_argument("--views", type=int, default=6)
ap.add_argument("--resolution", type=int, default=512)
ap.add_argument("--render-size", type=int, default=0, help="override (macOS CPU rasterizer is slow; try 384)")
ap.add_argument("--texture-size", type=int, default=0, help="override (try 1024)")
a = ap.parse_args()

try:
    from utils.torchvision_fix import apply_fix; apply_fix()
except Exception as e:
    print("torchvision fix skipped:", e)

from textureGenPipeline import Hunyuan3DPaintPipeline, Hunyuan3DPaintConfig
print("loading paint pipeline (first run downloads dinov2-giant ~4.5GB) ...")
conf = Hunyuan3DPaintConfig(a.views, a.resolution)
if a.render_size:
    conf.render_size = a.render_size
if a.texture_size:
    conf.texture_size = a.texture_size
print(f"render_size={conf.render_size} texture_size={conf.texture_size} views={a.views}")
pipe = Hunyuan3DPaintPipeline(conf)
print("painting", a.mesh, "from", a.image, "...")
out_path = pipe(mesh_path=a.mesh, image_path=a.image)
print("paint output ->", out_path)
# normalise the output name/location for us
dst = os.path.expanduser(a.out)
shutil.copy(out_path, dst)
print("copied ->", dst)
