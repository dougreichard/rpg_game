"""Stage 2.5 (CUDA) — TEXTURE a shape mesh from its reference image via Hunyuan3D-2.1 paint
(hy3dpaint). Outputs a textured GLB (real reference colours). CUDA-only (real custom_rasterizer
kernel). Forces the two filesystem config paths ABSOLUTE so it is cwd-independent (the upstream
layout prefixes the cfg with "hy3dpaint/"). Set HY3D_REPO to the Hunyuan3D-2.1 clone.

  conda run -n hunyuan3d python gen_prop_paint_cuda.py --mesh raw.glb --image ref.png --out painted.glb \
      [--views 6] [--resolution 512]
"""
import os, sys, argparse, shutil, time

REPO = os.environ.get("HY3D_REPO", r"E:\ai\Hunyuan3D-2.1")
PAINT = os.path.join(REPO, "hy3dpaint")
os.chdir(PAINT)
sys.path.insert(0, PAINT)
sys.path.insert(0, os.path.join(PAINT, "custom_rasterizer"))

ap = argparse.ArgumentParser()
ap.add_argument("--mesh", required=True)
ap.add_argument("--image", required=True)
ap.add_argument("--out", required=True)
ap.add_argument("--views", type=int, default=6)
ap.add_argument("--resolution", type=int, default=512)
ap.add_argument("--remesh-target", type=int, default=40000,
                help="quadric reduce BEFORE paint -> final tri budget (Synty: ~1.5-6k). No post-paint reduce.")
a = ap.parse_args()

try:
    from utils.torchvision_fix import apply_fix; apply_fix()
except Exception as e:
    print("torchvision fix skipped:", e)

from textureGenPipeline import Hunyuan3DPaintPipeline, Hunyuan3DPaintConfig

conf = Hunyuan3DPaintConfig(a.views, a.resolution)
conf.multiview_cfg_path = os.path.join(PAINT, "cfgs", "hunyuan-paint-pbr.yaml")
conf.realesrgan_ckpt_path = os.path.join(PAINT, "ckpt", "RealESRGAN_x4plus.pth")
conf.texture_size = 1536  # default 4096 is wasted — finalize_painted downsizes to 512; 1536->512
# is visually identical but ~11s faster paint (the bake atlas is smaller; diffusion is unchanged).
# Lean knobs (need the gates in hy3dpaint/textureGenPipeline.py; harmless no-op if absent):
conf.gen_mr = False         # metallic-roughness map is discarded downstream -> skip it
conf.skip_super_res = True  # RealESRGAN 4x is lost in the 512 downsize -> skip it (~9s, no loss)
conf.remesh_target = a.remesh_target  # quadric reduce pre-paint -> low-poly Synty budget (texture carries detail)

t0 = time.time()
pipe = Hunyuan3DPaintPipeline(conf)
print(f"paint pipeline ready in {time.time()-t0:.0f}s", flush=True)
t1 = time.time()
out_obj = pipe(mesh_path=a.mesh, image_path=a.image)
print(f"paint done in {time.time()-t1:.0f}s", flush=True)

glb = out_obj.replace(".obj", ".glb")
src = glb if os.path.exists(glb) else out_obj
shutil.copy(src, os.path.expanduser(a.out))
print("exported", a.out, flush=True)
