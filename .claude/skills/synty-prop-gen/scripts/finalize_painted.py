"""Stage 4 (painted track) — finalize a Hunyuan-PAINTED glb for the game.

KEEP THE PAINTED MESH EXACTLY AS-IS. Hunyuan's paint output is a non-watertight, multi-shell
mesh (thousands of open patch seams). It renders correctly in Godot as delivered, but ANY
geometry processing corrupts it:
  - Limited Dissolve folds faces across the open gaps -> "crushed",
  - normals_make_consistent can't orient a non-manifold mesh -> flips patches inward -> Godot
    culls them -> "holes",
  - auto-smooth writes custom split normals that read as dented on the low-poly result.
(We learned this the hard way — every one of those steps made the bench/barrel look bad.)

So this stage does ONLY the safe, transform/texture work the Mac needs:
  - downsize the baked diffuse texture (2048 -> 512: sharp on a low-poly prop, tiny to commit),
  - normalize: scale bbox height to target metres, centre X/Y, base at floor (min up -> 0).
No dissolve, no normals recalc, no shading change, no weld.

  blender --background --python finalize_painted.py -- <painted.glb> <out.glb> [tex=512] [target_height_m=1.0]
"""
import bpy, sys
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
IN, OUT = argv[0], argv[1]
TEX = int(argv[2]) if len(argv) > 2 else 512
TARGET_HEIGHT = float(argv[3]) if len(argv) > 3 else 1.0   # bbox height in metres (1 unit = 1 m)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=IN)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
if not meshes:
    print("NO MESH"); sys.exit(1)
bpy.ops.object.select_all(action="DESELECT")
for o in meshes:
    o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
obj = bpy.context.view_layer.objects.active
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
print("painted tris (kept as-is):", len(obj.data.polygons))

# downsize the baked texture(s) — scale + pack so the GLB export embeds the smaller image
for img in list(bpy.data.images):
    try:
        if max(img.size) > TEX:
            img.scale(TEX, TEX); img.pack()
            print("texture downsized ->", TEX, img.name)
    except Exception as e:
        print("tex skip", img.name, e)

# normalize transform only (geometry untouched)
def bounds():
    mn = [1e9] * 3; mx = [-1e9] * 3
    for c in obj.bound_box:
        w = obj.matrix_world @ Vector(c)
        for i in range(3):
            mn[i] = min(mn[i], w[i]); mx[i] = max(mx[i], w[i])
    return mn, mx

mn, mx = bounds(); size = [mx[i] - mn[i] for i in range(3)]
obj.scale = (TARGET_HEIGHT / size[2],) * 3
bpy.ops.object.transform_apply(scale=True)
mn, mx = bounds()
obj.location.x -= (mn[0] + mx[0]) / 2
obj.location.y -= (mn[1] + mx[1]) / 2
obj.location.z -= mn[2]
bpy.ops.object.transform_apply(location=True)

bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB")
print("final tris:", len(obj.data.polygons), "-> saved", OUT)
