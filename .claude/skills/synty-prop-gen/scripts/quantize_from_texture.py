"""Stage 4 (NEW) — Synty-fy a PAINTED prop by deriving its flat palette FROM the painted
texture (not the height-band heuristic). Samples the baseColor/albedo at each vertex's UV,
k-means quantizes to N flat colors, bakes them as vertex colors, and exports a texture-less
GLB (Godot renders it via vertex_color_use_as_albedo). Also writes a palette swatch PNG.

  conda run -n hunyuan3d python quantize_from_texture.py <painted.glb> <out.glb> [n_colors=8]

Run in the env with trimesh+numpy+scipy+PIL (hunyuan3d).
"""
import sys, numpy as np
import trimesh
from PIL import Image
from scipy.cluster.vq import kmeans2

IN, OUT = sys.argv[1], sys.argv[2]
N = int(sys.argv[3]) if len(sys.argv) > 3 else 8
np.random.seed(0)

loaded = trimesh.load(IN, process=False)
mesh = list(loaded.geometry.values())[0] if isinstance(loaded, trimesh.Scene) else loaded
V = len(mesh.vertices)
print(f"loaded {IN}: {V} verts, {len(mesh.faces)} faces")

uv = np.asarray(mesh.visual.uv, dtype=np.float64)
tex = mesh.visual.material.baseColorTexture
if tex is None:
    raise SystemExit("no baseColorTexture on mesh — is it actually painted?")
img = np.asarray(tex.convert("RGB"))
H, W = img.shape[:2]
print(f"texture {W}x{H}")

# sample albedo at each vertex UV (nearest texel; v flipped for glTF top-left origin)
px = np.clip((uv[:, 0] * (W - 1)).astype(int), 0, W - 1)
py = np.clip(((1.0 - uv[:, 1]) * (H - 1)).astype(int), 0, H - 1)
vcol = img[py, px].astype(np.float64)  # (V,3)

# k-means quantize the per-vertex colors -> N flat palette entries
centroids, labels = kmeans2(vcol, N, minit="++", seed=0)
# drop empty clusters
used = np.unique(labels)
palette = np.clip(centroids[used], 0, 255).astype(np.uint8)
remap = {old: i for i, old in enumerate(used)}
labels = np.array([remap[l] for l in labels])
quant = palette[labels]  # (V,3)
print(f"palette ({len(palette)} colors):")
for c in palette:
    print("  #%02x%02x%02x" % tuple(c))

# bake as vertex colors, strip texture, export
rgba = np.concatenate([quant, np.full((V, 1), 255, np.uint8)], axis=1)
mesh.visual = trimesh.visual.color.ColorVisuals(mesh=mesh, vertex_colors=rgba)
mesh.export(OUT)
print("exported", OUT)

# palette swatch
sw_h, sw_w = 80, 80 * len(palette)
sw = np.zeros((sw_h, sw_w, 3), np.uint8)
for i, c in enumerate(palette):
    sw[:, i * 80:(i + 1) * 80] = c
Image.fromarray(sw).save(OUT.rsplit(".", 1)[0] + "_palette.png")
print("palette swatch ->", OUT.rsplit(".", 1)[0] + "_palette.png")
