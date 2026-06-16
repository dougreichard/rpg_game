"""Stage 2 — mesh from a chosen reference via Hunyuan3D-2.1 (MPS), shape only,
then decimate to a Synty low-poly budget. Weights cache in ~/.cache/hy3dgen.

  conda run -n hunyuan3d python gen_prop_mesh.py --name organ_console --seed 11

GOTCHA baked in: Hunyuan's preprocessing uses an antialiased bilinear resize
(`aten::_upsample_bilinear2d_aa`) that MPS doesn't implement — so we enable the
CPU fallback for unsupported ops BEFORE importing torch. (Found the hard way.)
"""
import os
os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")  # must be set before torch import
import argparse, sys

REPO = os.path.expanduser("~/ai/hunyuan3d-mac")
os.chdir(REPO)
sys.path.insert(0, REPO)
sys.path.insert(0, os.path.join(REPO, "hy3dshape"))

ap = argparse.ArgumentParser()
ap.add_argument("--name", required=True)
ap.add_argument("--seed", default="11")
ap.add_argument("--faces", type=int, default=3500, help="Synty-ish low-poly budget")
a = ap.parse_args()

refs = os.path.expanduser("~/ai/refs")
REF = os.path.join(refs, f"{a.name}_ref_seed{a.seed}.png")
OUT_RAW = os.path.join(refs, f"{a.name}_raw.glb")
OUT_LOW = os.path.join(refs, f"{a.name}_lowpoly.glb")

from platform_utils import configure_torch_device
try:
    from torchvision_fix import apply_fix; apply_fix()
except Exception as e:
    print("torchvision fix skipped:", e)

from PIL import Image
device = configure_torch_device(); print("device:", device)

img = Image.open(REF).convert("RGBA")
try:
    from hy3dshape.rembg import BackgroundRemover
    img = BackgroundRemover()(img); print("background removed")
except Exception as e:
    print("rembg skipped:", e)

from hy3dshape.pipelines import Hunyuan3DDiTFlowMatchingPipeline
print("loading shape model ...")
pipe = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained("tencent/Hunyuan3D-2.1")
print("generating mesh from", REF, "...")
mesh = pipe(image=img)[0]
mesh.export(OUT_RAW); print("saved raw ->", OUT_RAW)

try:
    import trimesh
    tm = trimesh.load(OUT_RAW, force="mesh")
    print("raw faces:", len(tm.faces))
    low = tm.simplify_quadric_decimation(a.faces)
    low.export(OUT_LOW); print(f"saved low-poly ({len(low.faces)} faces) ->", OUT_LOW)
except Exception as e:
    print("decimation failed (raw still saved):", e)
print("DONE")
